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
