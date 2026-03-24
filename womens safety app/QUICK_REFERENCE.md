# Women Safety App - Quick Reference

## 📱 Quick Start Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Clean build
flutter clean
```

## 🔥 Firebase Console Links

- **Authentication**: https://console.firebase.google.com/project/_/authentication
- **Firestore**: https://console.firebase.google.com/project/_/firestore
- **Cloud Messaging**: https://console.firebase.google.com/project/_/notification

## 📦 Project Dependencies

### Core
- flutter_bloc: State management
- firebase_core: Firebase initialization
- firebase_auth: Authentication
- cloud_firestore: Database
- firebase_messaging: Push notifications

### Location
- geolocator: GPS location
- geocoding: Address lookup
- flutter_map: Map display
- latlong2: Coordinates

### UI
- flutter_spinkit: Loading indicators
- fluttertoast: Toast messages
- intl: Date formatting

### Communication
- url_launcher: WhatsApp/SMS/Call

### ML/AI
- google_ml_kit: Face detection
- tflite_flutter: Custom models
- agora_rtc_engine: Live streaming

### Native
- home_widget: Android widget
- permission_handler: Runtime permissions

## 🎨 Key Color Codes

- Primary: #E91E63 (Pink)
- Secondary: #C2185B (Dark Pink)
- SOS Red: #FF0000
- Safe Green: #4CAF50
- Warning Orange: #FF9800

## 📂 Important Files

### Configuration
- `pubspec.yaml` - Dependencies
- `android/app/google-services.json` - Firebase config
- `android/app/build.gradle` - Android setup
- `.gitignore` - Git exclusions

### Core Logic
- `lib/main.dart` - Entry point
- `lib/routes.dart` - Navigation
- `lib/services/sos_service.dart` - SOS logic
- `lib/cubits/auth_cubit.dart` - Auth state

### Widget
- `android/.../PanicWidgetProvider.kt` - Widget logic
- `android/res/layout/panic_widget.xml` - Widget UI
- `android/res/xml/panic_widget_info.xml` - Widget config

## 🔐 Permissions Needed

```xml
INTERNET
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
CAMERA
RECORD_AUDIO
CALL_PHONE
SEND_SMS
POST_NOTIFICATIONS
```

## 🧪 Test Credentials

```
Email: test@womensafety.com
Password: Test@123456
```

## 📞 Emergency Numbers (Example)

- Police: 100
- Ambulance: 102
- Women Helpline: 1091
- Child Helpline: 1098

## 🔄 Update Widget Data

```dart
await PanicWidgetService().updateWidget(
  userName: 'Jane Doe',
  guardianCount: 3,
  safetyStatus: 'Safe',
);
```

## 📊 Firestore Structure

```
users/{userId}
  - uid, email, name, phone, createdAt

guardians/{guardianId}
  - userId, name, phone, isPrimary

sos_logs/{sosId}
  - userId, latitude, longitude, timestamp, status
```

## 🐛 Debug Mode

```bash
# Enable verbose logging
flutter run -v

# Check logs
flutter logs

# Clear data
flutter clean
rm -rf android/.gradle
flutter pub get
```

## 🚀 Production Checklist

- [ ] Firebase project in production mode
- [ ] Remove test data
- [ ] Update app version in pubspec.yaml
- [ ] Test on multiple devices
- [ ] Review permissions
- [ ] Test offline functionality
- [ ] Verify widget works
- [ ] Test all SOS flows
- [ ] Check location accuracy
- [ ] Verify guardian alerts
- [ ] Test in different scenarios
- [ ] Review security rules
- [ ] Enable Firebase Analytics
- [ ] Set up crash reporting

## 💡 Tips

1. **Testing SOS**: Use test phone numbers, don't spam real contacts
2. **Location**: Test both indoor and outdoor
3. **Widget**: Uninstall/reinstall to refresh widget
4. **Firebase**: Use test mode initially, then secure rules
5. **Performance**: Profile app before release
6. **Battery**: Test background location impact

## 📝 Common Commands

```bash
# Check Flutter version
flutter --version

# Check for updates
flutter upgrade

# Analyze code
flutter analyze

# Format code
flutter format .

# Generate icons
flutter pub run flutter_launcher_icons:main

# Check dependencies
flutter pub outdated
```

## 🔗 Useful Resources

- Flutter Docs: https://flutter.dev/docs
- Firebase Docs: https://firebase.google.com/docs
- Material Design: https://material.io/design
- Bloc Pattern: https://bloclibrary.dev
- Geolocator: https://pub.dev/packages/geolocator
- Home Widget: https://pub.dev/packages/home_widget

---

**Last Updated**: January 2026
**Version**: 1.0.0
**Minimum SDK**: Android 21 (Lollipop)
**Target SDK**: Android 33
