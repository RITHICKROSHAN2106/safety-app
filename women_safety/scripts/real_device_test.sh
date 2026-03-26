#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${1:-}"
PACKAGE_NAME="${2:-com.womensafety.app}"
LOG_TAG="${3:-SOS_APP}"

echo "[1/6] Checking ADB..."
adb version >/dev/null

echo "[2/6] Detecting device..."
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID=$(adb devices | awk '/\tdevice$/{print $1; exit}')
fi
if [[ -z "$DEVICE_ID" ]]; then
  echo "No authorized Android device found." >&2
  exit 1
fi
echo "Using device: $DEVICE_ID"

echo "[3/6] Running app on real device..."
flutter run -d "$DEVICE_ID" --debug

echo "[4/6] Capturing logs (Ctrl+C to stop)..."
adb -s "$DEVICE_ID" logcat | grep -E "$LOG_TAG|SOS|Location|Notification|I/flutter"

echo "[5/6] Optional center tap"
SIZE=$(adb -s "$DEVICE_ID" shell wm size | grep -oE '[0-9]+x[0-9]+' | head -1 || true)
if [[ -n "$SIZE" ]]; then
  W=${SIZE%x*}
  H=${SIZE#*x}
  X=$((W/2))
  Y=$((H/2))
  adb -s "$DEVICE_ID" shell input tap "$X" "$Y"
fi

echo "[6/6] Done"
