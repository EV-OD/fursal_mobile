import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/payment_service.dart';
import '../data/checkout_state.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  final String transactionUuid;
  final String responseData;
  final String productCode;
  final double totalAmount;
  final String? venueName;

  const PaymentVerificationScreen({
    super.key,
    required this.transactionUuid,
    required this.responseData,
    required this.productCode,
    required this.totalAmount,
    this.venueName,
  });

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSuccess = false;
  Map<String, dynamic>? _bookingData;
  String? _refId;

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    try {
      final paymentService = PaymentService();
      final resp = await paymentService.verifyPayment(
        transactionUuid: widget.transactionUuid,
        responseData: widget.responseData,
        productCode: widget.productCode,
        totalAmount: widget.totalAmount,
      );

      // Check for success based on backend response structure
      // Response example: {"verified":true,"status":"COMPLETE", ...}
      final verified = resp['verified'] == true;
      final status = resp['status'];
      final success = verified || status == 'COMPLETE' || status == 'success';

      if (success) {
        if (mounted) {
          // Reset checkout state on success
          ref.read(checkoutProvider.notifier).reset();
          
          setState(() {
            _isLoading = false;
            _isSuccess = true;
            _bookingData = resp['bookingData'];
            _refId = resp['refId'];
          });
        }
      } else {
        final message = resp['message'] ?? 'Verification failed';
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handleContinue() {
    // Pop until the first route (Home)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Verifying Payment...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we confirm your booking.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );
    }

    if (_isSuccess) {
      final date = _bookingData?['date'] ?? 'N/A';
      final startTime = _bookingData?['startTime'] ?? 'N/A';
      final endTime = _bookingData?['endTime'] ?? 'N/A';
      final totalBookingAmount = _bookingData?['amount']?.toString() ?? 'N/A';

      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking has been confirmed.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Receipt Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (widget.venueName != null) ...[
                      _buildReceiptRow('Venue', widget.venueName!),
                      const Divider(height: 24),
                    ],
                    _buildReceiptRow('Date', date),
                    const SizedBox(height: 12),
                    _buildReceiptRow('Time', '$startTime - $endTime'),
                    const Divider(height: 24),
                    _buildReceiptRow(
                      'Amount Paid',
                      'Rs. ${widget.totalAmount.toStringAsFixed(0)}',
                      isBold: true,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 12),
                    _buildReceiptRow(
                      'Total Booking Amount',
                      'Rs. $totalBookingAmount',
                    ),
                    if (_refId != null) ...[
                      const Divider(height: 24),
                      _buildReceiptRow('Transaction Ref', _refId!),
                    ],
                    const SizedBox(height: 12),
                    _buildReceiptRow('Transaction ID', widget.transactionUuid),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, size: 64, color: Colors.red),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verification Failed',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Unknown error occurred',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Go Back'),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
