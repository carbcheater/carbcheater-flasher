# CarbCheater Flasher

Professional firmware update tool for CarbCheater automotive electronics devices.

![CarbCheater Logo](assets/app_icon.png)

## Overview

CarbCheater Flasher is a Windows desktop application that makes updating your CarbCheater devices simple and reliable. Built with Flutter for a modern, user-friendly experience.

### Supported Devices

- **Carb Cheater Brain Box** - Full-featured engine management controller
- **Carb Cheater Display** - Digital gauge display  
- **Lite Brain Box** - Compact controller version
- **Lite Display** - Compact display version

## Features

 **User-Friendly Interface**
- Large, readable text optimized for all users
- Step-by-step guidance through the update process
- Real-time device detection and connection status

 **Automatic Driver Management**
- Detects CH340 and CP210x USB drivers
- Visual status indicators (installed/not installed)
- Links to official driver downloads when needed

 **Reliable Updates**
- Automatic firmware download from secure API
- Progress tracking during flash process
- Verification after update completes
- Post-update instructions for vehicle calibration

 **Safe & Transparent**
- Open source code - nothing to hide
- Fetches firmware from official CarbCheater servers
- Confirmation dialogs prevent accidental updates
- Warning alerts during critical operations

## Installation

### For End Users

1. Download the latest installer: `CarbCheaterFlasher_Setup_v1.0.0.exe`
2. Run the installer (you may need to click "More info" → "Run anyway" on Windows SmartScreen)
3. The installer will optionally install USB drivers if needed
4. Launch from Start Menu or Desktop

### For Developers

```bash
# Clone the repository
git clone https://github.com/carbcheater/carbcheater-flasher.git
'''

#### Prerequisites

- Flutter SDK (3.0+)
- Windows 10/11 SDK
- Visual Studio 2019 or later with C++ tools
- Inno Setup (for building installer)

#### Build Instructions

```bash
# Clone the repository
git clone https://github.com/carbcheater/carbcheater-flasher.git
cd carbcheater-flasher

# Get dependencies
flutter pub get

# Run in development
flutter run -d windows

# Build release
flutter build windows --release
```

#### USB Drivers

The application requires USB-to-serial drivers for ESP32 communication:

- **CH340 Driver**: Download from [Sparks GoGo](https://sparks.gogo.co.nz/ch340.html)
- **CP210x Driver**: Download from [Silicon Labs](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)

Place driver installers in `drivers/` folder for inclusion in the installer.

#### Building the Installer

```bash
# After building the release, compile the Inno Setup script
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\installer_with_drivers.iss

# Output: installer\installer_output\CarbCheaterFlasher_Setup_v1.0.0.exe
```

## How It Works

1. **Device Connection**: Automatically scans COM ports for connected ESP32 devices
2. **Firmware Selection**: Fetches available firmware versions from CarbCheater API
3. **Download & Flash**: Downloads firmware files and flashes them to the device using esptool
4. **Verification**: Confirms successful flash and provides next steps

## Architecture

- **Frontend**: Flutter (Dart) - Cross-platform UI framework
- **Flashing**: esptool.py - Industry-standard ESP32 flash tool
- **Driver Detection**: Windows WMI queries for installed USB drivers
- **API**: RESTful JSON endpoints serving firmware metadata and binaries

## Firmware Privacy

This repository contains only the **flasher application**. Actual firmware binaries are:
- Hosted privately on CarbCheater servers
- Downloaded on-demand during updates
- Not included in this open-source code

## API Endpoints

The app connects to these CarbCheater API endpoints:

- Brain Box: `https://thecarbcheater.com/firmware-api.php?action=list`
- Display: `https://thecarbcheater.com/display-firmware-api.php?action=list`
- Lite Brain Box: `https://thecarbcheater.com/lite-firmware-api.php?action=list`
- Lite Display: `https://thecarbcheater.com/lite-display-firmware-api.php?action=list`

## Contributing

We welcome contributions! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details

## Support

- **Website**: https://thecarbcheater.com
- **Issues**: https://github.com/carbcheater/carbcheater-flasher/issues

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Uses [esptool](https://github.com/espressif/esptool) for ESP32 flashing
- Installer created with [Inno Setup](https://jrsoftware.org/isinfo.php)

---

**Note**: This is the firmware update tool only. For firmware itself, vehicle compatibility, and tuning services, visit [thecarbcheater.com](https://thecarbcheater.com).
