# Android Emulator Setup and APK Runner

A GitHub Action that sets up an Android emulator environment, installs APK files, and runs initialization and testing scripts for CI/CD pipelines.

## Features

- 🚀 Fast Android emulator setup optimized for CI/CD
- 📱 Automatic APK installation with package name detection
- 🔧 Pre-script execution for login processes and token injection
- 🧪 Run script execution via ADB commands for UI automation
- ⚙️ Configurable emulator settings (API level, architecture, profile)
- 🎯 Optimized for headless CI environments

## Usage

### Basic Example

```yaml
- name: Setup Android Emulator and Run APK
  uses: ./
  with:
    apk-path: '/path/to/your/app.apk'
    pre-script-path: './scripts/login-setup.sh'
    run-script-path: './scripts/run-tests.sh'
```

### Advanced Example

```yaml
- name: Setup Android Emulator
  uses: ./
  with:
    apk-path: '${{ github.workspace }}/app/build/outputs/apk/debug/app-debug.apk'
    pre-script-path: './scripts/inject-auth-token.sh'
    run-script-path: './scripts/ui-automation.sh'
    api-level: '30'
    target: 'google_apis'
    arch: 'x86_64'
    profile: 'pixel_4'
    emulator-options: '-no-snapshot-save -no-window -gpu swiftshader_indirect'
```

### Local Testing/Debug Example

```yaml
- name: Setup Android Emulator with Debug Window
  uses: ./
  with:
    apk-path: './app-debug.apk'
    pre-script-path: './scripts/setup.sh'
    run-script-path: './scripts/test.sh'
    debug-mode: 'true'  # Shows emulator window for visualization
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `apk-path` | Absolute path to the APK file to install | Yes | - |
| `pre-script-path` | Path to pre-script for initialization (login, token injection) | No | - |
| `run-script-path` | Path to script that runs the APK via ADB commands | No | - |
| `api-level` | Android API level for the emulator | No | `29` |
| `target` | Android target (google_apis or default) | No | `google_apis` |
| `arch` | Android architecture (x86_64 or x86) | No | `x86_64` |
| `profile` | AVD hardware profile | No | `Nexus 6` |
| `emulator-options` | Additional emulator startup options | No | `-no-snapshot-save -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim` |
| `debug-mode` | Enable debug mode with visible emulator window | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `emulator-name` | Name of the created Android emulator |

## Script Examples

### Pre-script (login-setup.sh)
```bash
#!/bin/bash
# Example pre-script for injecting authentication token

echo "Setting up authentication..."

# Wait for app to be ready
sleep 5

# Inject auth token into shared preferences
adb shell "run-as $PACKAGE_NAME sh -c 'mkdir -p shared_prefs'"
adb shell "run-as $PACKAGE_NAME sh -c 'echo \"<?xml version=\\\"1.0\\\" encoding=\\\"utf-8\\\" standalone=\\\"yes\\\" ?><map><string name=\\\"auth_token\\\">$AUTH_TOKEN</string></map>\" > shared_prefs/auth_prefs.xml'"

echo "Authentication setup completed"
```

### Run script (ui-automation.sh)
```bash
#!/bin/bash
# Example run script for UI automation

echo "Starting UI automation tests..."

# Launch the app
adb shell monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1

# Wait for app to load
sleep 10

# Take screenshot
adb exec-out screencap -p > screenshot_start.png

# Simulate user interactions
adb shell input tap 500 1000  # Tap login button
sleep 2

adb shell input tap 500 1500  # Tap main menu
sleep 3

# Take final screenshot
adb exec-out screencap -p > screenshot_end.png

echo "UI automation completed"
```

## Environment Variables

The following environment variables are automatically set and available in your scripts:

- `ADB_DEVICE_SERIAL`: The serial number of the emulator device
- `PACKAGE_NAME`: The package name extracted from the installed APK

## Prerequisites

Your workflow needs to have the Android SDK set up. Example:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Android SDK
      uses: android-actions/setup-android@v2
      
    - name: Setup Android Emulator and Run APK
      uses: ./
      with:
        apk-path: './app.apk'
```

## Troubleshooting

### Common Issues

1. **Emulator fails to start**: Ensure hardware acceleration is available or use software rendering
2. **APK installation fails**: Check APK path and ensure file exists
3. **Scripts not executing**: Verify script paths and ensure they are executable
4. **Timeout during boot**: Increase timeout or use a lower API level

### Debug Mode

Add these steps to debug emulator issues:

```yaml
- name: Debug Emulator
  run: |
    adb devices
    adb shell getprop ro.build.version.release
    adb shell pm list packages
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.