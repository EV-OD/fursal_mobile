import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../domain/booking.dart';
// booking_repository import removed — backend now handles final verification
import '../../../services/payment_service.dart';

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
      // Step 1: Call backend to initiate payment and get client-side params.
      final paymentService = PaymentService();
      final resp = await paymentService.initiatePayment(
        bookingId: widget.booking.id,
        totalAmount: widget.booking.amount,
      );

      // Backend may return either a pre-built payment URL (web flow) or an `esewa` object
      // containing the params needed for the eSewa SDK. Handle both.
      if (resp.containsKey('paymentUrl')) {
        final String url = resp['paymentUrl'] as String;
        final String? successUrl = resp['successUrl'] as String?;
        final String? failureUrl = resp['failureUrl'] as String?;
        await _openWebPayment(url, successUrl: successUrl, failureUrl: failureUrl);
      
      } else if (resp.containsKey('esewa')) {
        final esewa = resp['esewa'] as Map<String, dynamic>;
        final amount = esewa['amount'] ?? widget.booking.amount;
        final productCode = esewa['productCode'] ?? dotenv.env['ESEWA_CLIENT_ID'] ?? 'EPAYTEST';
        final secretKey = esewa['secretKey'] ?? dotenv.env['ESEWA_SECRET_KEY'] ?? '';
        final transactionUuid = esewa['transactionUuid'] ?? resp['transactionUuid'] ?? widget.booking.id;
        final successUrl = esewa['successUrl'] ?? 'https://example.com/success';
        final failureUrl = esewa['failureUrl'] ?? 'https://example.com/failure';

        final result = await Esewa.i.init(
          context: context,
          eSewaConfig: ESewaConfig.dev(
            amount: amount,
            productCode: productCode,
            secretKey: secretKey,
            transactionUuid: transactionUuid,
            successUrl: successUrl,
            failureUrl: failureUrl,
          ),
        );

        if (result.hasData) {
          await _handleEsewaResult(result.data!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Payment Failed: ${result.error}")));
          setState(() => _isProcessing = false);
        }
      } else {
        // Unexpected shape — fallback to previous client-side flow
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
          await _handleEsewaResult(result.data!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Payment Failed: ${result.error}")));
          setState(() => _isProcessing = false);
        }
      }
    } on Exception catch (e) {
      debugPrint("EXCEPTION : ${e.toString()}");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleEsewaResult(EsewaPaymentResponse response) async {
    // Send the returned response to backend for verification and to update booking atomically.
    try {
      final paymentService = PaymentService();
      final txnUuid = widget.booking.id; // prefer server-provided txnUuid if available earlier
      final resp = await paymentService.verifyPayment(
        transactionUuid: txnUuid,
        responseData: response.data ?? '',
      );

      // Backend should return a status; consider 'success' key or booking info.
      final success = resp['success'] == true || resp['status'] == 'success';

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment Successful! Booking Confirmed.")));
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        final message = resp['message'] ?? 'Verification failed';
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Verification failed: $message')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Verification Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openWebPayment(String url,
      {String? successUrl, String? failureUrl}) async {
    setState(() => _isProcessing = true);
    final paymentService = PaymentService();

    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Payment')),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url)),
          onLoadStop: (controller, uri) async {
            if (uri == null) return;
            final current = uri.toString();
            if (successUrl != null && current.startsWith(successUrl)) {
              // Close webview and verify with backend
              Navigator.of(context).pop();
              try {
                await paymentService.verifyPayment(
                    transactionUuid: widget.booking.id, responseData: 'redirect');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Payment Successful! Booking Confirmed.')));
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Verification Failed: $e')));
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            }
            if (failureUrl != null && current.startsWith(failureUrl)) {
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Payment Failed')));
                setState(() => _isProcessing = false);
              }
            }
          },
        ),
      );
    }));

    if (mounted) setState(() => _isProcessing = false);
  }

  // _verifyTransaction removed; verification now performed via backend in `_handleEsewaResult`.
}
