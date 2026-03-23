# 🚀 Quick Start Guide - Women Safety App

**Project**: Women Safety Mobile App  
**Last Updated**: October 19, 2025

---

## 📋 Quick Reference

### **Project Structure**
```
womenSafety/
├── women_safety/        # Flutter Mobile App
├── backend/             # Spring Boot API
├── FIREBASE_SETUP.md    # Firebase configuration guide
├── GOOGLE_MAPS_SETUP.md # Google Maps setup guide
├── SOS_IMPLEMENTATION.md# SOS features documentation
├── ARCHITECTURE.md      # System architecture
└── PROGRESS_REPORT.md   # Detailed progress report
```

---

## ⚡ Quick Setup (Essential Steps Only)

### **1. Firebase Setup (Required)**
```powershell
# 1. Go to: https://console.firebase.google.com/
# 2. Create project: "women-safety-app"
# 3. Register Android app, download google-services.json
#    Place in: women_safety/android/app/

# 4. Register iOS app, download GoogleService-Info.plist
#    Add to Xcode: ios/Runner/

# 5. Enable: Authentication, Firestore, Storage, FCM

# 6. Generate service account key for backend
#    Place in: backend/src/main/resources/
```

### **2. Google Maps Setup (Required)**
```powershell
# 1. Go to: https://console.cloud.google.com/
# 2. Create project, enable billing
# 3. Create API key, enable APIs:
#    - Maps SDK for Android
#    - Maps SDK for iOS
#    - Places API
#    - Directions API

# 4. Replace YOUR_API_KEY in:
#    - android/app/src/main/AndroidManifest.xml
#    - ios/Runner/AppDelegate.swift
```

### **3. Run Flutter App**
```powershell
cd women_safety

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### **4. Run Backend**
```powershell
cd backend

# Update application.yml with:
# - Database credentials
# - JWT secret
# - Firebase config path

# Start with Docker
docker-compose up -d

# Or run manually
mvn spring-boot:run
```

---

## 📱 Available SOS Services

### **Already Implemented:**
- ✅ **SMS Service** - Send emergency SMS to all contacts
- ✅ **Call Service** - Make emergency calls
- ✅ **WhatsApp Service** - Send WhatsApp messages
- ✅ **Email Service** - Send detailed email alerts

### **Usage Example:**
```dart
import 'package:women_safety/services/sms_service.dart';
import 'package:women_safety/services/call_service.dart';
import 'package:women_safety/services/whatsapp_service.dart';
import 'package:women_safety/services/email_service.dart';
import 'package:women_safety/models/guardian.dart';
import 'package:women_safety/models/sos_alert.dart';

// Create SOS alert
final alert = SOSAlert(
  userId: 'user123',
  latitude: 28.6139,
  longitude: 77.2090,
  timestamp: DateTime.now(),
  triggerType: 'BUTTON',
);

// Emergency contacts
final contacts = [
  Guardian(
    name: 'Mom',
    phone: '+919876543210',
    email: 'mom@example.com',
    relationship: 'Mother',
    isPrimary: true,
  ),
];

// Send SMS
await SmsService.sendSOSSms(contacts: contacts, alert: alert);

// Make call to primary contact
await CallService.makeEmergencyCall(contacts);

// Send WhatsApp
await WhatsAppService.sendSOSWhatsApp(contacts: contacts, alert: alert);

// Send Email
await EmailService.sendSOSEmail(
  contacts: contacts, 
  alert: alert,
  userName: 'Hritik',
);
```

---

## 🔑 Configuration Checklist

### **Firebase**
- [ ] Firebase project created
- [ ] `google-services.json` added to `android/app/`
- [ ] `GoogleService-Info.plist` added to Xcode
- [ ] Authentication enabled (Email, Google, Phone)
- [ ] Firestore enabled
- [ ] Cloud Storage enabled
- [ ] FCM enabled
- [ ] Service account key generated
- [ ] `firebase-service-account.json` added to backend

### **Google Maps**
- [ ] Google Cloud project created
- [ ] Billing enabled
- [ ] API key created and restricted
- [ ] Required APIs enabled
- [ ] API key added to `AndroidManifest.xml`
- [ ] API key added to `AppDelegate.swift` (iOS)

### **Backend**
- [ ] PostgreSQL installed/configured
- [ ] `application.yml` updated (DB, JWT, Firebase)
- [ ] Docker running (if using)

---

## 🧪 Quick Test Commands

### **Test Flutter App**
```powershell
cd women_safety

# Check for errors
flutter analyze

# Run tests
flutter test

# Run app
flutter run -d <device-id>
```

### **Test Backend**
```powershell
cd backend

# Build
mvn clean package

# Run tests
mvn test

# Start server
docker-compose up -d

# Check logs
docker-compose logs -f app
```

### **Test API Endpoints**
```powershell
# Register user
curl -X POST http://localhost:8080/api/v1/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"Test User\",\"email\":\"test@example.com\",\"phone\":\"+919876543210\",\"password\":\"password123\"}"

# Login
curl -X POST http://localhost:8080/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}"
```

---

## 📚 Documentation Quick Links

| Document | Purpose | When to Use |
|----------|---------|-------------|
| `FIREBASE_SETUP.md` | Complete Firebase configuration | Setting up Firebase for first time |
| `GOOGLE_MAPS_SETUP.md` | Complete Google Maps setup | Adding Maps functionality |
| `SOS_IMPLEMENTATION.md` | SOS features guide | Implementing emergency features |
| `ARCHITECTURE.md` | System architecture | Understanding overall design |
| `PROGRESS_REPORT.md` | Detailed progress status | Checking what's done/remaining |
| `PROJECT_README.md` | Project overview | Understanding the project |
| `SETUP_GUIDE.md` | Quick setup instructions | Initial project setup |

---

## 🆘 Emergency Contact Numbers (India)

```dart
// Use these in your app
CallService.callPolice()         // 100
CallService.callAmbulance()      // 102
CallService.callWomenHelpline()  // 181
CallService.callEmergencyServices() // 112 (universal)
```

---

## 🔧 Common Issues & Fixes

### **Issue**: App won't build
**Fix**: Run `flutter clean && flutter pub get`

### **Issue**: Maps not showing
**Fix**: 
1. Check API key in `AndroidManifest.xml`
2. Verify "Maps SDK for Android" is enabled
3. Wait 5-10 minutes after enabling API

### **Issue**: SMS not sending
**Fix**: 
1. Test on real device (not emulator)
2. Grant SMS permission in device settings
3. Check phone number format

### **Issue**: Firebase error on startup
**Fix**: 
1. Ensure `google-services.json` exists
2. Run `flutter clean && flutter pub get`
3. Check package name matches in Firebase console

### **Issue**: Backend won't start
**Fix**: 
1. Check PostgreSQL is running
2. Verify database credentials in `application.yml`
3. Ensure `firebase-service-account.json` exists

---

## 📊 Current Status

### **Completed** ✅
- Flutter app scaffold
- Spring Boot backend scaffold
- Google Maps integration
- SMS, Call, WhatsApp, Email services
- Complete documentation

### **Remaining** ⏳
- Firebase & Google Maps configuration (user action)
- Recording & Storage services
- Shake & Voice detection
- Main SOS coordinator
- Backend configuration

---

## 🎯 Next Actions

**Right Now:**
1. Open `FIREBASE_SETUP.md`
2. Follow steps to add Firebase config files
3. Open `GOOGLE_MAPS_SETUP.md`  
4. Add Google Maps API key
5. Test the app!

**After Configuration:**
6. Implement recording service
7. Implement shake detection
8. Implement voice activation
9. Create SOS coordinator
10. Configure backend

---

## 💬 Get Help

**Need detailed instructions?**
- Firebase: Read `FIREBASE_SETUP.md`
- Google Maps: Read `GOOGLE_MAPS_SETUP.md`
- SOS Features: Read `SOS_IMPLEMENTATION.md`

**Want to understand architecture?**
- Read `ARCHITECTURE.md`

**Check progress?**
- Read `PROGRESS_REPORT.md`

---

**Let's make this app amazing! 🚀**
