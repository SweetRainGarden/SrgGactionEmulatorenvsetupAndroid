#!/bin/bash
# Complete test command for RuntimeCrashChecker emulator setup

echo "=== Starting RuntimeCrashChecker Emulator Test ==="

# Set environment variables
export APK_PATH="/Users/rtang/StudioProjects/SrgGactionEmulatorenvsetupAndroid/test_resource/runtime_crash_checker_app_debug.apk"
export PRE_SCRIPT_PATH="/Users/rtang/StudioProjects/SrgGactionEmulatorenvsetupAndroid/test-pre-script.sh"
export RUN_SCRIPT_PATH="/Users/rtang/StudioProjects/SrgGactionEmulatorenvsetupAndroid/test-run-script.sh"
export API_LEVEL=29
export TARGET=google_apis
export PROFILE="Nexus 6"
export DEBUG_MODE=true  # Enable window for local testing visualization

echo "Configuration:"
echo "  APK Path: $APK_PATH"
echo "  Pre-script: $PRE_SCRIPT_PATH"  
echo "  Run-script: $RUN_SCRIPT_PATH"
echo "  API Level: $API_LEVEL"
echo ""

# Note: This test command is for local testing only
# In the new architecture, the android-emulator-runner handles the emulator setup
# and then runs our emulator-script.sh inside the emulator

echo "⚠️  WARNING: This test command is for reference only"
echo "The new action uses reactivecircus/android-emulator-runner internally"
echo "To test locally, you would need to:"
echo "1. Install Android SDK manually"
echo "2. Use android-emulator-runner directly, or"
echo "3. Use the GitHub Action in a workflow"
echo ""
echo "For quick testing, run the emulator-script.sh directly if you have an emulator running:"
echo "./emulator-script.sh"

echo ""
echo "=== Test completed! ==="
echo "Check the test_result directory for results:"
echo "  - test_result/screenshot_*.png files"
echo "  - test_result/app_logs.txt"