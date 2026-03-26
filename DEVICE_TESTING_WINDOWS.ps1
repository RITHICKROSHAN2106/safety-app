################################################################################
# WOMEN SAFETY APP - DEVICE TESTING GUIDE FOR WINDOWS
# Step-by-step commands for testing on Android device via USB debugging
# 
# Run this in PowerShell (Windows Terminal)
# Author: Testing Team
# Last Updated: March 25, 2026
################################################################################

# ============================================================================
# PART 1: SETUP AND VERIFICATION
# ============================================================================

Write-Host "Step 1: Verifying ADB Installation" -ForegroundColor Cyan
adb --version

Write-Host "`nStep 2: Listing Connected Devices" -ForegroundColor Cyan
adb devices -l

Write-Host "`nStep 3: Getting Device Details" -ForegroundColor Cyan
$DEVICE_ID = (adb devices | Select-Object -Index 1).Split()[0]
Write-Host "Using device: $DEVICE_ID"

# Get device info
Write-Host "`nDevice Information:" -ForegroundColor Yellow
$model = adb -s $DEVICE_ID shell getprop ro.product.model
$android = adb -s $DEVICE_ID shell getprop ro.build.version.release
$api = adb -s $DEVICE_ID shell getprop ro.build.version.sdk

Write-Host "  Model: $model"
Write-Host "  Android Version: $android"
Write-Host "  API Level: $api"

# ============================================================================
# PART 2: BUILD AND INSTALL APP
# ============================================================================

Write-Host "`nStep 4: Building Flutter App" -ForegroundColor Cyan
Set-Location women_safety
flutter build apk --release

Write-Host "`nStep 5: Installing APK on Device" -ForegroundColor Cyan
$APK_PATH = "build/app/outputs/flutter-apk/app-release.apk"
if (Test-Path $APK_PATH) {
    adb -s $DEVICE_ID install -r $APK_PATH
    Write-Host "✅ App installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ APK not found at $APK_PATH" -ForegroundColor Red
}

# ============================================================================
# PART 3: LAUNCH APP AND CAPTURE LOGS
# ============================================================================

Write-Host "`nStep 6: Launching App on Device" -ForegroundColor Cyan

# Clear existing logs
adb -s $DEVICE_ID logcat -c

# Launch app
$APP_PACKAGE = "com.womensafety.app"  # Update to your actual package name
adb -s $DEVICE_ID shell am start -n "$APP_PACKAGE/.MainActivity"

Write-Host "✅ App launched" -ForegroundColor Green

# Create logs directory
$LOG_DIR = "logs"
if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR | Out-Null
}

# Start capturing logs in background PowerShell job
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logfile = "$LOG_DIR/device_test_$timestamp.log"

Write-Host "`nStep 7: Capturing Logs to: $logfile" -ForegroundColor Cyan

# Start background job to capture logs
$scriptBlock = {
    param($device, $file)
    adb -s $device logcat | Tee-Object -FilePath $file
}

$job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $DEVICE_ID, $logfile
Write-Host "Logging in background (Job: $($job.Id))" -ForegroundColor Green

Start-Sleep -Seconds 3

# ============================================================================
# PART 4: MANUAL TESTING INSTRUCTIONS
# ============================================================================

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         MANUAL TESTING - PERFORM THESE STEPS              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host @"

TEST SCENARIO 1: SOS TRIGGER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. On your device, verify app is open
2. Tap the large red SOS button
3. Watch for:
   ✓ Red pulsing SOS indicator
   ✓ Emergency contacts list showing
   ✓ Location permission prompt (tap Allow)
   ✓ Audio recording starting (you'll hear a beep)
   ✓ Camera might flash (capturing evidence photo)

Expected: SOS becomes "ACTIVE" on screen
Expected log: [🚨 SOS] PANIC TRIGGERED FROM BUTTON

TEST SCENARIO 2: EMERGENCY CONTACTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. On device, go to "Guardians" or "Contacts" section
2. Add emergency contact:
   Name: John Doe
   Phone: +919123456789
   Email: john@example.com
3. Verify contact saves
4. Go back to home screen
5. Tap SOS button again
6. Verify "John Doe" appears in emergency contacts list

Expected log: [📲 NOTIFICATION] SMS sent to +919123456789

TEST SCENARIO 3: LOCATION TRACKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Keep SOS active
2. Move device around your house
3. Check logs for location updates
4. On device, tap any message with location link
5. Should open Google Maps with your location

Expected log: [📍 LOCATION] Location update received: lat: 12.xxxx, lng: 77.xxxx

TEST SCENARIO 4: CANCEL SOS
━━━━━━━━━━━━━━━━━━━━━━━━━━

1. SOS should still be active
2. Tap the "Cancel SOS" button (red button on screen)
3. Confirm cancellation when prompted
4. SOS status changes to inactive

Expected log: [✅ SUCCESS] SOS cancelled

TEST SCENARIO 5: OFFLINE MODE (Optional)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Enable Airplane Mode on device (Settings)
2. Trigger SOS button
3. Observe: SOS still works and sounds
4. Observe: Messages show "Queued" status
5. Disable Airplane Mode
6. SOS messages should send automatically

Expected log: [📤 QUEUE] SOS queued for later sending

"@

# ============================================================================
# PART 5: AUTOMATED LOG FILTERING
# ============================================================================

Write-Host "`nStep 8: Setting Up Log Filtering" -ForegroundColor Cyan
Write-Host "Press Enter to continue with log capture, then come back and run the filtering commands below..." -ForegroundColor Yellow
Read-Host

# Stop background job
Stop-Job -Id $job.Id
Wait-Job -Id $job.Id

# Analyze logs
Write-Host "`nStep 9: Analyzing Logs" -ForegroundColor Cyan

if (Test-Path $logfile) {
    Write-Host "`n📊 LOG ANALYSIS RESULTS:" -ForegroundColor Green
    Write-Host "════════════════════════════════" -ForegroundColor Green
    
    Write-Host "`n🚨 SOS Triggers Found:" -ForegroundColor Red
    Select-String -Path $logfile -Pattern "SOS.*trigger|PANIC" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.Line }
    
    Write-Host "`n📍 Location Updates Found:" -ForegroundColor Blue
    Select-String -Path $logfile -Pattern "Location|coordinate|📍" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.Line }
    
    Write-Host "`n📲 Notification Sends Found:" -ForegroundColor Cyan
    Select-String -Path $logfile -Pattern "notification|SMS|Email|📲" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.Line }
    
    Write-Host "`n❌ Errors Found:" -ForegroundColor Red
    Select-String -Path $logfile -Pattern "error|exception|❌|ERROR" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.Line }
    
    if ((Select-String -Path $logfile -Pattern "error|exception" -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Write-Host "  ✅ No errors found - great!" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Log file not found" -ForegroundColor Red
}

# ============================================================================
# PART 6: REAL-TIME LOG VIEWING
# ============================================================================

Write-Host "`n`nStep 10: Real-Time Log Filtering (LIVE)" -ForegroundColor Cyan
Write-Host "Choose what to monitor:" -ForegroundColor Yellow
Write-Host "1. SOS Events (default)"
Write-Host "2. Location Updates"
Write-Host "3. Notifications"
Write-Host "4. All Logs"
Write-Host "5. Errors Only"

$choice = Read-Host "Enter choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host "Monitoring SOS events... (Press Ctrl+C to stop)" -ForegroundColor Cyan
        adb -s $DEVICE_ID logcat | Select-String -Pattern "SOS|PANIC|🚨"
    }
    "2" {
        Write-Host "Monitoring location updates... (Press Ctrl+C to stop)" -ForegroundColor Cyan
        adb -s $DEVICE_ID logcat | Select-String -Pattern "Location|📍|coordinate"
    }
    "3" {
        Write-Host "Monitoring notifications... (Press Ctrl+C to stop)" -ForegroundColor Cyan
        adb -s $DEVICE_ID logcat | Select-String -Pattern "notification|SMS|📲|email"
    }
    "4" {
        Write-Host "Showing all logs... (Press Ctrl+C to stop)" -ForegroundColor Cyan
        adb -s $DEVICE_ID logcat
    }
    "5" {
        Write-Host "Monitoring errors... (Press Ctrl+C to stop)" -ForegroundColor Cyan
        adb -s $DEVICE_ID logcat | Select-String -Pattern "error|ERROR|exception|❌"
    }
    default {
        adb -s $DEVICE_ID logcat | Select-String -Pattern "SOS|PANIC|🚨"
    }
}

# ============================================================================
# PART 7: ADDITIONAL DEBUG COMMANDS
# ============================================================================

function Show-DebugMenu {
    Write-Host "`n`nStep 11: Additional Debug Tools" -ForegroundColor Cyan
    Write-Host "Choose an option:" -ForegroundColor Yellow
    Write-Host "1. Check App Version"
    Write-Host "2. Clear App Data"
    Write-Host "3. View App Files on Device"
    Write-Host "4. Force Stop App"
    Write-Host "5. Check Device Battery"
    Write-Host "6. Monitor Memory Usage"
    Write-Host "7. Export Logs to File"
    Write-Host "8. Exit"
    
    $choice = Read-Host "Enter choice (1-8)"
    
    switch ($choice) {
        "1" {
            Write-Host "`n📱 App Version:" -ForegroundColor Cyan
            adb -s $DEVICE_ID shell dumpsys package $APP_PACKAGE | Select-String "versionName"
        }
        "2" {
            Write-Host "`n🗑️ Clearing app data..." -ForegroundColor Yellow
            adb -s $DEVICE_ID shell pm clear $APP_PACKAGE
            Write-Host "✅ App data cleared" -ForegroundColor Green
        }
        "3" {
            Write-Host "`n📂 App Files on Device:" -ForegroundColor Cyan
            adb -s $DEVICE_ID shell ls -la /data/data/$APP_PACKAGE/files/
        }
        "4" {
            Write-Host "`n⛔ Force stopping app..." -ForegroundColor Yellow
            adb -s $DEVICE_ID shell am force-stop $APP_PACKAGE
            Write-Host "✅ App stopped" -ForegroundColor Green
        }
        "5" {
            Write-Host "`n🔋 Battery Status:" -ForegroundColor Cyan
            adb -s $DEVICE_ID shell dumpsys battery | Select-String "level|status|temperature"
        }
        "6" {
            Write-Host "`n💾 Memory Usage:" -ForegroundColor Cyan
            adb -s $DEVICE_ID shell dumpsys meminfo $APP_PACKAGE | Select-String "TOTAL"
        }
        "7" {
            $export_file = "$LOG_DIR/full_device_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            Write-Host "`n💾 Exporting logs..." -ForegroundColor Yellow
            adb -s $DEVICE_ID logcat -d > $export_file
            Write-Host "✅ Logs exported to: $export_file" -ForegroundColor Green
        }
        "8" {
            Write-Host "`nGoodbye!" -ForegroundColor Green
            return
        }
    }
    
    Show-DebugMenu  # Show menu again
}

# Uncomment to show interactive menu
# Show-DebugMenu

# ============================================================================
# PART 8: PANIC WIDGET TESTING (Optional)
# ============================================================================

function Test-PanicWidget {
    Write-Host "`n`nStep 12: Testing Panic Widget" -ForegroundColor Cyan
    Write-Host @"

PANIC WIDGET TEST PROCEDURE
═════════════════════════════

1. On your device, go to Home Screen
2. Press and hold on empty area → Add widget
3. Search for "Women Safety" or "Panic"
4. Add the panic button widget to home screen
5. With app CLOSED, tap the panic widget button
6. App should launch and trigger SOS immediately
7. Check logs for: [🚨 PANIC TRIGGERED FROM WIDGET]

Expected: SOS triggers without showing login screen

"@
    
    Read-Host "Press Enter after adding widget and testing..."
    
    Write-Host "Checking logs for widget trigger..." -ForegroundColor Cyan
    adb -s $DEVICE_ID logcat -d | Select-String -Pattern "WIDGET|widget_trigger|panic.*widget"
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

Write-Host "`n`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              TESTING COMPLETE!                            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host @"

✅ NEXT STEPS:
━━━━━━━━━━━━━━━

1. Review the log file: $logfile
   
   Example commands to view logs:
   
   # View in PowerShell
   Get-Content $logfile | Select-String "SOS"
   Get-Content $logfile | Select-String "ERROR"
   
   # View entire file
   Invoke-Item $logfile

2. Check device for any issues:
   - SOS button responsive?
   - Location updating on map?
   - Notifications arriving?
   - No errors in logs?

3. If tests pass, run the full test suite:
   
   # Flutter tests
   flutter test
   
   # Backend tests
   cd ..\backend
   mvn test

4. View code coverage:
   
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/HTML
   Invoke-Item coverage/HTML/index.html

5. Commit test results:
   
   git add $logfile
   git commit -m "Add device testing results"
   git push

📋 LOGS LOCATION: $LOG_DIR\
📊 CURRENT TEST LOG: $logfile

🧪 For issues, check the COMPREHENSIVE_TESTING_GUIDE.md for troubleshooting

Questions or issues? Check Slack #testing-issues or email qa@womensafety.com
"@

Write-Host "`nTest script completed! Device is still connected and ready for more tests." -ForegroundColor Green
