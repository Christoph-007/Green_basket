# GreenBasket Flutter — Complete Implementation Guide

> **Step-by-step instructions to build the GreenBasket mobile app from scratch**
> Based on the [Frontend Specification](./README.md)

---

## Prerequisites

- **Flutter SDK**: 3.22.0 or higher ([install guide](https://docs.flutter.dev/get-started/install))
- **Dart**: 3.4.0 or higher (comes with Flutter)
- **IDE**: VS Code with Flutter extension OR Android Studio
- **Device/Emulator**: Android device (API 21+) or iOS device (iOS 11+)
- **Backend**: GreenBasket backend running locally or deployed (see `backend/README.md`)
- **Tools**: Git, Android SDK, Xcode (for iOS)

---

## Phase 1: Project Setup & Foundation

### Step 1.1: Create Flutter Project

```bash
# Navigate to your workspace
cd ~/Desktop/Projects/GreenBasket

# Create Flutter app
flutter create frontend --org com.greenbasket --platforms android,ios

cd frontend

# Verify setup
flutter doctor
flutter run  # Should show default counter app
```

### Step 1.2: Configure `pubspec.yaml`

Replace the `dependencies` section with:

```yaml
name: greenbasket
description: Farm-fresh grocery delivery app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Networking
  dio: ^5.4.3
  retrofit: ^4.1.0
  json_annotation: ^4.9.0
  connectivity_plus: ^6.0.3

  # Navigation
  go_router: ^14.2.0

  # Dependency Injection
  get_it: ^7.6.9
  injectable: ^2.4.1

  # Local Storage
  hive_flutter: ^2.0.0
  flutter_secure_storage: ^9.2.2

  # UI & Design
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.10
  lottie: ^3.1.2
  google_fonts: ^6.2.1
  smooth_page_indicator: ^1.1.0
  flutter_staggered_grid_view: ^0.7.0
  pinput: ^5.0.0

  # Firebase
  firebase_core: ^3.3.0
  firebase_messaging: ^15.0.4

  # Payments
  flutter_stripe: ^10.1.1
  flutter_stripe_android: ^10.1.1

  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.3.0
  share_plus: ^9.0.0
  image_picker: ^1.1.2
  permission_handler: ^11.3.1
  flutter_rating_bar: ^4.0.1
  pull_to_refresh_flutter3: ^2.0.2
  dartz: ^0.10.1  # For Either type (functional error handling)

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.3
  build_runner: ^2.4.11
  retrofit_generator: ^8.1.2
  json_serializable: ^6.8.0
  injectable_generator: ^2.6.1
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/images/onboarding/
    - assets/images/placeholders/
    - assets/images/empty_states/
    - assets/icons/
    - assets/icons/payment/
    - assets/animations/
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
          weight: 400
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
```

Run:
```bash
flutter pub get
```

### Step 1.3: Create Folder Structure

```bash
# From frontend/ directory
mkdir -p lib/core/{constants,theme,network,storage,utils,error,di}
mkdir -p lib/data/{models,datasources/{remote,local},repositories}
mkdir -p lib/domain/{entities,repositories,usecases}
mkdir -p lib/presentation/{blocs,screens,widgets/{buttons,inputs,cards,navigation,feedback,loaders,common}}
mkdir -p lib/routes
mkdir -p assets/{images/{onboarding,placeholders,empty_states},icons/payment,animations,fonts}
```

### Step 1.4: Download Assets

**Fonts**: Download Poppins from [Google Fonts](https://fonts.google.com/specimen/Poppins)
- Save `Poppins-Regular.ttf`, `Poppins-Medium.ttf`, `Poppins-SemiBold.ttf`, `Poppins-Bold.ttf` to `assets/fonts/`

**Lottie Animations**: Download from [LottieFiles](https://lottiefiles.com/)
- `splash_logo.json` — search "basket" or "grocery logo"
- `loading_spinner.json` — search "green loading"
- `success_check.json` — search "success checkmark"
- `empty_cart.json` — search "empty cart"
- `error.json` — search "error shake"
- Save to `assets/animations/`

**Placeholder Images**: Create or download simple placeholders
- `product_placeholder.png` (300×300px, gray box with "Product" text)
- `avatar_placeholder.png` (100×100px, gray circle)
- Save to `assets/images/placeholders/`

### Step 1.5: Configure Environment

Create `lib/core/constants/app_config.dart`:

```dart
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:6000', // Change to your backend URL
  );
  
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_YOUR_STRIPE_TEST_KEY',
  );
}
```

---

## Phase 2: Design System Implementation

### Step 2.1: Colors

Create `lib/core/constants/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF40916C);
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color primarySurface = Color(0xFFD8F3DC);

  // Secondary
  static const Color secondary = Color(0xFFE76F51);
  static const Color secondaryLight = Color(0xFFF4A261);
  static const Color secondaryDark = Color(0xFFD62828);

  // Neutrals
  static const Color neutral900 = Color(0xFF1A1A2E);
  static const Color neutral700 = Color(0xFF4A4A68);
  static const Color neutral500 = Color(0xFF7C7C9A);
  static const Color neutral300 = Color(0xFFC4C4D4);
  static const Color neutral100 = Color(0xFFF0F0F5);
  static const Color neutral50 = Color(0xFFF8F8FC);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF2D6A4F);
  static const Color successLight = Color(0xFFD8F3DC);
  static const Color error = Color(0xFFD62828);
  static const Color errorLight = Color(0xFFFFE0E0);
  static const Color warning = Color(0xFFF4A261);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF457B9D);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Special
  static const Color organic = Color(0xFF52B788);
  static const Color premium = Color(0xFFFFD700);
  static const Color rating = Color(0xFFFFB703);
  static const Color discount = Color(0xFFD62828);
  static const Color shimmer = Color(0xFFE8E8EE);
  static const Color shimmerHighlight = Color(0xFFF5F5FA);
}
```

### Step 2.2: Typography

Create `lib/core/constants/app_typography.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle _base(double size, FontWeight weight, double height, double letterSpacing) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      letterSpacing: letterSpacing,
    );
  }

  // Display
  static TextStyle displayLg = _base(32, FontWeight.w700, 40, -0.5);
  static TextStyle displayMd = _base(28, FontWeight.w700, 36, -0.25);
  static TextStyle displaySm = _base(24, FontWeight.w600, 32, 0);

  // Heading
  static TextStyle headingLg = _base(22, FontWeight.w600, 28, 0);
  static TextStyle headingMd = _base(20, FontWeight.w600, 26, 0);
  static TextStyle headingSm = _base(18, FontWeight.w600, 24, 0);

  // Title
  static TextStyle titleLg = _base(16, FontWeight.w600, 22, 0.15);
  static TextStyle titleMd = _base(14, FontWeight.w600, 20, 0.1);
  static TextStyle titleSm = _base(13, FontWeight.w500, 18, 0.1);

  // Body
  static TextStyle bodyLg = _base(16, FontWeight.w400, 24, 0.5);
  static TextStyle bodyMd = _base(14, FontWeight.w400, 20, 0.25);
  static TextStyle bodySm = _base(12, FontWeight.w400, 18, 0.4);

  // Caption & Overline
  static TextStyle caption = _base(11, FontWeight.w400, 16, 0.4);
  static TextStyle overline = _base(10, FontWeight.w500, 14, 1.5);

  // Button
  static TextStyle buttonLg = _base(16, FontWeight.w600, 20, 0.5);
  static TextStyle buttonMd = _base(14, FontWeight.w600, 18, 0.5);
  static TextStyle buttonSm = _base(12, FontWeight.w600, 16, 0.5);
}
```

### Step 2.3: Spacing, Radius, Shadows

Create `lib/core/constants/app_spacing.dart`:

```dart
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}
```

Create `lib/core/constants/app_radius.dart`:

```dart
import 'package:flutter/material.dart';

class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
}
```

Create `lib/core/constants/app_shadows.dart`:

```dart
import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> none = [];
  
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.16),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> highest = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.20),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
```

### Step 2.4: Animation Durations

Create `lib/core/constants/app_durations.dart`:

```dart
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration splash = Duration(milliseconds: 2000);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration success = Duration(milliseconds: 1200);
  static const Duration button = Duration(milliseconds: 100);
}
```

### Step 2.5: Theme

Create `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.white,
        background: AppColors.neutral50,
      ),
      scaffoldBackgroundColor: AppColors.neutral50,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: AppTypography.headingLg.copyWith(color: AppColors.neutral900),
        iconTheme: const IconThemeData(color: AppColors.neutral700),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLg,
        displayMedium: AppTypography.displayMd,
        displaySmall: AppTypography.displaySm,
        headlineLarge: AppTypography.headingLg,
        headlineMedium: AppTypography.headingMd,
        headlineSmall: AppTypography.headingSm,
        titleLarge: AppTypography.titleLg,
        titleMedium: AppTypography.titleMd,
        titleSmall: AppTypography.titleSm,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.buttonLg,
        labelMedium: AppTypography.buttonMd,
        labelSmall: AppTypography.buttonSm,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.buttonLg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
```

---

**Continue to next section...**
