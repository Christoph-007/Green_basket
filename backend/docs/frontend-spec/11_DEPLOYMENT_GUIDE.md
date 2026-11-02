# GreenBasket Flutter — Deployment & Release Guide

## Pre-Deployment Checklist

### 1. Code Quality

- [ ] All tests passing (`flutter test`)
- [ ] Code coverage ≥ 80%
- [ ] No lint warnings (`flutter analyze`)
- [ ] Code formatted (`flutter format .`)
- [ ] No debug prints or console.log statements
- [ ] All TODOs resolved or documented
- [ ] Dead code removed
- [ ] Unused imports removed

### 2. Security

- [ ] API keys removed from code (use environment variables)
- [ ] No hardcoded credentials
- [ ] SSL certificate pinning enabled (production)
- [ ] ProGuard/R8 enabled for Android
- [ ] Obfuscation enabled for release builds
- [ ] Sensitive data encrypted in local storage
- [ ] JWT tokens in secure storage only
- [ ] Deep link validation implemented
- [ ] Input sanitization on all forms

### 3. Performance

- [ ] Images optimized (WebP format where possible)
- [ ] Lazy loading implemented for lists
- [ ] Caching strategy verified
- [ ] Network requests optimized (batching, debouncing)
- [ ] App size < 50MB
- [ ] Cold start time < 3 seconds
- [ ] Frame rate ≥ 60fps on target devices
- [ ] Memory leaks checked (DevTools)

### 4. User Experience

- [ ] All screens responsive (tested on multiple devices)
- [ ] Offline mode working correctly
- [ ] Error messages user-friendly
- [ ] Loading states on all async operations
- [ ] Empty states designed and implemented
- [ ] Pull-to-refresh working
- [ ] Back button behavior correct
- [ ] Deep links tested
- [ ] Push notifications working

### 5. Assets & Resources

- [ ] All placeholder images replaced
- [ ] App icons generated (all sizes)
- [ ] Splash screen configured
- [ ] Fonts embedded correctly
- [ ] Lottie animations optimized
- [ ] All images have 1x, 2x, 3x variants
- [ ] Asset licenses documented

---

## Android Deployment

### Step 1: Configure App Signing

Create `android/key.properties`:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=greenbasket
storeFile=../keystore/greenbasket-release.jks
```

**Generate Keystore**:

```bash
keytool -genkey -v -keystore ~/greenbasket-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias greenbasket
```

Move keystore to `android/keystore/greenbasket-release.jks`

### Step 2: Update `android/app/build.gradle`

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.greenbasket.app"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.greenbasket.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Step 3: ProGuard Rules

Create `android/app/proguard-rules.pro`:

```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dio
-keep class com.squareup.okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Stripe
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Your models (adjust package name)
-keep class com.greenbasket.app.data.models.** { *; }
```

### Step 4: Update AndroidManifest.xml

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

    <application
        android:label="GreenBasket"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"/>
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Deep Links -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="greenbasket"/>
                <data android:scheme="https" android:host="greenbasket.com"/>
            </intent-filter>
        </activity>

        <!-- Firebase Messaging -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>
    </application>
</manifest>
```

### Step 5: Network Security Config

Create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
    
    <!-- Only for development/staging -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

### Step 6: Build Release APK/AAB

```bash
# Build APK
flutter build apk --release --dart-define=BASE_URL=https://api.greenbasket.com

# Build App Bundle (for Play Store)
flutter build appbundle --release --dart-define=BASE_URL=https://api.greenbasket.com

# Build with obfuscation
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Output location
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### Step 7: Google Play Store Submission

1. **Create Play Console Account**: https://play.google.com/console
2. **Create App**:
   - App name: GreenBasket
   - Default language: English (US)
   - App/Game: App
   - Free/Paid: Free
3. **Store Listing**:
   - Title: GreenBasket - Fresh Groceries
   - Short description: Farm-fresh groceries delivered to your doorstep
   - Full description: (See marketing copy below)
   - App icon: 512×512px PNG
   - Feature graphic: 1024×500px
   - Screenshots: 2-8 per device type (phone, tablet)
   - Category: Shopping
   - Content rating: Everyone
4. **Upload AAB**: Production → Create release → Upload `app-release.aab`
5. **Release Notes**: Document what's new
6. **Review & Publish**

---

## iOS Deployment

### Step 1: Configure Xcode Project

Open `ios/Runner.xcworkspace` in Xcode:

1. **General Tab**:
   - Display Name: GreenBasket
   - Bundle Identifier: com.greenbasket.app
   - Version: 1.0.0
   - Build: 1
   - Deployment Target: iOS 12.0

2. **Signing & Capabilities**:
   - Team: Select your Apple Developer team
   - Signing Certificate: Apple Distribution
   - Provisioning Profile: App Store profile

### Step 2: Update Info.plist

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <key>CFBundleName</key>
    <string>GreenBasket</string>
    <key>CFBundleDisplayName</key>
    <string>GreenBasket</string>
    <key>CFBundleIdentifier</key>
    <string>com.greenbasket.app</string>
    
    <!-- Permissions -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to scan QR codes and upload product images</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo library access to upload images</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to show nearby stores and delivery options</string>
    
    <!-- Deep Links -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>greenbasket</string>
            </array>
        </dict>
    </array>
    
    <!-- Universal Links -->
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:greenbasket.com</string>
    </array>
</dict>
```

### Step 3: Build Release IPA

```bash
# Clean build
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release --dart-define=BASE_URL=https://api.greenbasket.com

# Build with obfuscation
flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols
```

### Step 4: Archive in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Any iOS Device (arm64)** as target
3. Product → Archive
4. Wait for archive to complete
5. Window → Organizer → Archives
6. Select archive → **Distribute App**
7. Choose **App Store Connect**
8. Upload to App Store Connect

### Step 5: App Store Connect Submission

1. **Create App**: https://appstoreconnect.apple.com
2. **App Information**:
   - Name: GreenBasket
   - Bundle ID: com.greenbasket.app
   - SKU: greenbasket-ios
   - Primary Language: English (US)
3. **Pricing**: Free
4. **App Privacy**: Fill privacy questionnaire
5. **Version Information**:
   - Screenshots: 6.5", 5.5" (required)
   - App Preview: Optional video
   - Description: (See marketing copy below)
   - Keywords: grocery, fresh, organic, delivery, farm
   - Support URL: https://greenbasket.com/support
   - Marketing URL: https://greenbasket.com
6. **Build**: Select uploaded build
7. **Submit for Review**

---

## Environment Configuration

### Development

```bash
# .env.development
BASE_URL=http://localhost:6000
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
FIREBASE_PROJECT_ID=greenbasket-dev
APP_ENV=development
```

### Staging

```bash
# .env.staging
BASE_URL=https://staging-api.greenbasket.com
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
FIREBASE_PROJECT_ID=greenbasket-staging
APP_ENV=staging
```

### Production

```bash
# .env.production
BASE_URL=https://api.greenbasket.com
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx
FIREBASE_PROJECT_ID=greenbasket-prod
APP_ENV=production
```

**Build with environment**:

```bash
flutter build apk --release --dart-define-from-file=.env.production
flutter build ios --release --dart-define-from-file=.env.production
```

---

## App Icons & Splash Screen

### Generate App Icons

Use [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons):

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#2D6A4F"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

```bash
flutter pub run flutter_launcher_icons
```

### Configure Splash Screen

Use [flutter_native_splash](https://pub.dev/packages/flutter_native_splash):

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.10

flutter_native_splash:
  color: "#2D6A4F"
  image: assets/images/splash_logo.png
  android_12:
    image: assets/images/splash_logo.png
    color: "#2D6A4F"
  ios: true
  android: true
```

```bash
flutter pub run flutter_native_splash:create
```

---

## Versioning Strategy

### Semantic Versioning

Format: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Breaking changes (e.g., 2.0.0)
- **MINOR**: New features (e.g., 1.1.0)
- **PATCH**: Bug fixes (e.g., 1.0.1)
- **BUILD**: Build number (auto-increment)

**Update in `pubspec.yaml`**:

```yaml
version: 1.0.0+1
```

### Version Bump Script

```bash
#!/bin/bash
# scripts/bump_version.sh

TYPE=$1  # major, minor, patch

if [ -z "$TYPE" ]; then
  echo "Usage: ./bump_version.sh [major|minor|patch]"
  exit 1
fi

# Extract current version
CURRENT=$(grep "version:" pubspec.yaml | sed 's/version: //')
VERSION=$(echo $CURRENT | cut -d'+' -f1)
BUILD=$(echo $CURRENT | cut -d'+' -f2)

# Parse version
MAJOR=$(echo $VERSION | cut -d'.' -f1)
MINOR=$(echo $VERSION | cut -d'.' -f2)
PATCH=$(echo $VERSION | cut -d'.' -f3)

# Bump version
case $TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

# Increment build
BUILD=$((BUILD + 1))

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD"

# Update pubspec.yaml
sed -i '' "s/version: .*/version: $NEW_VERSION/" pubspec.yaml

echo "Version bumped to $NEW_VERSION"
```

---

## Release Checklist

### Pre-Release

- [ ] All features tested on staging
- [ ] Regression tests passed
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Changelog updated
- [ ] Version bumped
- [ ] Release notes written
- [ ] App Store screenshots updated
- [ ] Marketing materials ready

### Release

- [ ] Build release artifacts
- [ ] Upload to Play Console / App Store Connect
- [ ] Submit for review
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Monitor analytics (Firebase Analytics)
- [ ] Prepare rollback plan

### Post-Release

- [ ] Verify app live on stores
- [ ] Monitor user reviews
- [ ] Track key metrics (DAU, retention, crashes)
- [ ] Respond to critical bugs within 24h
- [ ] Plan next release

---

## Rollback Strategy

### Android (Play Console)

1. Go to Production → Releases
2. Click **Create release** with previous version
3. Upload previous AAB
4. Release to 100% of users

### iOS (App Store Connect)

1. Cannot rollback directly
2. Must submit new build with previous version
3. Request expedited review if critical

**Prevention**: Use staged rollouts (10% → 50% → 100%)

---

## Monitoring & Analytics

### Firebase Crashlytics

```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(MyApp());
}
```

### Firebase Analytics

```dart
// Track screen views
FirebaseAnalytics.instance.logScreenView(
  screenName: 'ProductDetail',
  screenClass: 'ProductDetailScreen',
);

// Track events
FirebaseAnalytics.instance.logEvent(
  name: 'add_to_cart',
  parameters: {
    'product_id': productId,
    'product_name': productName,
    'price': price,
  },
);
```

---

## Marketing Copy

### Short Description (80 chars)

"Farm-fresh groceries delivered to your doorstep. Order now!"

### Full Description

**GreenBasket - Fresh Groceries Delivered**

Get farm-fresh fruits, vegetables, and groceries delivered straight to your home. GreenBasket connects you directly with local farmers and trusted merchants for the freshest produce at the best prices.

**Why Choose GreenBasket?**

🌱 **Farm Fresh**: Sourced directly from local farms
🚚 **Fast Delivery**: Same-day and scheduled delivery slots
💰 **Best Prices**: No middlemen, better value
🏆 **Premium Quality**: Handpicked, quality-checked products
🔒 **Secure Payments**: Multiple payment options including COD
🎁 **Rewards**: Earn loyalty points on every order

**Features:**

• Browse 1000+ fresh products
• Advanced search and filters
• Personalized recommendations
• Recipe inspiration with ingredients
• Real-time order tracking
• Flexible delivery slots
• Wallet and offers
• 24/7 customer support

**Categories:**

Fruits, Vegetables, Dairy, Bakery, Organic, Exotic, Herbs, Staples, and more!

Download GreenBasket today and experience the freshness!

---

## Support & Contact

- **Website**: https://greenbasket.com
- **Support Email**: support@greenbasket.com
- **Privacy Policy**: https://greenbasket.com/privacy
- **Terms of Service**: https://greenbasket.com/terms
