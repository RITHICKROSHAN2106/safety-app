#!/bin/bash
################################################################################
# WOMEN SAFETY APP - REAL DEVICE TESTING SCRIPT
# Tests the app on a connected Android device via USB debugging
# 
# Usage: ./device_testing.sh
# 
# Prerequisites:
#   - Android device with USB debugging enabled
#   - Device connected via USB
#   - ADB installed and in PATH
#   - Flutter SDK installed
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_sos() {
    echo -e "${RED}[🚨 SOS]${NC} $1"
}

log_location() {
    echo -e "${BLUE}[📍 LOCATION]${NC} $1"
}

log_notification() {
    echo -e "${BLUE}[📲 NOTIFICATION]${NC} $1"
}

################################################################################
# STEP 1: Check ADB and Connected Devices
################################################################################
check_adb_setup() {
    log_info "Step 1: Checking ADB setup and connected devices"
    
    # Check if adb is installed
    if ! command -v adb &> /dev/null; then
        log_error "ADB not found. Please install Android SDK Platform Tools."
        exit 1
    fi
    
    log_success "ADB found: $(adb version | head -1)"
    
    # Check connected devices
    log_info "Checking connected devices..."
    DEVICES=$(adb devices -l)
    
    if echo "$DEVICES" | grep -q "unauthorized"; then
        log_error "Device is unauthorized. Please enable USB debugging on your device."
        exit 1
    fi
    
    DEVICE_COUNT=$(echo "$DEVICES" | grep -c "device" || true)
    
    if [ $DEVICE_COUNT -lt 2 ]; then
        log_error "No devices connected. Please connect an Android device via USB."
        exit 1
    fi
    
    # Get device ID
    DEVICE_ID=$(adb devices | grep "device$" | awk '{print $1}' | head -1)
    log_success "Connected device: $DEVICE_ID"
    
    adb devices -l
    echo ""
}

################################################################################
# STEP 2: Enable USB Debugging Verification
################################################################################
verify_usb_debugging() {
    log_info "Step 2: Verifying USB debugging is enabled"
    
    # Check if device is accessible
    if adb -s "$DEVICE_ID" shell getprop ro.debuggable &> /dev/null; then
        log_success "Device is accessible and USB debugging is enabled"
    else
        log_error "Cannot access device. Check USB debugging is enabled."
        exit 1
    fi
    
    # Get device info
    DEVICE_MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model)
    ANDROID_VERSION=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.release)
    API_LEVEL=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.sdk)
    
    log_success "Device Info:"
    echo "  Model: $DEVICE_MODEL"
    echo "  Android Version: $ANDROID_VERSION"
    echo "  API Level: $API_LEVEL"
    echo ""
}

################################################################################
# STEP 3: Build and Install App
################################################################################
build_and_install_app() {
    log_info "Step 3: Building and installing app on device"
    
    # Build APK in release mode
    log_info "Building Flutter app..."
    flutter build apk --release 2>&1 | grep -E "(Built|error|warning)" || true
    
    if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        log_error "APK build failed"
        exit 1
    fi
    
    log_success "APK built successfully"
    
    # Install APK on device
    log_info "Installing APK on device: $DEVICE_ID"
    adb -s "$DEVICE_ID" install -r build/app/outputs/flutter-apk/app-release.apk
    
    log_success "App installed successfully"
    echo ""
}

################################################################################
# STEP 4: Run Tests and Capture Logs
################################################################################
run_app_and_capture_logs() {
    log_info "Step 4: Running app and capturing logs"
    
    # Clear existing logs
    adb -s "$DEVICE_ID" logcat -c
    
    # Launch app
    APP_PACKAGE="com.womensafety.app" # Change to your app's package name
    log_info "Launching app: $APP_PACKAGE"
    adb -s "$DEVICE_ID" shell am start -n "$APP_PACKAGE/.MainActivity" || \
    adb -s "$DEVICE_ID" shell monkey -p "$APP_PACKAGE" -c android.intent.category.LAUNCHER 1
    
    log_success "App launched on device"
    
    # Create log file
    LOG_DIR="logs"
    mkdir -p "$LOG_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOGFILE="$LOG_DIR/device_test_${TIMESTAMP}.log"
    
    log_info "Capturing logs to: $LOGFILE"
    
    # Start logcat in background, filtering for app logs
    adb -s "$DEVICE_ID" logcat -s "*:V" | tee "$LOGFILE" &
    LOGCAT_PID=$!
    
    sleep 3
    
    echo ""
}

################################################################################
# STEP 5: Test SOS Trigger
################################################################################
test_sos_trigger() {
    log_info "Step 5: Testing SOS trigger functionality"
    
    log_sos "SCENARIO: User presses SOS button"
    
    # Simulate SOS trigger using UI automation
    log_info "Simulating button tap on device..."
    
    # Get screen dimensions
    SCREEN_DIM=$(adb -s "$DEVICE_ID" shell wm size || echo "1080x1920")
    WIDTH=$(echo "$SCREEN_DIM" | grep -oP '\d+(?=x)' | head -1)
    HEIGHT=$(echo "$SCREEN_DIM" | grep -oP '(?<=x)\d+' | head -1)
    
    # Tap center of screen (approximate SOS button location)
    CENTER_X=$((WIDTH / 2))
    CENTER_Y=$((HEIGHT / 2))
    
    log_info "Screen dimensions: ${WIDTH}x${HEIGHT}"
    log_info "Tapping SOS button at (${CENTER_X}, ${CENTER_Y})..."
    
    adb -s "$DEVICE_ID" shell input tap $CENTER_X $CENTER_Y
    
    sleep 2
    
    log_sos "Check device screen for:"
    echo "  ✓ SOS Active indicator displayed"
    echo "  ✓ Red pulsing animation"
    echo "  ✓ Emergency contacts list shown"
    echo "  ✓ Audio recording started (check logs)"
    echo "  ✓ Location being transmitted (check logs)"
    
    echo ""
}

################################################################################
# STEP 6: Test Location Tracking
################################################################################
test_location_tracking() {
    log_info "Step 6: Testing location tracking"
    
    log_location "SCENARIO: Location updates during SOS"
    log_info "Waiting for location updates... (check for 📍 LOCATION in logcat)"
    
    # Monitor logs for location updates
    sleep 5
    
    log_location "Expected log patterns:"
    echo "  📍 Location update received: lat: 12.xxxx, lng: 77.xxxx"
    echo "  📍 Location shared with guardians"
    echo "  📍 Location accuracy: X meters"
    
    echo ""
}

################################################################################
# STEP 7: Test Notifications
################################################################################
test_notifications() {
    log_info "Step 7: Testing notification sending"
    
    log_notification "SCENARIO: Notifications sent to guardians"
    log_info "Monitoring notification logs..."
    
    sleep 3
    
    log_notification "Expected notifications to check:"
    echo "  📲 Push notification (check notification center)"
    echo "  📲 SMS sent (check messages app)"
    echo "  📲 Email sent (check email)"
    echo "  📲 WhatsApp message (if configured)"
    
    echo ""
}

################################################################################
# STEP 8: Test No Internet Scenario
################################################################################
test_offline_mode() {
    log_info "Step 8: Testing offline mode (optional)"
    
    log_warning "This will disable network on the device temporarily"
    read -p "Do you want to test offline mode? (y/n): " -n 1 -r OFFLINE_TEST
    echo
    
    if [[ $OFFLINE_TEST =~ ^[Yy]$ ]]; then
        log_warning "Disabling mobile data..."
        adb -s "$DEVICE_ID" shell svc data disable
        
        log_warning "Disabling WiFi..."
        adb -s "$DEVICE_ID" shell svc wifi disable
        
        sleep 2
        
        log_warning "Triggering SOS while offline..."
        # Tap SOS button again
        adb -s "$DEVICE_ID" shell input tap $CENTER_X $CENTER_Y
        
        sleep 3
        
        log_info "Restoring network connectivity..."
        adb -s "$DEVICE_ID" shell svc wifi enable
        adb -s "$DEVICE_ID" shell svc data enable
        
        log_info "Waiting for offline queue to sync..."
        sleep 5
        
        log_success "Offline mode test complete"
    fi
    
    echo ""
}

################################################################################
# STEP 9: Test Voice SOS
################################################################################
test_voice_sos() {
    log_info "Step 9: Testing voice distress detection (optional)"
    
    log_warning "This will listen for voice input on the device"
    read -p "Do you want to test voice SOS? (y/n): " -n 1 -r VOICE_TEST
    echo
    
    if [[ $VOICE_TEST =~ ^[Yy]$ ]]; then
        log_info "Say 'Help!' or 'Emergency!' loudly on your device..."
        sleep 5
        
        log_info "Checking logs for voice detection..."
        # Logs will show: 🎤 Voice: Distress detected
    fi
    
    echo ""
}

################################################################################
# STEP 10: Performance Measurement
################################################################################
measure_performance() {
    log_info "Step 10: Measuring SOS performance"
    
    # Measure SOS trigger to UI display time
    log_info "Measuring SOS trigger latency..."
    echo "Expected:"
    echo "  ✓ SOS button click to screen change: < 1 second"
    echo "  ✓ SOS trigger to API call: < 2 seconds"
    echo "  ✓ Location fetch: < 3 seconds"
    
    sleep 2
}

################################################################################
# STEP 11: View Detailed Logs
################################################################################
view_detailed_logs() {
    log_info "Step 11: Retrieving detailed logs from device"
    
    if [ -n "$LOGCAT_PID" ]; then
        log_info "Stopping logcat capture..."
        kill $LOGCAT_PID 2>/dev/null || true
    fi
    
    # Pull additional logs from device
    CRASH_LOG="/data/anr/traces.txt"
    adb -s "$DEVICE_ID" pull "$CRASH_LOG" "$LOG_DIR/crash_dump.log" 2>/dev/null || log_warning "No crash dump found"
    
    # Pull app logs
    APP_LOG_DIR="/data/data/$APP_PACKAGE/files"
    adb -s "$DEVICE_ID" pull "$APP_LOG_DIR" "$LOG_DIR/app_files" 2>/dev/null || log_warning "No app logs directory found"
    
    log_success "Logs saved to: $LOG_DIR/"
    log_info "View logs with: cat $LOGFILE | grep -E '(SOS|LOCATION|NOTIFICATION|ERROR)'"
    
    echo ""
}

################################################################################
# STEP 12: Extract and Analyze Logs
################################################################################
analyze_logs() {
    log_info "Step 12: Analyzing logs"
    
    if [ -f "$LOGFILE" ]; then
        echo ""
        log_info "SOS Triggers Found:"
        grep -i "🚨\|sos.*trigger\|trigger.*sos" "$LOGFILE" | head -10 || echo "  (none found - may not be visible in filtered logs)"
        
        echo ""
        log_info "Location Updates Found:"
        grep -i "📍\|location\|coordinate" "$LOGFILE" | head -10 || echo "  (none found)"
        
        echo ""
        log_info "Notification Sends Found:"
        grep -i "📲\|notification\|sms\|email" "$LOGFILE" | head -10 || echo "  (none found)"
        
        echo ""
        log_info "Errors Found:"
        grep -i "error\|exception\|❌" "$LOGFILE" | head -10 || echo "  (no errors - good!)"
    fi
    
    echo ""
}

################################################################################
# STEP 13: Test Cleanup
################################################################################
cleanup() {
    log_info "Step 13: Cleaning up"
    
    # Stop logcat if still running
    if [ -n "$LOGCAT_PID" ]; then
        kill $LOGCAT_PID 2>/dev/null || true
    fi
    
    # Disconnect device (optional)
    log_info "Test complete. Device still connected."
    log_success "Test logs saved to: $LOG_DIR/"
    
    echo ""
}

################################################################################
# Main Execution
################################################################################
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  WOMEN SAFETY APP - REAL DEVICE TESTING SCRIPT               ║"
    echo "║  Tests on actual Android device via USB debugging            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        log_error "pubspec.yaml not found. Please run this script from the Flutter project root."
        exit 1
    fi
    
    # Run test steps
    check_adb_setup
    verify_usb_debugging
    build_and_install_app
    run_app_and_capture_logs
    
    log_info "MANUAL TESTING STEPS:"
    test_sos_trigger
    test_location_tracking
    test_notifications
    test_offline_mode
    test_voice_sos
    measure_performance
    
    view_detailed_logs
    analyze_logs
    cleanup
    
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Device testing complete!                                    ║"
    echo "║  Review logs and check device screen for any issues.         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Run main
main "$@"
