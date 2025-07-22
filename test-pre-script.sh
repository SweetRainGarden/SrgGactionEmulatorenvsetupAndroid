#!/bin/bash
echo "=== Pre-script: RuntimeCrashChecker Setup ==="
echo "Package name: $PACKAGE_NAME"
echo "Device serial: $ADB_DEVICE_SERIAL"

# Wait for device to be fully ready
echo "Waiting for device to be fully ready..."
sleep 10

# Grant necessary permissions for the crash checker app
echo "Granting permissions for RuntimeCrashChecker..."
adb -s $ADB_DEVICE_SERIAL shell pm grant $PACKAGE_NAME android.permission.WRITE_EXTERNAL_STORAGE || true
adb -s $ADB_DEVICE_SERIAL shell pm grant $PACKAGE_NAME android.permission.READ_EXTERNAL_STORAGE || true
adb -s $ADB_DEVICE_SERIAL shell pm grant $PACKAGE_NAME android.permission.READ_PHONE_STATE || true

# Set up any initial configuration if needed
echo "Setting up app configuration..."

# Create test result directory
mkdir -p test_result

# Take initial screenshot
echo "Taking initial screenshot..."
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_initial.png
echo "Initial screenshot saved as test_result/screenshot_initial.png"

echo "=== Pre-script completed ==="