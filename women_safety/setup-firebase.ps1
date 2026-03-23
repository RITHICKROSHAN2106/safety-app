# Quick Firebase Setup Script
# Run this after downloading google-services.json from Firebase Console

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Women Safety App - Firebase Setup Assistant" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if google-services.json exists
$googleServicesPath = "android\app\google-services.json"
if (Test-Path $googleServicesPath) {
    Write-Host "✅ google-services.json found!" -ForegroundColor Green
    
    # Read and verify package name
    $content = Get-Content $googleServicesPath -Raw | ConvertFrom-Json
    $packageName = $content.client[0].client_info.android_client_info.package_name
    
    if ($packageName -eq "com.example.women_safety") {
        Write-Host "✅ Package name matches: $packageName" -ForegroundColor Green
    } else {
        Write-Host "❌ Package name mismatch!" -ForegroundColor Red
        Write-Host "   Expected: com.example.women_safety" -ForegroundColor Yellow
        Write-Host "   Found: $packageName" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "⚠️  Please recreate Firebase Android app with correct package name!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ google-services.json NOT found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📋 Please follow these steps:" -ForegroundColor Yellow
    Write-Host "   1. Go to https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "   2. Select your project (or create new)" -ForegroundColor White
    Write-Host "   3. Add Android app with package: com.example.women_safety" -ForegroundColor White
    Write-Host "   4. Download google-services.json" -ForegroundColor White
    Write-Host "   5. Place it at: $googleServicesPath" -ForegroundColor White
    Write-Host "   6. Run this script again" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""

# Step 2: Map setup summary
Write-Host "🗺️  Maps are powered by OpenStreetMap tiles via flutter_map." -ForegroundColor Cyan
Write-Host "   No Google Maps API key required." -ForegroundColor Green
Write-Host "   Override defaults with MAP_TILE_URL / MAP_ATTRIBUTION env vars if needed." -ForegroundColor Gray

Write-Host ""

# Step 3: Firebase services checklist
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Firebase Console Checklist" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please verify in Firebase Console:" -ForegroundColor Yellow
Write-Host "  [ ] Authentication → Email/Password enabled" -ForegroundColor White
Write-Host "  [ ] Firestore Database → Created" -ForegroundColor White
Write-Host "  [ ] Firestore → Security rules set" -ForegroundColor White
Write-Host "  [ ] Storage → Enabled" -ForegroundColor White
Write-Host "  [ ] Storage → Security rules set" -ForegroundColor White
Write-Host "  [ ] Cloud Messaging → Enabled (auto)" -ForegroundColor White
Write-Host "  [ ] Test user created in Authentication" -ForegroundColor White
Write-Host "  [ ] User document created in Firestore" -ForegroundColor White
Write-Host "  [ ] Emergency contacts added to user" -ForegroundColor White
Write-Host ""

# Step 4: Ready to build
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Ready to Build!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run these commands to rebuild your app:" -ForegroundColor Green
Write-Host "  flutter clean" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor White
Write-Host ""

# Ask if user wants to build now
$build = Read-Host "Do you want to build and run now? (y/n)"
if ($build -eq "y" -or $build -eq "Y") {
    Write-Host ""
    Write-Host "Starting build..." -ForegroundColor Cyan
    flutter clean
    flutter pub get
    flutter run
} else {
    Write-Host ""
    Write-Host "✅ Setup verification complete!" -ForegroundColor Green
    Write-Host "   Run 'flutter run' when ready to build." -ForegroundColor White
    Write-Host ""
}
