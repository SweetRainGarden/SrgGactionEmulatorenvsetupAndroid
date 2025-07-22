#!/bin/bash
echo "=== Run Script: RuntimeCrashChecker Testing ==="
echo "Package name: $PACKAGE_NAME"
echo "Device serial: $ADB_DEVICE_SERIAL"

# Ensure test result directory exists
mkdir -p test_result

# Take screenshot before launch
echo "Taking screenshot before app launch..."
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_before_launch.png
echo "Before launch screenshot saved as test_result/screenshot_before_launch.png"

# Launch the RuntimeCrashChecker app MainActivity directly
echo "Launching RuntimeCrashChecker MainActivity..."
adb -s $ADB_DEVICE_SERIAL shell am start -n $PACKAGE_NAME/.MainActivity

# Wait for app to fully load
echo "Waiting for app to load..."
sleep 5

# Take screenshot after launch
echo "Taking screenshot after app launch..."
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_after_launch.png
echo "After launch screenshot saved as test_result/screenshot_after_launch.png"

echo "=== Run script completed ==="
echo "Screenshots taken:"
echo "  - test_result/screenshot_before_launch.png"
echo "  - test_result/screenshot_after_launch.png"