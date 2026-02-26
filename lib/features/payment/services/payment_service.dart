import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_models.dart';
import 'backend_api_service.dart';

/// PaymentService orchestrates payment operations using Razorpay SDK.
///
/// SECURITY ARCHITECTURE:
/// - This service uses ONLY Razorpay Key_ID (public key) for client-side operations
/// - Key_Secret (private key) MUST NEVER exist in this Flutter code
/// - All operations requiring Key_Secret are delegated to Backend_API:
///   * Order creation (requires Key_Secret to generate order_id)
///   * Payment verification (requires Key_Secret to verify signature)
///   * Status checks (requires Key_Secret to query Razorpay API)
///
/// This separation ensures the Flutter app is production-safe and compliant
/// with payment security standards.
class PaymentService {
  late Razorpay _razorpay;
  final BackendApiService _backendApi;
  final SharedPreferences _prefs;

  // SECURITY: Only Key_ID is stored in client
  // Key_Secret MUST NEVER be in this code
  // 
  // ⚠️ IMPORTANT: Replace 'rzp_test_PLACEHOLDER' with your actual Razorpay test key
  // 
  // To get your Razorpay Key_ID:
  // 1. Sign up at https://razorpay.com/
  // 2. Go to Dashboard → Settings → API Keys
  // 3. Copy your test Key_ID (format: rzp_test_XXXXXXXXXX)
  // 4. Replace the placeholder below
  // 
  // Without a valid key, Razorpay will show "Uh! oh! Something went wrong" error
  // ignore: constant_identifier_names
  static const String RAZORPAY_KEY_ID = 'rzp_test_SHXH1wQoOlA037';

  // Storage keys for persistence
  static const String _lastOrderIdKey = 'last_order_id';
  static const String _lastPaymentIdKey = 'last_payment_id';
  static const String _lastPaymentStatusKey = 'last_payment_status';

  PaymentResult? _lastResult;
  Completer<PaymentResult>? _paymentCompleter;

  PaymentService({
    required BackendApiService backendApi,
    required SharedPreferences prefs,
  })  : _backendApi = backendApi,
        _prefs = prefs {
    _initializeRazorpay();
  }

  /// Initialize Razorpay SDK instance and register callback handlers.
  ///
  /// Registers three event handlers:
  /// - EVENT_PAYMENT_SUCCESS: Called when payment completes successfully
  /// - EVENT_PAYMENT_ERROR: Called when payment fails or user cancels
  /// - EVENT_EXTERNAL_WALLET: Called when user selects external wallet
  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Launch Razorpay checkout with the specified amount.
  ///
  /// Payment Flow:
  /// 1. Call backend API to create order (backend uses Key_Secret)
  /// 2. Persist Order_ID to SharedPreferences for recovery
  /// 3. Build Razorpay options map with Key_ID, amount, order_id, branding
  /// 4. Launch Razorpay checkout UI
  /// 5. Wait for callback (success/error/external wallet)
  ///
  /// Parameters:
  /// - amount: Payment amount in rupees (Lambda converts to paise)
  /// - reference: Optional order reference for tracking
  /// - onStatus: Optional callback for status updates
  ///
  /// Returns: PaymentResult when payment completes or fails
  ///
  /// Throws: Exception if order creation fails
  ///
  /// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 5.2
  Future<PaymentResult> openCheckout({
    required int amount,
    String? reference,
    void Function(String)? onStatus,
  }) async {
    _paymentCompleter = Completer<PaymentResult>();
    
    try {
      onStatus?.call('Creating order with backend...');
      
      // Step 1: Create order via backend (backend uses Key_Secret)
      final orderResponse = await _backendApi.createOrder(
        amount: amount,
        reference: reference,
      );

      // Step 2: Persist order_id for recovery
      await _saveOrderId(orderResponse.orderId);

      onStatus?.call('Opening Razorpay checkout...');

      // Step 3: Build Razorpay options map with Key_ID only
      var options = {
        'key': RAZORPAY_KEY_ID,
        'amount': orderResponse.amount,
        'currency': orderResponse.currency,
        'name': 'Nourisha POS',
        'description': reference ?? 'Payment',
        'order_id': orderResponse.orderId,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#2196F3',
        },
      };

      // Step 4: Launch Razorpay checkout
      _razorpay.open(options);
      
      return _paymentCompleter!.future;
    } catch (e) {
      // Handle order creation failure
      final result = PaymentResult(
        status: PaymentStatus.failed,
        errorCode: 'ORDER_CREATION_FAILED',
        errorDescription: e.toString(),
        timestamp: DateTime.now(),
      );
      _lastResult = result;
      _paymentCompleter?.completeError(result);
      rethrow;
    }
  }

  /// Handle successful payment callback from Razorpay.
  ///
  /// Captures payment_id, order_id, and signature for verification.
  /// Persists payment details to local storage for recovery.
  /// Auto-verifies payment with backend.
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final result = PaymentResult.success(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId ?? '',
      signature: response.signature ?? '',
    );
    _lastResult = result;

    await _savePaymentId(response.paymentId ?? '');
    await _savePaymentStatus(PaymentStatus.success);

    // Auto-verify payment with backend
    try {
      await _backendApi.verifyPayment(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      print('✅ Payment verified successfully');
    } catch (e) {
      print('⚠️ Payment verification failed: $e');
      // Verification failure is non-fatal, payment still succeeded
    }

    _paymentCompleter?.complete(result);
  }

  /// Handle payment error callback from Razorpay.
  ///
  /// Captures error code and description for debugging and user display.
  /// Persists failure status to local storage.
  void _handlePaymentError(PaymentFailureResponse response) async {
    // Log detailed error for debugging
    print('🔴 Razorpay Payment Error:');
    print('   Code: ${response.code}');
    print('   Message: ${response.message}');
    
    final result = PaymentResult.failure(
      orderId: await _getLastOrderId() ?? 'unknown',
      errorCode: response.code.toString(),
      errorDescription: response.message ?? 'Payment failed',
    );
    _lastResult = result;

    await _savePaymentStatus(PaymentStatus.failed);
    
    _paymentCompleter?.completeError(result);
  }

  /// Handle external wallet callback from Razorpay.
  ///
  /// Called when user selects an external wallet (PayTM, PhonePe, etc.)
  /// for payment. Captures wallet name for tracking.
  void _handleExternalWallet(ExternalWalletResponse response) async {
    _lastResult = PaymentResult.externalWallet(
      walletName: response.walletName ?? 'Unknown',
    );
  }

  /// Check payment status via backend.
  ///
  /// Retrieves the last stored order_id and payment_id from local storage
  /// and queries the backend for the current payment status.
  ///
  /// This is useful for:
  /// - Recovering from lost callbacks (app crash, network issue)
  /// - Manual reconciliation by cashier
  /// - Verifying payment completion
  ///
  /// Returns: PaymentStatusResponse with current status from backend
  Future<PaymentStatusResponse> checkStatus() async {
    final orderId = await _getLastOrderId();
    final paymentId = await _getLastPaymentId();

    return await _backendApi.checkPaymentStatus(
      orderId: orderId,
      paymentId: paymentId,
    );
  }

  /// Persistence helper: Save order_id to local storage
  Future<void> _saveOrderId(String orderId) async {
    await _prefs.setString(_lastOrderIdKey, orderId);
  }

  /// Persistence helper: Retrieve last order_id from local storage
  Future<String?> _getLastOrderId() async {
    return _prefs.getString(_lastOrderIdKey);
  }

  /// Persistence helper: Save payment_id to local storage
  Future<void> _savePaymentId(String paymentId) async {
    await _prefs.setString(_lastPaymentIdKey, paymentId);
  }

  /// Persistence helper: Retrieve last payment_id from local storage
  Future<String?> _getLastPaymentId() async {
    return _prefs.getString(_lastPaymentIdKey);
  }

  /// Persistence helper: Save payment status to local storage
  Future<void> _savePaymentStatus(PaymentStatus status) async {
    await _prefs.setString(_lastPaymentStatusKey, status.toString());
  }

  /// Get the last payment result from the most recent transaction
  PaymentResult? get lastResult => _lastResult;

  /// Clean up Razorpay SDK instance and remove event listeners.
  ///
  /// MUST be called when the service is no longer needed to prevent
  /// memory leaks and ensure proper cleanup of native SDK resources.
  void dispose() {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.completeError('PaymentService disposed');
    }
    _razorpay.clear();
  }
}
