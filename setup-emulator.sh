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
}

# Set default values
API_LEVEL=${API_LEVEL:-29}
TARGET=${TARGET:-google_apis}

# Auto-detect architecture based on host system
HOST_ARCH=$(uname -m)
HOST_OS=$(uname -s)

if [[ "$HOST_ARCH" == "arm64" ]] || [[ "$HOST_ARCH" == "aarch64" ]]; then
    if [[ "$HOST_OS" == "Darwin" ]]; then
        # macOS ARM64 - use ARM64 Android images
        ARCH=${ARCH:-arm64-v8a}
    else
        # Linux ARM64 - use x86_64 with emulation for better compatibility
        ARCH=${ARCH:-x86_64}
        print_warning "ARM64 Linux detected, using x86_64 emulation for compatibility"
    fi
else
    # x86_64 systems (Intel/AMD)
    ARCH=${ARCH:-x86_64}
fi

PROFILE=${PROFILE:-"Nexus 6"}

# Configure GPU options based on host system
if [[ "$HOST_OS" == "Linux" ]]; then
    # Linux - try hardware acceleration, fallback to software
    GPU_OPTIONS="-gpu host"
    print_info "Linux detected - attempting hardware GPU acceleration"
else
    # macOS and others - use software rendering
    GPU_OPTIONS="-gpu swiftshader_indirect"
fi

# Check for debug/local mode - enable window for visualization
if [ "$DEBUG_MODE" = "true" ] || [ "$LOCAL_MODE" = "true" ]; then
    EMULATOR_OPTIONS=${EMULATOR_OPTIONS:-"-no-snapshot-save $GPU_OPTIONS -no-audio -no-boot-anim"}
    print_info "Debug/Local mode enabled - emulator window will be visible"
else
    EMULATOR_OPTIONS=${EMULATOR_OPTIONS:-"-no-snapshot-save -no-window $GPU_OPTIONS -no-audio -no-boot-anim"}
fi

AVD_NAME="test-emulator-api-${API_LEVEL}"

# Initialize GitHub Step Summary (create local file if not in CI)
if [ -z "$GITHUB_STEP_SUMMARY" ]; then
    GITHUB_STEP_SUMMARY="$PWD/github_step_summary.md"
    touch "$GITHUB_STEP_SUMMARY"
    echo "" > "$GITHUB_STEP_SUMMARY"
    echo "Local summary will be saved to: $GITHUB_STEP_SUMMARY"
fi

if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "# 📱 Android Emulator Setup Summary" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## Configuration" >> "$GITHUB_STEP_SUMMARY"
    echo "- **API Level**: $API_LEVEL" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Target**: $TARGET" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Architecture**: $ARCH" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Profile**: $PROFILE" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## Setup Progress" >> "$GITHUB_STEP_SUMMARY"
fi

print_info "Starting Android emulator setup..."
print_info "API Level: $API_LEVEL"
print_info "Target: $TARGET"
print_info "Architecture: $ARCH"
print_info "Profile: $PROFILE"

# Check if Android SDK is available
if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
    print_error "Android SDK not found. Please set ANDROID_SDK_ROOT or ANDROID_HOME environment variable."
    exit 1
fi

# Set SDK root
if [ -n "$ANDROID_SDK_ROOT" ]; then
    SDK_ROOT="$ANDROID_SDK_ROOT"
else
    SDK_ROOT="$ANDROID_HOME"
fi

print_info "Android SDK Root: $SDK_ROOT"

# Add Android SDK tools to PATH
export PATH="$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$SDK_ROOT/emulator:$SDK_ROOT/build-tools/30.0.3:$PATH"

# Check if required tools exist
if ! command -v sdkmanager &> /dev/null; then
    print_error "sdkmanager not found in PATH"
    exit 1
fi

if ! command -v avdmanager &> /dev/null; then
    print_error "avdmanager not found in PATH"
    exit 1
fi

if ! command -v emulator &> /dev/null; then
    print_error "emulator not found in PATH"
    exit 1
fi

# Accept licenses
print_info "Accepting Android SDK licenses..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true

# Install required SDK components
print_info "Installing Android SDK components..."
sdkmanager "system-images;android-${API_LEVEL};${TARGET};${ARCH}" > /dev/null
sdkmanager "platforms;android-${API_LEVEL}" > /dev/null
sdkmanager "build-tools;30.0.3" > /dev/null

# Delete existing AVD if it exists
if avdmanager list avd | grep -q "Name: $AVD_NAME"; then
    print_warning "AVD $AVD_NAME already exists. Deleting..."
    avdmanager delete avd -n "$AVD_NAME"
fi

# Create AVD
print_info "Creating AVD: $AVD_NAME"
echo "no" | avdmanager create avd \
    -n "$AVD_NAME" \
    -k "system-images;android-${API_LEVEL};${TARGET};${ARCH}" \
    -d "$PROFILE" \
    --force

# Configure AVD for better CI performance
AVD_PATH="$HOME/.android/avd/${AVD_NAME}.avd"
if [ -f "$AVD_PATH/config.ini" ]; then
    print_info "Configuring AVD for CI environment..."
    # Optimize for CI
    echo "hw.lcd.density=240" >> "$AVD_PATH/config.ini"
    echo "hw.ramSize=2048" >> "$AVD_PATH/config.ini"
    echo "vm.heapSize=256" >> "$AVD_PATH/config.ini"
    echo "hw.accelerometer=no" >> "$AVD_PATH/config.ini"
    echo "hw.gps=no" >> "$AVD_PATH/config.ini"
    echo "hw.camera.back=none" >> "$AVD_PATH/config.ini"
    echo "hw.camera.front=none" >> "$AVD_PATH/config.ini"
fi

# Set fast shutdown for CI environments  
export ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=${ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL:-5}

# Start emulator in background
print_info "Starting emulator with options: $EMULATOR_OPTIONS"
emulator -avd "$AVD_NAME" $EMULATOR_OPTIONS &
EMULATOR_PID=$!

# Function to cleanup emulator on exit
cleanup() {
    print_info "Cleaning up emulator process..."
    if [ -n "$EMULATOR_PID" ] && kill -0 "$EMULATOR_PID" 2>/dev/null; then
        print_info "Force killing emulator (PID: $EMULATOR_PID)"
        kill -KILL "$EMULATOR_PID" 2>/dev/null || true
    fi
    
    # Kill any remaining emulator processes aggressively
    pkill -f "emulator.*$AVD_NAME" 2>/dev/null || true
    pkill -f "qemu-system" 2>/dev/null || true
}
trap cleanup EXIT

# Wait for emulator to be ready
print_info "Waiting for emulator to boot..."
adb wait-for-device

# Get the device serial for this emulator
ADB_DEVICE_SERIAL=$(adb devices | grep emulator | head -1 | cut -f1)
print_info "Using device serial: $ADB_DEVICE_SERIAL"

# Wait for system to be ready
timeout_counter=0
max_timeout=300 # 5 minutes

while true; do
    if [ $timeout_counter -ge $max_timeout ]; then
        print_error "Emulator failed to boot within timeout"
        exit 1
    fi
    
    boot_completed=$(adb -s "$ADB_DEVICE_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    if [ "$boot_completed" = "1" ]; then
        break
    fi
    
    print_info "Waiting for emulator to finish booting... (${timeout_counter}s/${max_timeout}s)"
    sleep 5
    timeout_counter=$((timeout_counter + 5))
done

print_info "Emulator is ready!"

# Disable system animations for faster testing
print_info "Disabling animations for testing..."
adb -s "$ADB_DEVICE_SERIAL" shell settings put global window_animation_scale 0
adb -s "$ADB_DEVICE_SERIAL" shell settings put global transition_animation_scale 0
adb -s "$ADB_DEVICE_SERIAL" shell settings put global animator_duration_scale 0

# Install APK if provided
if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
    print_info "Installing APK: $APK_PATH"
    adb -s "$ADB_DEVICE_SERIAL" install -r "$APK_PATH"
    
    # Extract package name from APK  
    PACKAGE_NAME=$(aapt dump badging "$APK_PATH" | grep "^package:" | sed "s/^package: name='\([^']*\)'.*/\1/")
    if [ -n "$PACKAGE_NAME" ]; then
        print_info "Installed package: $PACKAGE_NAME"
        if [ -n "$GITHUB_ENV" ]; then
            echo "PACKAGE_NAME=$PACKAGE_NAME" >> "$GITHUB_ENV"
        fi
    fi
else
    print_warning "No APK path provided or APK file not found: $APK_PATH"
fi

# Run pre-script if provided
if [ -n "$PRE_SCRIPT_PATH" ] && [ -f "$PRE_SCRIPT_PATH" ]; then
    print_info "Executing pre-script: $PRE_SCRIPT_PATH"
    chmod +x "$PRE_SCRIPT_PATH"
    
    # Export environment variables for the script
    export ADB_DEVICE_SERIAL
    export PACKAGE_NAME
    
    "$PRE_SCRIPT_PATH"
else
    print_warning "No pre-script provided or script file not found: $PRE_SCRIPT_PATH"
fi

# Run main script if provided
if [ -n "$RUN_SCRIPT_PATH" ] && [ -f "$RUN_SCRIPT_PATH" ]; then
    print_info "Executing run script: $RUN_SCRIPT_PATH"
    chmod +x "$RUN_SCRIPT_PATH"
    
    # Export environment variables for the script
    export ADB_DEVICE_SERIAL
    export PACKAGE_NAME
    
    "$RUN_SCRIPT_PATH"
else
    print_warning "No run script provided or script file not found: $RUN_SCRIPT_PATH"
fi

# Set output for other steps
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "emulator-name=$AVD_NAME" >> "$GITHUB_OUTPUT"
fi

print_info "Android emulator setup completed successfully!"
print_info "Emulator name: $AVD_NAME"
print_info "Device serial: $ADB_DEVICE_SERIAL"

# Add final summary to GitHub Step Summary
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## 🎉 Setup Complete!" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Emulator Name**: \`$AVD_NAME\`" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Device Serial**: \`$ADB_DEVICE_SERIAL\`" >> "$GITHUB_STEP_SUMMARY"
    if [ -n "$PACKAGE_NAME" ]; then
        echo "- **Installed Package**: \`$PACKAGE_NAME\`" >> "$GITHUB_STEP_SUMMARY"
    fi
    echo "" >> "$GITHUB_STEP_SUMMARY"
fi

# Keep emulator running for subsequent steps
print_info "Emulator will continue running for subsequent workflow steps..."