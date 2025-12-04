import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/booking.dart';
import '../data/booking_repository.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Venue', widget.booking.venueName),
            _buildDetailRow('Date', widget.booking.date),
            _buildDetailRow('Time',
                '${widget.booking.startTime} - ${widget.booking.endTime}'),
            _buildDetailRow('Amount', 'Rs. ${widget.booking.amount}'),
            const SizedBox(height: 32),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _payWithEsewa,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Pay with eSewa',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _payWithEsewa() async {
    setState(() => _isProcessing = true);

    try {
      final result = await Esewa.i.init(
        context: context,
        eSewaConfig: ESewaConfig.dev(
          amount: widget.booking.amount,
          productCode: dotenv.env['ESEWA_CLIENT_ID'] ?? 'EPAYTEST',
          secretKey: dotenv.env['ESEWA_SECRET_KEY'] ?? '8gBm/:&EnhH.1/q',
          transactionUuid: widget.booking.id,
          successUrl: "https://example.com/success",
          failureUrl: "https://example.com/failure",
        ),
      );

      if (result.hasData) {
        debugPrint(":::SUCCESS::: => ${result.data}");
        _verifyTransaction(result.data!);
      } else {
        debugPrint(":::FAILURE::: => ${result.error}");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment Failed: ${result.error}")));
        setState(() => _isProcessing = false);
      }
    } on Exception catch (e) {
      debugPrint("EXCEPTION : ${e.toString()}");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _verifyTransaction(EsewaPaymentResponse response) async {
    try {
      // In a real app, verify with backend using response.data (base64 encoded)
      // For now, we assume success and update Firestore
      debugPrint("Payment Response Data: ${response.data}");

      // Extract refId from response if available
      // Note: EsewaPaymentResponse might not expose refId directly depending on version,
      // but usually it's in the decoded data. For now we use a placeholder or try to get it.
      // The response.data is a base64 encoded string containing transaction details.
      // We will use the booking ID (transactionUuid) as the payment ID reference for now
      // as extracting the specific eSewa refId requires decoding the response.data.

      final now = DateTime.now();
      final esewaData = {
        'bookingType': 'mobile',
        'esewaAmount': widget.booking.amount,
        'esewaInitiatedAt': Timestamp.fromDate(now), // Approximate
        'esewaStatus': 'COMPLETE',
        'esewaTransactionCode':
            widget.booking.id, // Using booking ID as transaction code for now
        'esewaTransactionUuid': widget.booking.id,
        'paymentTimestamp': Timestamp.fromDate(now),
        'verifiedAt': Timestamp.fromDate(now),
      };

      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            widget.booking.id,
            'booked',
            booking: widget.booking,
            esewaData: esewaData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Payment Successful! Booking Confirmed.")));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Verification Failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
