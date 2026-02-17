import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'esptool_helper.dart';
import 'usb_driver_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set window size for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Note: This requires adding window_manager package to pubspec.yaml
    // For now, the window will use system defaults
    // We'll handle sizing in the scaffold
  }

  runApp(const CarbCheaterFlasherApp());
}

// Product configuration
enum ProductType {
  brainBox,
  display,
  liteBrainBox,
  liteDisplay,
}

class ProductConfig {
  final String name;
  final String apiUrl;
  final IconData icon;
  final Color accentColor;

  ProductConfig({
    required this.name,
    required this.apiUrl,
    required this.icon,
    required this.accentColor,
  });
}

final Map<ProductType, ProductConfig> productConfigs = {
  ProductType.brainBox: ProductConfig(
    name: 'Carb Cheater Brain Box',
    apiUrl: 'https://thecarbcheater.com/firmware-api.php?action=list',
    icon: Icons.developer_board, // Represents the ECU brain box
    accentColor: const Color(0xFF00D4AA),
  ),
  ProductType.display: ProductConfig(
    name: 'Display',
    apiUrl: 'https://thecarbcheater.com/display-firmware-api.php?action=list',
    icon: Icons.dashboard_customize,
    accentColor: const Color(0xFF6C5CE7),
  ),
  ProductType.liteBrainBox: ProductConfig(
    name: 'Lite Brain Box',
    apiUrl: 'https://thecarbcheater.com/lite-firmware-api.php?action=list',
    icon: Icons.developer_board, // Same as Brain Box, different color
    accentColor: const Color(0xFFFF6B6B),
  ),
  ProductType.liteDisplay: ProductConfig(
    name: 'Lite Display',
    apiUrl:
        'https://thecarbcheater.com/lite-display-firmware-api.php?action=list',
    icon: Icons.dashboard_customize, // Same as Display, different color
    accentColor: const Color(0xFFFECA57),
  ),
};

class CarbCheaterFlasherApp extends StatelessWidget {
  const CarbCheaterFlasherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarbCheater Flasher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4AA),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        fontFamily: 'SF Pro Display',
        // Increase default text sizes for older users
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      home: const ProductSelectionScreen(),
    );
  }
}

// Main Menu Screen
class ProductSelectionScreen extends StatelessWidget {
  const ProductSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00A896)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'CarbCheater',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Firmware Flasher',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        'Select Your Product',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Grid
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: const EdgeInsets.all(24.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1.1,
                        children: [
                          _buildProductCard(
                            context,
                            ProductType.brainBox,
                          ),
                          _buildProductCard(
                            context,
                            ProductType.display,
                          ),
                          _buildProductCard(
                            context,
                            ProductType.liteBrainBox,
                          ),
                          _buildProductCard(
                            context,
                            ProductType.liteDisplay,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductType type) {
    final config = productConfigs[type]!;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlasherHomePage(productType: type),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient accent in corner
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      config.accentColor.withOpacity(0.3),
                      config.accentColor.withOpacity(0),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: config.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: config.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        config.icon,
                        size: 48,
                        color: config.accentColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      config.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: config.accentColor.withOpacity(0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model classes for firmware data
class FirmwareFile {
  final String name;
  final String address;
  final int addressInt;
  final String url;
  final int size;

  FirmwareFile({
    required this.name,
    required this.address,
    required this.addressInt,
    required this.url,
    required this.size,
  });

  factory FirmwareFile.fromJson(Map<String, dynamic> json) {
    return FirmwareFile(
      name: json['name'],
      address: json['address'],
      addressInt: json['address_int'],
      url: json['url'],
      size: json['size'],
    );
  }
}

class FirmwareVersion {
  final String version;
  final String type;
  final String displayName;
  final String description;
  final String releaseDate;
  final int totalSize;
  final String totalSizeFormatted;
  final List<FirmwareFile> files;

  FirmwareVersion({
    required this.version,
    required this.type,
    required this.displayName,
    required this.description,
    required this.releaseDate,
    required this.totalSize,
    required this.totalSizeFormatted,
    required this.files,
  });

  factory FirmwareVersion.fromJson(Map<String, dynamic> json) {
    var filesList = json['files'] as List;
    List<FirmwareFile> files =
        filesList.map((file) => FirmwareFile.fromJson(file)).toList();

    return FirmwareVersion(
      version: json['version'],
      type: json['type'],
      displayName: json['display_name'],
      description: json['description'],
      releaseDate: json['release_date'],
      totalSize: json['total_size'],
      totalSizeFormatted: json['total_size_formatted'],
      files: files,
    );
  }
}

// Flasher Screen (updated to use product config)
class FlasherHomePage extends StatefulWidget {
  final ProductType productType;

  const FlasherHomePage({super.key, required this.productType});

  @override
  State<FlasherHomePage> createState() => _FlasherHomePageState();
}

class _FlasherHomePageState extends State<FlasherHomePage>
    with TickerProviderStateMixin {
  String? selectedPort;
  FirmwareVersion? selectedFirmware;
  bool isUpdating = false;
  bool isLoadingFirmware = false;
  double updateProgress = 0.0;
  String statusMessage = 'Ready to flash';
  List<String> availablePorts = [];
  List<FirmwareVersion> availableFirmware = [];
  String? errorMessage;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  Timer? _portScanTimer;

  // Driver status
  bool ch340Installed = false;
  bool cp210xInstalled = false;
  bool checkingDrivers = true;
  bool ch340Connected = false;
  bool cp210xConnected = false;

  ProductConfig get config => productConfigs[widget.productType]!;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _detectPorts();
    _fetchFirmwareList();
    _checkDriverStatus();

    // Start automatic port scanning every 2 seconds
    _portScanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!isUpdating) {
        _detectPorts();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _portScanTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkDriverStatus() async {
    final status = await USBDriverHelper.checkDriverStatus();
    setState(() {
      ch340Installed = status.ch340Installed;
      cp210xInstalled = status.cp210xInstalled;
      checkingDrivers = false;
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _detectPorts() {
    try {
      final ports = SerialPort.availablePorts;
      List<String> detectedPorts = [];
      List<String> esp32Ports = [];
      bool foundCH340 = false;
      bool foundCP210x = false;

      for (final portName in ports) {
        try {
          final port = SerialPort(portName);
          final description = port.description ?? '';
          final manufacturer = port.manufacturer ?? '';

          bool isCH340 = description.contains('CH340');
          bool isCP210x = description.contains('CP210') ||
              manufacturer.contains('Silicon Labs');

          bool isESP32 = isCH340 ||
              isCP210x ||
              description.contains('USB-SERIAL') ||
              manufacturer.contains('QinHeng');

          if (isCH340) foundCH340 = true;
          if (isCP210x) foundCP210x = true;

          if (isESP32) {
            final portLabel =
                '$portName (${description.isEmpty ? manufacturer : description})';
            detectedPorts.add(portLabel);
            esp32Ports.add(portLabel);
          } else {
            detectedPorts.add(portName);
          }

          port.dispose();
        } catch (e) {
          detectedPorts.add(portName);
        }
      }

      // Only update if ports list actually changed
      bool portsChanged = detectedPorts.length != availablePorts.length ||
          !detectedPorts.every((port) => availablePorts.contains(port)) ||
          foundCH340 != ch340Connected ||
          foundCP210x != cp210xConnected;

      if (portsChanged) {
        setState(() {
          ch340Connected = foundCH340;
          cp210xConnected = foundCP210x;

          if (detectedPorts.isEmpty) {
            availablePorts = [];
            statusMessage = 'No devices detected';
            // Clear selection if device was unplugged
            if (selectedPort != null) {
              selectedPort = null;
            }
          } else {
            availablePorts = detectedPorts;

            // Auto-select if exactly one ESP32 port is found
            if (esp32Ports.length == 1 && selectedPort == null) {
              selectedPort = esp32Ports.first;
              // Check if firmware is also selected for combined message
              if (selectedFirmware != null) {
                statusMessage = 'Ready to flash!';
              } else {
                statusMessage = 'Auto-selected: ${esp32Ports.first}';
              }
            }
            // Only update status if we're not updating
            else if (!isUpdating && updateProgress == 0) {
              // Show ready message if both are selected
              if (selectedPort != null && selectedFirmware != null) {
                statusMessage = 'Ready to flash!';
              } else {
                statusMessage = 'Found ${detectedPorts.length} device(s)';
              }
            }

            // If selected port is no longer available, clear it
            if (selectedPort != null &&
                !availablePorts.contains(selectedPort)) {
              selectedPort = null;
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        availablePorts = [];
        statusMessage = 'Error detecting ports';
      });
    }
  }

  Future<void> _fetchFirmwareList() async {
    setState(() {
      isLoadingFirmware = true;
      errorMessage = null;
      statusMessage = 'Fetching firmware...';
    });

    try {
      final response = await http.get(Uri.parse(config.apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<FirmwareVersion> firmwareList = [];
          for (var fw in data['firmware']) {
            firmwareList.add(FirmwareVersion.fromJson(fw));
          }

          setState(() {
            availableFirmware = firmwareList;
            isLoadingFirmware = false;

            // Auto-select latest firmware if available and nothing is selected
            if (firmwareList.isNotEmpty && selectedFirmware == null) {
              selectedFirmware = firmwareList.first; // First in list is latest
              statusMessage =
                  'Auto-selected latest: ${firmwareList.first.displayName}';
            } else {
              statusMessage =
                  '${firmwareList.length} firmware version(s) available';
            }
          });
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load firmware list');
      }
    } catch (e) {
      setState(() {
        isLoadingFirmware = false;
        errorMessage = 'Failed to fetch firmware: $e';
        statusMessage = 'Error loading firmware';
      });
      _showError('Could not fetch firmware list');
    }
  }

  Future<void> _startUpdate() async {
    if (selectedPort == null || selectedFirmware == null) {
      _showError('Please select both a device and firmware version');
      return;
    }

    setState(() {
      isUpdating = true;
      updateProgress = 0.0;
      statusMessage = 'Preparing...';
      errorMessage = null;
    });

    try {
      final espToolAvailable = await ESPToolHelper.isESPToolAvailable();
      if (!espToolAvailable) {
        throw Exception(
            'esptool not found! Please place esptool.exe in the tools folder.');
      }

      setState(() {
        statusMessage = 'Downloading firmware...';
        updateProgress = 0.1;
      });

      final tempDir = await getTemporaryDirectory();
      final firmwareDir =
          Directory('${tempDir.path}/firmware_${selectedFirmware!.version}');

      if (!await firmwareDir.exists()) {
        await firmwareDir.create(recursive: true);
      }

      final files = selectedFirmware!.files;
      List<Map<String, String>> downloadedFiles = [];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        setState(() {
          statusMessage = 'Downloading ${file.name}...';
          updateProgress = 0.1 + ((i / files.length) * 0.2);
        });

        final response = await http.get(Uri.parse(file.url));
        if (response.statusCode == 200) {
          final filePath = '${firmwareDir.path}/${file.name}.bin';
          final localFile = File(filePath);
          await localFile.writeAsBytes(response.bodyBytes);

          downloadedFiles.add({
            'address': file.address,
            'path': filePath,
            'name': file.name,
            'size': file.size.toString(),
          });
        } else {
          throw Exception('Failed to download ${file.name}');
        }
      }

      setState(() {
        statusMessage = 'Starting flash...';
        updateProgress = 0.3;
      });

      await ESPToolHelper.flashMultipleFiles(
        port: selectedPort!,
        files: downloadedFiles,
        onOutput: (String output) {
          print('esptool: $output');
        },
        onProgress: (double progress) {
          setState(() {
            // Map esptool's 0-100% to our 30-100% range
            // 0% esptool = 30% overall, 100% esptool = 100% overall
            updateProgress = 0.3 + (progress * 0.7);
          });
        },
        onStage: (String stage) {
          setState(() {
            statusMessage = stage;
          });
        },
      );

      setState(() {
        updateProgress = 1.0;
        statusMessage = 'Flash complete!';
        isUpdating = false;
      });

      _showSuccess(
          'Firmware ${selectedFirmware!.version} installed successfully!');
    } catch (e) {
      setState(() {
        isUpdating = false;
        errorMessage = e.toString();
        statusMessage = 'Flash failed';
      });
      _showError('Update failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF4757),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F3A), Color(0xFF0A0E27)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      config.accentColor,
                      config.accentColor.withOpacity(0.6)
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: config.accentColor.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle,
                    size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Update Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              if (widget.productType == ProductType.brainBox ||
                  widget.productType == ProductType.liteBrainBox)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Steps:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: config.accentColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildNextStep(
                          '1', 'Unplug your device from the computer'),
                      const SizedBox(height: 12),
                      _buildNextStep('2', 'Plug it back into your vehicle'),
                      const SizedBox(height: 12),
                      _buildNextStep('3',
                          'Key on with engine OFF for 30 seconds, then key back OFF for 30 seconds to calibrate MAP sensor'),
                      const SizedBox(height: 12),
                      _buildNextStep('4', 'Start your engine'),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      updateProgress = 0.0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            config.accentColor,
                            config.accentColor.withOpacity(0.7)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: config.accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        config.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Firmware Flasher',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: isUpdating ? null : _detectPorts,
                      icon: const Icon(Icons.refresh_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                      ),
                      tooltip: 'Refresh devices',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: isUpdating || isLoadingFirmware
                          ? null
                          : _fetchFirmwareList,
                      icon: const Icon(Icons.cloud_download_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                      ),
                      tooltip: 'Refresh firmware',
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 700),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Device Selection
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: config.accentColor
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.usb_rounded,
                                        color: config.accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Device',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (availablePorts.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Colors.orange[300],
                                            size: 32),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Device not found',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18,
                                                  color: Colors.orange[300],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Make sure your device is plugged into a USB port on your computer, then wait a few seconds.',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white70,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      dropdownColor: const Color(0xFF1A1F3A),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                      hint: Text(
                                        'Select device...',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                      value: selectedPort,
                                      items: availablePorts.map((port) {
                                        return DropdownMenuItem(
                                          value: port,
                                          child: Text(port),
                                        );
                                      }).toList(),
                                      onChanged: isUpdating
                                          ? null
                                          : (value) {
                                              setState(() {
                                                selectedPort = value;
                                                statusMessage =
                                                    'Device selected';
                                              });
                                            },
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Firmware Selection (same UI, different API endpoint based on product)
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: config.accentColor
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.settings_suggest_rounded,
                                        color: config.accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Firmware',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (isLoadingFirmware)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(
                                        color: config.accentColor,
                                      ),
                                    ),
                                  )
                                else if (availableFirmware.isEmpty)
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.cloud_off_rounded,
                                          size: 48,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No firmware available',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: DropdownButtonFormField<
                                            FirmwareVersion>(
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          dropdownColor:
                                              const Color(0xFF1A1F3A),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                          hint: Text(
                                            'Select firmware version...',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                            ),
                                          ),
                                          value: selectedFirmware,
                                          items:
                                              availableFirmware.map((firmware) {
                                            return DropdownMenuItem(
                                              value: firmware,
                                              child: Row(
                                                children: [
                                                  Text(firmware.displayName),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: firmware.type ==
                                                              'stable'
                                                          ? config.accentColor
                                                          : Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      firmware.type
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: isUpdating
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    selectedFirmware = value;
                                                    statusMessage =
                                                        'Firmware selected';
                                                  });
                                                },
                                        ),
                                      ),
                                      if (selectedFirmware != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: config.accentColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: config.accentColor
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.notes,
                                                    size: 16,
                                                    color: config.accentColor
                                                        .withOpacity(0.8),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Release Notes',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: config.accentColor
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                selectedFirmware!
                                                        .description.isNotEmpty
                                                    ? selectedFirmware!
                                                        .description
                                                    : 'Version ${selectedFirmware!.displayName}\nReleased: ${_formatDate(selectedFirmware!.releaseDate)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Progress Card
                          if (isUpdating || updateProgress > 0)
                            _buildGlassCard(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        statusMessage,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${(updateProgress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: config.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: updateProgress,
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  config.accentColor,
                                                  config.accentColor
                                                      .withOpacity(0.7),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: config.accentColor
                                                      .withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (!isUpdating && updateProgress == 0)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: errorMessage != null
                                          ? Colors.red
                                          : config.accentColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (errorMessage != null
                                                  ? Colors.red
                                                  : config.accentColor)
                                              .withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    statusMessage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Flash Button - Larger for older users
                          SizedBox(
                            width: double.infinity,
                            height: 70,
                            child: ElevatedButton(
                              onPressed: isUpdating ||
                                      isLoadingFirmware ||
                                      selectedPort == null ||
                                      selectedFirmware == null
                                  ? null
                                  : () => _confirmAndStartUpdate(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: config.accentColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.white.withOpacity(0.1),
                                disabledForegroundColor:
                                    Colors.white.withOpacity(0.3),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isUpdating
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text(
                                          'Updating...',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.flash_on_rounded,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text(
                                          'Update Firmware',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Driver Status Bar at Bottom
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (checkingDrivers)
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Checking drivers...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'USB Drivers: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          _buildDriverBadge('CH340', ch340Installed),
                          const SizedBox(width: 8),
                          _buildDriverBadge('CP210x', cp210xInstalled),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverBadge(String name, bool installed) {
    // Determine the status based on driver and connection
    bool isConnected = (name == 'CH340' && ch340Connected) ||
        (name == 'CP210x' && cp210xConnected);

    Color statusColor;
    IconData statusIcon;

    if (!installed) {
      // Red: Driver not installed
      statusColor = const Color(0xFFFF4757);
      statusIcon = Icons.cancel;
    } else if (!isConnected) {
      // Yellow: Driver installed but not connected
      statusColor = const Color(0xFFFECA57);
      statusIcon = Icons.remove_circle;
    } else {
      // Green: Driver installed and connected
      statusColor = const Color(0xFF00D4AA);
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepGuide() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.accentColor.withOpacity(0.15),
            config.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: config.accentColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                'How to Update',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideStep('1', 'Connect your device via USB cable',
              Icons.usb_rounded, selectedPort != null),
          const SizedBox(height: 12),
          _buildGuideStep('2', 'Select a firmware version below',
              Icons.download_rounded, selectedFirmware != null),
          const SizedBox(height: 12),
          _buildGuideStep('3', 'Click the "Update Firmware" button',
              Icons.flash_on_rounded, false),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
      String number, String text, IconData icon, bool completed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed
            ? config.accentColor.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? config.accentColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: completed
                  ? config.accentColor
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text(
                      number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17,
                color: completed ? Colors.white : Colors.white70,
                fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Icon(icon, color: config.accentColor.withOpacity(0.6), size: 24),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: config.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: config.accentColor.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: config.accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndStartUpdate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ready to Update?',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will take about 2 minutes.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange[300], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Do not unplug or close this program during the update!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: config.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Start Update',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _startUpdate();
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }
}
