# USB Driver Files

This folder should contain the USB-to-serial drivers for ESP32 communication.

## Required Files

To build the installer with driver support, place these files in this folder:

### 1. CH340 Driver
- **Filename:** `CH34x_Install_Windows_v3_4.EXE`
- **Download:** https://sparks.gogo.co.nz/ch340.html
- **Size:** ~238 KB

### 2. CP210x Driver  
- **Filename:** `CP201x_Windows_Drivers.exe`
- **Download:** https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
- **Size:** ~1 MB
- **Note:** Download the "CP210x VCP Windows" version

## After Downloading

Your `drivers/` folder should contain:
```
drivers/
├── CH34x_Install_Windows_v3_4.EXE
└── CP201x_Windows_Drivers.exe
```

Then you can build the installer which will include these drivers.

## For End Users

End users don't need to download these separately - they're included in the installer and installed automatically if needed.
