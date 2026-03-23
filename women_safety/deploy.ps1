# 🚀 Quick Deploy to Real Device - Women Safety App

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Women Safety App - Real Device Test" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Check Flutter installed
if (-not (Test-Command flutter)) {
    Write-Host "❌ Flutter not found! Please install Flutter SDK first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter detected" -ForegroundColor Green
flutter --version

Write-Host ""
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "  Step 1: Checking Firebase Config" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

# Check for google-services.json
$androidConfig = "android\app\google-services.json"
if (Test-Path $androidConfig) {
    Write-Host "✅ Android Firebase config found: $androidConfig" -ForegroundColor Green
} else {
    Write-Host "⚠️  Android Firebase config NOT found: $androidConfig" -ForegroundColor Yellow
    Write-Host "   Please add google-services.json from Firebase Console" -ForegroundColor Yellow
    Write-Host "   App will still run but Firebase features won't work" -ForegroundColor Yellow
}

# Check for GoogleService-Info.plist
$iosConfig = "ios\Runner\GoogleService-Info.plist"
if (Test-Path $iosConfig) {
    Write-Host "✅ iOS Firebase config found: $iosConfig" -ForegroundColor Green
} else {
    Write-Host "⚠️  iOS Firebase config NOT found: $iosConfig" -ForegroundColor Yellow
    Write-Host "   Required for iOS deployment" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "  Step 2: Checking Map Config" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "🗺️  Using OpenStreetMap tiles via flutter_map (no API key required)." -ForegroundColor Cyan
Write-Host "   Set MAP_TILE_URL / MAP_ATTRIBUTION env vars to override the defaults." -ForegroundColor Gray

Write-Host ""
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "  Step 3: Cleaning Build" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "🧹 Running flutter clean..." -ForegroundColor Cyan
flutter clean

Write-Host ""
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "  Step 4: Getting Dependencies" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "📦 Running flutter pub get..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "  Step 5: Checking Connected Devices" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

Write-Host "🔍 Detecting devices..." -ForegroundColor Cyan
flutter devices

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Ready to Deploy!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Ask user which mode to deploy
Write-Host "Choose deployment mode:" -ForegroundColor Yellow
Write-Host "  1. Debug mode (fast, with hot reload)" -ForegroundColor White
Write-Host "  2. Release mode (optimized, production-ready)" -ForegroundColor White
Write-Host "  3. Profile mode (performance testing)" -ForegroundColor White
Write-Host "  4. Exit" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Enter choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🚀 Launching in DEBUG mode..." -ForegroundColor Green
        Write-Host "   Features: Hot reload, DevTools, Debug logs" -ForegroundColor Gray
        Write-Host ""
        flutter run
    }
    "2" {
        Write-Host ""
        Write-Host "🚀 Launching in RELEASE mode..." -ForegroundColor Green
        Write-Host "   Features: Optimized performance, smaller size" -ForegroundColor Gray
        Write-Host ""
        flutter run --release
    }
    "3" {
        Write-Host ""
        Write-Host "🚀 Launching in PROFILE mode..." -ForegroundColor Green
        Write-Host "   Features: Performance profiling enabled" -ForegroundColor Gray
        Write-Host ""
        flutter run --profile
    }
    "4" {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "❌ Invalid choice. Exiting." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 App should now be running on your device" -ForegroundColor Green
Write-Host "📋 Check console above for any errors" -ForegroundColor Yellow
Write-Host "📚 See REAL_DEVICE_TESTING_GUIDE.md for testing checklist" -ForegroundColor Yellow
Write-Host ""
Write-Host "Happy Testing! 🎉" -ForegroundColor Cyan
