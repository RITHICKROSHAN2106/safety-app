# 🚀 FIRST TIME SETUP - START HERE

Welcome to the Women Safety App! Follow these simple steps to get started.

## ⚡ QUICK START (5 Minutes)

### Step 1: Check Flutter Installation
Open PowerShell in this folder and run:
```powershell
flutter doctor
```

If you see checkmarks ✓ for Flutter and Android toolchain, you're ready!

If not, install Flutter from: https://flutter.dev/docs/get-started/install/windows

### Step 2: Install Dependencies
```powershell
flutter pub get
```
This downloads all required packages. Takes 1-2 minutes.

### Step 3: Connect Your Android Phone
1. Enable Developer Options:
   - Settings → About Phone
   - Tap "Build Number" 7 times
   
2. Enable USB Debugging:
   - Settings → Developer Options
   - Turn on "USB Debugging"

3. Connect phone to computer via USB

4. Verify connection:
```powershell
flutter devices
```
You should see your device listed!

### Step 4: Run the App
```powershell
flutter run
```

The app will install and launch on your phone! 🎉

**Note**: First run takes 5-10 minutes to compile. Subsequent runs are faster.

---

## 🔥 IMPORTANT: Firebase Setup Required

The app will crash without Firebase! Here's the minimal setup:

### 1. Create Firebase Project (10 minutes)
1. Go to https://console.firebase.google.com/
2. Click "Add Project"
3. Name it "Women Safety App"
4. Click through the setup

### 2. Add Android App
1. Click Android icon
2. Package name: `com.example.women_safety_app`
3. Download `google-services.json`
4. Place it here:
   ```
   android/app/google-services.json
   ```

### 3. Enable Services
In Firebase Console:
- Go to Authentication → Get Started → Enable Email/Password
- Go to Firestore Database → Create Database → Start in Test Mode

### 4. Rebuild and Run
```powershell
flutter clean
flutter pub get
flutter run
```

Now the app will work properly! ✅

---

## 📱 WHAT TO EXPECT

### On First Launch:
1. Splash screen appears (2 seconds)
2. Login screen shows
3. Tap "Register" to create account
4. Fill in your details
5. Login with credentials
6. You're in! 🎉

### Test the Features:
1. **Add Guardian**:
   - Home → Guardians → Add Guardian
   - Enter friend's details
   - Mark as primary

2. **Test SOS**:
   - Home → SOS Emergency
   - Tap SOS button 3 times
   - Countdown starts
   - Alert sent! (to guardians)

3. **Add Widget**:
   - Long press home screen
   - Widgets → Women Safety
   - Drag to home screen
   - Instant SOS access!

---

## 🎯 NEXT STEPS

After basic setup works:

1. **Read Full Documentation**:
   - `README.md` - Complete overview
   - `SETUP_GUIDE.md` - Detailed setup
   - `QUICK_REFERENCE.md` - Commands & tips

2. **Customize**:
   - Change colors in `lib/app.dart`
   - Add alarm sound to `assets/sounds/alarm.mp3`
   - Replace app icon

3. **Test Everything**:
   - SOS flow
   - Location sharing
   - Guardian alerts
   - Widget functionality

4. **Build Release**:
   - See `SETUP_GUIDE.md` Phase 7
   - Create signed APK
   - Deploy to Play Store

---

## 🐛 TROUBLESHOOTING

### "Firebase not initialized"
**Fix**: Add google-services.json to `android/app/`

### "Location permission denied"
**Fix**: Grant location permission in app settings

### "Widget not showing"
**Fix**: Uninstall app, reinstall, rebuild widget

### "Build failed"
**Fix**: Run these commands:
```powershell
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### "Package not found"
**Fix**: Check package name matches in:
- AndroidManifest.xml
- build.gradle
- Firebase Console

---

## 💡 PRO TIPS

1. **Development**: Use `flutter run` for hot reload
2. **Testing**: Use real device, not emulator for location
3. **Widget**: Refresh by rebuilding app after data changes
4. **Logs**: Use `flutter logs` to see debug output
5. **Clean Build**: Run `flutter clean` before release build

---

## 📞 HELP & SUPPORT

### If you're stuck:

1. **Check Docs**:
   - README.md
   - SETUP_GUIDE.md
   - QUICK_REFERENCE.md

2. **Common Issues**:
   - All documented in SETUP_GUIDE.md
   - Solutions provided

3. **Flutter Issues**:
   - Run `flutter doctor`
   - Fix any issues shown

4. **Android Issues**:
   - Clean build folder
   - Sync Gradle
   - Rebuild project

---

## ✅ VERIFICATION CHECKLIST

Before considering setup complete:

- [ ] `flutter doctor` shows all green checkmarks
- [ ] `flutter pub get` completes successfully
- [ ] Device shows in `flutter devices`
- [ ] `google-services.json` is in place
- [ ] App launches without errors
- [ ] Can register new account
- [ ] Can login successfully
- [ ] Can add guardian
- [ ] Can trigger SOS
- [ ] Widget appears on home screen
- [ ] Widget button works

---

## 🎉 SUCCESS!

If all items above are checked, your app is ready!

You now have a fully functional Women Safety App with:
- 🚨 Emergency SOS system
- 📍 Real-time location sharing
- 👥 Guardian management
- 📱 Android home widget
- 🤖 AI-powered features
- 🔔 Push notifications

---

## 🚀 READY TO DEPLOY?

When you're ready for production:

1. Follow SETUP_GUIDE.md Phase 7
2. Generate signing key
3. Build release APK
4. Test on multiple devices
5. Submit to Play Store

**Estimated time to production**: 1-2 hours (after setup)

---

## 📚 LEARNING RESOURCES

Want to understand the code better?

- **Flutter**: https://flutter.dev/docs
- **Firebase**: https://firebase.google.com/docs
- **BLoC Pattern**: https://bloclibrary.dev
- **Material Design**: https://material.io/design

---

## 🏁 YOU'RE ALL SET!

The app is production-ready and fully functional.

**Questions?** Check the documentation files.

**Ready to build something amazing?** Go for it! 💪

---

**Remember**: This is a final-year/production-grade application. Take your time to understand each component. Every file is well-commented and documented.

**Good luck with your project!** 🎓✨
