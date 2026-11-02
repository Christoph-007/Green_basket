# GreenBasket — Assets, Animations, Development Timeline & Best Practices

## 9. Assets & Resources

### 9.1 Asset Directory Structure

```
assets/
├── images/
│   ├── onboarding/
│   │   ├── onboarding_1.png       # Farm produce illustration
│   │   ├── onboarding_2.png       # Cart/ordering illustration
│   │   └── onboarding_3.png       # Delivery illustration
│   ├── placeholders/
│   │   ├── product_placeholder.png
│   │   ├── avatar_placeholder.png
│   │   └── category_placeholder.png
│   └── empty_states/
│       ├── empty_cart.png
│       ├── empty_orders.png
│       ├── empty_wishlist.png
│       ├── empty_notifications.png
│       └── empty_search.png
├── icons/
│   ├── logo.svg                   # App logo vector
│   ├── google.svg                 # Google sign-in icon
│   ├── organic_badge.svg
│   ├── premium_badge.svg
│   └── payment/
│       ├── upi.svg
│       ├── card.svg
│       └── cod.svg
├── animations/
│   ├── splash_logo.json           # Lottie: logo entrance
│   ├── loading_spinner.json       # Lottie: green spinner
│   ├── success_check.json         # Lottie: order success checkmark
│   ├── empty_cart.json            # Lottie: empty cart bounce
│   ├── error.json                 # Lottie: error shake
│   └── confetti.json              # Lottie: order placed confetti
└── fonts/
    ├── Poppins-Regular.ttf
    ├── Poppins-Medium.ttf
    ├── Poppins-SemiBold.ttf
    └── Poppins-Bold.ttf
```

### 9.2 Naming Convention
- Snake_case for all assets: `onboarding_1.png`, `empty_cart.json`
- Density variants: `1.5x/`, `2.0x/`, `3.0x/` folders for raster images
- SVGs preferred for icons (no density variants needed)

### 9.3 Font Registration (pubspec.yaml)

```yaml
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

---

## 10. Animations & Micro-Interactions

### 10.1 Page Transitions
- **Default**: `FadeTransition` 300ms `fastOutSlowIn` for all GoRouter routes
- **Modal routes** (bottom sheets, dialogs): `SlideTransition` bottom-up 350ms `easeInOut`
- **Product Detail**: `Hero` animation on product image from ProductCard

### 10.2 Component Animations
| Element | Animation | Duration | Curve |
|---|---|---|---|
| Button press | Scale 1.0 → 0.97 → 1.0 | 100ms | easeIn |
| Wishlist heart | Scale bounce 1.0 → 1.3 → 1.0 + color transition | 250ms | elasticOut |
| Cart badge +1 | Scale pop 1.0 → 1.4 → 1.0 | 200ms | bounceOut |
| Add to cart | Fly-to-cart (small product image arc to cart icon) | 400ms | easeInOut |
| Quantity +/- | Number fade-slide transition | 150ms | easeOut |
| Tab switch | CrossFade between tab bodies | 200ms | easeInOut |
| Pull-to-refresh | Native `RefreshIndicator` (primary color) | system | system |
| Snackbar entry | SlideTransition from bottom | 250ms | easeOut |
| Skeleton shimmer | Linear gradient sweep left-to-right | 1500ms (loop) | linear |
| Card tap | InkWell ripple (default Material) | system | system |
| List item appear | FadeInUp (staggered, 50ms delay per item) | 300ms | easeOut |
| Checkout step | SlideTransition horizontal between steps | 300ms | easeInOut |

### 10.3 Lottie Animations
| Name | File | Loop | Duration | Used In |
|---|---|---|---|---|
| Splash logo | `splash_logo.json` | No | 2000ms | Splash Screen |
| Loading | `loading_spinner.json` | Yes | 1200ms | Full-screen loading overlay |
| Order success | `success_check.json` | No | 1200ms | Order Success Screen |
| Empty cart | `empty_cart.json` | Yes (gentle) | 3000ms | Cart empty state |
| Error | `error.json` | No | 800ms | Error states |
| Confetti | `confetti.json` | No | 2000ms | Order success background |

---

## 11. Features & Considerations

### 11.1 Performance
- **Image caching**: `CachedNetworkImage` with disk cache (max 200 items, 500MB)
- **Lazy loading**: `ListView.builder` / `GridView.builder` everywhere; never `children: []` for dynamic lists
- **Pagination**: 20 items per page, infinite scroll with 300dp load-ahead threshold
- **Debouncing**: 300ms for search, 500ms for quantity changes (API call batching)
- **Build optimization**: `const` constructors wherever possible, `RepaintBoundary` on heavy widgets

### 11.2 Security
- Tokens in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android)
- No API keys in client code — all sensitive ops go through backend
- Input sanitization: trim whitespace, validate formats client-side, server validates authoritatively
- Certificate pinning (optional, via Dio): pin backend SSL cert for production
- ProGuard/R8 obfuscation for Android release builds

### 11.3 Accessibility
- Semantic labels (`Semantics` widget) on all interactive elements
- Touch targets: minimum 48×48dp
- Color contrast: WCAG AA compliant (4.5:1 for text, 3:1 for large text)
- Font scaling: support up to 1.5× system font scale
- Announcing state changes via `SemanticsService.announce`

### 11.4 Testing Strategy

**Unit Tests** (domain + data layers):
- Repository implementations (mock API, verify data mapping)
- Bloc/Cubit logic (bloc_test: given events → assert state sequence)
- Validator functions
- Target: ≥80% coverage

**Widget Tests** (presentation layer):
- Each reusable component (buttons, cards, inputs) — verify rendering, states, interactions
- Screen-level tests with mocked Blocs

**Integration Tests** (end-to-end, on device):
- Login → Browse → Add to Cart → Checkout flow
- Offline cart persistence

**Run commands**:
```bash
# Unit + Widget tests
flutter test

# Integration tests
flutter test integration_test/

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 12. Development Timeline

### Phase 1 — Foundation (Week 1–2)
- Project setup, folder structure, dependencies
- Design system implementation (`app_colors.dart`, theme, typography)
- Network layer (Dio, interceptors, error handling)
- Local storage (Hive, SecureStorage)
- DI container (get_it + injectable)
- Core components: GBPrimaryButton, GBTextField, GBSnackbar, shimmer loaders
- **Milestone**: `flutter run` with placeholder screens, themed correctly

### Phase 2 — Authentication (Week 2–3)
- Auth API integration (login, signup, forgot password, OTP, token refresh)
- AuthBloc with all states
- Splash, Onboarding, Login, Signup, Forgot Password, OTP screens
- Navigation guards (redirect unauthenticated users)
- **Milestone**: Complete auth flow end-to-end with backend

### Phase 3 — Product Browsing (Week 3–5)
- Product, Category API integration
- Home screen with all sections (banners, categories, flash deals, popular, recipes)
- Categories screen
- Product Listing with filter/sort
- Product Detail screen
- Search with debounce, suggestions, results
- Bottom navigation bar
- **Milestone**: Full product browsing experience, search functional

### Phase 4 — Cart & Checkout (Week 5–6)
- Cart API integration + offline persistence
- CartBloc with add/update/remove/coupon
- Cart screen with price summary
- Multi-step checkout (address, slot, payment, review)
- Stripe PaymentSheet integration (`flutter_stripe`)
- Order Success screen
- **Milestone**: Place an order end-to-end

### Phase 5 — Orders & Profile (Week 6–7)
- Orders API integration
- Orders list with tabs (active/completed/cancelled)
- Order detail with tracking timeline
- Profile screen with menu
- Edit profile, address management (CRUD)
- Wishlist screen
- Notifications screen
- Settings screen
- **Milestone**: All screens functional, user management complete

### Phase 6 — Polish & Extended Features (Week 7–9)
- Recipe browsing + "add to cart" from recipe
- Wallet screen
- Loyalty points display
- Referral code screen
- All animations and micro-interactions
- Edge case handling (empty states, error states, offline)
- Performance optimization (profiling, removing jank)
- Accessibility audit
- Testing (unit, widget, integration)
- **Milestone**: Production-quality app ready for QA

### Dependencies

```
Phase 1 ──→ Phase 2 ──→ Phase 3 ──→ Phase 4 ──→ Phase 5 ──→ Phase 6
                            │                        │
                            └── Phase 4 needs ───────┘ (addresses from Phase 5
                                product data)           can be parallelized)
```

> **Note**: Phases 5 and 3–4 can partially overlap — address management and profile features are independent of product/cart work.

---

## 13. Best Practices & Guidelines

### 13.1 Naming Conventions
| Type | Convention | Example |
|---|---|---|
| Files | snake_case | `product_card.dart` |
| Classes | PascalCase | `ProductCard` |
| Variables | camelCase | `totalPrice` |
| Constants | lowerCamelCase | `defaultPadding` |
| Bloc Events | PascalCase (verb) | `AddItemToCart` |
| Bloc States | PascalCase (adj/noun) | `CartLoaded` |
| Routes | lowercase with slashes | `/products/:id` |
| Assets | snake_case | `empty_cart.json` |

### 13.2 Code Organization Principles
1. **Feature-first**: Group by feature, not by type (screens, blocs, models together per feature when in `presentation/blocs/`)
2. **Dependency rule**: Domain knows nothing about Data or Presentation. Data depends on Domain. Presentation depends on Domain.
3. **Single responsibility**: one Bloc per feature, one repository per data domain
4. **Composition over inheritance**: prefer composing widgets with small, focused children

### 13.3 Widget Patterns
- Extract widgets into methods only when they need `BuildContext`; otherwise extract to classes
- Always use `const` constructors
- Keep `build()` methods under 50 lines — extract sub-widgets
- Use `BlocSelector` / `BlocBuilder` with `buildWhen` to minimize rebuilds

### 13.4 Error Handling Pattern
```dart
// Repository
try {
  final response = await api.getProducts();
  return Right(response.data!.map((m) => m.toEntity()).toList());
} on DioException catch (e) {
  return Left(ErrorHandler.handle(e));
} catch (e) {
  return Left(UnknownFailure(e.toString()));
}

// Bloc
on<LoadProducts>((event, emit) async {
  emit(ProductLoading());
  final result = await repository.getProducts();
  result.fold(
    (failure) => emit(ProductError(failure.message)),
    (products) => emit(ProductLoaded(products)),
  );
});
```

### 13.5 Quality Checklist
- [ ] No `dynamic` types (use proper models)
- [ ] All public APIs documented
- [ ] Loading state for every async UI
- [ ] Error state with retry for every data-fetching screen
- [ ] Empty state for every list screen
- [ ] Form validation on all inputs
- [ ] Touch targets ≥ 48dp
- [ ] `const` constructors used
- [ ] No hardcoded strings (use constants or l10n keys)
- [ ] No hardcoded colors (use design system tokens)
- [ ] Tests written for Bloc logic
- [ ] Widget tests for custom components
- [ ] No console prints in production (use logger)

### 13.6 Git Workflow
- Branch naming: `feature/auth-login`, `fix/cart-total`, `refactor/product-card`
- Commit messages: conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`)
- PR size: max 400 lines changed per PR
- Required: 1 review, CI green (tests + lint)

---

## Appendix

### A. Glossary
- **Bloc**: Business Logic Component — manages state via events
- **Cubit**: Simplified Bloc — state changes via method calls (no events)
- **GoRouter**: Declarative routing for Flutter with deep link support
- **Hive**: Lightweight, fast key-value database for Flutter
- **Retrofit**: Type-safe HTTP client generator for Dart

### B. Related Files
- Backend API: [`server.js`](../../server.js) — full endpoint listing
- Backend models: [`src/models/`](../../src/models) — data schema reference
- Backend docs: [`docs/`](../) — API documentation
