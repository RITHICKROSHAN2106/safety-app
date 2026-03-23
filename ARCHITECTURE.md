# Women Safety App - System Architecture

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────┐         ┌──────────────────┐                      │
│  │  Flutter Mobile  │         │  Admin Dashboard │                      │
│  │   (Android/iOS)  │         │  (React/Angular) │                      │
│  └────────┬─────────┘         └────────┬─────────┘                      │
│           │                             │                                │
│           │ REST API (JWT)              │ REST API (JWT)                 │
│           │                             │                                │
└───────────┼─────────────────────────────┼────────────────────────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│               ┌──────────────────────────────────┐                       │
│               │   Spring Boot Backend (Java 17)  │                       │
│               ├──────────────────────────────────┤                       │
│               │  ┌────────────────────────────┐  │                       │
│               │  │  Security Layer (JWT)      │  │                       │
│               │  └────────────┬───────────────┘  │                       │
│               │               │                   │                       │
│               │  ┌────────────▼───────────────┐  │                       │
│               │  │  REST Controllers          │  │                       │
│               │  │  - AuthController          │  │                       │
│               │  │  - SOSController           │  │                       │
│               │  │  - AdminController         │  │                       │
│               │  └────────────┬───────────────┘  │                       │
│               │               │                   │                       │
│               │  ┌────────────▼───────────────┐  │                       │
│               │  │  Service Layer             │  │                       │
│               │  │  - AuthService             │  │                       │
│               │  │  - SOSService              │  │                       │
│               │  │  - NotificationService     │  │                       │
│               │  └────────────┬───────────────┘  │                       │
│               │               │                   │                       │
│               │  ┌────────────▼───────────────┐  │                       │
│               │  │  Repository Layer (JPA)    │  │                       │
│               │  │  - UserRepository          │  │                       │
│               │  │  - SOSAlertRepository      │  │                       │
│               │  │  - LocationLogRepository   │  │                       │
│               │  └────────────┬───────────────┘  │                       │
│               └───────────────┼───────────────────┘                       │
│                               │                                           │
└───────────────────────────────┼───────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                PostgreSQL Database                                │   │
│  ├──────────────────────────────────────────────────────────────────┤   │
│  │  Tables:                                                          │   │
│  │  - users (profiles, auth)                                         │   │
│  │  - emergency_contacts (user contacts)                             │   │
│  │  - sos_alerts (emergency alerts)                                  │   │
│  │  - location_logs (tracking history)                               │   │
│  │  - danger_zones (unsafe areas)                                    │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │
│  │  Firebase FCM   │  │  Google Maps    │  │  Twilio/SMS     │         │
│  │  (Push Notif)   │  │  (Location)     │  │  (Alerts)       │         │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘         │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Flow Diagrams

### 1. User Registration Flow

```
Flutter App                 Backend API              Database
     │                           │                       │
     │  POST /auth/register      │                       │
     ├──────────────────────────>│                       │
     │   {name, email, phone,    │                       │
     │    password}               │                       │
     │                           │   Save User            │
     │                           ├──────────────────────>│
     │                           │                       │
     │                           │<──────────────────────┤
     │                           │   User Created        │
     │   {token, userId}         │                       │
     │<──────────────────────────┤                       │
     │                           │                       │
```

### 2. SOS Alert Flow

```
Flutter App          Backend API        Database      Firebase FCM    Emergency Contacts
     │                    │                 │               │                │
     │  Trigger SOS       │                 │               │                │
     │  (Button/Shake)    │                 │               │                │
     │                    │                 │               │                │
     │  POST /sos         │                 │               │                │
     ├───────────────────>│                 │               │                │
     │  {lat, lng,        │                 │               │                │
     │   mediaUrl}        │                 │               │                │
     │                    │  Save Alert     │               │                │
     │                    ├────────────────>│               │                │
     │                    │                 │               │                │
     │                    │  Fetch Contacts │               │                │
     │                    ├────────────────>│               │                │
     │                    │<────────────────┤               │                │
     │                    │                 │               │                │
     │                    │  Send Push      │               │                │
     │                    ├────────────────────────────────>│                │
     │                    │                 │               │                │
     │                    │  Send SMS/Call (via Twilio)     │                │
     │                    ├────────────────────────────────────────────────>│
     │                    │                 │               │                │
     │  Success           │                 │               │   📱 Notified  │
     │<───────────────────┤                 │               │                │
     │                    │                 │               │                │
```

### 3. Location Tracking Flow

```
Flutter App (Periodic)    Backend API         Database
     │                         │                  │
     │  Every 30s              │                  │
     │  POST /location         │                  │
     ├────────────────────────>│                  │
     │  {lat, lng, accuracy}   │                  │
     │                         │  Save Log        │
     │                         ├─────────────────>│
     │                         │                  │
     │                         │<─────────────────┤
     │  Success                │                  │
     │<────────────────────────┤                  │
     │                         │                  │
```

---

## 🔐 Security Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Security Layers                          │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Transport Security                                       │
│     ├─ HTTPS/TLS encryption                                 │
│     └─ Certificate pinning (mobile)                         │
│                                                              │
│  2. Authentication                                           │
│     ├─ JWT tokens (24h expiry)                              │
│     ├─ BCrypt password hashing                              │
│     └─ Firebase Auth integration                            │
│                                                              │
│  3. Authorization                                            │
│     ├─ Role-based access (USER, ADMIN)                      │
│     ├─ JWT validation filter                                │
│     └─ Spring Security config                               │
│                                                              │
│  4. Data Security                                            │
│     ├─ Database encryption at rest                          │
│     ├─ Sensitive data encryption (AES)                      │
│     └─ Secure key storage                                   │
│                                                              │
│  5. API Security                                             │
│     ├─ CORS policy                                           │
│     ├─ Rate limiting (future)                               │
│     └─ Input validation                                     │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Schema

```sql
-- Core Tables

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'USER',
    fcm_token VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE emergency_contacts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    relationship VARCHAR(50),
    is_primary BOOLEAN DEFAULT FALSE
);

CREATE TABLE sos_alerts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    media_url VARCHAR(500),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    trigger_type VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(100)
);

CREATE TABLE location_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE TABLE danger_zones (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius DOUBLE PRECISION NOT NULL,
    threat_level VARCHAR(20) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);
```

---

## 🚀 Deployment Architecture

### Development Environment

```
Developer Machine
├── Flutter App (localhost:5000)
├── Backend API (localhost:8080)
└── PostgreSQL (localhost:5432)
```

### Production Environment (AWS Example)

```
┌───────────────────────────────────────────────────────────┐
│                    AWS Cloud                               │
├───────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐         ┌─────────────┐                  │
│  │  Route 53   │────────>│ CloudFront  │                  │
│  │   (DNS)     │         │   (CDN)     │                  │
│  └─────────────┘         └──────┬──────┘                  │
│                                  │                          │
│  ┌──────────────────────────────▼──────────────────────┐  │
│  │         Application Load Balancer (ALB)             │  │
│  └──────────────────────────────┬──────────────────────┘  │
│                                  │                          │
│  ┌──────────────────────────────▼──────────────────────┐  │
│  │           EC2 Auto Scaling Group                     │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │Backend #1│  │Backend #2│  │Backend #3│          │  │
│  │  │(Docker)  │  │(Docker)  │  │(Docker)  │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────┬──────────────────────┘  │
│                                  │                          │
│  ┌──────────────────────────────▼──────────────────────┐  │
│  │      RDS PostgreSQL (Multi-AZ)                       │  │
│  │  ┌─────────────┐     ┌─────────────┐                │  │
│  │  │   Primary   │────>│   Standby   │                │  │
│  │  └─────────────┘     └─────────────┘                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         S3 (Media Storage - Videos/Audio)            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└───────────────────────────────────────────────────────────┘

External Services:
├── Firebase Cloud Messaging
├── Google Maps Platform
└── Twilio (SMS)
```

---

## 🔄 Microservices Future Architecture (Optional)

```
┌────────────────────────────────────────────────────────────┐
│                   API Gateway                               │
│              (Kong / AWS API Gateway)                       │
└───┬────────────┬────────────┬────────────┬─────────────────┘
    │            │            │            │
    ▼            ▼            ▼            ▼
┌────────┐  ┌────────┐  ┌────────┐  ┌────────────┐
│ Auth   │  │  SOS   │  │ Location│  │   AI Risk  │
│Service │  │Service │  │ Service │  │  Prediction│
│        │  │        │  │         │  │  (Python)  │
└───┬────┘  └───┬────┘  └───┬─────┘  └────┬───────┘
    │           │           │             │
    ▼           ▼           ▼             ▼
┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
│MongoDB │  │Postgres│  │Redis   │  │ML Model│
│(User)  │  │(Alerts)│  │(Cache) │  │Storage │
└────────┘  └────────┘  └────────┘  └────────┘
```

---

## 📱 Mobile App Architecture

```
Flutter App Architecture (Clean Architecture)

┌──────────────────────────────────────────────────┐
│              Presentation Layer                   │
│  ┌────────────────────────────────────────────┐  │
│  │  Screens (UI)                               │  │
│  │  - SplashScreen, LoginScreen, HomeScreen   │  │
│  │  - SOSScreen, MapScreen, ProfileScreen     │  │
│  └─────────────────┬──────────────────────────┘  │
│                    │                              │
│  ┌─────────────────▼──────────────────────────┐  │
│  │  Widgets (Reusable Components)             │  │
│  │  - PrimaryButton, OnboardingAnimation      │  │
│  └─────────────────┬──────────────────────────┘  │
└────────────────────┼──────────────────────────────┘
                     │
┌────────────────────▼──────────────────────────────┐
│              Business Logic Layer                 │
│  ┌────────────────────────────────────────────┐  │
│  │  Blocs/Cubits (State Management)          │  │
│  │  - ThemeCubit, AuthCubit, LocationCubit   │  │
│  │  - SosCubit                                │  │
│  └─────────────────┬──────────────────────────┘  │
└────────────────────┼──────────────────────────────┘
                     │
┌────────────────────▼──────────────────────────────┐
│                 Data Layer                        │
│  ┌────────────────────────────────────────────┐  │
│  │  Services                                   │  │
│  │  - NotificationService, PermissionsService │  │
│  │  - ApiClient (HTTP)                        │  │
│  └─────────────────┬──────────────────────────┘  │
│                    │                              │
│  ┌─────────────────▼──────────────────────────┐  │
│  │  Models (Data Classes)                      │  │
│  │  - User, Guardian, SOSAlert                │  │
│  └─────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘
```

---

## 🧩 Tech Stack Summary

| Component | Technology |
|-----------|------------|
| **Mobile App** | Flutter 3.x, Dart |
| **Backend API** | Spring Boot 3.2, Java 17 |
| **Database** | PostgreSQL 15 |
| **Authentication** | JWT, Firebase Auth |
| **Push Notifications** | Firebase Cloud Messaging |
| **Maps** | Google Maps SDK |
| **State Management** | flutter_bloc, provider |
| **HTTP Client** | http (Flutter), RestTemplate (Spring) |
| **ORM** | JPA/Hibernate |
| **Containerization** | Docker, Docker Compose |
| **Documentation** | Swagger/OpenAPI |
| **Testing** | JUnit, Mockito, flutter_test |

---

**Last Updated:** October 2025  
**Version:** 1.0.0
