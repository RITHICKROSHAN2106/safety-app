# Firebase Setup - Without Storage (Temporary)

## What Works Without Storage:
✅ User Authentication
✅ Firestore Database (user data, contacts)
✅ Real-time location tracking
✅ SMS alerts
✅ Phone calls
✅ WhatsApp messages
✅ Email alerts
✅ Push notifications

## What Won't Work Without Storage:
❌ Video recording during SOS
❌ Photo capture during SOS
❌ Profile picture uploads
❌ Any file/media uploads

---

## Quick Setup Without Storage

### Step 1: Skip Storage Setup
Just ignore the Storage section for now - Firebase will show the upgrade message, but your app will handle it gracefully.

### Step 2: Enable These Services Only

#### A. Authentication
```
Firebase Console → Authentication → Get Started
→ Email/Password → Enable → Save
```

#### B. Firestore Database
```
Firebase Console → Firestore Database → Create Database
→ Production mode → Choose location (asia-south1) → Enable
```

#### C. Set Firestore Rules
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

### Step 3: Download Configuration

1. Go to **Project Settings** (gear icon top left)
2. Scroll to **Your apps** section
3. Click on your Android app
4. Download **google-services.json**
5. Place it in: `women_safety/android/app/google-services.json`

### Step 4: Create Test User & Data

#### A. Create User
```
Authentication → Add user
Email: test@womensafety.com
Password: Test123456!
→ Copy the UID (e.g., "vR8kL2mN4pQ6sT9uW1xY3zA5")
```

#### B. Add User Document in Firestore
```
Firestore → Start collection → "users"
Document ID: [paste UID from above]

Add fields:
- name: "Test User" (string)
- email: "test@womensafety.com" (string)
- phone: "+1234567890" (string)
- createdAt: [click "Set to current time"] (timestamp)
- guardians: (array) →
    [0] (map):
      - name: "Emergency Contact 1" (string)
      - phone: "+1234567891" (string)
      - relation: "Family" (string)
      - email: "contact1@example.com" (string)
    
    [1] (map):
      - name: "Emergency Contact 2" (string)
      - phone: "+1234567892" (string)
      - relation: "Friend" (string)
      - email: "contact2@example.com" (string)
    
    [2] (map):
      - name: "Local Police" (string)
      - phone: "911" (string)
      - relation: "Police" (string)
      - email: "police@local.gov" (string)

→ Save
```

### Step 5: Update App to Handle Missing Storage

The app will automatically handle missing storage gracefully - videos/photos just won't be uploaded, but all other SOS features work!

### Step 6: Run the App

```powershell
cd C:\Users\HRITIK\Desktop\womenSafety\women_safety
flutter clean
flutter pub get
flutter run
```

### Step 7: Test Sign In

```
Email: test@womensafety.com
Password: Test123456!
```

You should see:
✅ Successful login
✅ Emergency contacts loaded
✅ Can trigger SOS alerts (without video/photo)
✅ SMS/Call/WhatsApp/Email work
✅ Location tracking works

---

## When You're Ready to Add Storage

Later, when you want video/photo features:

1. **Upgrade to Blaze plan** (pay-as-you-go with free tier)
2. **Enable Storage** in Firebase Console
3. **Set Storage rules** (from FIREBASE_SETUP_GUIDE.md)
4. **Rebuild app** - no code changes needed!

**Your app is designed to work with or without Storage!** 🎉

---

## Cost Information

### Spark Plan (Current - FREE)
- ✅ Authentication: Unlimited
- ✅ Firestore: 1 GB storage, 50K reads/day, 20K writes/day
- ✅ Cloud Messaging: Unlimited
- ❌ Storage: Not available

### Blaze Plan (FREE tier is generous!)
- ✅ Everything in Spark
- ✅ Storage: 5 GB free, $0.026/GB after
- ✅ More Firestore: 10 GB free storage, 50K reads/day, 20K writes/day

**For testing/personal use, you'll likely never exceed free tier!** 💰

---

## Next Steps

1. [ ] Download google-services.json
2. [ ] Place in android/app/
3. [ ] Enable Authentication
4. [ ] Enable Firestore
5. [ ] Create test user
6. [ ] Add user data with guardians
7. [ ] Run app and sign in
8. [ ] Test SOS features (except video/photo)

---

**You can fully test your app without Storage! Add it later when needed.** ✅
