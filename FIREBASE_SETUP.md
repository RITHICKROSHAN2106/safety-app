# Firebase Configuration Guide

This guide will help you set up Firebase for your Women Safety App.

## 📋 Prerequisites

- A Google account
- Firebase CLI (optional but recommended)
- Flutter SDK installed
- Android Studio / Xcode

---

## 🔥 Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `women-safety-app`
4. Enable Google Analytics (recommended)
5. Click **"Create project"**

---

## 📱 Step 2: Register Android App

### 2.1 Add Android App

1. In Firebase Console, click the **Android icon** (⚙️)
2. **Package name**: `com.womensafety.women_safety`
   - ⚠️ Must match `applicationId` in `android/app/build.gradle`
3. **App nickname**: Women Safety (optional)
4. **Debug signing certificate SHA-1**: (for Google Sign-In)
   ```powershell
   # Get SHA-1 from your keystore:
   cd android
   ./gradlew signingReport
   # Copy SHA-1 from output
   ```
5. Click **"Register app"**

### 2.2 Download Configuration File

1. Download `google-services.json`
2. Place it in: `women_safety/android/app/google-services.json`

### 2.3 Add Firebase SDK

**File**: `android/build.gradle` (already configured)
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

**File**: `android/app/build.gradle` (already configured)
```gradle
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
}
```

---

## 🍎 Step 3: Register iOS App

### 3.1 Add iOS App

1. In Firebase Console, click the **iOS icon** (⚙️)
2. **Bundle ID**: `com.womensafety.womenSafety`
   - ⚠️ Must match Bundle Identifier in Xcode
   - Open `ios/Runner.xcworkspace` in Xcode
   - Go to Runner → General → Bundle Identifier
3. **App nickname**: Women Safety (optional)
4. Click **"Register app"**

### 3.2 Download Configuration File

1. Download `GoogleService-Info.plist`
2. Open `ios/Runner.xcworkspace` in Xcode
3. Drag `GoogleService-Info.plist` into Runner folder (below `Runner/Info.plist`)
4. ✅ Check "Copy items if needed"
5. ✅ Check "Runner" target

### 3.3 Update Info.plist

**File**: `ios/Runner/Info.plist`

Add these entries inside `<dict>`:

```xml
<!-- Firebase Cloud Messaging -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>

<!-- Background modes for notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>Camera access is required to record emergency videos.</string>

<!-- Microphone permission -->
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required to record emergency audio.</string>

<!-- Location permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required to share your location during emergencies.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Location access is required to track your location for safety.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location access is required to track your location for safety.</string>

<!-- Speech recognition -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is required for voice-activated SOS.</string>
```

---

## 🌐 Step 4: Register Web App (Optional)

### 4.1 Add Web App

1. In Firebase Console, click the **Web icon** (⚙️)
2. **App nickname**: Women Safety Web
3. ✅ Check "Also set up Firebase Hosting"
4. Click **"Register app"**

### 4.2 Add Firebase Configuration

**File**: `women_safety/web/index.html`

Find `<!-- TODO: Add Firebase Config -->` and replace with:

```html
<script type="module">
  // Import the functions you need from the SDKs you need
  import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js";
  import { getAnalytics } from "https://www.gstatic.com/firebasejs/10.7.0/firebase-analytics.js";
  
  // Your web app's Firebase configuration
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID",
    measurementId: "YOUR_MEASUREMENT_ID"
  };

  // Initialize Firebase
  const app = initializeApp(firebaseConfig);
  const analytics = getAnalytics(app);
</script>
```

**🔑 Get these values from:**
Firebase Console → Project Settings → Your apps → Web app

---

## 🔔 Step 5: Enable Firebase Services

### 5.1 Enable Authentication

1. Go to **Build → Authentication**
2. Click **"Get started"**
3. Enable these sign-in methods:
   - ✅ **Email/Password**
   - ✅ **Google** (for social login)
   - ✅ **Phone** (for OTP)

### 5.2 Enable Cloud Firestore

1. Go to **Build → Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in production mode"**
4. Select a location (closest to your users)
5. Click **"Enable"**

### 5.3 Enable Cloud Storage

1. Go to **Build → Storage**
2. Click **"Get started"**
3. Choose **"Start in production mode"**
4. Click **"Done"**

### 5.4 Enable Cloud Messaging (FCM)

1. Go to **Build → Cloud Messaging**
2. Click **"Get started"**
3. FCM is now enabled!

---

## 🔐 Step 6: Firebase Security Rules

### Firestore Rules

**Firestore → Rules tab:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // SOS alerts - users can create, admins can read all
    match /sos_alerts/{alertId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (request.auth.token.admin == true || 
         resource.data.userId == request.auth.uid);
    }
    
    // Location tracking
    match /location_logs/{logId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null && 
        (request.auth.token.admin == true || 
         resource.data.userId == request.auth.uid);
    }
  }
}
```

### Storage Rules

**Storage → Rules tab:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // SOS media files
    match /sos_media/{userId}/{fileName} {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    
    // Profile pictures
    match /profile_pictures/{userId}/{fileName} {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
  }
}
```

---

## 🔧 Step 7: Backend Configuration (Spring Boot)

### 7.1 Generate Service Account Key

1. Go to **Project Settings** (⚙️ icon)
2. Click **"Service accounts"** tab
3. Click **"Generate new private key"**
4. Click **"Generate key"** (downloads JSON file)
5. Rename it to `firebase-service-account.json`
6. Place it in: `backend/src/main/resources/firebase-service-account.json`

⚠️ **IMPORTANT**: Never commit this file to Git!

### 7.2 Update application.yml

**File**: `backend/src/main/resources/application.yml`

```yaml
firebase:
  config-path: classpath:firebase-service-account.json
```

---

## ✅ Step 8: Verify Configuration

### Test Flutter App

```powershell
cd women_safety

# Clean and get packages
flutter clean
flutter pub get

# Run app
flutter run
```

**Expected**: App should start without Firebase errors.

### Test Backend

```powershell
cd backend

# Build and run with Docker
docker-compose up -d

# Check logs
docker-compose logs -f app
```

**Expected**: Backend should start and connect to Firebase.

---

## 🧪 Test Firebase Integration

### Test Authentication

```dart
// In your Flutter app
import 'package:firebase_auth/firebase_auth.dart';

Future<void> testAuth() async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
      .signInAnonymously();
    print('✅ Firebase Auth working: ${userCredential.user?.uid}');
  } catch (e) {
    print('❌ Firebase Auth error: $e');
  }
}
```

### Test Firestore

```dart
// In your Flutter app
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirestore() async {
  try {
    await FirebaseFirestore.instance
      .collection('test')
      .doc('test_doc')
      .set({'timestamp': FieldValue.serverTimestamp()});
    print('✅ Firestore working!');
  } catch (e) {
    print('❌ Firestore error: $e');
  }
}
```

### Test FCM (Push Notifications)

```dart
// In your Flutter app
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> testFCM() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print('✅ FCM Token: $token');
  } catch (e) {
    print('❌ FCM error: $e');
  }
}
```

---

## 🐛 Troubleshooting

### Android Issues

**Error**: `google-services.json not found`
- **Solution**: Ensure file is in `android/app/google-services.json`
- Run `flutter clean && flutter pub get`

**Error**: `FirebaseApp not initialized`
- **Solution**: Check package name matches in:
  - `google-services.json` → `"package_name"`
  - `android/app/build.gradle` → `applicationId`

### iOS Issues

**Error**: `GoogleService-Info.plist not found`
- **Solution**: Re-add file to Xcode project (drag & drop)
- Ensure "Copy items if needed" is checked

**Error**: Permission denied (Camera/Location)
- **Solution**: Add usage descriptions to `Info.plist` (see Step 3.3)

### Backend Issues

**Error**: `firebase-service-account.json not found`
- **Solution**: Place file in `src/main/resources/`
- Check `application.yml` path

**Error**: `Firebase initialization failed`
- **Solution**: Verify JSON file is valid
- Check Firebase project ID matches

---

## 📚 Useful Links

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Admin SDK (Java)](https://firebase.google.com/docs/admin/setup)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)

---

## ✅ Configuration Checklist

- [ ] Firebase project created
- [ ] Android app registered
- [ ] `google-services.json` added to `android/app/`
- [ ] iOS app registered
- [ ] `GoogleService-Info.plist` added to Xcode project
- [ ] iOS `Info.plist` updated with permissions
- [ ] Web app registered (optional)
- [ ] Authentication enabled (Email, Google, Phone)
- [ ] Firestore enabled
- [ ] Cloud Storage enabled
- [ ] FCM enabled
- [ ] Firestore security rules set
- [ ] Storage security rules set
- [ ] Service account key generated
- [ ] `firebase-service-account.json` added to backend
- [ ] `application.yml` updated
- [ ] Flutter app runs without errors
- [ ] Backend starts without errors
- [ ] Firebase Auth tested
- [ ] Firestore tested
- [ ] FCM token obtained

---

**Next**: Configure Google Maps API → See `GOOGLE_MAPS_SETUP.md`
