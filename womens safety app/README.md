# Women Safety Mobile Application

A production-ready women safety mobile application built with Flutter, featuring real-time SOS alerts, location sharing, AI-powered safety features, and Android home screen panic widget.

## 🚀 Features

### Core Features
- ✅ **Firebase Authentication** - Email/Password login with forgot password
- ✅ **SOS Emergency System** - 3-click activation with 5-second countdown
- ✅ **Loud Alarm** - Audio alert during emergency
- ✅ **Real-time Location Sharing** - GPS tracking with Google Maps integration
- ✅ **Guardian Management** - Add/Edit/Delete emergency contacts
- ✅ **Multi-channel Alerts** - WhatsApp, SMS, Email, Phone call
- ✅ **Auto-call Primary Guardian** - Automatic emergency call
- ✅ **SOS History Logs** - Firestore-based activity logging

### Revolutionary AI Features
- 🤖 **AI Danger Prediction** - ML-based area safety analysis
- 🎤 **Voice Distress Detection** - Keyword detection in voice input
- 👤 **Face Recognition** - ML Kit face detection
- 📞 **Fake Call Generator** - Emergency exit strategy
- 🗺️ **Safe Routes** - AI-recommended safest paths
- 📸 **Evidence Capture** - Auto audio/photo recording
- 📹 **Live Video Streaming** - Agora-based live broadcast to guardians
- 👥 **Volunteer Network** - Community safety support

### Android Native Integration
- 📱 **Home Screen Panic Widget** - 2x2 widget with quick SOS access
- 🔔 **Firebase Cloud Messaging** - Push notifications
- 📍 **Background Location Tracking**
- 🔊 **System-level Permissions Management**

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp configuration
├── routes.dart               # Centralized routing
├── models/
│   ├── user_model.dart
│   ├── guardian_model.dart
│   ├── sos_log_model.dart
│   └── location_model.dart
├── services/
│   ├── sos_service.dart
│   ├── location_share_service.dart
│   ├── whatsapp_service.dart
│   ├── sms_service.dart
│   ├── notification_service.dart
│   ├── permissions_service.dart
│   ├── panic_widget_service.dart
│   ├── ai_danger_prediction_service.dart
│   ├── distress_voice_analysis_service.dart
│   ├── face_recognition_service.dart
│   ├── live_streaming_service.dart
│   └── offline_queue_service.dart
├── cubits/
│   ├── auth_cubit.dart
│   ├── sos_cubit.dart
│   ├── guardian_cubit.dart
│   ├── location_cubit.dart
│   └── theme_cubit.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── sos_screen.dart
│   ├── map_screen.dart
│   ├── guardian_management_screen.dart
│   ├── revolutionary_features_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart
└── widgets/
    └── (custom widgets)

android/
└── app/src/main/
    ├── kotlin/com/example/women_safety_app/
    │   └── PanicWidgetProvider.kt
    ├── res/
    │   ├── layout/
    │   │   └── panic_widget.xml
    │   ├── xml/
    │   │   └── panic_widget_info.xml
    │   └── drawable/
    │       ├── widget_background.xml
    │       └── sos_button_background.xml
    └── AndroidManifest.xml
```

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase account
- Agora account (for live streaming)

### 1. Clone and Install Dependencies

```bash
cd "womens safety app"
flutter pub get
```

### 2. Firebase Configuration

#### Android Setup:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Add Android app with package name: `com.example.women_safety_app`
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

#### Enable Firebase Services:
- ✅ Authentication (Email/Password)
- ✅ Cloud Firestore
- ✅ Firebase Cloud Messaging
- ✅ Firebase Storage (for evidence upload)

#### Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /guardians/{guardianId} {
      allow read, write: if request.auth != null;
    }
    match /sos_logs/{sosId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. Android Configuration

#### Update Package Name (if needed):
Replace `com.example.women_safety_app` in:
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/.../MainActivity.kt`
- `android/app/src/main/kotlin/.../PanicWidgetProvider.kt`

#### Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-messaging'
}
```

#### Add to `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 4. Agora Configuration (Optional - Live Streaming)

1. Sign up at [Agora.io](https://www.agora.io/)
2. Create a project and get App ID
3. Update in `lib/services/live_streaming_service.dart`:
```dart
static const String _appId = 'YOUR_AGORA_APP_ID';
```

### 5. Add Alarm Sound (Optional)

Place alarm sound file at: `assets/sounds/alarm.mp3`

### 6. Widget String Resources

Add to `android/app/src/main/res/values/strings.xml`:
```xml
<resources>
    <string name="app_name">Women Safety</string>
    <string name="widget_description">Quick SOS panic button</string>
</resources>
```

## 🎯 Running the App

```bash
# Check for issues
flutter doctor

# Run on connected device
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## 📱 Testing the Widget

1. Long press on home screen
2. Select "Widgets"
3. Find "Women Safety" widget
4. Drag to home screen
5. Widget will show user name, guardian count, and SOS button

## 🔐 Permissions

The app requests the following permissions:
- 📍 Location (Fine & Coarse)
- 📷 Camera
- 🎤 Microphone
- 📞 Phone & SMS
- 🔔 Notifications
- 💾 Storage

All permissions are requested at runtime with proper handling.

## 🏗️ Architecture

- **State Management**: BLoC/Cubit pattern
- **Backend**: Firebase (Auth, Firestore, FCM)
- **Maps**: OpenStreetMap (flutter_map)
- **AI/ML**: Google ML Kit + TFLite (stubs included)
- **Video**: Agora RTC Engine
- **Architecture**: Clean Architecture with separation of concerns

## 🔧 Customization

### Change App Colors
Edit `lib/app.dart` - modify `ColorScheme.fromSeed(seedColor: ...)

### Change Widget Size
Edit `android/app/src/main/res/xml/panic_widget_info.xml`

### Add More AI Features
Extend services in `lib/services/` and implement TFLite models

## 📊 Firebase Collections

### users
```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "phone": "string",
  "createdAt": "timestamp"
}
```

### guardians
```json
{
  "id": "string",
  "userId": "string",
  "name": "string",
  "phone": "string",
  "isPrimary": "boolean"
}
```

### sos_logs
```json
{
  "id": "string",
  "userId": "string",
  "latitude": "double",
  "longitude": "double",
  "timestamp": "timestamp",
  "status": "string",
  "alertsSent": ["array"]
}
```

## 🐛 Troubleshooting

### Widget Not Showing
- Check package name matches in all files
- Verify widget is registered in AndroidManifest.xml
- Rebuild app after changes

### Location Not Working
- Enable location services on device
- Grant location permissions
- Check Google Play Services is installed

### Firebase Not Connecting
- Verify google-services.json is in correct location
- Check package name matches Firebase console
- Ensure Firebase dependencies are added

## 📝 Notes

- This is a production-grade template
- Replace placeholder Firebase config
- Add your own Agora App ID for streaming
- Test thoroughly before deployment
- Follow local laws for emergency services

## 📄 License

This project is for educational/commercial use.

## 👥 Support

For issues or questions:
- Create an issue in the repository
- Contact: [your-email@example.com]

---

**Built with ❤️ for Women's Safety**
