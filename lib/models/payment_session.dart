/// In-memory storage for current payment context.
///
/// This class maintains the payment session state across screens during
/// the app session. All data is lost when the app restarts.
class PaymentSession {
  /// The Razorpay order ID from the backend.
  String? orderId;

  /// The Razorpay payment ID received after successful payment.
  String? paymentId;

  /// The payment signature for verification.
  String? signature;

  /// Returns true when all three fields (orderId, paymentId, signature) are non-null.
  bool get hasSession =>
      orderId != null && paymentId != null && signature != null;

  /// Resets the session by clearing all fields.
  void clear() {
    orderId = null;
    paymentId = null;
    signature = null;
  }
}
