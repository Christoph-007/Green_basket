# Green Basket — Flutter app

One app for customers, merchants and admins of the Green Basket marketplace.
The backend is in `../backend` (Node.js + Express + MongoDB).

## Requirements

- Flutter 3.38.x (Dart 3.10) — matches `pubspec.lock`
- A running backend (`cd ../backend && npm install && npm run dev`, port 5002)

## Running against your backend

The API address is set at run/build time with `--dart-define`
(see `lib/config/constants.dart`):

```bash
# Android emulator (10.0.2.2 is the host machine)
flutter run --dart-define=API_URL=http://10.0.2.2:5002/api

# iOS simulator
flutter run --dart-define=API_URL=http://localhost:5002/api

# Real device on the same Wi-Fi (use your computer's LAN IP)
flutter run --dart-define=API_URL=http://192.168.1.20:5002/api
```

The Socket.IO URL is derived from `API_URL` (without `/api`); override it
with `--dart-define=SOCKET_URL=...` if needed. Without `API_URL` the app
uses `http://10.0.2.2:5002/api` on Android and `http://localhost:5002/api`
everywhere else (a real phone needs `API_URL` set to your computer's LAN IP).

### A backend change doesn't show up in the app?

Almost always one of these:

- The backend process is still the old one. Restart it (`npm run dev` restarts on save; `npm start` does not).
- The app is talking to a different backend than the one you edited. The API address is baked in at build time, so check the `--dart-define=API_URL=...` you launched with.
- The app was only hot-reloaded. Stop it and run `flutter run ...` again after changing `API_URL` or any `const`/startup code.
- A real device cannot reach `localhost` or `10.0.2.2`; use your computer's LAN IP.

Run `cd ../backend && npm run check:api` to confirm every call the app makes
matches a route the backend serves.

## Push notifications (optional)

The app runs without them. To turn them on:

- **iOS:** `ios/Runner/GoogleService-Info.plist` is already in the repo.
- **Android:** download `google-services.json` for the Android app
  (`com.greenbasket.greenbasket_app`) from the Firebase console and put it in
  `android/app/`. Then add the Google Services Gradle plugin:
  `id("com.google.gms.google-services") version "4.4.2" apply false` in
  `android/settings.gradle.kts` and `id("com.google.gms.google-services")` in
  the `plugins` block of `android/app/build.gradle.kts`.
  Without the file, `Firebase.initializeApp()` fails on Android, which is
  caught in `lib/main.dart`, and push is simply disabled.

## Tests

```bash
flutter analyze
flutter test
```

`test/single_flight_test.dart` covers the logic that makes several requests
share one token refresh (so parallel 401s no longer sign the user out).

`test/api_integration_test.dart` exercises the real repositories against a
real backend (cart, quote, checkout, cancel, wallet, referral, delivery
zones). It is skipped unless `API_URL` is given:

```bash
cd ../backend
MONGODB_URI=mongodb://127.0.0.1:27017/gb_e2e node scripts/seed-e2e.js   # wipes that DB
MONGODB_URI=mongodb://127.0.0.1:27017/gb_e2e PORT=5002 node server.js

cd ../flutter_app
flutter test test/api_integration_test.dart --dart-define=API_URL=http://127.0.0.1:5002/api
```

The backend also checks that every API call in this app matches a backend
route: `cd ../backend && npm run check:api`.

## UI conventions

These keep the three roles (customer, merchant, admin) looking and behaving alike.

**Design tokens.** Colours, spacing, radius and text styles live in `lib/config/theme.dart`
(`AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`). Do not write `Color(0x...)` in a
screen; add a named token instead. Order statuses get their colour, icon and label from
`OrderStatusStyle` (`lib/config/status_style.dart`).

**Shared widgets** (`lib/widgets/common/`): `GBButton`, `GBCard`, `GBAppBar`, `GBTextField`,
`GBGradientHeader`, `GBStatCard`, `GBStatusChip`, `GBSnack`, `LazyIndexedStack`.
Extend one of these with an optional parameter before hand-building a new variant.

**Money.** Format amounts with `AppHelpers.formatCurrency`, `formatCurrencyFlexible` (API
values that may be text or null) or `formatPrice` (product prices). Do not build `'₹$x'` by hand.

**Messages.** Use `GBSnack.success / error / info / warning / plain`, not `Get.snackbar`.

**Accessibility.** Every `IconButton` has a `tooltip`. Text and fills must keep 4.5:1 contrast;
`test/contrast_test.dart` checks the palette. Use `AppColors.textHint` for placeholders only.
Do not use 9 or 10 px text.

**State management (one rule).**
- Server data, lists, loading and error state live in a GetX controller and are shown with `Obx`.
- `setState` is fine for small local UI state: a password visibility toggle, a selected chip,
  an animation, a text controller.
- If a `StatefulWidget` stores data that came from an API, move it to the screen's controller.
- Do not migrate screens in bulk; apply the rule when you touch a screen for another reason.

**Fonts.** Poppins is bundled in `assets/fonts/`. After changing `pubspec.yaml` do a full
restart, not a hot reload.
