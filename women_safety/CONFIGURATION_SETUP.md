# 🔧 Configuration Setup Guide

## Date: November 22, 2025

This guide will help you configure all 8 revolutionary features to make them fully operational.

---

## 📋 **TABLE OF CONTENTS**

1. [Agora Live Streaming Setup](#1-agora-live-streaming-setup)
2. [TensorFlow Lite AI Model Setup](#2-tensorflow-lite-ai-model-setup)
3. [Android Panic Widget Configuration](#3-android-panic-widget-configuration)
4. [Permissions Configuration](#4-permissions-configuration)
5. [Firebase Configuration](#5-firebase-configuration)
6. [Testing Checklist](#6-testing-checklist)

---

## 1️⃣ **Agora Live Streaming Setup**

### Step 1: Create Agora Account
1. Go to https://www.agora.io/
2. Click **"Sign Up"** (free for 10,000 minutes/month)
3. Verify your email

### Step 2: Create Project
1. Go to **Console** → **Projects**
2. Click **"Create New Project"**
3. Name: `Women Safety Live Streaming`
4. Use Case: **Video Calling**
5. Click **"Submit"**

### Step 3: Get App ID
1. In your project, find **"App ID"** under **Basic Information**
2. Copy the App ID (format: `abc123def456ghi789jkl012`)

### Step 4: Update Code
Open `lib/services/live_streaming_service.dart` and update line 15:

```dart
// BEFORE:
static const String _appId = 'YOUR_AGORA_APP_ID';

// AFTER:
static const String _appId = 'abc123def456ghi789jkl012'; // Your actual App ID
```

### Step 5: (Optional) Enable Token Authentication
For production, enable token authentication:
1. In Agora Console → **Project Settings**
2. Enable **"App Certificate"**
3. Implement token server (see Agora docs)

### Verification:
- ✅ Run the app → Revolutionary Features → Live Streaming
- ✅ Click "Start Streaming" - should connect without errors
- ✅ Check Agora Console for active channel

---

## 2️⃣ **TensorFlow Lite AI Model Setup**

### Option A: Use Pre-trained Model (Recommended for Testing)

#### Step 1: Download Sample Model
Download a simple danger prediction model:
```
https://github.com/women-safety/ml-models/danger_prediction_model.tflite
```
*Note: This is a placeholder URL - you'll need to train your own model*

#### Step 2: Create Assets Folder
```bash
mkdir assets
mkdir assets\models
```

#### Step 3: Add Model File
Place `danger_prediction_model.tflite` in:
```
assets/models/danger_prediction_model.tflite
```

#### Step 4: Update pubspec.yaml
Already done! The assets section should include:
```yaml
flutter:
  assets:
    - assets/models/
```

### Option B: Train Your Own Model (Production)

#### Step 1: Collect Training Data
Create a dataset with these features:
- Hour of day (0-23)
- Is night time (0 or 1)
- Is weekend (0 or 1)
- Latitude
- Longitude
- Historical incident count
- Population density (1-3)
- Lighting condition (1-3)

Labels: Danger score (0-10)

#### Step 2: Train Model
Use TensorFlow/Keras:

```python
import tensorflow as tf
from tensorflow import keras

# Create model
model = keras.Sequential([
    keras.layers.Dense(16, activation='relu', input_shape=(8,)),
    keras.layers.Dropout(0.2),
    keras.layers.Dense(8, activation='relu'),
    keras.layers.Dense(1, activation='linear')  # Output: 0-10
])

# Compile
model.compile(
    optimizer='adam',
    loss='mse',
    metrics=['mae']
)

# Train
model.fit(X_train, y_train, epochs=100, validation_split=0.2)

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save
with open('danger_prediction_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

#### Step 3: Deploy Model
Place the trained model in `assets/models/danger_prediction_model.tflite`

### Verification:
- ✅ Run: `flutter pub get`
- ✅ Check assets are bundled: `flutter build apk --release`
- ✅ Test AI prediction screen - should show predictions without errors

---

## 3️⃣ **Android Panic Widget Configuration**

### Step 1: Create Widget Provider (Kotlin)

Create file: `android/app/src/main/kotlin/com/example/women_safety/PanicWidgetProvider.kt`

```kotlin
package com.example.women_safety

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PanicWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.panic_widget)
            
            // Get data from SharedPreferences
            val widgetData = HomeWidgetPlugin.getData(context)
            val userName = widgetData.getString("userName", "User")
            val isEnabled = widgetData.getBoolean("isEnabled", false)
            
            // Update widget text
            views.setTextViewText(R.id.widget_text, "SOS - $userName")
            
            // Set click handler
            val intent = Intent(context, MainActivity::class.java)
            intent.action = "PANIC_BUTTON_PRESSED"
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_button, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

### Step 2: Create Widget Layout (XML)

Create file: `android/app/src/main/res/layout/panic_widget.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="16dp"
    android:background="@drawable/widget_background">

    <Button
        android:id="@+id/widget_button"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:text="🚨 SOS"
        android:textSize="24sp"
        android:textColor="#FFFFFF"
        android:background="#FF0000"
        android:gravity="center" />

    <TextView
        android:id="@+id/widget_text"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Panic Button"
        android:textColor="#FFFFFF"
        android:textSize="12sp"
        android:layout_marginTop="4dp" />
</LinearLayout>
```

### Step 3: Create Widget Background

Create file: `android/app/src/main/res/drawable/widget_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#FF0000" />
    <corners android:radius="16dp" />
</shape>
```

### Step 4: Update AndroidManifest.xml

Add inside `<application>` tag:

```xml
<receiver
    android:name=".PanicWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/panic_widget_info" />
</receiver>
```

### Step 5: Create Widget Info

Create file: `android/app/src/main/res/xml/panic_widget_info.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/panic_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:description="@string/panic_widget_description" />
```

### Step 6: Add String Resource

In `android/app/src/main/res/values/strings.xml`:

```xml
<string name="panic_widget_description">One-tap SOS panic button</string>
```

### Verification:
- ✅ Rebuild app: `flutter clean && flutter build apk`
- ✅ Long press home screen → Widgets → Find "Women Safety"
- ✅ Drag widget to home screen
- ✅ Tap widget - should trigger panic

---

## 4️⃣ **Permissions Configuration**

### Android Permissions

In `android/app/src/main/AndroidManifest.xml`, ensure these permissions exist:

```xml
<manifest ...>
    <!-- Existing permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- NEW: Add these for revolutionary features -->
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- For panic widget -->
    <uses-permission android:name="com.android.launcher.permission.INSTALL_SHORTCUT" />
</manifest>
```

### iOS Permissions (Info.plist)

In `ios/Runner/Info.plist`, add:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face recognition and live streaming during emergencies</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice distress detection and live streaming</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to register guardian faces</string>
```

---

## 5️⃣ **Firebase Configuration**

### Firestore Security Rules

Update Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules...
    
    // NEW: Volunteer guardians collection
    match /volunteer_guardians/{volunteerId} {
      allow read: if true; // Public read for finding nearby volunteers
      allow write: if request.auth != null && request.auth.uid == volunteerId;
    }
    
    // NEW: Volunteer alerts
    match /volunteer_alerts/{alertId} {
      allow read, write: if request.auth != null;
    }
    
    // NEW: Rides collection
    match /rides/{rideId} {
      allow read, write: if request.auth != null;
    }
    
    // NEW: Ride alerts
    match /ride_alerts/{alertId} {
      allow read, write: if request.auth != null;
    }
    
    // NEW: Guardian faces
    match /guardian_faces/{faceId} {
      allow read, write: if request.auth != null;
    }
    
    // NEW: Incidents (for AI danger prediction)
    match /incidents/{incidentId} {
      allow read: if true; // Public read for ML model
      allow write: if request.auth != null;
    }
    
    // NEW: Danger zones
    match /danger_zones/{zoneId} {
      allow read: if true; // Public read
      allow write: if request.auth != null;
    }
  }
}
```

### Create Firestore Indexes

In Firebase Console → Firestore → Indexes, create:

1. **volunteer_guardians**
   - Fields: `latitude` (Ascending), `longitude` (Ascending)
   - Query scope: Collection

2. **incidents**
   - Fields: `latitude` (Ascending), `longitude` (Ascending), `timestamp` (Descending)
   - Query scope: Collection

---

## 6️⃣ **Testing Checklist**

### Feature 1: Fake Call ✅
- [ ] Open Revolutionary Features → Fake Call
- [ ] Set caller name "Mom" and number "+91 98765 43210"
- [ ] Set delay to 5 seconds
- [ ] Click "Schedule Fake Call"
- [ ] Wait 5 seconds - realistic call screen should appear
- [ ] Test answer button
- [ ] Test decline button

### Feature 2: Panic Widget ✅
- [ ] Open Revolutionary Features → Panic Widget
- [ ] Enable widget toggle
- [ ] Click "Update Widget"
- [ ] Exit app, go to home screen
- [ ] Long press → Widgets → Find "Women Safety"
- [ ] Add widget to home screen
- [ ] Tap widget - app should open with SOS triggered

### Feature 3: Live Streaming ✅
- [ ] Configure Agora App ID (see Section 1)
- [ ] Open Revolutionary Features → Live Streaming
- [ ] Click "Start Streaming"
- [ ] Should show "LIVE STREAMING" with channel ID
- [ ] Test camera switch button
- [ ] Test microphone mute button
- [ ] Click "Stop Streaming"

### Feature 4: Ride Tracking ✅
- [ ] Add at least 1 guardian first
- [ ] Open Revolutionary Features → Ride Tracking
- [ ] Select ride type "Ola"
- [ ] Fill in driver details
- [ ] Click "Start Ride Tracking"
- [ ] Check Firestore → `rides` collection for new document
- [ ] Guardians should receive WhatsApp with tracking link
- [ ] Move phone 500m away to test deviation alert
- [ ] Click "End Ride Safely"

### Feature 5: Guardian Network ✅
- [ ] Open Revolutionary Features → Guardian Network
- [ ] Enable "Register as Volunteer Guardian"
- [ ] Set help radius to 5 km
- [ ] Click "Find Nearby Volunteers"
- [ ] Should show list of volunteers (if any registered)
- [ ] Check Firestore → `volunteer_guardians` collection

### Feature 6: Face Recognition ✅
- [ ] Open Revolutionary Features → Face Recognition
- [ ] Click "Register Guardian Face"
- [ ] Take photo of guardian
- [ ] Should show "Guardian Face Registered"
- [ ] Click "Verify Face Now"
- [ ] Take photo of same person
- [ ] Should show "✅ Verified" with confidence %

### Feature 7: Voice Distress Analysis ✅
- [ ] Open Revolutionary Features → Voice Distress Analysis
- [ ] Click "Start Voice Analysis"
- [ ] Speak normally - distress score should be low (0-30)
- [ ] Say "help me" - distress score should increase (40-60)
- [ ] Say "help help emergency" loudly - score should hit 80+
- [ ] Should auto-trigger warning at 80% distress
- [ ] Click "Stop Analysis"

### Feature 8: AI Danger Prediction ✅
- [ ] Configure TFLite model (see Section 2)
- [ ] Open Revolutionary Features → AI Danger Prediction
- [ ] Should auto-detect current location danger
- [ ] Should show danger score (0-10) and level
- [ ] Should show safety recommendations
- [ ] Click refresh button to recalculate
- [ ] Click "Get Safe Route" (coming soon feature)

---

## 🚨 **Troubleshooting**

### Issue: Agora "Invalid App ID" Error
**Solution**: 
1. Check App ID has no spaces
2. Verify App ID is 32 characters
3. Make sure you're using App ID, not App Certificate

### Issue: TFLite Model Not Found
**Solution**:
1. Verify file path: `assets/models/danger_prediction_model.tflite`
2. Run `flutter pub get`
3. Rebuild app: `flutter clean && flutter build apk`

### Issue: Panic Widget Not Showing
**Solution**:
1. Check PanicWidgetProvider.kt exists
2. Verify AndroidManifest.xml has receiver declaration
3. Rebuild: `flutter clean && flutter build apk`
4. Reinstall app completely

### Issue: Face Recognition Crashes
**Solution**:
1. Check camera permissions granted
2. Verify google_ml_kit dependency installed
3. Test on physical device (not emulator)

### Issue: Voice Distress Not Working
**Solution**:
1. Check microphone permission granted
2. Test in quiet environment
3. Speak clearly and loudly for keyword detection

---

## 📱 **Quick Start Commands**

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Install on device
flutter install

# Run with logs
flutter run --release -v

# Test specific feature
flutter run --dart-define=TEST_FEATURE=fake_call
```

---

## 🎉 **Configuration Complete!**

Once all configurations are done:
1. ✅ Agora App ID configured
2. ✅ TFLite model in assets
3. ✅ Panic widget XML files created
4. ✅ Permissions added to manifest
5. ✅ Firestore rules updated
6. ✅ All features tested

**Your app is now FULLY OPERATIONAL with all 8 revolutionary features! 🚀**

---

## 📞 **Support**

If you encounter issues:
1. Check logs: `flutter run -v`
2. Verify Firestore collections exist
3. Test permissions: `adb shell pm list permissions -g`
4. Review this configuration guide step-by-step

**Built with ❤️ for women's safety worldwide**
