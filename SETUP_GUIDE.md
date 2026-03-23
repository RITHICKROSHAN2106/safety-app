# Women Safety - Quick Setup Guide

## 🚀 Complete Setup in 5 Minutes

### Prerequisites Checklist
- [ ] Java 17+ installed
- [ ] Maven 3.9+ installed
- [ ] PostgreSQL 15+ OR Docker installed
- [ ] Flutter SDK (latest stable)
- [ ] Firebase project created

---

## Step 1: Backend Setup (5 min)

### A. Using Docker (Easiest)

```powershell
# Navigate to backend
cd c:\Users\HRITIK\Desktop\womenSafety\backend

# Start PostgreSQL + Backend
docker-compose up -d

# Check logs
docker-compose logs -f backend
```

Backend will be at: `http://localhost:8080`

### B. Manual Setup

```powershell
# 1. Install PostgreSQL and create database
createdb womensafety

# 2. Update application.yml with your DB credentials
# Edit: src/main/resources/application.yml

# 3. Add Firebase service account JSON
# Place your firebase-service-account.json in src/main/resources/

# 4. Run backend
mvn spring-boot:run
```

---

## Step 2: Flutter App Setup (5 min)

```powershell
# Navigate to Flutter app
cd c:\Users\HRITIK\Desktop\womenSafety\women_safety

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

### Configure Firebase

1. **Android:**
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/`

2. **iOS:**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Place in `ios/Runner/`

3. **Google Maps API Key:**
   - Get API key from Google Cloud Console
   - Edit `android/app/src/main/AndroidManifest.xml`
   - Replace `YOUR_API_KEY` with your actual key

---

## Step 3: Test the Integration

### A. Test Backend API

```powershell
# Register a user
curl -X POST http://localhost:8080/api/v1/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"Test User\",\"email\":\"test@example.com\",\"phone\":\"+1234567890\",\"password\":\"password123\"}"

# Login
curl -X POST http://localhost:8080/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"emailOrPhone\":\"test@example.com\",\"password\":\"password123\"}"
```

Or use Swagger UI: `http://localhost:8080/swagger-ui.html`

### B. Test Flutter App

1. Open app on emulator/device
2. Register new account
3. Navigate through screens
4. Test SOS button (will call backend API)

---

## 🔧 Troubleshooting

### Backend Issues

**Port 8080 already in use:**
```powershell
# Change port in application.yml
server:
  port: 8081
```

**Database connection failed:**
- Check PostgreSQL is running: `psql -U postgres`
- Verify credentials in `application.yml`

**Firebase error:**
- Ensure `firebase-service-account.json` is in `src/main/resources/`
- Check file permissions

### Flutter Issues

**Google Maps not showing:**
- Verify API key in `AndroidManifest.xml`
- Enable Maps SDK in Google Cloud Console

**Firebase auth failed:**
- Verify `google-services.json` is in `android/app/`
- Run `flutter clean` then `flutter pub get`

**Permissions denied:**
- Check location permissions in device settings
- Grant camera/microphone permissions

---

## 📱 Next Steps

### For Development:

1. **Add Emergency Contacts:**
   - Implement UI in Flutter
   - Call backend API to save contacts

2. **Test SOS Flow:**
   - Trigger SOS from app
   - Check backend logs for alert creation
   - Verify push notifications

3. **Test Location Tracking:**
   - Enable location services
   - Verify location logs in database

### For Production:

1. **Backend:**
   - Update JWT secret in `application.yml`
   - Use environment variables for secrets
   - Deploy to AWS EC2 + RDS
   - Enable HTTPS with SSL certificate

2. **Flutter App:**
   - Build release APK: `flutter build apk --release`
   - Test on real devices
   - Submit to Play Store / App Store

3. **Firebase:**
   - Configure Firebase security rules
   - Set up Firebase Storage for media uploads
   - Enable Firebase Analytics

---

## 📊 Verify Setup

✅ **Backend Running:**
- Visit: `http://localhost:8080/swagger-ui.html`
- Should see API documentation

✅ **Database Connected:**
- Check PostgreSQL: `psql -U postgres -d womensafety`
- Run: `\dt` to see tables

✅ **Flutter App Running:**
- App opens on device/emulator
- Can navigate between screens
- Settings toggle works

✅ **API Integration:**
- Register user from Flutter app
- Login successful
- SOS button creates alert in backend

---

## 🎯 Quick Commands Reference

### Backend
```powershell
mvn clean install          # Build
mvn spring-boot:run        # Run
mvn test                   # Test
docker-compose up -d       # Docker start
docker-compose logs -f     # View logs
```

### Flutter
```powershell
flutter pub get           # Get dependencies
flutter run               # Run app
flutter test              # Run tests
flutter clean             # Clean build
flutter build apk         # Build Android APK
```

### Database
```powershell
psql -U postgres          # Connect to PostgreSQL
\l                        # List databases
\c womensafety            # Connect to database
\dt                       # List tables
```

---

## 🔗 Important URLs

- Backend API: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- API Docs: `http://localhost:8080/api-docs`
- Firebase Console: `https://console.firebase.google.com`
- Google Cloud Console: `https://console.cloud.google.com`

---

## 📞 Need Help?

- Check logs: Backend (`docker-compose logs -f`), Flutter (`flutter run -v`)
- Consult READMEs: `/backend/README.md`, `/women_safety/README.md`
- Review Postman collection: `/backend/postman_collection.json`

**Happy Coding! 🚀**
