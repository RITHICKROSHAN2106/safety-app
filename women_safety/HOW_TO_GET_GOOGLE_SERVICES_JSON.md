# 📥 Download google-services.json - Step by Step

## Visual Guide

### Step 1: Open Firebase Console
```
URL: https://console.firebase.google.com/
→ Sign in with Google account
→ Select "womensafety" project
```

### Step 2: Go to Project Settings
```
Look at top-left corner:
[Firebase logo] [Project Overview ▼]

Click the ⚙️ (gear/settings icon) next to "Project Overview"
→ Click "Project settings"
```

### Step 3: Find Your Apps Section
```
Scroll down to "Your apps" section
You'll see: "Firebase SDK snippet"

Look for Android icon 🤖
```

### Step 4A: If Android App Exists
```
✅ You'll see your app listed
→ Scroll down in that app card
→ Find "google-services.json"
→ Click "Download google-services.json" button
→ Save the file
```

### Step 4B: If No Android App Yet
```
❌ No apps shown
→ Click "Add app" button
→ Click Android icon 🤖

Fill the form:
┌─────────────────────────────────────────┐
│ Android package name (required)         │
│ com.example.women_safety                │ ← MUST BE EXACT!
├─────────────────────────────────────────┤
│ App nickname (optional)                 │
│ Women Safety App                        │
├─────────────────────────────────────────┤
│ Debug signing certificate SHA-1         │
│ [Leave empty for now]                   │
└─────────────────────────────────────────┘

→ Click "Register app"
→ Click "Download google-services.json"
→ Save the file
→ Click "Next" → "Next" → "Continue to console"
```

### Step 5: Move the File
```
From: C:\Users\HRITIK\Downloads\google-services.json
To:   C:\Users\HRITIK\Desktop\womenSafety\women_safety\android\app\google-services.json

In File Explorer:
1. Open Downloads folder
2. Find google-services.json
3. Right-click → Cut (or Ctrl+X)
4. Navigate to: C:\Users\HRITIK\Desktop\womenSafety\women_safety\android\app\
5. Right-click → Paste (or Ctrl+V)
```

### Step 6: Verify File Location
```
Check this exact path exists:
women_safety/
  android/
    app/
      google-services.json  ← File MUST be here!
      build.gradle.kts
      src/
```

### Step 7: Verify File Content
```
Open the file (with Notepad or VS Code)
Check for these key parts:

{
  "project_info": {
    "project_id": "womensafety-40922",
    ...
  },
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "com.example.women_safety"  ← MUST MATCH!
        }
      }
    }
  ]
}
```

### Step 8: Rebuild App
```powershell
cd C:\Users\HRITIK\Desktop\womenSafety\women_safety
flutter clean
flutter pub get
flutter run
```

---

## ⚠️ Common Mistakes

### ❌ Wrong package name
```
File has: "package_name": "com.womensafety.app"
Should be: "package_name": "com.example.women_safety"
```
**Fix**: Delete Android app in Firebase, create new one with correct name

### ❌ Wrong file location
```
❌ android/google-services.json  (too high)
❌ android/app/src/google-services.json  (too deep)
✅ android/app/google-services.json  (CORRECT!)
```

### ❌ File not downloaded
```
Still in browser's download popup, not saved to disk
```
**Fix**: Actually click download and save the file

---

## 🔍 Troubleshooting

### "File google-services.json is missing"
→ File not in correct location
→ Check: `android\app\google-services.json` (not `android\google-services.json`)

### "Package name mismatch"
→ Firebase has different package than app
→ Must be: `com.example.women_safety` everywhere

### "No Firebase project"
→ Create new project at https://console.firebase.google.com/
→ Click "Add project"
→ Name: "Women Safety"

---

## 📍 Exact File Path Required

```
C:\Users\HRITIK\Desktop\womenSafety\women_safety\android\app\google-services.json
```

Not anywhere else! This is the ONLY correct location.

---

## ✅ Success Indicators

After placing file correctly:
- ✅ File exists at exact path above
- ✅ Package name matches: com.example.women_safety
- ✅ File size is ~1-3 KB (JSON text file)
- ✅ Can open and see JSON content

Then run:
```powershell
flutter clean
flutter pub get
flutter run
```

Should build successfully! 🎉

---

## 🆘 Still Stuck?

Run this command to verify:
```powershell
Test-Path "android\app\google-services.json"
```

Should return: `True`

If returns `False`, file is not there!
