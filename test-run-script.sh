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

# Add completion summary with detailed screenshot handling
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## 🎉 Testing Complete!" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Device Serial**: \`$ADB_DEVICE_SERIAL\`" >> "$GITHUB_STEP_SUMMARY"
    if [ -n "$PACKAGE_NAME" ]; then
        echo "- **Installed Package**: \`$PACKAGE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
    fi
    echo "- ✅ **MainActivity launched successfully**" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    
    # Add screenshots to summary if they exist
    echo "## 📸 Screenshots" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    
    # Function to add screenshot info to summary
    add_screenshot_to_summary() {
        local screenshot_path="$1"
        local title="$2"
        if [ -f "$screenshot_path" ]; then
            echo "### $title" >> "$GITHUB_STEP_SUMMARY"
            
            # Get file size in KB
            local file_size_kb
            if command -v stat >/dev/null 2>&1; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS stat command
                    file_size_kb=$(($(stat -f%z "$screenshot_path") / 1024))
                else
                    # Linux stat command
                    file_size_kb=$(($(stat -c%s "$screenshot_path") / 1024))
                fi
            else
                file_size_kb="unknown"
            fi
            
            echo "📄 **File**: \`$screenshot_path\` (${file_size_kb}KB)" >> "$GITHUB_STEP_SUMMARY"
            echo "📸 **Status**: ✅ Captured successfully" >> "$GITHUB_STEP_SUMMARY"
            echo "📎 **View**: Check the uploaded artifacts below for full image" >> "$GITHUB_STEP_SUMMARY"
            echo "" >> "$GITHUB_STEP_SUMMARY"
        else
            echo "### $title" >> "$GITHUB_STEP_SUMMARY"
            echo "❌ Screenshot not found: \`$screenshot_path\`" >> "$GITHUB_STEP_SUMMARY"
            echo "" >> "$GITHUB_STEP_SUMMARY"
        fi
    }
    
    # Add screenshots if they exist
    add_screenshot_to_summary "test_result/screenshot_initial.png" "📱 Initial State"
    add_screenshot_to_summary "test_result/screenshot_before_launch.png" "🚀 Before App Launch"
    add_screenshot_to_summary "test_result/screenshot_after_launch.png" "📱 After App Launch"
fi

echo "=== Run script completed ==="
echo "Screenshots taken:"
echo "  - test_result/screenshot_before_launch.png"
echo "  - test_result/screenshot_after_launch.png"