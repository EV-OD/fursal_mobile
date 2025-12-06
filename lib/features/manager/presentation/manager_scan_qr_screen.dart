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

        // Feedback sound or vibration could go here

        try {
          // Fetch booking
          final booking =
              await ref.read(bookingRepositoryProvider).getBookingById(code);

          if (mounted) {
            _showVerificationSheet(context, booking, code);
          }
        } catch (e) {
          if (mounted) {
            _showVerificationSheet(context, null, code);
          }
        }
        break; // Process only first valid code
      }
    }
  }

  void _showVerificationSheet(
      BuildContext context, Booking? booking, String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false, // Prevent accidental dismissal during processing
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (booking != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: booking.status == 'confirmed'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    booking.status == 'confirmed'
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 48,
                    color: booking.status == 'confirmed'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                booking.status == 'confirmed'
                    ? 'Booking Verified'
                    : 'Booking Status: ${booking.status.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Customer',
                value: booking.userId, // Use name if available
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.stadium_outlined,
                label: 'Venue',
                value: booking.venueName,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date & Time',
                value:
                    '${booking.date}\n${booking.startTime} - ${booking.endTime}',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isProcessing = false;
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Scan Next'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/manager/bookings');
                        setState(() {
                          _isProcessing = false;
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Invalid QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No booking found for the scanned code.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Code: $code',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isProcessing = false;
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    ).then((_) {
      // Reset processing state if sheet is dismissed by other means
      if (_isProcessing) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.amber);
                  default:
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
                return Icon(Icons.cameraswitch_outlined, color: Colors.white);
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
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppTheme.primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Align QR code within the frame',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(0, 1),
                        )
                      ]),
                ),
                SizedBox(height: 8),
                Text(
                  'Scanning will start automatically',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;

    // Calculate cut-out rect
    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutSize / 2 + borderOffset,
      rect.top +
          height / 2 -
          cutOutSize / 2 +
          borderOffset -
          cutOutBottomOffset,
      cutOutSize - borderOffset * 2,
      cutOutSize - borderOffset * 2,
    );

    // Draw Overlay
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)));

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw Border Corners
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final borderPath = Path();

    // Top left
    borderPath.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    borderPath.lineTo(cutOutRect.left, cutOutRect.top);
    borderPath.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top right
    borderPath.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    borderPath.lineTo(cutOutRect.right, cutOutRect.top);
    borderPath.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom right
    borderPath.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    borderPath.lineTo(cutOutRect.right, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Bottom left
    borderPath.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.left, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
      borderRadius: borderRadius,
      borderLength: borderLength,
      cutOutSize: cutOutSize,
      cutOutBottomOffset: cutOutBottomOffset,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
