#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    # Add to GitHub Step Summary if available
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
        echo "✅ $1" >> "$GITHUB_STEP_SUMMARY"
    fi
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    # Add to GitHub Step Summary if available
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
        echo "⚠️ $1" >> "$GITHUB_STEP_SUMMARY"
    fi
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    # Add to GitHub Step Summary if available
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
        echo "❌ $1" >> "$GITHUB_STEP_SUMMARY"
    fi
    exit 1
}

# Initialize GitHub Step Summary (create local file if not in CI)
if [ -z "$GITHUB_STEP_SUMMARY" ]; then
    # Create test_result directory if it doesn't exist
    mkdir -p test_result
    GITHUB_STEP_SUMMARY="$PWD/test_result/local_github_step_summary.md"
    # Reset/create the file fresh for each run
    echo "" > "$GITHUB_STEP_SUMMARY"
    echo "Local summary will be saved to: $GITHUB_STEP_SUMMARY"
fi

if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "# 📱 Android Emulator APK Testing Summary" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## Configuration" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Emulator**: Already started by android-emulator-runner" >> "$GITHUB_STEP_SUMMARY"
    if [ -n "$APK_PATH" ]; then
        echo "- **APK Path**: \`$APK_PATH\`" >> "$GITHUB_STEP_SUMMARY"
    fi
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## Execution Progress" >> "$GITHUB_STEP_SUMMARY"
fi

print_info "Android emulator is ready! Starting APK testing..."

# Get device serial
ADB_DEVICE_SERIAL=$(adb get-serialno)
print_info "Device serial: $ADB_DEVICE_SERIAL"

# Install APK if provided
if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
    print_info "Installing APK: $APK_PATH"
    adb install -r "$APK_PATH"
    
    # Extract package name from APK
    # First try to find aapt in build-tools
    AAPT_PATH=""
    if [ -n "$ANDROID_HOME" ]; then
        # Find the latest build-tools version
        if [ -d "$ANDROID_HOME/build-tools" ]; then
            BUILD_TOOLS_VERSION=$(ls -1 "$ANDROID_HOME/build-tools" | grep -E '^[0-9]+\.' | sort -V | tail -1)
            if [ -n "$BUILD_TOOLS_VERSION" ] && [ -f "$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/aapt" ]; then
                AAPT_PATH="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/aapt"
            fi
        fi
    fi
    
    # Try system aapt as fallback
    if [ -z "$AAPT_PATH" ] && command -v aapt >/dev/null 2>&1; then
        AAPT_PATH="aapt"
    fi
    
    if [ -n "$AAPT_PATH" ]; then
        PACKAGE_NAME=$("$AAPT_PATH" dump badging "$APK_PATH" | grep "^package:" | sed "s/^package: name='\([^']*\)'.*/\1/")
        if [ -n "$PACKAGE_NAME" ]; then
            print_info "Installed package: $PACKAGE_NAME"
            # Set output for GitHub Actions
            echo "package-name=$PACKAGE_NAME" >> "$GITHUB_OUTPUT" 2>/dev/null || true
        fi
    else
        print_warning "aapt not available, cannot extract package name"
        PACKAGE_NAME=""
    fi
else
    print_warning "No APK path provided or APK file not found: $APK_PATH"
    PACKAGE_NAME=""
fi

# Export environment variables for scripts
export ADB_DEVICE_SERIAL
export PACKAGE_NAME

# Run pre-script if provided
if [ -n "$PRE_SCRIPT_PATH" ] && [ -f "$PRE_SCRIPT_PATH" ]; then
    print_info "Executing pre-script: $PRE_SCRIPT_PATH"
    chmod +x "$PRE_SCRIPT_PATH"
    "$PRE_SCRIPT_PATH"
else
    print_warning "No pre-script provided or script file not found: $PRE_SCRIPT_PATH"
fi

# Run main script if provided
if [ -n "$RUN_SCRIPT_PATH" ] && [ -f "$RUN_SCRIPT_PATH" ]; then
    print_info "Executing run script: $RUN_SCRIPT_PATH"
    chmod +x "$RUN_SCRIPT_PATH"
    "$RUN_SCRIPT_PATH"
else
    print_warning "No run script provided or script file not found: $RUN_SCRIPT_PATH"
fi

# Add final summary with screenshots to GitHub Step Summary
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## 🎉 Testing Complete!" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Device Serial**: \`$ADB_DEVICE_SERIAL\`" >> "$GITHUB_STEP_SUMMARY"
    if [ -n "$PACKAGE_NAME" ]; then
        echo "- **Installed Package**: \`$PACKAGE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
    fi
    echo "" >> "$GITHUB_STEP_SUMMARY"
    
    # Add screenshots to summary if they exist
    echo "## 📸 Screenshots" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    
    # Function to add screenshot to summary
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
                file_size_kb=0
            fi
            
            echo "📄 **File**: \`$screenshot_path\` (${file_size_kb}KB)" >> "$GITHUB_STEP_SUMMARY"
            
            # Only embed small images (under 200KB) to avoid GitHub's 1MB limit
            if [ "$file_size_kb" -lt 200 ] && command -v base64 >/dev/null 2>&1; then
                local base64_image=$(base64 -i "$screenshot_path" | tr -d '\n')
                echo "![Screenshot](data:image/png;base64,$base64_image)" >> "$GITHUB_STEP_SUMMARY"
            else
                echo "📎 Screenshot too large for inline display - check artifacts" >> "$GITHUB_STEP_SUMMARY"
            fi
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

# Set outputs for GitHub Actions
echo "emulator-name=test-emulator" >> "$GITHUB_OUTPUT" 2>/dev/null || true
echo "device-serial=$ADB_DEVICE_SERIAL" >> "$GITHUB_OUTPUT" 2>/dev/null || true

print_info "Android emulator APK testing completed successfully!"
print_info "Device serial: $ADB_DEVICE_SERIAL"
if [ -n "$PACKAGE_NAME" ]; then
    print_info "Package: $PACKAGE_NAME"
fi