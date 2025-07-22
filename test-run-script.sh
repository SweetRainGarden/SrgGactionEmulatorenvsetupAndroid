#!/bin/bash
# Initialize local summary file if not in CI
if [ -z "$GITHUB_STEP_SUMMARY" ]; then
    GITHUB_STEP_SUMMARY="$PWD/local_github_step_summary.md"
    touch "$GITHUB_STEP_SUMMARY"
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