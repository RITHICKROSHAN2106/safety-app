# Google Maps API Configuration Guide

> ⚠️ **Heads up:** The Women Safety app now ships with OpenStreetMap tiles via `flutter_map`, so you no longer need a Google Maps API key for the default experience. Keep this reference only if you plan to swap back to Google Maps.

This guide will help you set up Google Maps for your Women Safety App.

---

## 📋 Prerequisites

- A Google Cloud account
- Billing enabled (Google Maps requires a billing account, but offers $200 free credits monthly)
- Flutter SDK installed
- Android Studio / Xcode

---

## 🗺️ Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **"Select a project"** → **"New Project"**
3. **Project name**: `women-safety-app`
4. Click **"Create"**
5. Wait for project creation (30-60 seconds)

---

## 💳 Step 2: Enable Billing (Required)

1. Go to **Billing** in the left menu
2. Click **"Link a billing account"**
3. Follow the steps to add a payment method
4. ✅ Don't worry: Google Maps offers **$200 free credits/month**

**Monthly Free Usage:**
- 28,000+ map loads
- 40,000+ directions requests
- 100,000+ geocoding requests

---

## 🔑 Step 3: Create API Key

### 3.1 Generate API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"API key"**
3. Copy the API key (e.g., `AIzaSyC1234567890abcdefghijklmnopqrstuvw`)
4. Click **"Restrict Key"** (recommended for security)

### 3.2 Restrict API Key (Android)

1. **Name**: `Android Maps Key`
2. **Application restrictions**:
   - Select **"Android apps"**
   - Click **"Add an item"**
   - **Package name**: `com.womensafety.women_safety`
   - **SHA-1 fingerprint**: Get from Android keystore
   
   ```powershell
   # Get SHA-1 from debug keystore:
   cd women_safety\android
   
   # Windows (PowerShell):
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   
   # Copy the SHA-1 certificate fingerprint
   ```

3. **API restrictions**:
   - Select **"Restrict key"**
   - Check these APIs:
     - ✅ Maps SDK for Android
     - ✅ Places API
     - ✅ Directions API
     - ✅ Geolocation API
     - ✅ Geocoding API
4. Click **"Save"**

### 3.3 Create Additional Keys (Optional)

**For iOS:**
- Create another key
- Name: `iOS Maps Key`
- Restrict to **"iOS apps"**
- Add Bundle ID: `com.womensafety.womenSafety`

**For Web:**
- Create another key
- Name: `Web Maps Key`
- Restrict to **"HTTP referrers"**
- Add your domain: `https://yourdomain.com/*`

---

## ⚡ Step 4: Enable Required APIs

1. Go to **APIs & Services** → **Library**
2. Search and **Enable** these APIs:

### Essential APIs
- ✅ **Maps SDK for Android**
- ✅ **Maps SDK for iOS** (if supporting iOS)
- ✅ **Places API** (for nearby safe zones)
- ✅ **Geolocation API** (for location tracking)
- ✅ **Geocoding API** (for address lookup)
- ✅ **Directions API** (for route sharing)

### Optional APIs
- **Distance Matrix API** (for calculating travel distances)
- **Roads API** (for road snapping)
- **Time Zone API** (for timezone conversions)

---

## 📱 Step 5: Configure Android App

### 5.1 Add API Key to AndroidManifest.xml

**File**: `women_safety/android/app/src/main/AndroidManifest.xml`

Find this line:
```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY" />
```

Replace with your actual API key:
```xml
<meta-data 
    android:name="com.google.android.geo.API_KEY" 
    android:value="AIzaSyC1234567890abcdefghijklmnopqrstuvw" />
```

⚠️ **Security Note**: For production, use a restricted key!

### 5.2 Verify AndroidManifest.xml

Ensure these permissions are present:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Internet permission for Maps -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Location permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <application
        android:label="Women Safety"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Google Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="AIzaSyC1234567890abcdefghijklmnopqrstuvw" />
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            ...>
        </activity>
    </application>
</manifest>
```

✅ Your file already has this structure!

---

## 🍎 Step 6: Configure iOS App

### 6.1 Add API Key to AppDelegate

**File**: `ios/Runner/AppDelegate.swift`

Add this import at the top:
```swift
import GoogleMaps
```

Update the `application` method:
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add your Google Maps API key
    GMSServices.provideAPIKey("AIzaSyC1234567890abcdefghijklmnopqrstuvw")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 6.2 Update Info.plist

**File**: `ios/Runner/Info.plist`

Add these entries:

```xml
<!-- Google Maps API Key -->
<key>GMSApiKey</key>
<string>AIzaSyC1234567890abcdefghijklmnopqrstuvw</string>

<!-- Location permissions (already in your file) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required to share your location during emergencies.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Location access is required to track your location for safety.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location access is required to track your location for safety.</string>
```

### 6.3 Install CocoaPods

```powershell
cd women_safety/ios
pod install
```

---

## 🌐 Step 7: Configure Web App (Optional)

**File**: `women_safety/web/index.html`

Add this in the `<head>` section:

```html
<head>
  <!-- ... existing code ... -->
  
  <!-- Google Maps JavaScript API -->
  <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyC1234567890abcdefghijklmnopqrstuvw"></script>
</head>
```

---

## ✅ Step 8: Verify Configuration

### Test Maps on Android

```powershell
cd women_safety

# Run on Android device/emulator
flutter run
```

**Expected**:
- Map should load with default location (India)
- Current location marker should appear (blue dot)
- No errors in console

### Test Maps on iOS

```powershell
cd women_safety

# Run on iOS simulator
flutter run -d ios
```

---

## 🧪 Test Google Maps Features

### Test Basic Map Display

Your `map_screen.dart` already has this implemented:

```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(20.5937, 78.9629), // Center of India
    zoom: 5,
  ),
  myLocationEnabled: true,
  myLocationButtonEnabled: false,
  markers: _markers,
  onMapCreated: (GoogleMapController controller) {
    _mapController = controller;
    _getCurrentLocation();
  },
)
```

### Test Current Location

```dart
Future<void> _getCurrentLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // Move camera to current location
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
    
    print('✅ Current location: ${position.latitude}, ${position.longitude}');
  } catch (e) {
    print('❌ Location error: $e');
  }
}
```

### Test Places API (Nearby Safe Zones)

Create a new service:

**File**: `lib/services/places_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesService {
  static const String apiKey = 'AIzaSyC1234567890abcdefghijklmnopqrstuvw';
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  static Future<List<Map<String, dynamic>>> getNearbyPoliceStations(
    LatLng location,
    int radiusMeters,
  ) async {
    final url = '$baseUrl?location=${location.latitude},${location.longitude}'
        '&radius=$radiusMeters&type=police&key=$apiKey';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getNearbyHospitals(
    LatLng location,
    int radiusMeters,
  ) async {
    final url = '$baseUrl?location=${location.latitude},${location.longitude}'
        '&radius=$radiusMeters&type=hospital&key=$apiKey';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    }
    return [];
  }
}
```

---

## 💰 Cost Estimation

### Monthly Free Tier ($200 credit)
- **Map loads**: 28,000 free
- **Directions**: 40,000 free requests
- **Geocoding**: 100,000 free requests
- **Places**: 100,000 free requests

### Typical Usage for Women Safety App
Assuming 1,000 active users:
- Map loads: ~30,000/month = $0 (within free tier)
- Directions: ~5,000/month = $0 (within free tier)
- Places API: ~10,000/month = $0 (within free tier)

**Expected Monthly Cost**: $0 (assuming moderate usage)

### Set Up Budget Alerts

1. Go to **Billing** → **Budgets & alerts**
2. Click **"Create budget"**
3. Set budget: **$50/month**
4. Set alert threshold: **50%, 90%, 100%**
5. Enter your email for notifications

---

## 🔒 Security Best Practices

### 1. Restrict API Keys

✅ **DO:**
- Use separate keys for Android, iOS, and Web
- Restrict by application (package name/bundle ID)
- Restrict by API (only enable needed APIs)

❌ **DON'T:**
- Use unrestricted keys in production
- Share keys publicly (GitHub, etc.)
- Use same key for all platforms

### 2. Environment Variables

For production, store API keys in environment files:

**Create**: `lib/services/config_prod.dart` (add to `.gitignore`)

```dart
class Config {
  static const String googleMapsApiKey = 'AIzaSyC1234567890abcdefghijklmnopqrstuvw';
}
```

**Update**: `.gitignore`

```
# API Keys
lib/services/config_prod.dart
```

### 3. Monitor Usage

1. Go to **APIs & Services** → **Dashboard**
2. Monitor API usage daily
3. Set up alerts for unusual spikes

---

## 🐛 Troubleshooting

### Android Issues

**Error**: "The Google Maps API Key is not valid"
- **Solution**: 
  - Check API key in `AndroidManifest.xml`
  - Verify "Maps SDK for Android" is enabled
  - Check SHA-1 fingerprint matches

**Error**: "Map shows only grey tiles"
- **Solution**:
  - Enable "Maps SDK for Android" in Google Cloud Console
  - Wait 5-10 minutes for API to activate
  - Check internet connection

**Error**: "Location permission denied"
- **Solution**:
  - Add permissions to `AndroidManifest.xml`
  - Request runtime permissions (already implemented in `permissions_service.dart`)

### iOS Issues

**Error**: "Google Maps SDK not found"
- **Solution**:
  - Run `cd ios && pod install`
  - Clean build: `flutter clean`
  - Rebuild: `flutter run`

**Error**: "API key not found in AppDelegate"
- **Solution**:
  - Add `GMSServices.provideAPIKey()` in `AppDelegate.swift`
  - Import `GoogleMaps` at the top

### Billing Issues

**Error**: "This API project is not authorized"
- **Solution**:
  - Enable billing on Google Cloud project
  - Wait 5-10 minutes for activation

---

## 📚 Useful Links

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Maps Platform](https://developers.google.com/maps)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [Places API Documentation](https://developers.google.com/maps/documentation/places/web-service)
- [Directions API Documentation](https://developers.google.com/maps/documentation/directions)

---

## ✅ Configuration Checklist

- [ ] Google Cloud project created
- [ ] Billing enabled
- [ ] API key created
- [ ] API key restricted (Android/iOS/Web)
- [ ] Maps SDK for Android enabled
- [ ] Maps SDK for iOS enabled (if needed)
- [ ] Places API enabled
- [ ] Directions API enabled
- [ ] Geolocation API enabled
- [ ] Geocoding API enabled
- [ ] API key added to `AndroidManifest.xml`
- [ ] API key added to `AppDelegate.swift` (iOS)
- [ ] Budget alerts set up
- [ ] App tested on device/emulator
- [ ] Current location working
- [ ] Map displays correctly
- [ ] No API errors in console

---

**Congratulations!** 🎉 Google Maps is now configured for your Women Safety App.

**Next**: Implement SOS features → See `SOS_IMPLEMENTATION.md`
