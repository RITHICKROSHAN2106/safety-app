# Firebase Data Structure for Women Safety App

## 📊 Firestore Database Structure

```
firestore/
│
├── users/
│   ├── {userId1}/                    ← Document (User UID from Authentication)
│   │   ├── name: "John Doe"          ← String
│   │   ├── email: "john@example.com" ← String
│   │   ├── phone: "+1234567890"      ← String
│   │   ├── createdAt: timestamp      ← Timestamp
│   │   └── guardians: [              ← Array of Maps
│   │       {
│   │         name: "Emergency Contact 1",
│   │         phone: "+1234567890",
│   │         relation: "Family",
│   │         email: "contact1@example.com"
│   │       },
│   │       {
│   │         name: "Emergency Contact 2",
│   │         phone: "+0987654321",
│   │         relation: "Friend",
│   │         email: "contact2@example.com"
│   │       }
│   │   ]
│   │
│   ├── {userId2}/                    ← Another user
│   │   ├── name: "Jane Smith"
│   │   ├── email: "jane@example.com"
│   │   └── ...
│   │
│
├── sos_alerts/                       ← Collection
│   ├── {alertId1}/                   ← Auto-generated document
│   │   ├── userId: "abc123"          ← String (reference to user)
│   │   ├── latitude: 37.7749         ← Number
│   │   ├── longitude: -122.4194      ← Number
│   │   ├── timestamp: timestamp      ← Timestamp
│   │   ├── type: "shake"             ← String (shake/voice/manual)
│   │   ├── status: "active"          ← String (active/resolved)
│   │   ├── message: "I need help!"   ← String
│   │   └── contactsNotified: [...]   ← Array
│   │
│
└── emergency_contacts/               ← Collection (alternative structure)
    ├── {contactId1}/
    │   ├── userId: "abc123"
    │   ├── name: "Contact Name"
    │   ├── phone: "+1234567890"
    │   └── relation: "Family"
    │
```

## 🗄️ Firebase Storage Structure

```
storage/
│
├── sos_videos/
│   ├── {userId}/
│   │   ├── {alertId}_video.mp4
│   │   └── {alertId}_video_2.mp4
│   │
│
├── sos_images/
│   ├── {userId}/
│   │   ├── {alertId}_photo.jpg
│   │   └── {alertId}_photo_2.jpg
│   │
│
└── user_profiles/
    ├── {userId}/
    │   └── profile_picture.jpg
    │
```

## 🔐 Authentication Structure

```
Firebase Authentication
│
├── User 1
│   ├── UID: "abc123xyz456"         ← This is your userId
│   ├── Email: "test@example.com"
│   ├── Password: (hashed)
│   └── Email Verified: true/false
│
├── User 2
│   ├── UID: "def789uvw012"
│   └── ...
│
```

## 📝 Example Data - Test User

### Authentication
```json
{
  "uid": "vR8kL2mN4pQ6sT9uW1xY3zA5",
  "email": "test@example.com",
  "emailVerified": false,
  "displayName": null,
  "photoURL": null,
  "disabled": false
}
```

### Firestore - users/{uid}
```json
{
  "name": "Test User",
  "email": "test@example.com",
  "phone": "+1234567890",
  "createdAt": "2025-10-20T10:30:00Z",
  "guardians": [
    {
      "name": "Mom",
      "phone": "+1234567891",
      "relation": "Family",
      "email": "mom@example.com"
    },
    {
      "name": "Best Friend",
      "phone": "+1234567892",
      "relation": "Friend",
      "email": "friend@example.com"
    },
    {
      "name": "Local Police",
      "phone": "911",
      "relation": "Police",
      "email": "police@local.gov"
    }
  ]
}
```

### Firestore - sos_alerts/{alertId}
```json
{
  "userId": "vR8kL2mN4pQ6sT9uW1xY3zA5",
  "latitude": 28.7041,
  "longitude": 77.1025,
  "timestamp": "2025-10-20T15:45:30Z",
  "type": "shake",
  "status": "active",
  "message": "Emergency! I need help!",
  "contactsNotified": [
    "+1234567891",
    "+1234567892",
    "911"
  ],
  "videoUrl": "gs://bucket/sos_videos/userId/alertId_video.mp4",
  "imageUrls": [
    "gs://bucket/sos_images/userId/alertId_photo1.jpg",
    "gs://bucket/sos_images/userId/alertId_photo2.jpg"
  ]
}
```

## 🔗 How Data Connects

```
┌─────────────────────┐
│  Firebase Auth      │
│  User Login         │
│  UID: abc123        │
└──────────┬──────────┘
           │
           │ Uses UID as Document ID
           ↓
┌─────────────────────┐
│  Firestore          │
│  users/abc123       │
│  - name             │
│  - email            │
│  - phone            │
│  - guardians[]      │ ────┐
└──────────┬──────────┘     │
           │                 │ Read contacts
           │                 │
           │ Create alert    ↓
           ↓           ┌──────────────┐
┌─────────────────────┐│  App loads   │
│  Firestore          ││  emergency   │
│  sos_alerts/xyz789  ││  contacts    │
│  - userId: abc123   │└──────────────┘
│  - location         │
│  - timestamp        │
│  - contactsNotified │
└─────────────────────┘
```

## 🎯 What to Create First

### 1. Firebase Authentication User
```
Email: test@example.com
Password: Test123456!
→ Get UID (e.g., "vR8kL2mN4pQ6sT9uW1xY3zA5")
```

### 2. Firestore users Document
```
Collection: users
Document ID: vR8kL2mN4pQ6sT9uW1xY3zA5  ← Same as UID!
Fields: name, email, phone, guardians (array)
```

### 3. Add Guardians Array
```
In the user document, add field:
guardians: [
  {name: "Contact 1", phone: "+123...", relation: "Family", email: "..."},
  {name: "Contact 2", phone: "+456...", relation: "Friend", email: "..."},
  {name: "Contact 3", phone: "+789...", relation: "Police", email: "..."}
]
```

---

## 💡 Important Notes

1. **UID = Document ID**: The user's UID from Authentication MUST match the document ID in Firestore users collection

2. **Array of Maps**: Guardians is an array where each item is a map (object) with fields: name, phone, relation, email

3. **Security**: Only authenticated users can read/write their own data (set by security rules)

4. **Auto-generated IDs**: SOS alerts use auto-generated IDs (don't manually create them)

---

## 📸 Firebase Console Screenshots Guide

### Where to find User UID:
```
Firebase Console → Authentication → Users tab
Click on user → See UID at top
```

### How to create user document:
```
Firebase Console → Firestore Database → Data tab
Click "Start collection" → Enter "users"
Document ID → Manual → Paste UID
Add fields → name, email, phone, guardians
```

### How to add guardians array:
```
In user document:
Click "Add field" → Field name: "guardians" → Type: "array"
Click "Add item" → Type: "map"
Add map fields: name, phone, relation, email
Repeat for each contact (3-5 recommended)
```

---

**This structure is already implemented in your app!**
Just follow QUICK_START_FIREBASE.md to set it up. 🚀
