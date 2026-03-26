param(
    [string]$DeviceId = "",
    [string]$PackageName = "com.womensafety.app",
    [string]$LogTag = "SOS_APP"
)

$ErrorActionPreference = 'Stop'

Write-Host "[1/6] Checking ADB..." -ForegroundColor Cyan
adb version | Out-Null

Write-Host "[2/6] Detecting device..." -ForegroundColor Cyan
if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    $devices = adb devices | Select-String "\tdevice$"
    if (-not $devices) { throw "No authorized Android device found." }
    $DeviceId = ($devices[0].ToString().Split("`t"))[0]
}
Write-Host "Using device: $DeviceId" -ForegroundColor Green

Write-Host "[3/6] Running app on real device..." -ForegroundColor Cyan
flutter run -d $DeviceId --debug

Write-Host "[4/6] Capturing logs (Ctrl+C to stop)..." -ForegroundColor Cyan
adb -s $DeviceId logcat | Select-String -Pattern "$LogTag|SOS|Location|Notification|I/flutter"

Write-Host "[5/6] Optional: Trigger tap at screen center" -ForegroundColor Cyan
$size = adb -s $DeviceId shell wm size
if ($size -match '(\d+)x(\d+)') {
    $x = [int]$Matches[1] / 2
    $y = [int]$Matches[2] / 2
    adb -s $DeviceId shell input tap $x $y
}

Write-Host "[6/6] Done" -ForegroundColor Green
