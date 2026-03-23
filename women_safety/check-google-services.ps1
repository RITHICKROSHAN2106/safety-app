# Google Services JSON Checker
# Run this AFTER placing google-services.json file

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Google Services Configuration Checker" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$filePath = "android\app\google-services.json"
$expectedPackage = "com.example.women_safety"

# Check if file exists
if (Test-Path $filePath) {
    Write-Host "✅ google-services.json found!" -ForegroundColor Green
    Write-Host "   Location: $filePath" -ForegroundColor Gray
    Write-Host ""
    
    # Read and parse JSON
    try {
        $content = Get-Content $filePath -Raw | ConvertFrom-Json
        
        # Check project ID
        $projectId = $content.project_info.project_number
        Write-Host "📋 Project Info:" -ForegroundColor Yellow
        Write-Host "   Project Number: $projectId" -ForegroundColor White
        
        # Check package name
        $packageName = $content.client[0].client_info.android_client_info.package_name
        Write-Host "   Package Name: $packageName" -ForegroundColor White
        Write-Host ""
        
        # Verify package name
        if ($packageName -eq $expectedPackage) {
            Write-Host "✅ Package name is CORRECT!" -ForegroundColor Green
            Write-Host "   Expected: $expectedPackage" -ForegroundColor Gray
            Write-Host "   Found: $packageName" -ForegroundColor Gray
        } else {
            Write-Host "❌ Package name MISMATCH!" -ForegroundColor Red
            Write-Host "   Expected: $expectedPackage" -ForegroundColor Yellow
            Write-Host "   Found: $packageName" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "⚠️  This WILL cause build errors!" -ForegroundColor Red
            Write-Host "   Please recreate Android app in Firebase with correct package name" -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }
        
        # Check file size
        $fileSize = (Get-Item $filePath).Length
        Write-Host ""
        Write-Host "📦 File Info:" -ForegroundColor Yellow
        Write-Host "   Size: $fileSize bytes" -ForegroundColor White
        
        if ($fileSize -lt 500) {
            Write-Host "   ⚠️  File seems too small (might be corrupted)" -ForegroundColor Yellow
        } elseif ($fileSize -gt 10000) {
            Write-Host "   ⚠️  File seems too large (might be wrong file)" -ForegroundColor Yellow
        } else {
            Write-Host "   ✅ File size looks good!" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "❌ Error reading google-services.json!" -ForegroundColor Red
        Write-Host "   File might be corrupted or invalid JSON" -ForegroundColor Yellow
        Write-Host "   Error: $_" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
    
} else {
    Write-Host "❌ google-services.json NOT FOUND!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected location:" -ForegroundColor Yellow
    Write-Host "   $filePath" -ForegroundColor White
    Write-Host "   Full path: $PWD\$filePath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📥 How to get it:" -ForegroundColor Yellow
    Write-Host "   1. Go to https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "   2. Select your project" -ForegroundColor White
    Write-Host "   3. Click ⚙️ (Settings) → Project settings" -ForegroundColor White
    Write-Host "   4. Scroll to 'Your apps' → Android app" -ForegroundColor White
    Write-Host "   5. Download google-services.json" -ForegroundColor White
    Write-Host "   6. Place it at: android\app\google-services.json" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 See HOW_TO_GET_GOOGLE_SERVICES_JSON.md for detailed guide" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ✅ Configuration looks good!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Ready to build! Run these commands:" -ForegroundColor Green
Write-Host "   flutter clean" -ForegroundColor White
Write-Host "   flutter pub get" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor White
Write-Host ""

# Ask if user wants to build now
$build = Read-Host "Build and run now? (y/n)"
if ($build -eq "y" -or $build -eq "Y") {
    Write-Host ""
    Write-Host "Starting build..." -ForegroundColor Cyan
    Write-Host ""
    flutter clean
    flutter pub get
    flutter run
}
