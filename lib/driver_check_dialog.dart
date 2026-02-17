import 'package:flutter/material.dart';
import 'usb_driver_helper.dart';

class DriverCheckDialog extends StatefulWidget {
  const DriverCheckDialog({super.key});

  @override
  State<DriverCheckDialog> createState() => _DriverCheckDialogState();
}

class _DriverCheckDialogState extends State<DriverCheckDialog> {
  bool isChecking = true;
  DriverStatus? driverStatus;

  @override
  void initState() {
    super.initState();
    _checkDrivers();
  }

  Future<void> _checkDrivers() async {
    setState(() => isChecking = true);
    final status = await USBDriverHelper.checkDriverStatus();
    setState(() {
      driverStatus = status;
      isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1F3A),
              Color(0xFF0A0E27),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isChecking
                        ? Colors.blue
                        : (driverStatus?.needsDrivers ?? false)
                            ? Colors.orange
                            : const Color(0xFF00D4AA),
                    isChecking
                        ? Colors.blue.withOpacity(0.6)
                        : (driverStatus?.needsDrivers ?? false)
                            ? Colors.orange.withOpacity(0.6)
                            : const Color(0xFF00A896),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isChecking
                            ? Colors.blue
                            : (driverStatus?.needsDrivers ?? false)
                                ? Colors.orange
                                : const Color(0xFF00D4AA))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isChecking
                    ? Icons.search
                    : (driverStatus?.needsDrivers ?? false)
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              isChecking
                  ? 'Checking USB Drivers...'
                  : (driverStatus?.needsDrivers ?? false)
                      ? 'Driver Installation Needed'
                      : 'Drivers OK!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Status
            if (isChecking)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              )
            else if (driverStatus != null) ...[
              // Driver status list
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildDriverStatusRow(
                      'CH340 Driver',
                      driverStatus!.ch340Installed,
                      Icons.memory,
                    ),
                    const SizedBox(height: 12),
                    _buildDriverStatusRow(
                      'CP210x Driver',
                      driverStatus!.cp210xInstalled,
                      Icons.usb,
                    ),
                    if (driverStatus!.unknownDevices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.orange[300],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${driverStatus!.unknownDevices.length} unknown device(s) detected',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Message
              Text(
                driverStatus!.needsDrivers
                    ? 'USB drivers are required to communicate with your ESP32. Click below to install them.'
                    : 'All required USB drivers are installed. You\'re ready to flash!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              if (driverStatus!.needsDrivers) ...[
                // Install buttons
                if (!driverStatus!.ch340Installed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await USBDriverHelper.openCH340DriverPage();
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download CH340 Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (!driverStatus!.ch340Installed &&
                    !driverStatus!.cp210xInstalled)
                  const SizedBox(height: 12),
                if (!driverStatus!.cp210xInstalled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await USBDriverHelper.openCP210xDriverPage();
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download CP210x Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checkDrivers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Re-check Drivers'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStatusRow(String name, bool installed, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (installed ? const Color(0xFF00D4AA) : Colors.orange)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: installed ? const Color(0xFF00D4AA) : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Icon(
          installed ? Icons.check_circle : Icons.cancel,
          color: installed ? const Color(0xFF00D4AA) : Colors.orange,
          size: 24,
        ),
      ],
    );
  }
}

// Helper function to show the dialog
Future<void> showDriverCheckDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const DriverCheckDialog(),
  );
}
