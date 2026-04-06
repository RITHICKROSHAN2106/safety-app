# Gemini setup helper for the Women Safety app.
# Run from the women_safety folder in PowerShell.

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Women Safety App - Gemini Setup Assistant" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$geminiKey = Read-Host "Paste your Gemini API key"
if ([string]::IsNullOrWhiteSpace($geminiKey)) {
    Write-Host "No Gemini API key provided. Exiting." -ForegroundColor Red
    exit 1
}

$backendSecret = Read-Host "Enter a backend secret to protect /api/v1/ai/chat"
if ([string]::IsNullOrWhiteSpace($backendSecret)) {
    $backendSecret = [Guid]::NewGuid().ToString("N")
    Write-Host "Generated backend secret: $backendSecret" -ForegroundColor Yellow
}

$backendUrl = Read-Host "Backend URL" 
if ([string]::IsNullOrWhiteSpace($backendUrl)) {
    $backendUrl = "http://localhost:8080"
}

Write-Host ""
Write-Host "Saving environment variables for the current process..." -ForegroundColor Cyan
$env:GEMINI_API_KEY = $geminiKey
$env:BACKEND_API_KEY = $backendSecret
$env:BACKEND_URL = $backendUrl
$env:GEMINI_MODEL = "gemini-2.0-flash"
$env:FEATURE_GEMINI_ASSISTANT = "true"

Write-Host ""
$savePersistently = Read-Host "Save these variables permanently for future terminals? (y/n)"
if ($savePersistently -match '^[Yy]') {
    setx GEMINI_API_KEY $geminiKey | Out-Null
    setx BACKEND_API_KEY $backendSecret | Out-Null
    setx BACKEND_URL $backendUrl | Out-Null
    setx GEMINI_MODEL "gemini-2.0-flash" | Out-Null
    setx FEATURE_GEMINI_ASSISTANT "true" | Out-Null
    Write-Host "Environment variables saved with setx." -ForegroundColor Green
    Write-Host "Open a new PowerShell window for them to take effect." -ForegroundColor Yellow
} else {
    Write-Host "Environment variables set only for this PowerShell session." -ForegroundColor Yellow
}

Write-Host ""
$runFlutter = Read-Host "Run Flutter with these values now? (y/n)"
if ($runFlutter -match '^[Yy]') {
    flutter run --dart-define=BACKEND_URL=$backendUrl --dart-define=BACKEND_API_KEY=$backendSecret --dart-define=FEATURE_GEMINI_ASSISTANT=true
} else {
    Write-Host ""
    Write-Host "Use this Flutter command later:" -ForegroundColor Cyan
    Write-Host "flutter run --dart-define=BACKEND_URL=$backendUrl --dart-define=BACKEND_API_KEY=$backendSecret --dart-define=FEATURE_GEMINI_ASSISTANT=true" -ForegroundColor White
}