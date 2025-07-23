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
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

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


# Set outputs for GitHub Actions
echo "emulator-name=test-emulator" >> "$GITHUB_OUTPUT" 2>/dev/null || true
echo "device-serial=$ADB_DEVICE_SERIAL" >> "$GITHUB_OUTPUT" 2>/dev/null || true

print_info "Android emulator setup completed successfully!"
print_info "Device serial: $ADB_DEVICE_SERIAL"
if [ -n "$PACKAGE_NAME" ]; then
    print_info "Package: $PACKAGE_NAME"
fi