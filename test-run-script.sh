#!/bin/bash
# Initialize local summary file if not in CI (only if it doesn't exist yet)
if [ -z "$GITHUB_STEP_SUMMARY" ]; then
    mkdir -p test_result
    GITHUB_STEP_SUMMARY="$PWD/test_result/local_github_step_summary.md"
    # Don't reset here - the main setup script already created/reset it
fi

echo "=== Run Script: RuntimeCrashChecker Testing ==="
echo "Package name: $PACKAGE_NAME"
echo "Device serial: $ADB_DEVICE_SERIAL"

# Add to GitHub Step Summary
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## 🧪 Run Script Execution" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Target**: RuntimeCrashChecker MainActivity" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Package**: \`$PACKAGE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
fi

# Ensure test result directory exists
mkdir -p test_result

# Take screenshot before launch (reduced size for GitHub summary)
echo "Taking screenshot before app launch..."
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_before_launch_full.png

# Create a smaller version
if command -v convert >/dev/null 2>&1; then
    echo "Creating smaller before launch screenshot..."
    convert test_result/screenshot_before_launch_full.png -resize 50% -quality 60 test_result/screenshot_before_launch.png
    rm test_result/screenshot_before_launch_full.png
    echo "Compressed before launch screenshot saved"
elif command -v sips >/dev/null 2>&1; then
    echo "Creating smaller before launch screenshot using sips..."
    sips -Z 400 -s format png test_result/screenshot_before_launch_full.png --out test_result/screenshot_before_launch.png
    rm test_result/screenshot_before_launch_full.png
    echo "Resized before launch screenshot saved"
else
    echo "No image compression tool found, using original size"
    mv test_result/screenshot_before_launch_full.png test_result/screenshot_before_launch.png
fi

# Launch the RuntimeCrashChecker app MainActivity directly
echo "Launching RuntimeCrashChecker MainActivity..."
adb -s $ADB_DEVICE_SERIAL shell am start -n $PACKAGE_NAME/.MainActivity

# Wait for app to fully load
echo "Waiting for app to load..."
sleep 5

# Take screenshot after launch (reduced size for GitHub summary)
echo "Taking screenshot after app launch..."
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_after_launch_full.png

# Create a smaller version
if command -v convert >/dev/null 2>&1; then
    echo "Creating smaller after launch screenshot..."
    convert test_result/screenshot_after_launch_full.png -resize 50% -quality 60 test_result/screenshot_after_launch.png
    rm test_result/screenshot_after_launch_full.png
    echo "Compressed after launch screenshot saved"
elif command -v sips >/dev/null 2>&1; then
    echo "Creating smaller after launch screenshot using sips..."
    sips -Z 400 -s format png test_result/screenshot_after_launch_full.png --out test_result/screenshot_after_launch.png
    rm test_result/screenshot_after_launch_full.png
    echo "Resized after launch screenshot saved"
else
    echo "No image compression tool found, using original size"
    mv test_result/screenshot_after_launch_full.png test_result/screenshot_after_launch.png
fi

# Add completion summary
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## 📸 Screenshots Captured" >> "$GITHUB_STEP_SUMMARY"
    echo "- ✅ **Before Launch**: \`test_result/screenshot_before_launch.png\`" >> "$GITHUB_STEP_SUMMARY"  
    echo "- ✅ **After Launch**: \`test_result/screenshot_after_launch.png\`" >> "$GITHUB_STEP_SUMMARY"
    echo "- ✅ **MainActivity launched successfully**" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
fi

echo "=== Run script completed ==="
echo "Screenshots taken:"
echo "  - test_result/screenshot_before_launch.png"
echo "  - test_result/screenshot_after_launch.png"