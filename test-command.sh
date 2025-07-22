#!/bin/bash
# Complete test command for RuntimeCrashChecker emulator setup

echo "=== Starting RuntimeCrashChecker Emulator Test ==="

# Set environment variables
export APK_PATH="/Users/rtang/StudioProjects/SrgGactionEmulatorenvsetupAndroid/test_res/runtime_crash_checker_app_debug.apk"
export PRE_SCRIPT_PATH="/Users/rtang/StudioProjects/SrgGactionEmulatorenvsetupAndroid/test-pre-script.sh"
export RUN_SCRIPT_PATH="/Users/rtang/StudioProjects/SrgGactionEmulatorenvsetupAndroid/test-run-script.sh"
export API_LEVEL=29
export TARGET=google_apis
export PROFILE="Nexus 6"
export EMULATOR_OPTIONS="-no-snapshot-save -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim"

echo "Configuration:"
echo "  APK Path: $APK_PATH"
echo "  Pre-script: $PRE_SCRIPT_PATH"  
echo "  Run-script: $RUN_SCRIPT_PATH"
echo "  API Level: $API_LEVEL"
echo ""

# Run the setup script
./setup-emulator.sh

echo ""
echo "=== Test completed! ==="
echo "Check the test_result directory for results:"
echo "  - test_result/screenshot_*.png files"
echo "  - test_result/app_logs.txt"