import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/checkout_state.dart';
import 'payment_verification_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkoutState = ref.watch(checkoutProvider);
    final booking = checkoutState.booking;
    final pm = checkoutState.paymentParams ?? {};

    // If no booking/payment data, show error
    if (booking == null || !checkoutState.hasPaymentParams) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Checkout session expired or invalid',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please go back and select a slot again.',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final amountStr =
        pm['amount']?.toString() ?? booking.amount.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Summary Card
                    _buildSectionTitle('Booking Summary'),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSummaryRow(Icons.stadium_outlined, 'Venue',
                                booking.venueName),
                            const Divider(height: 24),
                            _buildSummaryRow(Icons.calendar_today_outlined,
                                'Date', booking.date),
                            const Divider(height: 24),
                            _buildSummaryRow(Icons.access_time_outlined, 'Time',
                                '${booking.startTime} - ${booking.endTime}'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Details Card
                    _buildSectionTitle('Payment Details'),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildPaymentRow(
                              'Total Booking Amount',
                              'Rs. ${booking.amount.toStringAsFixed(0)}',
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentRow(
                              'Advance Payment (16.66%)',
                              'Rs. $amountStr',
                              isTotal: true,
                            ),
                            const Divider(height: 24),
                            _buildPaymentRow('Payment Method', 'eSewa'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Transaction Info Card - prominently show transaction UUID
                    _buildSectionTitle('Transaction Info'),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.shade100),
                      ),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Transaction ID',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: SelectableText(
                                checkoutState.transactionUuid ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keep this ID for your records',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Pay Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text(
                          'Rs. $amountStr',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _payWithEsewa,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF60BB46), // eSewa green
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://esewa.com.np/common/images/esewa-icon-large.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.payment,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Pay with eSewa',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ],
                              ),
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _payWithEsewa() async {
    setState(() => _isProcessing = true);

    final checkoutState = ref.read(checkoutProvider);
    final paymentParams = checkoutState.paymentParams;

    if (paymentParams == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment params not ready')));
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final amountRaw = paymentParams['amount'];
      final successUrl = paymentParams['successUrl'] as String?;
      final failureUrl = paymentParams['failureUrl'] as String?;
      final productCode = paymentParams['productCode'] as String?;
      final transactionUuid = paymentParams['transactionUuid'] as String?;

      double amount;
      try {
        amount = double.parse(amountRaw.toString());
      } catch (_) {
        throw Exception(
            'Invalid amount format from server: ${amountRaw.toString()}');
      }

      // Initialize eSewa using server-provided params only.
      final result = await Esewa.i.init(
        context: context,
        eSewaConfig: ESewaConfig.dev(
          amount: amount,
          productCode: productCode!,
          secretKey: dotenv.env['ESEWA_SECRET_KEY'] ?? '',
          transactionUuid: transactionUuid!,
          successUrl: successUrl!,
          failureUrl: failureUrl!,
        ),
      );

      if (result.hasData) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PaymentVerificationScreen(
                transactionUuid: transactionUuid,
                responseData: result.data!.data ?? '',
                productCode: productCode,
                totalAmount: amount,
                venueName: checkoutState.booking?.venueName,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment Failed: ${result.error}")));
      }
    } on Exception catch (e) {
      debugPrint("EXCEPTION : ${e.toString()}");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
