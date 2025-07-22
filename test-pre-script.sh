#!/bin/bash
# Initialize local summary file if not in CI (only if it doesn't exist yet)
if [ -z "$GITHUB_STEP_SUMMARY" ]; then
    mkdir -p test_result
    GITHUB_STEP_SUMMARY="$PWD/test_result/local_github_step_summary.md"
    # Don't reset here - the main setup script already created/reset it
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

# Take initial screenshot (reduced size for GitHub summary)
echo "Taking initial screenshot..."
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_initial_full.png

# Create a smaller version using ImageMagick if available, otherwise use original
if command -v convert >/dev/null 2>&1; then
    echo "Creating smaller screenshot for summary..."
    convert test_result/screenshot_initial_full.png -resize 50% -quality 60 test_result/screenshot_initial.png
    rm test_result/screenshot_initial_full.png
    echo "Compressed screenshot saved as test_result/screenshot_initial.png"
elif command -v sips >/dev/null 2>&1; then
    echo "Creating smaller screenshot using sips..."
    sips -Z 400 -s format png test_result/screenshot_initial_full.png --out test_result/screenshot_initial.png
    rm test_result/screenshot_initial_full.png
    echo "Resized screenshot saved as test_result/screenshot_initial.png"
else
    echo "No image compression tool found, using original size"
    mv test_result/screenshot_initial_full.png test_result/screenshot_initial.png
    echo "Original screenshot saved as test_result/screenshot_initial.png"
fi

# Add completion to GitHub Step Summary
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "✅ **Pre-script completed** - Permissions granted, initial screenshot captured" >> "$GITHUB_STEP_SUMMARY"
fi

echo "=== Pre-script completed ==="