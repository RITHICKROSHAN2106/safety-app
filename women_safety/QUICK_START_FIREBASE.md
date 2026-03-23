# 🚀 Quick Start - Firebase Setup (5 Minutes)

## ⚡ Super Fast Setup

### Step 1: Firebase Console (2 minutes)
```
1. Open: https://console.firebase.google.com/
2. Click "Add project" → Name: "Women Safety" → Create
3. Click Android icon → Package: com.example.women_safety → Register
4. Download google-services.json
5. Place file in: women_safety/android/app/google-services.json
```

### Step 2: Enable Services (2 minutes)
```
In Firebase Console:
✓ Authentication → Enable Email/Password
✓ Firestore Database → Create Database (Production mode)
✓ Storage → Get Started
```

### Step 3: Create Test User (1 minute)
```
1. Authentication → Add user
   Email: test@example.com
   Password: Test123456!

2. Copy the User UID (e.g., abc123xyz)

3. Firestore → Start collection → "users"
   Document ID: [paste UID]
   Fields:
     name: "Test User"
     email: "test@example.com"
     phone: "+1234567890"
     guardians: [array]
       → Add 3 maps with: name, phone, relation, email
```

### Step 4: Rebuild App
```powershell
cd women_safety
flutter clean
flutter pub get
flutter run
```

### Step 5: Test
```
1. App opens on your device
2. Sign in with: test@example.com / Test123456!
3. See your emergency contacts loaded!
```

---

## 📱 What Each Service Does

| Service | Purpose | Required? |
|---------|---------|-----------|
| Authentication | User login/signup | ✅ YES |
| Firestore | Store user data & contacts | ✅ YES |
| Storage | Store SOS videos/images | ✅ YES |
| Cloud Messaging | Push notifications | ⚠️ Optional |
| OpenStreetMap (flutter_map) | Location tracking | ✅ YES |

---

## �️ Map Tiles (OpenStreetMap)

No API keys are required. The app uses OpenStreetMap tiles by default. Override with:

```
flutter run --dart-define MAP_TILE_URL=https://your-tiles/{z}/{x}/{y}.png
flutter run --dart-define MAP_ATTRIBUTION="Map data © Your Provider"
flutter run --dart-define MAP_USER_AGENT=com.your.bundle
```

---

## ✅ Verification Checklist

Before running app:
- [ ] google-services.json in android/app/ folder
- [ ] Package name is com.example.women_safety everywhere
- [ ] Firebase Authentication enabled
- [ ] Firestore database created
- [ ] Test user created
- [ ] User document with guardians in Firestore
- [ ] Map loads using OpenStreetMap tiles (or your custom server)

---

## 🆘 Quick Troubleshooting

### App crashes on startup?
→ Check google-services.json is in android/app/ folder

### "No Firebase App created" error?
→ Run: `flutter clean` then `flutter pub get` then `flutter run`

### Can't sign in?
→ Make sure test user exists in Firebase Authentication

### No contacts loading?
→ Check user document exists in Firestore with guardians array

---

## 📞 Support

Need help? Check:
1. FIREBASE_SETUP_GUIDE.md (detailed guide)
2. Run: `.\setup-firebase.ps1` (setup assistant)
3. Check Firebase Console for errors

---

**Total Time: 5-7 minutes** ⏱️

Ready? Let's go! 🚀
