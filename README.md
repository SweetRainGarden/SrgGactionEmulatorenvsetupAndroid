# Android Emulator Setup and APK Runner

[![Action Test](https://github.com/SweetRainGarden/SrgGactionEmulatorenvsetupAndroid/actions/workflows/emulator_env_setup_action_checker.yml/badge.svg)](https://github.com/SweetRainGarden/SrgGactionEmulatorenvsetupAndroid/actions/workflows/emulator_env_setup_action_checker.yml)

A GitHub Action that sets up an Android emulator environment, installs APK files, and executes custom scripts for CI/CD pipelines. Built on top of the proven [reactivecircus/android-emulator-runner](https://github.com/ReactiveCircus/android-emulator-runner) for reliable emulator management.

## ✨ Features

- 🚀 **Reliable Emulator Setup** - Built on battle-tested android-emulator-runner
- 📱 **Automatic APK Installation** - Install and extract package information
- 🔧 **Pre-script Execution** - Setup authentication, tokens, or configuration
- 🧪 **Run Script Execution** - Custom ADB commands and UI automation
- ⚙️ **Configurable Options** - API level, architecture, profile, and emulator settings
- 🎯 **CI/CD Optimized** - Headless mode with comprehensive logging
- 📊 **GitHub Step Summary** - Visual progress reporting with detailed outputs
- 🛡️ **Robust Error Handling** - Guard logic and validation for all operations

## 🚀 Quick Start

### Basic Usage

```yaml
name: Android APK Testing
on: [push, pull_request]

jobs:
  test-apk:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Run Android Emulator with APK
      uses: SweetRainGarden/SrgGactionEmulatorenvsetupAndroid@main
      with:
        apk-path: '${{ github.workspace }}/app-debug.apk'
        pre-script-path: './scripts/setup-auth.sh'
        run-script-path: './scripts/run-tests.sh'
```

### Advanced Configuration

```yaml
    - name: Setup Android Emulator
      uses: SweetRainGarden/SrgGactionEmulatorenvsetupAndroid@main
      with:
        apk-path: '${{ github.workspace }}/app/build/outputs/apk/debug/app-debug.apk'
        pre-script-path: './scripts/inject-tokens.sh'
        run-script-path: './scripts/ui-automation.sh'
        api-level: '30'
        target: 'google_apis'
        arch: 'x86_64'
        profile: 'pixel_4'
        emulator-options: '-no-snapshot-save -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim'
```

## 📋 Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `apk-path` | Absolute path to the APK file to install | ✅ Yes | - |
| `pre-script-path` | Path to pre-script for initialization (login, token injection) | No | - |
| `run-script-path` | Path to script that runs the APK via ADB commands | No | - |
| `api-level` | Android API level for the emulator | No | `29` |
| `target` | Android target (`google_apis` or `default`) | No | `google_apis` |
| `arch` | Android architecture (`x86_64` or `x86`) | No | `x86_64` |
| `profile` | AVD hardware profile | No | `Nexus 6` |
| `emulator-options` | Additional emulator startup options | No | See below |

**Default emulator-options:**
```
-no-snapshot-save -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim -camera-back none -camera-front none
```

## 📤 Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `emulator-name` | Name of the emulator runner | `android-emulator-runner` |
| `device-serial` | Device serial number of the emulator | `emulator-5554` |
| `package-name` | Package name extracted from the APK | `com.example.myapp` |

### Using Outputs

```yaml
    - name: Setup Android Emulator
      id: emulator
      uses: SweetRainGarden/SrgGactionEmulatorenvsetupAndroid@main
      with:
        apk-path: './app.apk'
        
    - name: Use Outputs
      run: |
        echo "Emulator: ${{ steps.emulator.outputs.emulator-name }}"
        echo "Device: ${{ steps.emulator.outputs.device-serial }}"
        echo "Package: ${{ steps.emulator.outputs.package-name }}"
```

## 📝 Script Examples

### Pre-script Example (setup-auth.sh)

```bash
#!/bin/bash
echo "=== Setting up authentication ==="

# Wait for device to be ready
sleep 5

# Grant permissions
adb -s $ADB_DEVICE_SERIAL shell pm grant $PACKAGE_NAME android.permission.WRITE_EXTERNAL_STORAGE

# Inject authentication token
AUTH_TOKEN="your-test-token-here"
adb -s $ADB_DEVICE_SERIAL shell "run-as $PACKAGE_NAME sh -c 'mkdir -p shared_prefs'"
adb -s $ADB_DEVICE_SERIAL shell "run-as $PACKAGE_NAME sh -c 'echo \"<?xml version=\\\"1.0\\\" encoding=\\\"utf-8\\\" standalone=\\\"yes\\\" ?><map><string name=\\\"auth_token\\\">$AUTH_TOKEN</string></map>\" > shared_prefs/auth.xml'"

echo "Authentication setup completed"
```

### Run Script Example (ui-automation.sh)

```bash
#!/bin/bash
echo "=== Starting UI automation ==="

# Create results directory
mkdir -p test_result

# Launch the app
echo "Launching $PACKAGE_NAME..."
adb -s $ADB_DEVICE_SERIAL shell am start -n $PACKAGE_NAME/.MainActivity

# Wait for app to load
sleep 5

# Take screenshot
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_start.png

# Simulate user interactions
echo "Performing UI interactions..."
adb -s $ADB_DEVICE_SERIAL shell input tap 500 1000  # Tap login button
sleep 2

adb -s $ADB_DEVICE_SERIAL shell input tap 500 1500  # Tap main screen
sleep 3

# Take final screenshot
adb -s $ADB_DEVICE_SERIAL exec-out screencap -p > test_result/screenshot_end.png

echo "UI automation completed successfully"
```

## 🌍 Environment Variables

The following environment variables are automatically exported for your scripts:

| Variable | Description | Example |
|----------|-------------|---------|
| `ADB_DEVICE_SERIAL` | Serial number of the emulator device | `emulator-5554` |
| `PACKAGE_NAME` | Package name extracted from APK | `com.example.app` |

## 🔧 Matrix Testing

Test across multiple configurations:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-13]
    api-level: [28, 29, 30]
    
runs-on: ${{ matrix.os }}
steps:
  - name: Test APK
    uses: SweetRainGarden/SrgGactionEmulatorenvsetupAndroid@main
    with:
      apk-path: './app.apk'
      api-level: ${{ matrix.api-level }}
```

## 🐛 Troubleshooting

### Common Issues

**APK Installation Fails**
```bash
# Check APK file exists and is valid
ls -la ./app.apk
aapt dump badging ./app.apk
```

**Scripts Not Executing**
```bash
# Ensure scripts are executable
chmod +x ./scripts/*.sh
```

**Emulator Connection Issues**
```bash
# Debug emulator state
adb devices
adb shell getprop sys.boot_completed
```

### Debug Steps

Add debugging information to your workflow:

```yaml
    - name: Debug Environment
      run: |
        echo "=== Environment Debug ==="
        adb devices
        adb shell getprop ro.build.version.release
        adb shell pm list packages | grep -i ${{ steps.emulator.outputs.package-name }}
```

## 🏗️ Architecture

This action is built on top of:

- **[reactivecircus/android-emulator-runner](https://github.com/ReactiveCircus/android-emulator-runner)** - Reliable emulator management
- **Custom APK installation logic** - Package name extraction with aapt
- **Script execution framework** - Environment variable exports and error handling
- **GitHub Actions integration** - Comprehensive outputs and Step Summary reporting

## 📊 GitHub Step Summary

The action automatically generates detailed progress reports in GitHub Actions Step Summary, including:

- ✅ Configuration details and progress tracking
- 📱 APK installation status and package information  
- 🔧 Script execution results and timing
- 📸 Screenshot information (when generated by scripts)
- ⚠️ Warnings and error details for debugging

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ReactiveCircus](https://github.com/ReactiveCircus) for the excellent android-emulator-runner
- The Android development community for testing and feedback