# 🧪 Testing Checklist for Revolutionary Features

## Pre-Testing Setup

### 1. Firebase Configuration
- [ ] Ensure Firebase is configured in `google-services.json`
- [ ] Firestore database is in **test mode** (open rules for testing)
- [ ] Firebase Storage rules allow uploads
- [ ] Firebase Authentication is enabled

### 2. Device Permissions
When the app launches, you'll be prompted for permissions. **Grant all:**
- [ ] Location (Allow all the time)
- [ ] Phone/Call (for direct calling)
- [ ] SMS (for sending alerts)
- [ ] Camera (for evidence photos)
- [ ] Microphone (for audio recording)
- [ ] Notifications (for alerts)
- [ ] Battery optimization (disable for app)

---

## 🚨 Test 1: Basic SOS Trigger

### Steps:
1. **Add at least 2 guardians** in your profile
   - Go to Profile → Emergency Contacts
   - Add Name, Phone, Relationship
   
2. **Trigger SOS** using the red button on home screen

3. **Expected Results:**
   - ✅ Alarm sound starts playing (45 seconds)
   - ✅ SMS sent to all guardians
   - ✅ Phone starts calling first guardian
   - ✅ Success notification appears

### Verify in Logs:
```
🚨 ========== SOS TRIGGERED ==========
📍 STEP 1: Getting current location...
🎬 STEP 1.5: Starting evidence capture...
🎯 STEP 1.6: Starting guardian live tracking...
🔊 STEP 3: Starting local alarm...
📱 STEP 4: Sending SMS alerts...
📞 STEP 5: Starting smart call escalation...
```

---

## 📞 Test 2: Smart Call Escalation

### Steps:
1. Trigger SOS
2. **Don't answer the first call**
3. Wait 30 seconds

### Expected Results:
- ✅ Call attempt 1 to Guardian 1
- ⏱️ Wait 30 seconds
- ✅ Call attempt 2 to Guardian 1
- ⏱️ Wait 30 seconds
- ✅ Call attempt 3 to Guardian 1
- ⏱️ Wait 30 seconds
- ✅ Escalate to Guardian 2 (3 attempts)
- ✅ Escalate to Guardian 3 (3 attempts)
- ✅ Finally calls emergency services (112/911)

### Verify in Logs:
```
📞 Starting smart call escalation...
📞 Attempt 1/3 to Guardian 1 (John)...
⏳ Waiting 30 seconds before retry...
📞 Attempt 2/3 to Guardian 1 (John)...
📞 Escalating to next guardian: Guardian 2
📞 Calling emergency services: 112
```

---

## 🌐 Test 3: Offline Queue System

### Steps:
1. **Enable Airplane Mode** on device
2. Trigger SOS
3. Wait for "queued for offline retry" message
4. **Disable Airplane Mode**

### Expected Results:
- ✅ SMS/Alerts queued when offline
- ✅ "Queued for offline retry" message appears
- ✅ When network returns, alerts auto-send
- ✅ Queue processes automatically

### Verify in Logs:
```
💾 Queueing alert for offline retry...
📥 Alert queued: 1 items in queue
🌐 Network restored, processing queue...
✅ Queue processed: 1 alerts sent
```

### Check Firestore:
- Collection: `offline_queue`
- Should see queued alerts

---

## 🎯 Test 4: Guardian Live Tracking

### Steps:
1. Trigger SOS
2. Open Firestore console in browser
3. Navigate to `live_tracking` collection

### Expected Results in Firestore:
```json
{
  "sessionId": "track_1731328800000",
  "userId": "your_user_id",
  "status": "active",
  "currentLocation": {
    "latitude": 28.7041,
    "longitude": 77.1025,
    "accuracy": 10.5,
    "timestamp": "2025-11-11T10:30:00.000Z"
  },
  "locationHistory": [
    { "latitude": 28.7041, "longitude": 77.1025, "timestamp": "..." },
    { "latitude": 28.7042, "longitude": 77.1026, "timestamp": "..." },
    // Updates every 5-10 seconds
  ],
  "acknowledgments": {}
}
```

### Verify:
- ✅ Location updates every 5 seconds (first 2 minutes)
- ✅ Then every 10 seconds
- ✅ `locationHistory` array grows
- ✅ Each update has lat, lng, accuracy, speed, heading

---

## 🎬 Test 5: Evidence Capture

### Steps:
1. Grant Camera + Microphone permissions
2. Trigger SOS
3. Wait 30 seconds
4. Check Firebase Storage console

### Expected Results:

#### Audio Recording:
- Path: `/evidence/evidence_xxxxx/audio/`
- File: `evidence_audio_xxxxx.aac.encrypted`
- Size: ~2-5 MB (5:30 minutes)

#### Photo Capture:
- Path: `/evidence/evidence_xxxxx/photos/`
- Files: Multiple photos (every 10 seconds)
- Each: ~50-200 KB

#### Firestore Evidence Session:
Collection: `evidence_sessions`
```json
{
  "sessionId": "evidence_1731328800000",
  "userId": "your_user_id",
  "status": "active",
  "evidence": {
    "audio": [
      {
        "url": "https://firebasestorage.../audio.encrypted",
        "timestamp": "...",
        "checksum": "abc123...",
        "size": 2048576
      }
    ],
    "photos": [
      { "url": "...", "timestamp": "...", "checksum": "..." },
      { "url": "...", "timestamp": "...", "checksum": "..." }
    ],
    "environmental": [
      {
        "timestamp": "...",
        "deviceTime": 1731328800000,
        "timezone": "Asia/Kolkata"
      }
    ]
  }
}
```

### Verify in Logs:
```
🎬 Starting evidence capture...
✅ Evidence capture started
🎤 Audio recording started: /path/to/audio.aac
📷 Camera initialized
📷 Photo captured: /path/to/photo.jpg
🔒 File encrypted: /path/to/photo.jpg.encrypted
☁️ File uploaded: https://...
```

---

## 🚗 Test 6: Safe Journey Mode

### Steps:
1. Create a "Start Journey" screen (see UI_INTEGRATION_GUIDE.md)
2. Or manually call the service:
```dart
final journeyService = SafeJourneyService();
await journeyService.startJourney(
  userId: user.id,
  userName: "Your Name",
  startLocation: { 'latitude': 28.7041, 'longitude': 77.1025 },
  destinationLocation: { 'latitude': 28.6139, 'longitude': 77.2090 },
  destinationName: "New Delhi Railway Station",
  estimatedArrival: DateTime.now().add(Duration(hours: 1)),
  guardianPhones: ['+1234567890'],
);
```

3. Start walking/driving
4. Wait 10 minutes for check-in prompt
5. Move off route (500m+ deviation)

### Expected Results:
- ✅ Journey session created in Firestore
- ✅ Location updates every 30 seconds
- ✅ Check-in reminder after 10 minutes
- ✅ Route deviation alert if >500m off
- ✅ ETA alert if delayed 15+ minutes
- ✅ Auto-end when within 100m of destination

### Check Firestore:
Collection: `safe_journeys`
```json
{
  "journeyId": "journey_1731328800000",
  "status": "active",
  "destinationName": "New Delhi Railway Station",
  "estimatedArrival": "2025-11-11T11:30:00Z",
  "locationHistory": [...],
  "checkIns": [
    { "timestamp": "...", "message": "All good" }
  ],
  "alerts": [
    { "type": "route_deviation", "message": "...", "timestamp": "..." }
  ]
}
```

---

## 🔧 Debugging Tips

### If Location Not Working:
1. Check permission granted: **Allow all the time**
2. Enable **High accuracy** in device settings
3. Ensure GPS is enabled
4. Check logs for permission errors

### If Calls Not Working:
1. Check CALL_PHONE permission granted
2. Verify guardian phone numbers include country code
3. Check logs for "Direct call permission denied"

### If SMS Not Sending:
1. Check SMS permission granted
2. If permission denied, app should open SMS composer
3. Verify guardian phone numbers are valid

### If Evidence Not Capturing:
1. Check Camera + Microphone permissions
2. Check Firebase Storage rules (allow writes)
3. Look for encryption errors in logs
4. Verify Firebase Storage bucket is set up

### If Live Tracking Not Working:
1. Check Firestore rules (allow reads/writes)
2. Verify internet connection
3. Check Firebase console for `live_tracking` collection
4. Look for location update logs

---

## 📊 Performance Checks

### Battery Usage:
- Monitor battery drain during testing
- Should be <5% per hour with active tracking
- Location updates are optimized

### Network Usage:
- Monitor data consumption
- Location updates: ~1 KB each
- Photos: ~100 KB each
- Audio: ~2-5 MB total

### App Responsiveness:
- UI should remain smooth
- No freezing during SOS
- Background services don't block UI

---

## ✅ Success Criteria

### Minimum Requirements:
- [ ] SOS trigger works with alarm + SMS + call
- [ ] At least 1 guardian receives alert
- [ ] Location is captured and sent
- [ ] App doesn't crash during SOS

### Advanced Features (Revolutionary):
- [ ] Call escalation tries all guardians
- [ ] Offline queue holds and resends alerts
- [ ] Live tracking updates in real-time
- [ ] Evidence capture works (audio + photos)
- [ ] Safe Journey Mode tracks location

### Production Ready:
- [ ] All 6 advanced features tested
- [ ] No critical errors in logs
- [ ] Battery drain acceptable (<5%/hr)
- [ ] Permissions handled gracefully
- [ ] User experience is smooth

---

## 🎉 What to Look For

### Signs of Success:
1. **Logs are verbose** - You'll see detailed print statements
2. **Firestore fills up** - New documents in collections
3. **Firebase Storage grows** - Encrypted files uploaded
4. **Guardian phones ring** - Calls are escalating
5. **Location updates smoothly** - Maps show movement

### Red Flags:
1. **No logs appearing** - Service not running
2. **Firestore empty** - Network or permission issue
3. **No files in Storage** - Upload failing
4. **Calls not escalating** - Permission or logic issue
5. **Location not updating** - GPS permission issue

---

## 📞 Need Help?

### Check These First:
1. **Logs**: `flutter run --verbose` for detailed output
2. **Firestore**: Check all collections exist and have data
3. **Storage**: Verify files are uploading
4. **Permissions**: All should be granted

### Common Issues:
- **"Permission denied"**: Grant all permissions in settings
- **"Null location"**: Enable GPS and location permission
- **"Network error"**: Check internet connection
- **"Build failed"**: Run `flutter clean && flutter pub get`

---

## 🚀 Next: Production Deployment

Once testing is complete:
1. Replace encryption keys (evidence_capture_service.dart)
2. Replace tracking URLs (guardian_tracking_service.dart, safe_journey_service.dart)
3. Set up proper Firestore security rules
4. Configure Firebase Storage rules
5. Set up FCM for push notifications
6. Add crash reporting (Firebase Crashlytics)
7. Test on multiple devices
8. Submit to Google Play Store

**Good luck with testing! 🎉**
