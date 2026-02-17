import 'dart:io';
import 'package:process_run/shell.dart';

class USBDriverHelper {
  /// Check if CH340 drivers are installed (Windows)
  static Future<bool> isCH340DriverInstalled() async {
    if (!Platform.isWindows) return true; // Only check on Windows

    try {
      final shell = Shell();

      // Query device manager for CH340 devices
      final result = await shell.run(
        'wmic path Win32_PnPEntity where "Caption like \'%CH340%\'" get Caption /format:list',
      );

      // If we find CH340 devices, driver is installed
      return result.first.stdout.toString().contains('CH340');
    } catch (e) {
      // If query fails, assume driver might not be installed
      return false;
    }
  }

  /// Check if CP210x drivers are installed (Windows)
  static Future<bool> isCP210xDriverInstalled() async {
    if (!Platform.isWindows) return true; // Only check on Windows

    try {
      final shell = Shell();

      // Query device manager for CP210x devices
      final result = await shell.run(
        'wmic path Win32_PnPEntity where "Caption like \'%CP210%\' or Caption like \'%Silicon Labs%\'" get Caption /format:list',
      );

      // If we find CP210x/Silicon Labs devices, driver is installed
      final output = result.first.stdout.toString();
      return output.contains('CP210') || output.contains('Silicon Labs');
    } catch (e) {
      return false;
    }
  }

  /// Check for unknown devices that might need drivers
  static Future<List<String>> getUnknownDevices() async {
    if (!Platform.isWindows) return [];

    try {
      final shell = Shell();

      // Find devices with problems (Code 28 = drivers not installed)
      final result = await shell.run(
        'wmic path Win32_PnPEntity where "ConfigManagerErrorCode=28" get Caption /format:list',
      );

      List<String> unknownDevices = [];
      final output = result.first.stdout.toString();

      // Parse output
      final lines = output.split('\n');
      for (var line in lines) {
        if (line.contains('Caption=') && line.trim().isNotEmpty) {
          final deviceName = line.split('Caption=')[1].trim();
          if (deviceName.isNotEmpty) {
            unknownDevices.add(deviceName);
          }
        }
      }

      return unknownDevices;
    } catch (e) {
      return [];
    }
  }

  /// Download CH340 driver
  static Future<String?> downloadCH340Driver() async {
    // Driver download URL
    const driverUrl =
        'https://github.com/nodemcu/nodemcu-devkit/raw/master/Drivers/CH341SER.EXE';

    try {
      final tempDir = Directory.systemTemp;
      final driverPath = '${tempDir.path}\\CH341SER.EXE';

      // Download using PowerShell
      final shell = Shell();
      await shell.run(
        'powershell -Command "Invoke-WebRequest -Uri \'$driverUrl\' -OutFile \'$driverPath\'"',
      );

      return driverPath;
    } catch (e) {
      print('Failed to download CH340 driver: $e');
      return null;
    }
  }

  /// Download CP210x driver
  static Future<String?> downloadCP210xDriver() async {
    // Silicon Labs CP210x driver URL (you'll need to host this or use official link)
    const driverUrl =
        'https://www.silabs.com/documents/public/software/CP210x_Universal_Windows_Driver.zip';

    try {
      final tempDir = Directory.systemTemp;
      final zipPath = '${tempDir.path}\\CP210x_Driver.zip';

      // Download using PowerShell
      final shell = Shell();
      await shell.run(
        'powershell -Command "Invoke-WebRequest -Uri \'$driverUrl\' -OutFile \'$zipPath\'"',
      );

      // Extract zip
      final extractPath = '${tempDir.path}\\CP210x_Driver';
      await shell.run(
        'powershell -Command "Expand-Archive -Path \'$zipPath\' -DestinationPath \'$extractPath\' -Force"',
      );

      // Return path to installer
      return '$extractPath\\CP210xVCPInstaller_x64.exe';
    } catch (e) {
      print('Failed to download CP210x driver: $e');
      return null;
    }
  }

  /// Install driver (requires admin)
  static Future<bool> installDriver(String driverPath) async {
    try {
      final shell = Shell();

      // Run installer with admin privileges
      await shell.run(
        'powershell -Command "Start-Process -FilePath \'$driverPath\' -Verb RunAs -Wait"',
      );

      return true;
    } catch (e) {
      print('Failed to install driver: $e');
      return false;
    }
  }

  /// Open driver download page in browser
  static Future<void> openCH340DriverPage() async {
    const url = 'https://sparks.gogo.co.nz/ch340.html';

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', url]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  }

  /// Open CP210x driver download page
  static Future<void> openCP210xDriverPage() async {
    const url =
        'https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers';

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', url]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  }

  /// Comprehensive driver check
  static Future<DriverStatus> checkDriverStatus() async {
    if (!Platform.isWindows) {
      return DriverStatus(
        ch340Installed: true,
        cp210xInstalled: true,
        unknownDevices: [],
        needsDrivers: false,
      );
    }

    final ch340 = await isCH340DriverInstalled();
    final cp210x = await isCP210xDriverInstalled();
    final unknown = await getUnknownDevices();

    return DriverStatus(
      ch340Installed: ch340,
      cp210xInstalled: cp210x,
      unknownDevices: unknown,
      needsDrivers: unknown.isNotEmpty || (!ch340 && !cp210x),
    );
  }
}

class DriverStatus {
  final bool ch340Installed;
  final bool cp210xInstalled;
  final List<String> unknownDevices;
  final bool needsDrivers;

  DriverStatus({
    required this.ch340Installed,
    required this.cp210xInstalled,
    required this.unknownDevices,
    required this.needsDrivers,
  });

  @override
  String toString() {
    return 'DriverStatus(CH340: $ch340Installed, CP210x: $cp210xInstalled, Unknown: ${unknownDevices.length})';
  }
}
