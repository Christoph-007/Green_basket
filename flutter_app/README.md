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
with `--dart-define=SOCKET_URL=...` if needed. Without `API_URL`, the
previous hard-coded LAN address is used.

## Tests

```bash
flutter analyze
flutter test
```

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
