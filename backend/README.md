# Women Safety Backend - Spring Boot

A complete backend API for the Women Safety mobile application with SOS alerts, location tracking, and Firebase Cloud Messaging integration.

## 🚀 Features

- **User Management**: Registration, login with JWT authentication
- **SOS Alerts**: Emergency alert creation with location, media, and notifications
- **Location Tracking**: Route history and real-time location logs
- **Admin Dashboard**: Alert management, analytics, and broadcast notifications
- **Security**: Spring Security with JWT, BCrypt password encryption
- **Firebase Integration**: Push notifications via FCM
- **API Documentation**: Swagger/OpenAPI UI

## 🛠 Tech Stack

- Java 17
- Spring Boot 3.2
- PostgreSQL 15
- Spring Security + JWT
- Firebase Admin SDK
- JPA/Hibernate
- Lombok + MapStruct
- Docker + Docker Compose

## 📋 Prerequisites

- Java 17+
- Maven 3.9+
- PostgreSQL 15+ (or use Docker)
- Firebase Service Account JSON

## 🔧 Setup

### 1. Clone and configure

```powershell
cd c:\Users\HRITIK\Desktop\womenSafety\backend
```

### 2. Configure Firebase

Download your Firebase service account JSON file and place it at:
```
src/main/resources/firebase-service-account.json
```

### 3. Configure application.yml

Update `src/main/resources/application.yml`:
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/womensafety
    username: your-db-user
    password: your-db-password

jwt:
  secret: your-secret-key-minimum-256-bits
```

### 4. Run with Docker

```powershell
docker-compose up -d
```

Backend will be available at: `http://localhost:8080`

### 5. Run locally (without Docker)

```powershell
# Start PostgreSQL first
mvn spring-boot:run
```

## 📚 API Documentation

Once running, access Swagger UI at:
```
http://localhost:8080/swagger-ui.html
```

## 🔐 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login and get JWT token

### SOS Alerts
- `POST /api/v1/sos` - Create SOS alert
- `GET /api/v1/sos/active` - Get active alerts
- `GET /api/v1/sos/my-alerts` - Get current user's alerts
- `PUT /api/v1/sos/{id}/resolve` - Resolve alert (Admin)

### Admin
- `POST /api/v1/admin/notify` - Send broadcast notification (Admin only)

## 🧪 Testing

```powershell
mvn test
```

## 📦 Build

```powershell
mvn clean package
```

JAR will be in `target/women-safety-backend-1.0.0.jar`

## 🚢 Deployment

### AWS EC2 + RDS

1. Launch EC2 instance (Ubuntu 22.04)
2. Create RDS PostgreSQL instance
3. Update `application.yml` with RDS endpoint
4. Upload JAR and run:

```bash
java -jar women-safety-backend-1.0.0.jar
```

### Docker Deployment

```bash
docker build -t women-safety-backend .
docker run -p 8080:8080 women-safety-backend
```

## 🔒 Security Notes

1. Change JWT secret in production
2. Use environment variables for sensitive data
3. Enable HTTPS
4. Configure Firebase security rules
5. Set up rate limiting
6. Use secrets manager (AWS Secrets Manager, Azure Key Vault)

## 📊 Database Schema

- **users**: User profiles and authentication
- **emergency_contacts**: User emergency contacts
- **sos_alerts**: Emergency alerts with location and status
- **location_logs**: User location history
- **danger_zones**: Predefined unsafe areas

## 🤝 Integration with Flutter App

The Flutter app should:
1. Call `/api/v1/auth/register` or `/login` to get JWT token
2. Include token in `Authorization: Bearer <token>` header
3. Call `/api/v1/sos` to create alerts
4. Store FCM token in user profile for push notifications

## 📝 License

MIT

## 👥 Contributors

- Backend Development Team
