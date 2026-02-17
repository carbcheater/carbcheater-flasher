import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';

class ESPToolHelper {
  static const String espToolVersion = '4.7.0';

  /// Get the path to esptool executable
  static Future<String> getESPToolPath() async {
    if (Platform.isWindows) {
      // For Windows, we'll bundle esptool.exe
      final appDir = Directory.current.path;
      return '$appDir\\tools\\esptool.exe';
    } else {
      // For Mac/Linux, use Python version
      final appDir = Directory.current.path;
      return '$appDir/tools/esptool.py';
    }
  }

  /// Flash a single firmware file to ESP32
  static Future<void> flashFile({
    required String port,
    required String address,
    required String filePath,
    required Function(String) onOutput,
    required Function(double) onProgress,
  }) async {
    final shell = Shell();

    String espToolPath = await getESPToolPath();

    // Extract just the port name (remove description)
    String portName = port.split(' ').first;

    // Build esptool command
    List<String> command;

    if (Platform.isWindows) {
      command = [
        espToolPath,
        '--chip',
        'esp32',
        '--port',
        portName,
        '--baud',
        '921600',
        '--before',
        'default_reset',
        '--after',
        'hard_reset',
        'write_flash',
        '-z',
        '--flash_mode',
        'dio',
        '--flash_freq',
        '40m',
        '--flash_size',
        'detect',
        address,
        filePath,
      ];
    } else {
      command = [
        'python3',
        espToolPath,
        '--chip',
        'esp32',
        '--port',
        portName,
        '--baud',
        '921600',
        '--before',
        'default_reset',
        '--after',
        'hard_reset',
        'write_flash',
        '-z',
        '--flash_mode',
        'dio',
        '--flash_freq',
        '40m',
        '--flash_size',
        'detect',
        address,
        filePath,
      ];
    }

    onOutput('Executing: ${command.join(' ')}');

    try {
      final process = await Process.start(
        command.first,
        command.sublist(1),
        runInShell: true,
      );

      // Listen to stdout
      process.stdout.transform(SystemEncoding().decoder).listen((data) {
        onOutput(data);

        // Parse progress from esptool output
        // esptool outputs progress like: "Writing at 0x00010000... (10 %)"
        final progressMatch = RegExp(r'\((\d+)\s*%\)').firstMatch(data);
        if (progressMatch != null) {
          final progress = int.parse(progressMatch.group(1)!);
          onProgress(progress / 100.0);
        }
      });

      // Listen to stderr
      process.stderr.transform(SystemEncoding().decoder).listen((data) {
        onOutput('ERROR: $data');
      });

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        throw Exception('esptool exited with code $exitCode');
      }
    } catch (e) {
      throw Exception('Failed to flash: $e');
    }
  }

  /// Flash multiple files (complete firmware update)
  static Future<void> flashMultipleFiles({
    required String port,
    required List<Map<String, String>>
        files, // [{address: '0x1000', path: '/path/to/file.bin'}]
    required Function(String) onOutput,
    required Function(double) onProgress,
    required Function(String) onStage,
  }) async {
    final shell = Shell();

    String espToolPath = await getESPToolPath();

    // Extract just the port name (remove description)
    String portName = port.split(' ').first;

    // Build command to flash all files at once (more efficient)
    List<String> command;

    if (Platform.isWindows) {
      command = [
        espToolPath,
        '--chip',
        'esp32',
        '--port',
        portName,
        '--baud',
        '921600',
        '--before',
        'default_reset',
        '--after',
        'hard_reset',
        'write_flash',
        '-z',
        '--flash_mode',
        'dio',
        '--flash_freq',
        '40m',
        '--flash_size',
        'detect',
      ];
    } else {
      command = [
        'python3',
        espToolPath,
        '--chip',
        'esp32',
        '--port',
        portName,
        '--baud',
        '921600',
        '--before',
        'default_reset',
        '--after',
        'hard_reset',
        'write_flash',
        '-z',
        '--flash_mode',
        'dio',
        '--flash_freq',
        '40m',
        '--flash_size',
        'detect',
      ];
    }

    // Add all files and their addresses
    for (final file in files) {
      command.add(file['address']!);
      command.add(file['path']!);
    }

    onOutput('Executing: ${command.join(' ')}');
    onStage('Connecting to ESP32...');

    try {
      final process = await Process.start(
        command.first,
        command.sublist(1),
        runInShell: true,
      );

      String currentStage = 'Connecting';

      // Listen to stdout
      process.stdout.transform(SystemEncoding().decoder).listen((data) {
        onOutput(data);

        // Detect stage changes
        if (data.contains('Chip is')) {
          currentStage = 'Connected to ESP32';
          onStage(currentStage);
        } else if (data.contains('Erasing flash')) {
          currentStage = 'Erasing flash...';
          onStage(currentStage);
        } else if (data.contains('Writing at 0x')) {
          currentStage = 'Writing firmware...';
          onStage(currentStage);
        } else if (data.contains('Hash of data verified')) {
          currentStage = 'Verifying...';
          onStage(currentStage);
        } else if (data.contains('Hard resetting')) {
          currentStage = 'Rebooting device...';
          onStage(currentStage);
        }

        // Parse progress percentage from esptool output
        final progressMatch = RegExp(r'\((\d+)\s*%\)').firstMatch(data);
        if (progressMatch != null) {
          final espToolPercent = int.parse(progressMatch.group(1)!);
          // Just pass through the percentage directly (0-100%)
          onProgress(espToolPercent / 100.0);
        }
      });

      // Listen to stderr
      process.stderr.transform(SystemEncoding().decoder).listen((data) {
        onOutput('STDERR: $data');
      });

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        throw Exception('esptool exited with code $exitCode');
      }

      onStage('Flash complete!');
      onProgress(1.0);
    } catch (e) {
      throw Exception('Failed to flash: $e');
    }
  }

  /// Check if esptool is available
  static Future<bool> isESPToolAvailable() async {
    try {
      final espToolPath = await getESPToolPath();
      final file = File(espToolPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Download and setup esptool (for first-time setup)
  static Future<void> setupESPTool() async {
    // This would download esptool if not present
    // For now, we'll assume it's bundled with the app
    throw UnimplementedError(
        'Auto-download not implemented yet. Please bundle esptool manually.');
  }
}
