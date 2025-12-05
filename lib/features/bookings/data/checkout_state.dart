import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/booking.dart';

/// Holds all checkout-related state: booking info and payment params.
/// This ensures we don't call initiatePayment multiple times.
class CheckoutState {
  final Booking? booking;
  final Map<String, dynamic>? paymentParams;
  final String? transactionUuid;
  final String? signature;
  final String? productCode;
  final bool isInitiatingPayment;
  final String? error;

  const CheckoutState({
    this.booking,
    this.paymentParams,
    this.transactionUuid,
    this.signature,
    this.productCode,
    this.isInitiatingPayment = false,
    this.error,
  });

  CheckoutState copyWith({
    Booking? booking,
    Map<String, dynamic>? paymentParams,
    String? transactionUuid,
    String? signature,
    String? productCode,
    bool? isInitiatingPayment,
    String? error,
  }) {
    return CheckoutState(
      booking: booking ?? this.booking,
      paymentParams: paymentParams ?? this.paymentParams,
      transactionUuid: transactionUuid ?? this.transactionUuid,
      signature: signature ?? this.signature,
      productCode: productCode ?? this.productCode,
      isInitiatingPayment: isInitiatingPayment ?? this.isInitiatingPayment,
      error: error,
    );
  }

  /// Check if payment has been initiated (we have transactionUuid)
  bool get hasPaymentParams => transactionUuid != null && paymentParams != null;

  /// Clear error
  CheckoutState clearError() => copyWith(error: null);

  /// Reset entire checkout state
  static const CheckoutState initial = CheckoutState();
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(CheckoutState.initial);

  /// Set booking after createBooking API succeeds
  void setBooking(Booking booking) {
    state = state.copyWith(booking: booking);
  }

  /// Set payment params after initiatePayment API succeeds
  void setPaymentParams({
    required Map<String, dynamic> paymentParams,
    required String transactionUuid,
    required String signature,
    required String productCode,
  }) {
    state = state.copyWith(
      paymentParams: paymentParams,
      transactionUuid: transactionUuid,
      signature: signature,
      productCode: productCode,
      isInitiatingPayment: false,
    );
  }

  /// Mark that we're initiating payment
  void setInitiatingPayment(bool value) {
    state = state.copyWith(isInitiatingPayment: value);
  }

  /// Set error
  void setError(String error) {
    state = state.copyWith(error: error, isInitiatingPayment: false);
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  /// Reset checkout state (after payment success or user cancels)
  void reset() {
    state = CheckoutState.initial;
  }
}

/// Global checkout state provider
final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier();
});
