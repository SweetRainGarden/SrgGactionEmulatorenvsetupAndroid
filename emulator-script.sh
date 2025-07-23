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

print_info "Android emulator is ready! Starting APK testing..."

# Get device serial with error handling
ADB_DEVICE_SERIAL=$(adb get-serialno 2>/dev/null || echo "unknown")
if [ -n "$ADB_DEVICE_SERIAL" ] && [ "$ADB_DEVICE_SERIAL" != "unknown" ]; then
    print_info "Device serial: $ADB_DEVICE_SERIAL"
else
    print_warning "Could not determine device serial - emulator may not be ready"
    ADB_DEVICE_SERIAL="unknown"
fi

# Install APK if provided
if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
    print_info "Installing APK: $APK_PATH"
    if adb install -r "$APK_PATH"; then
        print_info "APK installation completed successfully"
    else
        print_error "APK installation failed"
    fi
    
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
    if "$PRE_SCRIPT_PATH"; then
        print_info "Pre-script executed successfully"
    else
        print_error "Pre-script execution failed"
    fi
else
    print_warning "No pre-script provided or script file not found: $PRE_SCRIPT_PATH"
fi

# Run main script if provided
if [ -n "$RUN_SCRIPT_PATH" ] && [ -f "$RUN_SCRIPT_PATH" ]; then
    print_info "Executing run script: $RUN_SCRIPT_PATH"
    chmod +x "$RUN_SCRIPT_PATH"
    if "$RUN_SCRIPT_PATH"; then
        print_info "Run script executed successfully"
    else
        print_error "Run script execution failed"
    fi
else
    print_warning "No run script provided or script file not found: $RUN_SCRIPT_PATH"
fi


# Set outputs for GitHub Actions with guard logic
if [ -n "$GITHUB_OUTPUT" ]; then
    # Emulator name - use descriptive name based on configuration
    EMULATOR_NAME="android-emulator-runner"
    echo "emulator-name=$EMULATOR_NAME" >> "$GITHUB_OUTPUT"
    print_info "Output set - Emulator name: $EMULATOR_NAME"
    
    # Device serial - validate and provide fallback
    if [ -n "$ADB_DEVICE_SERIAL" ] && [ "$ADB_DEVICE_SERIAL" != "unknown" ]; then
        echo "device-serial=$ADB_DEVICE_SERIAL" >> "$GITHUB_OUTPUT"
        print_info "Output set - Device serial: $ADB_DEVICE_SERIAL"
    else
        echo "device-serial=" >> "$GITHUB_OUTPUT"
        print_warning "Device serial could not be determined"
    fi
    
    # Package name - validate and provide fallback
    if [ -n "$PACKAGE_NAME" ]; then
        echo "package-name=$PACKAGE_NAME" >> "$GITHUB_OUTPUT"
        print_info "Output set - Package name: $PACKAGE_NAME"
    else
        echo "package-name=" >> "$GITHUB_OUTPUT"
        print_warning "Package name could not be extracted from APK"
    fi
else
    print_warning "GITHUB_OUTPUT not available - outputs not set"
fi

print_info "Android emulator setup completed successfully!"
print_info "Device serial: $ADB_DEVICE_SERIAL"
if [ -n "$PACKAGE_NAME" ]; then
    print_info "Package: $PACKAGE_NAME"
fi