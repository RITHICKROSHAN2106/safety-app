# 🛡️ Women Safety App - Complete Full-Stack Solution

A comprehensive safety application with Flutter mobile app, Spring Boot backend, and admin dashboard for real-time emergency alerts and monitoring.

## 📱 Project Structure

```
womenSafety/
├── women_safety/          # Flutter Mobile App
├── backend/               # Spring Boot Backend API
└── admin-dashboard/       # React/Angular Admin Panel (coming soon)
```

## 🚀 Quick Start Guide

### 1. Flutter Mobile App

Navigate to the Flutter app directory:

```powershell
cd women_safety
flutter pub get
flutter run
```

**Setup Requirements:**
- Flutter SDK (latest stable)
- Android Studio / Xcode
- Firebase project configured
- Google Maps API key

See [women_safety/README.md](women_safety/README.md) for detailed setup.

### 2. Spring Boot Backend

Navigate to the backend directory:

```powershell
cd backend
docker-compose up -d
```

Or run locally:

```powershell
mvn spring-boot:run
```

**Setup Requirements:**
- Java 17+
- PostgreSQL 15+ (or use Docker)
- Firebase service account JSON
- Maven 3.9+

See [backend/README.md](backend/README.md) for detailed setup.

### 3. Admin Dashboard (Coming Soon)

Web-based admin panel for monitoring alerts and analytics.

## 🎯 Features Overview

### Mobile App (Flutter)
- ✅ Material 3 UI with dark/light theme
- ✅ Firebase Authentication (Google, Email, Phone OTP)
- ✅ Live Google Maps tracking
- ✅ SOS Button with multiple triggers (button, shake, voice)
- ✅ Emergency contact management
- ✅ Real-time location sharing
- ✅ Push notifications via FCM
- ⏳ Video/audio recording and upload
- ⏳ Nearby safe zones (police stations, hospitals)
- ⏳ Geo-fence alerts for danger zones
- ⏳ Companion mode for live route sharing
- ⏳ Offline mode with SMS fallback
- ⏳ Multi-language support
- ⏳ AI chatbot for safety tips

### Backend (Spring Boot)
- ✅ User registration and JWT authentication
- ✅ SOS alert management with location
- ✅ Push notifications via Firebase Cloud Messaging
- ✅ Emergency contact storage
- ✅ Location tracking and route history
- ✅ Admin dashboard API endpoints
- ✅ PostgreSQL database
- ✅ Swagger/OpenAPI documentation
- ✅ Docker deployment
- ✅ CORS enabled for Flutter frontend
- ⏳ SMS alerts via Twilio
- ⏳ AI risk prediction microservice

### Admin Dashboard (Planned)
- ⏳ Real-time SOS alert monitoring on map
- ⏳ User management and analytics
- ⏳ Heatmap for high-risk areas
- ⏳ Danger zone management
- ⏳ Broadcast notifications
- ⏳ Reports and CSV/PDF export
- ⏳ WebSocket for real-time updates

## 🔗 Integration Flow

```
Flutter App → Spring Boot API → PostgreSQL
     ↓              ↓
Firebase FCM ← Admin Dashboard
```

1. User registers/logs in via Flutter app
2. App gets JWT token from backend
3. User triggers SOS → sends location to backend
4. Backend stores alert in database
5. Backend sends push notifications to emergency contacts
6. Admin dashboard receives real-time alert updates
7. Admin can view and resolve alerts

## 🌐 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login and get JWT token

### SOS Alerts
- `POST /api/v1/sos` - Create SOS alert
- `GET /api/v1/sos/active` - Get active alerts
- `GET /api/v1/sos/my-alerts` - Get user alerts
- `PUT /api/v1/sos/{id}/resolve` - Resolve alert

### Admin
- `POST /api/v1/admin/notify` - Send broadcast notification

Full API docs: `http://localhost:8080/swagger-ui.html`

## 🔒 Security

- JWT-based authentication
- BCrypt password encryption
- Role-based access control (USER, ADMIN)
- HTTPS/TLS in production
- Firebase security rules
- API rate limiting (recommended for production)

## 🛠 Technology Stack

### Mobile App
- Flutter 3.x (latest stable)
- Dart
- firebase_core, firebase_auth, cloud_firestore
- google_maps_flutter, geolocator
- flutter_bloc, provider
- lottie, camera, sensors_plus, speech_to_text

### Backend
- Java 17
- Spring Boot 3.2
- Spring Security + JWT
- PostgreSQL 15
- Firebase Admin SDK
- JPA/Hibernate, Lombok, MapStruct

### Admin Dashboard (Planned)
- React.js (Vite + Tailwind) or Angular
- Recharts / Chart.js
- Google Maps / Mapbox
- Firebase Cloud Messaging
- Axios for API calls

## 📦 Deployment

### Development
- Flutter: `flutter run`
- Backend: `docker-compose up -d`

### Production

#### Mobile App
```powershell
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ipa --release
```

#### Backend
```powershell
# Docker
docker build -t women-safety-backend .
docker run -p 8080:8080 women-safety-backend

# AWS EC2 + RDS
# See backend/README.md for deployment guide
```

## 🧪 Testing

### Flutter
```powershell
cd women_safety
flutter test
```

### Backend
```powershell
cd backend
mvn test
```

## 📝 Environment Variables

### Backend (.env or application.yml)
```yaml
JWT_SECRET=your-secret-key-256-bits
DB_URL=jdbc:postgresql://localhost:5432/womensafety
DB_USER=postgres
DB_PASSWORD=your-password
FIREBASE_SERVICE_ACCOUNT=path/to/service-account.json
```

### Flutter (firebase config files)
- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist
- Replace YOUR_API_KEY in AndroidManifest.xml

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file

## 👥 Team

- Flutter Development
- Backend Development
- UI/UX Design
- DevOps & Deployment

## 🔮 Future Enhancements

- [ ] AI-powered risk prediction
- [ ] WhatsApp integration for alerts
- [ ] Live video streaming during SOS
- [ ] Wearable device integration
- [ ] Multi-city danger zone database
- [ ] Community safety reports
- [ ] Integration with local police APIs

## 📞 Support

For issues or questions:
- Create GitHub issue
- Email: support@womensafety.app

---

**Built with ❤️ for women's safety worldwide**
