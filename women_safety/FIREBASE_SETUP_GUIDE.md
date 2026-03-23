# Firebase Configuration Guide for Women Safety App

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
- Open your browser and go to: https://console.firebase.google.com/
- Sign in with your Google account

### 1.2 Create New Project
1. Click **"Add project"** or **"Create a project"**
2. Enter project name: **"Women Safety"** (or any name you prefer)
3. Click **"Continue"**
4. **Google Analytics**: You can enable or disable it (recommended: enable)
5. Click **"Create project"**
6. Wait for project creation to complete
7. Click **"Continue"** when done

---

## Step 2: Add Android App to Firebase

### 2.1 Register Your App
1. In Firebase Console, click on the **Android icon** (or "Add app" → "Android")
2. Fill in the form:
   - **Android package name**: `com.example.women_safety`
     (⚠️ IMPORTANT: Must match exactly!)
   - **App nickname** (optional): "Women Safety App"
   - **Debug signing certificate SHA-1** (optional for now, needed later for Google Sign-In)
3. Click **"Register app"**

### 2.2 Download google-services.json
1. Click **"Download google-services.json"**
2. Save the file to your computer
3. **IMPORTANT**: Move/Copy this file to:
   ```
   C:\Users\HRITIK\Desktop\womenSafety\women_safety\android\app\google-services.json
   ```
4. Click **"Next"**

### 2.3 Add Firebase SDK (Already Done!)
- Skip this step - we already have Firebase dependencies in pubspec.yaml
- Click **"Next"**

### 2.4 Finish Setup
- Click **"Continue to console"**

---

## Step 3: Enable Firebase Services

### 3.1 Enable Authentication
1. In Firebase Console, click **"Build"** → **"Authentication"**
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable **"Email/Password"**:
   - Click on "Email/Password"
   - Toggle **"Enable"** to ON
   - Toggle **"Email link (passwordless sign-in)"** to OFF (optional)
   - Click **"Save"**
5. (Optional) Enable **"Google"** sign-in:
   - Click on "Google"
   - Toggle **"Enable"** to ON
   - Enter project support email
   - Click **"Save"**

### 3.2 Enable Cloud Firestore
1. In Firebase Console, click **"Build"** → **"Firestore Database"**
2. Click **"Create database"**
3. **Start in production mode** (we'll set rules later)
4. Choose location: **asia-south1 (Mumbai)** or closest to you
5. Click **"Enable"**
6. Wait for database creation

### 3.3 Set Firestore Security Rules
1. In Firestore, go to **"Rules"** tab
2. Replace the rules with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // SOS Alerts - users can create and read their own alerts
    match /sos_alerts/{alertId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Emergency contacts - users can manage their own contacts
    match /emergency_contacts/{contactId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
    }
  }
}
```
3. Click **"Publish"**

### 3.4 Enable Firebase Storage
1. Click **"Build"** → **"Storage"**
2. Click **"Get started"**
3. **Start in production mode**
4. Choose same location as Firestore
5. Click **"Done"**

### 3.5 Set Storage Security Rules
1. Go to **"Rules"** tab in Storage
2. Replace with:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /sos_videos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /sos_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /user_profiles/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
3. Click **"Publish"**

### 3.6 Enable Cloud Messaging (for Push Notifications)
1. Click **"Build"** → **"Cloud Messaging"**
2. No additional setup needed - it's enabled by default
3. Note down the **Server Key** (you'll need this for backend)

---

## Step 4: Create Test Data in Firestore

### 4.1 Create Test User
1. Go to **"Authentication"** → **"Users"** tab
2. Click **"Add user"**
3. Enter:
   - **Email**: your-test-email@gmail.com
   - **Password**: TestPassword123!
4. Click **"Add user"**
5. Copy the **User UID** (e.g., `abc123xyz456`)

### 4.2 Add User Data in Firestore
1. Go to **"Firestore Database"** → **"Data"** tab
2. Click **"Start collection"**
3. Collection ID: `users`
4. Click **"Next"**
5. Document ID: **Paste the User UID from step 4.1**
6. Add fields:
   ```
   Field: name        Type: string   Value: Your Name
   Field: email       Type: string   Value: your-test-email@gmail.com
   Field: phone       Type: string   Value: +1234567890
   Field: createdAt   Type: timestamp Value: (click "Set to current time")
   ```
7. Click **"Save"**

### 4.3 Add Emergency Contacts
1. Click on the user document you just created
2. Click **"Add field"** → Choose **"Array"**
3. Field name: `guardians`
4. Add array items (each is a **Map**):
   
   **First Contact (Map)**:
   ```
   name: "Emergency Contact 1"
   phone: "+1234567890"
   relation: "Family"
   email: "contact1@example.com"
   ```
   
   **Second Contact (Map)**:
   ```
   name: "Emergency Contact 2"
   phone: "+0987654321"
   relation: "Friend"
   email: "contact2@example.com"
   ```
   
   **Third Contact (Map)**:
   ```
   name: "Emergency Contact 3"
   phone: "+1122334455"
   relation: "Police"
   email: "contact3@example.com"
   ```
5. Click **"Save"**

---

## Step 5: Verify google-services.json Placement

### 5.1 Check File Location
Make sure `google-services.json` is in the correct location:
```
women_safety/
  android/
    app/
      google-services.json  ← Should be here!
```

### 5.2 Verify File Content
Open `google-services.json` and verify:
- `"package_name": "com.example.women_safety"`
- Has Firebase URLs and keys

---

## Step 6: Update Android Build Files (Already Done!)

Your `android/app/build.gradle.kts` should already have:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Check this line exists
}
```

Your `android/build.gradle.kts` should have:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")  // ← Check this exists
    }
}
```

---

## Step 7: Rebuild and Test

### 7.1 Clean and Rebuild
```powershell
cd C:\Users\HRITIK\Desktop\womenSafety\women_safety
flutter clean
flutter pub get
flutter run
```

### 7.2 Test Sign In
1. Open the app on your device
2. Try signing in with the test credentials:
   - Email: your-test-email@gmail.com
   - Password: TestPassword123!
3. App should load your profile and emergency contacts

---

## Step 8: Map Tiles (OpenStreetMap)

The app now uses OpenStreetMap tiles via `flutter_map`, so no Google Maps API key is required.

### 8.1 Optional: Custom Tile Server
If you have a custom tile server:
1. Set environment values when building the app:
  ```powershell
  flutter run --dart-define MAP_TILE_URL=https://your-tile-server/{z}/{x}/{y}.png
  flutter run --dart-define MAP_ATTRIBUTION="Map data © Your Provider"
  flutter run --dart-define MAP_USER_AGENT=com.your.bundle
  ```
2. Rebuild the app to apply the overrides.

### 8.2 Default Tile Usage
- By default the app points to `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
- Attribution defaults to `Map tiles © OpenStreetMap contributors`.
- Make sure you comply with OpenStreetMap tile usage policy or provide your own tile server for heavy traffic.

---

## Step 9: Final Testing Checklist

- [ ] google-services.json in correct location
- [ ] Firebase project created
- [ ] Authentication enabled
- [ ] Firestore database created
- [ ] Test user created in Authentication
- [ ] User data added in Firestore
- [ ] Emergency contacts added
- [ ] Map tiles load (OpenStreetMap defaults or custom server)
- [ ] App builds successfully
- [ ] Can sign in with test credentials
- [ ] Emergency contacts load correctly
- [ ] Can trigger SOS (test mode)

---

## Troubleshooting

### Issue: "No Firebase App '[DEFAULT]' has been created"
**Solution**: Make sure `google-services.json` is in `android/app/` folder

### Issue: "Failed to load FirebaseOptions"
**Solution**: 
1. Delete `google-services.json`
2. Re-download from Firebase Console
3. Place in `android/app/` folder
4. Run `flutter clean` and rebuild

### Issue: Package name mismatch
**Solution**: Verify package name is `com.example.women_safety` in:
- Firebase Console
- `google-services.json`
- `android/app/build.gradle.kts`
- `AndroidManifest.xml`

### Issue: Maps not showing
**Solution**:
1. Verify API key is correct
2. Check if Maps SDK for Android is enabled
3. Verify SHA-1 fingerprint is added

---

## Quick Reference

### Important Files
- Firebase config: `android/app/google-services.json`
- Maps API key: `android/app/src/main/AndroidManifest.xml`
- Package name: `com.example.women_safety`

### Firebase Console URLs
- Main console: https://console.firebase.google.com/
- Your project: https://console.firebase.google.com/project/YOUR_PROJECT_ID

### Test Credentials
- Email: your-test-email@gmail.com
- Password: TestPassword123!

---

## Need Help?

If you encounter any issues:
1. Check the error messages in the Flutter console
2. Verify all files are in correct locations
3. Ensure package names match everywhere
4. Try `flutter clean` and rebuild
5. Check Firebase Console for any service that's not enabled

---

**Created**: October 20, 2025
**Last Updated**: October 20, 2025
