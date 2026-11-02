# GreenBasket Flutter Frontend — Specification Index

> **Complete architecture & planning guide for the GreenBasket Mini mobile app**
> Generated: 2026-02-13 | **Production-Ready Specification**

This specification is organized into 13 comprehensive documents covering architecture, design, implementation, testing, deployment, and security. A Flutter developer should read them in order for full context, but each is self-contained for reference.

---

## Core Specification Documents

| # | File | Contents |
|---|---|---|
| 01 | [Executive Summary](./01_EXECUTIVE_SUMMARY.md) | Tech stack, project structure, dependencies, network layer, storage strategy, error handling |
| 02 | [Design System](./02_DESIGN_SYSTEM.md) | Color palette, typography, spacing, border radius, shadows, icons, animation tokens |
| 03 | [Screens: Auth & Home](./03_SCREENS_AUTH_HOME.md) | Splash, Onboarding, Login, Sign Up, Forgot Password, OTP, Home Screen |
| 04 | [Screens: Product & Cart](./04_SCREENS_PRODUCT_CART.md) | Categories, Product Listing, Product Detail, Search, Cart, Checkout, Order Success |
| 05 | [Screens: Orders & Profile](./05_SCREENS_ORDERS_PROFILE.md) | Orders List, Order Detail, Profile, Edit Profile, Addresses, Wishlist, Notifications, Settings |
| 06 | [Component Library](./06_COMPONENT_LIBRARY.md) | Buttons, inputs, cards, navigation, feedback, display components — all with props, dimensions, states |
| 07 | [State, Navigation & API](./07_STATE_NAV_API.md) | Bloc architecture, GoRouter routes, Retrofit API services, caching, offline support |
| 08 | [Assets, Timeline & Practices](./08_ASSETS_TIMELINE_PRACTICES.md) | Asset structure, animations, performance, security, testing, 9-week timeline, coding guidelines |

## Implementation & Production Guides

| # | File | Contents |
|---|---|---|
| 09 | [API & Data Models](./09_API_MODELS_MAPPING.md) | Complete API endpoint mapping, request/response models, Retrofit services, Bloc events |
| 10 | [Testing Strategy](./10_TESTING_STRATEGY.md) | Unit, widget, integration, golden tests, coverage goals, CI/CD, testing best practices |
| 11 | [Deployment Guide](./11_DEPLOYMENT_GUIDE.md) | Android/iOS build, signing, store submission, versioning, monitoring, marketing copy |
| 12 | [Performance Optimization](./12_PERFORMANCE_OPTIMIZATION.md) | Build size, runtime performance, memory, startup, animations, profiling, benchmarks |
| 13 | [Security Audit](./13_SECURITY_AUDIT.md) | Authentication, data protection, network security, payments, privacy, compliance checklist |

## Implementation Guides (In Progress)

| File | Contents |
|---|---|
| [Implementation Guide](./IMPLEMENTATION_GUIDE.md) | Phase 1-2: Project setup, design system implementation |
| [Implementation Guide Part 2](./IMPLEMENTATION_GUIDE_PART2.md) | Phase 3-4: Network layer, DI, core components |

---

## Quick Reference

### Project Overview
- **23 screens** specified with full component breakdowns
- **30+ reusable components** with exact dimensions, colors, and states
- **204 backend APIs** fully mapped to frontend implementation
- **State management**: flutter_bloc (Bloc/Cubit pattern)
- **Navigation**: go_router with StatefulShellRoute for bottom tabs
- **API**: Retrofit + Dio with auth interceptor and token refresh
- **Offline**: Hive for cart persistence, product cache, search history
- **Payments**: Stripe PaymentSheet (`flutter_stripe`) — replaces Razorpay
- **Timeline**: 9 weeks across 6 phases
- **Testing**: 80%+ coverage target with unit, widget, integration tests
- **Security**: OWASP Mobile Top 10 compliant, GDPR/CCPA ready

### Key Features
✅ JWT authentication with biometric support  
✅ Product browsing with advanced search & filters  
✅ Offline cart with auto-sync  
✅ Multi-step checkout with Stripe PaymentSheet  
✅ Real-time order tracking  
✅ Push notifications (Firebase)  
✅ Recipe integration with "add to cart"  
✅ Loyalty points & wallet  
✅ Wishlist with price drop alerts  

---

## How to Use This Spec

### For Project Managers
1. **Start with 01** for project overview and tech decisions
2. **Review 08** for timeline and resource planning
3. **Check 11** for deployment and release strategy
4. **Monitor 10** for testing requirements

### For Developers
1. **Read 01-02** to understand architecture and design system
2. **Implement 02** first — create all design system files
3. **Build 06** core components — they're reused everywhere
4. **Follow 08 timeline** for feature implementation order
5. **Reference 07 & 09** when wiring up API calls and state
6. **Use 03-05** as pixel-perfect screen guides
7. **Apply 12** performance optimizations throughout
8. **Follow 13** security checklist before each release

### For QA/Testers
1. **Review 10** for testing strategy and coverage goals
2. **Use 03-05** for functional testing scenarios
3. **Check 12** for performance benchmarks
4. **Verify 13** security requirements

### For DevOps
1. **Follow 11** for build and deployment process
2. **Set up 10** CI/CD pipelines
3. **Configure 12** performance monitoring
4. **Implement 13** security measures

---

## Document Status

| Document | Status | Last Updated |
|---|---|---|
| 01-08 | ✅ Complete | 2026-02-18 |
| 09 | ✅ Complete | 2026-02-18 |
| 10 | ✅ Complete | 2026-02-18 |
| 11 | ✅ Complete | 2026-02-18 |
| 12 | ✅ Complete | 2026-02-18 |
| 13 | ✅ Complete | 2026-02-18 |
| Implementation Guides | 🚧 In Progress | 2026-02-18 |

---

## Quick Start

```bash
# 1. Clone and setup
git clone <repo-url>
cd frontend
flutter pub get

# 2. Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run app
flutter run --dart-define=BASE_URL=http://localhost:6000

# 4. Run tests
flutter test --coverage

# 5. Build release
flutter build apk --release --dart-define=BASE_URL=https://api.greenbasket.com
```

---

## Support

- **Specification Issues**: Create GitHub issue with `[spec]` tag
- **Implementation Questions**: Check implementation guides or ask team
- **Backend API**: See `backend/server.js` for endpoint documentation

