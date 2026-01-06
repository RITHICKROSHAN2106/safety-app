# 🚀 COMPLETE SETUP GUIDE - Women Safety App

## Step-by-Step Installation & Configuration

### PHASE 1: Environment Setup (15 minutes)

#### 1.1 Install Flutter
```bash
# Verify Flutter installation
flutter doctor -v

# Expected: All checkmarks green
# If not, follow flutter.dev/docs/get-started/install
```

#### 1.2 Install Dependencies
```bash
cd "C:\Users\leela\OneDrive\Desktop\womens safety app"
flutter pub get
```

#### 1.3 Verify Android Setup
```bash
flutter doctor --android-licenses
# Accept all licenses
```

---

### PHASE 2: Firebase Setup (20 minutes)

#### 2.1 Create Firebase Project
1. Visit: https://console.firebase.google.com/
2. Click "Add Project"
3. Project name: "Women Safety App"
4. Disable Google Analytics (optional)
5. Click "Create Project"

#### 2.2 Add Android App
1. Click "Android" icon
2. Package name: `com.example.women_safety_app`
3. App nickname: "Women Safety"
4. Click "Register app"

#### 2.3 Download Configuration
1. Download `google-services.json`
2. Place it in:
   ```
   womens safety app/android/app/google-services.json
   ```

#### 2.4 Enable Authentication
1. In Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password" provider
4. Click "Save"

#### 2.5 Create Firestore Database
1. In Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **Test Mode** (we'll add rules later)
4. Choose location (closest to your users)
5. Click "Enable"

#### 2.6 Set Firestore Rules
1. Go to Firestore → Rules tab
2. Replace with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Guardians collection
    match /guardians/{guardianId} {
      allow read, write: if request.auth != null;
    }
    
    // SOS logs collection
    match /sos_logs/{sosId} {
      allow read, write: if request.auth != null;
    }
  }
}
```
3. Click "Publish"

#### 2.7 Enable Cloud Messaging
1. In Firebase Console → Cloud Messaging
2. No additional setup needed (auto-enabled)

---

### PHASE 3: Android Configuration (15 minutes)

#### 3.1 Update build.gradle (Project level)
File: `android/build.gradle`

Add to `dependencies` block:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

Full block should look like:
```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10"
        classpath 'com.google.gms:google-services:4.4.0'  // ADD THIS
    }
}
```

#### 3.2 Update build.gradle (App level)
File: `android/app/build.gradle`

Add at the BOTTOM of file (after android { } block):
```gradle
apply plugin: 'com.google.gms.google-services'
```

Add to `dependencies` block:
```gradle
implementation platform('com.google.firebase:firebase-bom:32.7.0')
implementation 'com.google.firebase:firebase-analytics'
implementation 'com.google.firebase:firebase-messaging'
```

#### 3.3 Create strings.xml
File: `android/app/src/main/res/values/strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Women Safety</string>
    <string name="widget_description">Quick SOS panic button for emergencies</string>
</resources>
```

#### 3.4 Create Widget Preview (Optional)
File: `android/app/src/main/res/drawable/widget_preview.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#E91E63"/>
    <corners android:radius="12dp"/>
</shape>
```

---

### PHASE 4: Optional Features (10 minutes)

#### 4.1 Agora Live Streaming Setup
1. Visit: https://console.agora.io/
2. Sign up / Log in
3. Create new project
4. Get "App ID"
5. Update in `lib/services/live_streaming_service.dart`:
   ```dart
   static const String _appId = 'YOUR_AGORA_APP_ID_HERE';
   ```

#### 4.2 Add Alarm Sound
1. Get an alarm sound (MP3 format)
2. Place at: `assets/sounds/alarm.mp3`
3. Make sure it's loud and attention-grabbing

---

### PHASE 5: First Run (10 minutes)

#### 5.1 Connect Android Device
```bash
# Enable USB Debugging on your phone:
# Settings → About Phone → Tap "Build Number" 7 times
# Settings → Developer Options → Enable "USB Debugging"

# Verify device connection
flutter devices
```

#### 5.2 Run the App
```bash
flutter run
```

#### 5.3 Create Test Account
1. App will open to Login screen
2. Tap "Register"
3. Fill in:
   - Name: Your Name
   - Email: test@example.com
   - Phone: +1234567890
   - Password: Test@123
4. Tap "Register"

#### 5.4 Add Test Guardian
1. Go to Home → Guardians
2. Tap "Add Guardian"
3. Fill in:
   - Name: Emergency Contact
   - Phone: +1234567890
   - Relationship: Friend
   - Check "Primary Guardian"
4. Tap "Add"

---

### PHASE 6: Testing (15 minutes)

#### 6.1 Test SOS Flow
1. Home → Tap "SOS EMERGENCY" button
2. Tap SOS button 3 times quickly
3. Countdown starts (5 seconds)
4. Tap "SEND ALERT NOW" or wait
5. Alert is triggered ✅

#### 6.2 Test Location Sharing
1. Home → Tap "Share Location"
2. Grant location permission
3. Map loads with your location ✅
4. Tap share icon
5. Choose WhatsApp or SMS

#### 6.3 Test Widget
1. Long press home screen
2. Tap "Widgets"
3. Find "Women Safety"
4. Drag 2x2 widget to home screen
5. Widget shows your name and guardian count ✅
6. Tap SOS button on widget
7. App opens to SOS screen ✅

#### 6.4 Test AI Features
1. Home → Tap "AI-Powered Features"
2. Try each feature:
   - AI Danger Prediction
   - Voice Distress Detection
   - Face Recognition
   - Fake Call Generator
   - Safe Routes
   - Evidence Capture
   - Live Streaming
   - Volunteer Network

---

### PHASE 7: Build Release APK (10 minutes)

#### 7.1 Generate Keystore
```bash
keytool -genkey -v -keystore womens-safety-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias women-safety
```

Answer the prompts. Remember the passwords!

#### 7.2 Configure Signing
Create file: `android/key.properties`
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=women-safety
storeFile=../womens-safety-key.jks
```

#### 7.3 Update app/build.gradle
Before `android {` block:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside `android {` block, before `buildTypes`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

Inside `buildTypes.release`:
```gradle
signingConfig signingConfigs.release
```

#### 7.4 Build APK
```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

#### 7.5 Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

Bundle location: `build/app/outputs/bundle/release/app-release.aab`

---

## 📋 CHECKLIST

Before deployment, ensure:

- [ ] Firebase project created and configured
- [ ] google-services.json in correct location
- [ ] Authentication enabled in Firebase
- [ ] Firestore database created with rules
- [ ] All permissions in AndroidManifest.xml
- [ ] Widget registered in manifest
- [ ] Alarm sound added (optional)
- [ ] Agora App ID configured (optional)
- [ ] App tested on physical device
- [ ] SOS flow works end-to-end
- [ ] Location sharing functional
- [ ] Widget appears and works
- [ ] Guardian management works
- [ ] Release APK builds successfully

---

## 🐛 Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution**: Verify file is at `android/app/google-services.json`

### Issue: "FirebaseApp not initialized"
**Solution**: 
1. Check google-services.json is correct
2. Run `flutter clean`
3. Run `flutter pub get`
4. Rebuild app

### Issue: Location not working
**Solution**:
1. Enable location on device
2. Grant location permission in app
3. Check Google Play Services installed

### Issue: Widget not showing
**Solution**:
1. Verify package name matches everywhere
2. Check widget registered in AndroidManifest.xml
3. Rebuild app (`flutter clean && flutter build apk`)

### Issue: Permissions denied
**Solution**:
1. Go to App Settings → Permissions
2. Grant all required permissions
3. Some permissions need manual enabling

### Issue: Build fails
**Solution**:
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter build apk
```

---

## 📱 Device Requirements

**Minimum:**
- Android 5.0 (API 21)
- 2GB RAM
- GPS enabled
- Google Play Services

**Recommended:**
- Android 8.0+ (API 26+)
- 4GB+ RAM
- Active internet connection
- Location services enabled

---

## 🎯 Next Steps

1. **Customize Branding**
   - Change app name in `android/app/src/main/res/values/strings.xml`
   - Change app icon (use flutter_launcher_icons package)
   - Modify colors in `lib/app.dart`

2. **Add More Features**
   - Implement TFLite models for AI features
   - Add real-time location tracking
   - Implement chat with guardians
   - Add safety tips and resources

3. **Deploy to Play Store**
   - Create Developer account ($25 one-time)
   - Prepare store listing
   - Upload app bundle
   - Submit for review

4. **Monitor & Improve**
   - Set up Firebase Analytics
   - Monitor crash reports
   - Gather user feedback
   - Release updates

---

## 📞 Support

Need help? 
- Check README.md for detailed documentation
- Review code comments in each file
- Test on multiple devices
- Contact: [your-support-email]

---

**🎉 Congratulations! Your Women Safety App is ready!**
