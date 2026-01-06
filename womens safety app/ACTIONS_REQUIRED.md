# 🚨 IMMEDIATE ACTIONS REQUIRED

Before running the app, you MUST complete these steps:

---

## ⚡ STEP 1: Install Flutter (if not installed)

1. Visit: https://docs.flutter.dev/get-started/install/windows
2. Download Flutter SDK
3. Extract to `C:\src\flutter`
4. Add to PATH: `C:\src\flutter\bin`
5. Open new PowerShell and run:
   ```powershell
   flutter doctor
   ```
6. Fix any issues shown

---

## ⚡ STEP 2: Install Dependencies

Open PowerShell in this folder and run:

```powershell
flutter pub get
```

Wait for all packages to download (1-2 minutes).

---

## ⚡ STEP 3: Firebase Setup (REQUIRED!)

### The app WILL CRASH without Firebase configuration!

1. **Go to Firebase Console**
   - https://console.firebase.google.com/
   - Click "Add Project"
   - Name: "Women Safety App"
   - Create project

2. **Add Android App**
   - Click Android icon
   - Package name: `com.example.women_safety_app`
   - Download `google-services.json`

3. **Place Configuration File**
   - Put `google-services.json` in:
   ```
   android/app/google-services.json
   ```
   - This location is CRITICAL!

4. **Enable Services**
   - Go to Authentication → Enable Email/Password
   - Go to Firestore Database → Create database (test mode)

---

## ⚡ STEP 4: Connect Android Device

1. **Enable Developer Mode on Phone**
   - Settings → About Phone
   - Tap "Build Number" 7 times

2. **Enable USB Debugging**
   - Settings → Developer Options
   - Turn on "USB Debugging"

3. **Connect to Computer**
   - Connect phone via USB
   - Allow USB debugging when prompted

4. **Verify Connection**
   ```powershell
   flutter devices
   ```
   - Your device should appear

---

## ⚡ STEP 5: Run the App

```powershell
flutter run
```

First build takes 5-10 minutes. Be patient!

---

## 🎯 QUICK TEST

Once app launches:

1. Tap "Register"
2. Create account (use any email)
3. Tap "Add Guardian"
4. Add a test contact
5. Tap "SOS Emergency"
6. Test SOS flow

---

## ⚠️ COMMON ERRORS & FIXES

### "google-services.json not found"
**Fix**: Place file in `android/app/google-services.json`

### "FirebaseApp not initialized"  
**Fix**: 
```powershell
flutter clean
flutter pub get
flutter run
```

### "No devices found"
**Fix**: 
- Enable USB debugging
- Reconnect phone
- Accept debugging prompt

### "Gradle build failed"
**Fix**:
```powershell
cd android
./gradlew clean
cd ..
flutter run
```

---

## 📞 NEED HELP?

1. Read `START_HERE.md` - Beginner guide
2. Read `SETUP_GUIDE.md` - Detailed setup
3. Check `CHECKLIST.md` - Step by step
4. Read `QUICK_REFERENCE.md` - Troubleshooting

---

## ✅ READY CHECKLIST

Before considering setup complete:

- [ ] Flutter installed and working (`flutter doctor` passes)
- [ ] Dependencies installed (`flutter pub get` successful)
- [ ] Firebase project created
- [ ] `google-services.json` in correct location
- [ ] Authentication enabled in Firebase
- [ ] Firestore database created
- [ ] Android device connected
- [ ] App builds and runs
- [ ] Can register account
- [ ] Can add guardian

---

## 🎉 AFTER SETUP

Once everything works:

1. **Customize**:
   - Change colors in `lib/app.dart`
   - Add alarm sound to `assets/sounds/alarm.mp3`
   - Update app name in `android/app/src/main/res/values/strings.xml`

2. **Test Widget**:
   - Long press home screen
   - Add "Women Safety" widget
   - Test SOS button on widget

3. **Build Release**:
   - Follow Phase 7 in `SETUP_GUIDE.md`
   - Create keystore
   - Build signed APK

---

## 🚀 TIME ESTIMATES

- **Environment Setup**: 30 minutes
- **Firebase Setup**: 15 minutes
- **First Build**: 10 minutes
- **Testing**: 15 minutes
- **Total**: ~70 minutes

---

## 💡 PRO TIPS

1. **Keep PowerShell open** - Faster to run commands
2. **Use `flutter hot reload`** - Press 'r' while app is running
3. **Check logs** - Run `flutter logs` in another terminal
4. **Clean regularly** - `flutter clean` fixes many issues
5. **Backup keystore** - Keep your .jks file safe!

---

## 🎯 CRITICAL FILES TO CHECK

Before running, ensure these exist:

```
✓ pubspec.yaml
✓ lib/main.dart
✓ android/app/src/main/AndroidManifest.xml
✓ android/app/build.gradle
✓ android/build.gradle
✗ android/app/google-services.json  (YOU MUST ADD THIS!)
```

---

## 📱 MINIMUM REQUIREMENTS

- **OS**: Windows 10/11
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space
- **Phone**: Android 5.0+ (API 21+)
- **Internet**: Required for setup

---

## ⏰ QUICK START (5 Minutes)

If Flutter is already installed:

1. Open PowerShell in project folder
2. Run: `flutter pub get`
3. Add `google-services.json` to `android/app/`
4. Connect phone
5. Run: `flutter run`

Done! ✅

---

## 🔥 FIREBASE QUICK SETUP

Can't figure out Firebase? Here's the absolute minimum:

1. https://console.firebase.google.com/ → Add Project
2. Skip Analytics
3. Click Android icon
4. Package: `com.example.women_safety_app`
5. Download JSON file
6. Put in `android/app/google-services.json`
7. Authentication → Get Started → Enable Email/Password
8. Firestore → Create Database → Test Mode → Enable

That's it! App will work.

---

## 🎊 YOU'RE READY!

If you've completed the steps above, run:

```powershell
flutter run
```

And watch your Women Safety App come to life! 🚀

---

**Need more help?** Read the detailed guides:
- `START_HERE.md` - First-time setup
- `SETUP_GUIDE.md` - Complete walkthrough  
- `CHECKLIST.md` - Step-by-step checklist
- `README.md` - Full documentation

**Still stuck?** Check the troubleshooting sections in any guide.

**Ready to deploy?** Follow Phase 7 in SETUP_GUIDE.md

---

**Last Updated**: January 2026
**Status**: Production Ready ✅
**Your Mission**: Make women safer! 💪
