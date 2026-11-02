# GreenBasket Flutter — Comprehensive Testing Strategy

## Testing Pyramid

```
                    ▲
                   /E\      E2E Tests (5%)
                  /   \     - Critical user flows
                 /     \    - 10-15 tests
                /-------\   
               /  Wid   \   Widget Tests (25%)
              /   get    \  - Component testing
             /   Tests    \ - 50-80 tests
            /-------------\
           /     Unit      \ Unit Tests (70%)
          /      Tests      \ - Business logic
         /                   \ - 200+ tests
        /---------------------\
```

---

## 1. Unit Testing Strategy

### 1.1 What to Test

**Blocs/Cubits** (Priority: HIGH):
- All event handlers
- State transitions
- Error handling
- Edge cases

**Repositories** (Priority: HIGH):
- API call mapping
- Error handling
- Data transformation (model → entity)
- Caching logic

**Utilities** (Priority: MEDIUM):
- Validators
- Formatters
- Extensions
- Debouncer

**Models** (Priority: LOW):
- JSON serialization/deserialization
- `toEntity()` conversions

### 1.2 Example: Testing AuthBloc

```dart
// test/presentation/blocs/auth/auth_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUser = User(id: '1', name: 'Test User', email: tEmail);
    const tTokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when login succeeds',
      build: () {
        when(() => mockAuthRepository.login(tEmail, tPassword))
            .thenAnswer((_) async => Right((tUser, tTokens)));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLoginRequested(
        email: tEmail,
        password: tPassword,
      )),
      expect: () => [
        AuthLoading(),
        Authenticated(user: tUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.login(tEmail, tPassword)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockAuthRepository.login(tEmail, tPassword))
            .thenAnswer((_) async => Left(ServerFailure('Server error')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLoginRequested(
        email: tEmail,
        password: tPassword,
      )),
      expect: () => [
        AuthLoading(),
        AuthError(message: 'Server error'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when logout succeeds',
      build: () {
        when(() => mockAuthRepository.logout())
            .thenAnswer((_) async => Right(unit));
        return authBloc;
      },
      seed: () => Authenticated(user: tUser),
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );
  });
}
```

### 1.3 Example: Testing Repository

```dart
// test/data/repositories/auth_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

class MockAuthApi extends Mock implements AuthApi {}
class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthApi mockAuthApi;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockAuthApi = MockAuthApi();
    mockSecureStorage = MockSecureStorage();
    repository = AuthRepositoryImpl(
      authApi: mockAuthApi,
      secureStorage: mockSecureStorage,
    );
  });

  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    final tAuthResponse = AuthResponse(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      user: UserModel(id: '1', name: 'Test', email: tEmail),
    );

    test('should return User and tokens when login succeeds', () async {
      // arrange
      when(() => mockAuthApi.login(any()))
          .thenAnswer((_) async => ApiResponse(
                success: true,
                data: tAuthResponse,
              ));
      when(() => mockSecureStorage.saveTokens(any(), any()))
          .thenAnswer((_) async => {});

      // act
      final result = await repository.login(tEmail, tPassword);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (data) {
          expect(data.$1.email, tEmail);
          expect(data.$2.accessToken, 'access_token');
        },
      );
      verify(() => mockSecureStorage.saveTokens('access_token', 'refresh_token'))
          .called(1);
    });

    test('should return ServerFailure when API throws DioException', () async {
      // arrange
      when(() => mockAuthApi.login(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: ServerException('Server error'),
          type: DioExceptionType.badResponse,
        ),
      );

      // act
      final result = await repository.login(tEmail, tPassword);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should not return success'),
      );
    });
  });
}
```

### 1.4 Example: Testing Validators

```dart
// test/core/utils/validators_test.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('should return null for valid email', () {
        expect(Validators.email('test@example.com'), null);
        expect(Validators.email('user.name+tag@example.co.uk'), null);
      });

      test('should return error for invalid email', () {
        expect(Validators.email(''), 'Email is required');
        expect(Validators.email('invalid'), 'Enter a valid email');
        expect(Validators.email('test@'), 'Enter a valid email');
        expect(Validators.email('@example.com'), 'Enter a valid email');
      });
    });

    group('password', () {
      test('should return null for valid password', () {
        expect(Validators.password('Password1'), null);
        expect(Validators.password('MyP@ssw0rd'), null);
      });

      test('should return error for invalid password', () {
        expect(Validators.password(''), 'Password is required');
        expect(Validators.password('short'), 'Password must be at least 6 characters');
        expect(Validators.password('alllowercase1'), 'Password must contain at least one uppercase letter');
        expect(Validators.password('ALLUPPERCASE1'), 'Password must contain at least one lowercase letter');
        expect(Validators.password('NoNumbers'), 'Password must contain at least one number');
      });
    });

    group('phone', () {
      test('should return null for valid phone', () {
        expect(Validators.phone('9876543210'), null);
        expect(Validators.phone('1234567890'), null);
      });

      test('should return error for invalid phone', () {
        expect(Validators.phone(''), 'Phone number is required');
        expect(Validators.phone('123'), 'Enter a valid 10-digit phone number');
        expect(Validators.phone('12345678901'), 'Enter a valid 10-digit phone number');
        expect(Validators.phone('abcdefghij'), 'Enter a valid 10-digit phone number');
      });
    });
  });
}
```

### 1.5 Running Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/presentation/blocs/auth/auth_bloc_test.dart

# Run tests with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Run tests in watch mode (requires fswatch on macOS)
flutter test --watch
```

**Coverage Target**: ≥ 80% for blocs, repositories, and utilities

---

## 2. Widget Testing Strategy

### 2.1 What to Test

**Reusable Components** (Priority: HIGH):
- Rendering with different props
- User interactions (tap, input, swipe)
- State changes
- Edge cases (loading, error, empty)

**Screens** (Priority: MEDIUM):
- Initial render with mocked Bloc
- User flows (form submission, navigation)
- Error states

### 2.2 Example: Testing GBPrimaryButton

```dart
// test/presentation/widgets/buttons/gb_primary_button_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GBPrimaryButton', () {
    testWidgets('renders label correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GBPrimaryButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GBPrimaryButton(
              label: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GBPrimaryButton));
      await tester.pumpAndSettle();

      expect(pressed, true);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GBPrimaryButton(
              label: 'Test Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GBPrimaryButton(
              label: 'Test Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GBPrimaryButton(
              label: 'Test Button',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
```

### 2.3 Example: Testing ProductCard

```dart
// test/presentation/widgets/cards/product_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  group('ProductCard', () {
    final testProduct = Product(
      id: '1',
      name: 'Fresh Tomatoes',
      price: 49.99,
      comparePrice: 69.99,
      unit: 'kg',
      primaryImage: 'https://example.com/tomato.jpg',
      averageRating: 4.5,
      totalReviews: 128,
      tags: ['organic'],
    );

    testWidgets('renders product information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('Fresh Tomatoes'), findsOneWidget);
      expect(find.text('₹49.99'), findsOneWidget);
      expect(find.text('₹69.99'), findsOneWidget);
      expect(find.text('per kg'), findsOneWidget);
    });

    testWidgets('shows discount badge when comparePrice exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('-29%'), findsOneWidget);
    });

    testWidgets('shows organic tag when product is organic', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('Organic'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProductCard));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('shows Add button when not in cart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              isInCart: false,
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsOneWidget);
      expect(find.byType(GBQuantitySelector), findsNothing);
    });

    testWidgets('shows quantity selector when in cart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              isInCart: true,
              cartQuantity: 2,
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsNothing);
      expect(find.byType(GBQuantitySelector), findsOneWidget);
    });
  });
}
```

### 2.4 Example: Testing LoginScreen with Mocked Bloc

```dart
// test/presentation/screens/auth/login_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders all UI elements', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Log in to continue'), findsOneWidget);
      expect(find.byType(GBTextField), findsNWidgets(2)); // Email + Password
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap login without entering data
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('dispatches login event when form is valid', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid credentials
      await tester.enterText(
        find.byType(GBTextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(GBTextField).last,
        'Password1',
      );

      // Tap login
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(AuthLoginRequested(
            email: 'test@example.com',
            password: 'Password1',
          ))).called(1);
    });

    testWidgets('shows loading indicator when state is AuthLoading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar when state is AuthError', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          AuthLoading(),
          AuthError(message: 'Invalid credentials'),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
```

---

## 3. Integration Testing Strategy

### 3.1 Critical User Flows to Test

1. **Authentication Flow**: Signup → OTP → Login → Home
2. **Product Browse & Add to Cart**: Home → Product Detail → Add to Cart → Cart
3. **Checkout Flow**: Cart → Checkout (Address, Slot, Payment) → Order Success
4. **Order Tracking**: Orders → Order Detail
5. **Profile Management**: Profile → Edit Profile → Save

### 3.2 Example: E2E Checkout Flow

```dart
// integration_test/checkout_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:greenbasket/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Checkout Flow E2E', () {
    testWidgets('complete checkout from cart to order success', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Assume user is already logged in and has items in cart
      // Navigate to cart
      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();

      // Verify cart has items
      expect(find.byType(CartItemCard), findsWidgets);

      // Tap proceed to checkout
      await tester.tap(find.text('Proceed to Checkout'));
      await tester.pumpAndSettle();

      // Step 1: Select address
      expect(find.text('Delivery Address'), findsOneWidget);
      await tester.tap(find.byType(RadioListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Select delivery slot
      expect(find.text('Delivery Slot'), findsOneWidget);
      await tester.tap(find.text('9 AM – 11 AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Select payment method
      expect(find.text('Payment Method'), findsOneWidget);
      await tester.tap(find.text('Cash on Delivery'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Review and place order
      expect(find.text('Order Review'), findsOneWidget);
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle(Duration(seconds: 3)); // Wait for API

      // Verify order success screen
      expect(find.text('Order Placed!'), findsOneWidget);
      expect(find.textContaining('GB'), findsOneWidget); // Order ID
    });
  });
}
```

### 3.3 Running Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/

# Run specific test
flutter test integration_test/checkout_flow_test.dart

# Run with driver (for reporting)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/checkout_flow_test.dart
```

---

## 4. Golden Testing (Visual Regression)

### 4.1 Setup

```yaml
# pubspec.yaml (dev_dependencies)
golden_toolkit: ^0.15.0
```

### 4.2 Example: Golden Test for ProductCard

```dart
// test/presentation/widgets/cards/product_card_golden_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('ProductCard Golden Tests', () {
    testGoldens('ProductCard renders correctly', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ])
        ..addScenario(
          name: 'Default',
          widget: ProductCard(product: testProduct),
        )
        ..addScenario(
          name: 'With Discount',
          widget: ProductCard(product: testProductWithDiscount),
        )
        ..addScenario(
          name: 'In Cart',
          widget: ProductCard(
            product: testProduct,
            isInCart: true,
            cartQuantity: 2,
          ),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'product_card');
    });
  });
}
```

**Generate Goldens**:
```bash
flutter test --update-goldens
```

---

## 5. Performance Testing

### 5.1 Frame Rate Monitoring

```dart
// test/performance/scroll_performance_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Product list scrolls at 60fps', (tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    await binding.watchPerformance(() async {
      final listFinder = find.byType(Scrollable);
      await tester.fling(listFinder, Offset(0, -500), 10000);
      await tester.pumpAndSettle();
    });

    final summary = binding.reportData!;
    expect(summary['average_frame_build_time_millis'], lessThan(16)); // 60fps
  });
}
```

---

## 6. Test Coverage Goals

| Layer | Target Coverage | Priority |
|---|---|---|
| Blocs/Cubits | ≥ 90% | Critical |
| Repositories | ≥ 85% | Critical |
| Models | ≥ 70% | Medium |
| Utilities | ≥ 90% | High |
| Widgets | ≥ 60% | Medium |
| Screens | ≥ 40% | Low |
| **Overall** | **≥ 80%** | **Target** |

---

## 7. CI/CD Integration

### 7.1 GitHub Actions Workflow

```yaml
# .github/workflows/test.yml

name: Flutter Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Run unit & widget tests
        run: flutter test --coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
      
      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage is below 80%: $COVERAGE%"
            exit 1
          fi
```

---

## 8. Testing Best Practices

1. **AAA Pattern**: Arrange → Act → Assert
2. **One assertion per test**: Focus on single behavior
3. **Descriptive test names**: `should return error when email is invalid`
4. **Mock external dependencies**: Never call real APIs in tests
5. **Test edge cases**: Empty lists, null values, network failures
6. **Fast tests**: Unit tests should run in milliseconds
7. **Deterministic**: Tests should always produce same result
8. **Independent**: Tests should not depend on each other
9. **Clean up**: Always dispose controllers, close streams
10. **Test user behavior**: Not implementation details

---

## 9. Test Maintenance

- **Run tests before every commit**
- **Fix failing tests immediately** (don't skip or ignore)
- **Update tests when refactoring**
- **Review test coverage in PRs**
- **Archive obsolete tests** (don't delete, comment why)
- **Keep test data factories** in `test/fixtures/`
- **Document complex test setups**

---

## 10. Quick Reference Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific file
flutter test test/path/to/file_test.dart

# Run tests matching name
flutter test --name "AuthBloc"

# Run integration tests
flutter test integration_test/

# Update golden files
flutter test --update-goldens

# Run tests in watch mode (requires fswatch)
flutter test --watch

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```
