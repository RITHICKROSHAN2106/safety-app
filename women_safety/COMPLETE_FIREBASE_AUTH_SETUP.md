# 🔥 Complete Firebase Authentication Setup

## What "Auth to be wired" Means
This message means you need to **enable Authentication services** in Firebase Console.

---

## 🚀 Quick 3-Step Setup

### Step 1: Enable Authentication (2 minutes)

1. **In Firebase Console** (where you are now)
2. **Click "Authentication"** in the left sidebar
3. **Click "Get started"** button
4. **Go to "Sign-in method" tab**
5. **Enable Email/Password**:
   - Click on "Email/Password" row
   - Toggle **"Enable"** switch to ON
   - Click **"Save"**

**✅ Done! Authentication is now enabled.**

---

### Step 2: Enable Firestore Database (2 minutes)

1. **Click "Firestore Database"** in left sidebar
2. **Click "Create database"** button
3. **Select "Start in production mode"**
4. **Choose location**: `asia-south1 (Mumbai)` or closest to you
5. **Click "Enable"**
6. **Wait for database creation** (~30 seconds)

**Set Security Rules:**
1. Go to **"Rules"** tab
2. Replace with this:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /sos_alerts/{alertId} {
      allow read, write: if request.auth != null;
    }
  }
}
```
3. Click **"Publish"**

**✅ Done! Firestore is ready.**

---

### Step 3: Create Test User & Data (3 minutes)

#### A. Create Test User
1. **Go to "Authentication" → "Users" tab**
2. **Click "Add user"**
3. **Fill in**:
   - Email: `test@womensafety.com`
   - Password: `Test123456!`
4. **Click "Add user"**
5. **COPY THE USER UID** (e.g., `vR8kL2mN4pQ6sT9uW1xY3zA5`)

#### B. Add User Document in Firestore
1. **Go to "Firestore Database" → "Data" tab**
2. **Click "Start collection"**
3. **Collection ID**: `users`
4. **Click "Next"**
5. **Document ID**: Paste the UID you copied above
6. **Add these fields**:

| Field | Type | Value |
|-------|------|-------|
| name | string | Test User |
| email | string | test@womensafety.com |
| phone | string | +1234567890 |
| createdAt | timestamp | (click "Set to current time") |

7. **Click "Save"**

#### C. Add Emergency Contacts Array
1. **Click on the user document** you just created
2. **Click "Add field"**
3. **Field name**: `guardians`
4. **Type**: `array`
5. **Add 3 items** (each is a `map`):

**Contact 1 (map):**
```
name: "Mom" (string)
phone: "+1234567891" (string)
relation: "Family" (string)
email: "mom@example.com" (string)
```

**Contact 2 (map):**
```
name: "Best Friend" (string)
phone: "+1234567892" (string)
relation: "Friend" (string)
email: "friend@example.com" (string)
```

**Contact 3 (map):**
```
name: "Police" (string)
phone: "911" (string)
relation: "Emergency" (string)
email: "emergency@local.gov" (string)
```

6. **Click "Update"**

**✅ Done! Test data is ready.**

---

## 🎯 Now Build Your App!

Run these commands:

```powershell
cd C:\Users\HRITIK\Desktop\womenSafety\women_safety
flutter clean
flutter pub get
flutter run
```

### What Should Happen:
- ✅ App builds successfully
- ✅ App opens on your device
- ✅ No Firebase errors
- ✅ Can sign in with: `test@womensafety.com` / `Test123456!`
- ✅ Emergency contacts load automatically
- ✅ Can test SOS features

---

## 📱 After App Launches

### Test Sign In:
```
Email: test@womensafety.com
Password: Test123456!
```

### What You'll See:
- ✅ User profile loads
- ✅ 3 emergency contacts appear
- ✅ SOS button is active
- ✅ All features work

---

## ⚠️ Important Notes

### Storage (Optional for Now)
You might see "Storage requires billing" - **skip it for now**:
- Video/photo upload won't work
- Everything else works perfectly
- Add Storage later when needed (see FIREBASE_SETUP_WITHOUT_STORAGE.md)

### Map Tiles
The app uses OpenStreetMap tiles by default:
- Location tracking and visualization work out of the box
- No API key is required
- Override tiles via MAP_TILE_URL / MAP_ATTRIBUTION when needed

---

## ✅ Verification Checklist

Before running app:
- [x] google-services.json in `android/app/`
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore Database created
- [ ] Firestore security rules set
- [ ] Test user created in Authentication
- [ ] User document created in Firestore
- [ ] guardians array added with 3 contacts

After completing checklist → Run `flutter run`!

---

## 🆘 Troubleshooting

### "No Firebase App created" error
→ Make sure google-services.json is in `android/app/` (not `android/`)
→ Run: `flutter clean` then rebuild

### "User not found" error
→ Make sure test user exists in Authentication
→ Check email/password are correct

### "No contacts loading"
→ Make sure user document exists in Firestore
→ Check guardians array has items
→ Verify document ID matches user UID

---

**Total time: ~7 minutes to complete all steps!** ⏱️

Then your app will be fully functional! 🚀
