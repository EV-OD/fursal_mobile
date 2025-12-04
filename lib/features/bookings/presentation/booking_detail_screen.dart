import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../domain/booking.dart';
import 'payment_screen.dart';
import 'invoice_preview_screen.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _isGeneratingInvoice = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isExpired = booking.status == 'pending' &&
        booking.holdExpiresAt != null &&
        booking.holdExpiresAt!.toDate().isBefore(DateTime.now());

    final canPay = booking.status == 'pending' && !isExpired;

    // Check if booking is completed (time passed)
    DateTime? endDateTime;
    try {
      endDateTime = DateTime.parse('${booking.date} ${booking.endTime}:00');
    } catch (_) {
      endDateTime = DateTime.now();
    }
    final isCompleted =
        (booking.status == 'booked' || booking.status == 'confirmed') &&
            endDateTime.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(context, booking, isExpired, isCompleted),
            const SizedBox(height: 24),
            _buildDetailCard(context, booking),
            const SizedBox(height: 24),
            if ((booking.status == 'confirmed' || booking.status == 'booked') &&
                !isCompleted &&
                booking.paymentStatus == 'paid') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingInvoice
                      ? null
                      : () => _generateAndDownloadInvoice(context, booking),
                  icon: _isGeneratingInvoice
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_isGeneratingInvoice
                      ? 'Generating...'
                      : 'Download Invoice'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else if (canPay) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(booking: booking),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Pay Now',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _verifyPayment(context, ref),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Verify Payment',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
      BuildContext context, Booking booking, bool isExpired, bool isCompleted) {
    Color color;
    String text;
    IconData icon;

    if (isCompleted) {
      color = Colors.blue;
      text = 'Booking Completed';
      icon = Icons.task_alt;
    } else if ((booking.status == 'confirmed' || booking.status == 'booked') &&
        booking.paymentStatus == 'paid') {
      color = Colors.green;
      text = 'Booking Confirmed';
      icon = Icons.check_circle;
    } else if (booking.status == 'cancelled') {
      color = Colors.red;
      text = 'Booking Cancelled';
      icon = Icons.cancel;
    } else if (isExpired) {
      color = Colors.grey;
      text = 'Booking Expired';
      icon = Icons.timer_off;
    } else {
      color = Colors.orange;
      text = 'Payment Pending';
      icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, Booking booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.venueName,
                style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 32),
            _buildRow('Date', booking.date),
            _buildRow('Time', '${booking.startTime} - ${booking.endTime}'),
            _buildRow('Amount', 'Rs. ${booking.amount}'),
            _buildRow('Booking ID', booking.id),
            if (booking.holdExpiresAt != null && booking.status == 'pending')
              _buildRow(
                  'Expires At',
                  DateFormat('HH:mm:ss')
                      .format(booking.holdExpiresAt!.toDate())),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndDownloadInvoice(
      BuildContext context, Booking booking) async {
    setState(() {
      _isGeneratingInvoice = true;
    });

    try {
      // Load logo
      final logoBytes =
          (await rootBundle.load('assets/logo.png')).buffer.asUint8List();

      // Prepare invoice data
      final invoiceData = InvoiceData(
        bookingId: booking.id,
        venueName: booking.venueName,
        userId: booking.userId,
        date: booking.date,
        startTime: booking.startTime,
        endTime: booking.endTime,
        amount: booking.amount,
        logoBytes: logoBytes,
        invoiceDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        venueId: booking.venueId,
        paymentId: booking.paymentId,
      );

      // Generate PDF
      final pdfBytes = await compute(generateInvoicePdf, invoiceData);

      final fileName = 'Invoice_${booking.id}.pdf';

      if (mounted) {
        setState(() {
          _isGeneratingInvoice = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InvoicePreviewScreen(
              pdfBytes: pdfBytes,
              fileName: fileName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingInvoice = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _verifyPayment(BuildContext context, WidgetRef ref) async {
    // In a real app, this would call a backend API to check payment status with eSewa
    // For now, we'll show a dialog explaining this is a manual check or simulation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Payment'),
        content: const Text(
            'If you have completed the payment but the status is not updated, please click "Check Status". This will attempt to verify the transaction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Simulate verification check
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking payment status...')),
              );

              // Here we would call the repository to check status
              // For now, we just reload the booking or show a message
              // If we had the transaction ID, we could check it.

              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Payment verification pending. Please contact support if issue persists.')),
                );
              }
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }
}

class InvoiceData {
  final String bookingId;
  final String venueName;
  final String userId;
  final String date;
  final String startTime;
  final String endTime;
  final double amount;
  final Uint8List logoBytes;
  final String invoiceDate;
  final String venueId;
  final String? paymentId;

  InvoiceData({
    required this.bookingId,
    required this.venueName,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.logoBytes,
    required this.invoiceDate,
    required this.venueId,
    this.paymentId,
  });
}

Future<Uint8List> generateInvoicePdf(InvoiceData data) async {
  final pdf = pw.Document();
  final logoImage = pw.MemoryImage(data.logoBytes);

  // Generate QR Code Data
  final qrData = {
    'bookingId': data.bookingId,
    'userId': data.userId,
    'venueId': data.venueId,
    'amount': data.amount,
    'date': data.date,
    'startTime': data.startTime,
    'endTime': data.endTime,
    'transactionId': data.paymentId, // Using transactionId as requested
    'timestamp': DateTime.now().toIso8601String(),
  };
  final qrString = jsonEncode(qrData);
  final bytes = utf8.encode(qrString);
  final hash = sha256.convert(bytes);
  final finalQrContent = jsonEncode({
    'data': qrData,
    'hash': hash.toString(),
  });

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with Logo
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INVOICE',
                        style: pw.TextStyle(
                            fontSize: 40, fontWeight: pw.FontWeight.bold)),
                    pw.Text('SajiloKhel',
                        style: const pw.TextStyle(fontSize: 20)),
                  ],
                ),
                pw.Image(logoImage, width: 80, height: 80),
              ],
            ),
            pw.SizedBox(height: 40),

            // Invoice Details (Top Right)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Invoice Date: ${data.invoiceDate}'),
                    pw.Text('Booking ID: ${data.bookingId}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Billed To (Left)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Billed To:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('User ID: ${data.userId}'),
              ],
            ),

            pw.SizedBox(height: 40),
            pw.Text('Booking Details',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Venue'),
                pw.Text(data.venueName),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date & Time'),
                pw.Text('${data.date} | ${data.startTime} - ${data.endTime}'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Booked By'),
                pw.Text(data.userId),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Platform'),
                pw.Text('Mobile App (SajiloKhel)'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Amount',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text('Rs. ${data.amount}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: finalQrContent,
                width: 200,
                height: 200,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('Scan to verify booking')),
            pw.Spacer(),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Thank you for booking with SajiloKhel!'),
                pw.Text('Contact: contact@sajilokhel.com'),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
