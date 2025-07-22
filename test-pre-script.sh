#!/bin/bash
# Initialize local summary file if not in CI
if [ -z "$GITHUB_STEP_SUMMARY" ]; then
    GITHUB_STEP_SUMMARY="$PWD/github_step_summary.md"
    touch "$GITHUB_STEP_SUMMARY"
fi

echo "=== Pre-script: RuntimeCrashChecker Setup ==="
echo "Package name: $PACKAGE_NAME"
echo "Device serial: $ADB_DEVICE_SERIAL"

# Add to GitHub Step Summary if available
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## 🔧 Pre-Script Execution" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Package**: \`$PACKAGE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Device**: \`$ADB_DEVICE_SERIAL\`" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
fi

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

# Add completion to GitHub Step Summary
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "✅ **Pre-script completed** - Permissions granted, initial screenshot captured" >> "$GITHUB_STEP_SUMMARY"
fi

echo "=== Pre-script completed ==="