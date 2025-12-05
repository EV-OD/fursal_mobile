import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/domain/booking.dart';
import '../../../core/theme.dart';

class ManagerScanQRScreen extends ConsumerStatefulWidget {
  const ManagerScanQRScreen({super.key});

  @override
  ConsumerState<ManagerScanQRScreen> createState() =>
      _ManagerScanQRScreenState();
}

class _ManagerScanQRScreenState extends ConsumerState<ManagerScanQRScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final code = barcode.rawValue!;

        setState(() {
          _isProcessing = true;
        });

        // Fetch booking
        final booking =
            await ref.read(bookingRepositoryProvider).getBookingById(code);

        if (mounted) {
          _showVerificationDialog(context, booking, code);
        }
        break; // Process only first valid code
      }
    }
  }

  void _showVerificationDialog(
      BuildContext context, Booking? booking, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              booking != null ? Icons.check_circle : Icons.error,
              color: booking != null ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(booking != null ? 'Booking Verified' : 'Invalid QR'),
          ],
        ),
        content: booking != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Customer:', booking.userId),
                  _infoRow('Venue:', booking.venueName),
                  _infoRow('Date:', booking.date),
                  _infoRow(
                      'Time:', '${booking.startTime} - ${booking.endTime}'),
                  _infoRow('Status:', booking.status.toUpperCase(),
                      isStatus: true),
                  const Divider(),
                  if (booking.status == 'confirmed')
                    const Text(
                      'This booking is valid.',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  else
                    Text(
                      'Warning: Booking is ${booking.status}.',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    )
                ],
              )
            : Text('No booking found for code: $code'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isProcessing = false;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Scan Next'),
          ),
          if (booking != null)
            ElevatedButton(
              onPressed: () {
                context.push('/manager/bookings');
                setState(() {
                  _isProcessing = false;
                });
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child: const Text('View Details',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500),
              )),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isStatus
                      ? (value == 'CONFIRMED' ? Colors.green : Colors.red)
                      : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Booking QR',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.orange);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.blue);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  default:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner markers or scan animation could go here
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
