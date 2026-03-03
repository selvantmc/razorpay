import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/payment_api.dart';
import '../models/payment_session.dart';
import '../widgets/primary_button.dart';
import '../widgets/info_row.dart';
import '../features/payment/services/subscription_service.dart';
import '../features/payment/services/local_storage_service.dart';
import '../features/payment/services/local_notification_service.dart';
import '../widgets/status_badge.dart';

class PaymentScreen extends StatefulWidget {
  final PaymentSession session;

  const PaymentScreen({super.key, required this.session});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Razorpay _razorpay;

  // Services
  late final SubscriptionService _subscriptionService;
  late final LocalStorageService _localStorageService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _resultMessage;
  String? _lastCreatedOrderId;
  String _currentStatus = '';        // ← real-time status from subscription
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();

    // Init services
    _localStorageService = LocalStorageService();
    _subscriptionService = SubscriptionService(
      localStorageService: _localStorageService,
      localNotificationService: LocalNotificationService(),
    );

    // Wire up real-time callback
    _subscriptionService.onOrderUpdated = (update) {
      if (!mounted) return;
      final status = update['status'] as String? ?? '';
      setState(() {
        _currentStatus = status;
        _showRetry     = status == 'failed';
        _isLoading     = false;
        _resultMessage = 'Status updated: $status';
      });
    };

    // Init Razorpay SDK
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _subscriptionService.cancelAllSubscriptions();
    super.dispose();
  }

  void clearLocalData() {
    setState(() {
      _errorMessage  = null;
      _resultMessage = null;
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      widget.session.orderId    = response.orderId;
      widget.session.paymentId  = response.paymentId;
      widget.session.signature  = response.signature;
    });
    // Verify payment — subscription will update UI when Lambda responds
    _verifyPayment();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _showRetry    = true;
      _errorMessage = response.code == Razorpay.PAYMENT_CANCELLED
          ? 'Payment cancelled. Tap Retry to try again.'
          : 'Payment failed: ${response.message}';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External wallet: ${response.walletName}')),
      );
    }
  }

  Future<void> _createOrder() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading     = true;
    _errorMessage  = null;
    _resultMessage = null;
    _showRetry     = false;
    _currentStatus = '';
  });

  try {
    final amount    = double.parse(_amountController.text);
    final orderData = await PaymentApi.createOrder(amount);
    final orderId   = orderData['orderId'] as String;
    _lastCreatedOrderId = orderId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_order_id', orderId);

    // ✅ Initialize BEFORE subscribing
    await _localStorageService.initialize();
    await _subscriptionService.subscribeToOrder(orderId);

    _razorpay.open({
      'key':      'rzp_test_SHXH1wQoOlA037',
      'amount':   orderData['amount'],
      'currency': 'INR',
      'name':     'Nourisha Pay',
      'description': 'Payment for order',
      'order_id': orderId,
      'prefill':  {'contact': '9999999999', 'email': 'test@example.com'},
    });
  } catch (e) {
    setState(() {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    setState(() => _isLoading = false);
  }
}


  Future<void> _verifyPayment() async {
    if (widget.session.orderId == null ||
        widget.session.paymentId == null ||
        widget.session.signature == null) return;

    try {
      await PaymentApi.verifyPayment(
        orderId:   widget.session.orderId!,
        paymentId: widget.session.paymentId!,
        signature: widget.session.signature!,
      );
      // UI updates via subscription callback — no setState needed here
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    final orderId = widget.session.orderId ?? _lastCreatedOrderId;
    if (orderId == null) {
      setState(() => _errorMessage = 'No order ID. Create an order first.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await PaymentApi.checkPaymentStatus(orderId);
      setState(() {
        _resultMessage = const JsonEncoder.withIndent('  ').convert(result);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _retryPayment() {
    if (_lastCreatedOrderId == null) return;
    setState(() {
      _showRetry     = false;
      _errorMessage  = null;
      _currentStatus = '';
    });
    // Re-subscribe same orderId + reopen SDK
    _subscriptionService.subscribeToOrder(_lastCreatedOrderId!);
    _razorpay.open({
      'key':      'rzp_test_SHXH1wQoOlA037',
      'amount':   int.parse(_amountController.text) * 100,
      'currency': 'INR',
      'name':     'Nourisha Pay',
      'description': 'Retry payment',
      'order_id': _lastCreatedOrderId,
      'prefill':  {'contact': '9999999999', 'email': 'test@example.com'},
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Real-time status badge
              if (_currentStatus.isNotEmpty) ...[
                StatusBadge(status: _currentStatus),
                const SizedBox(height: 12),
              ],

              // Amount input
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText:  'Enter amount in ₹',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  final amount = double.tryParse(value);
                  if (amount == null)  return 'Please enter a valid number';
                  if (amount <= 0)     return 'Amount must be greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              PrimaryButton(
                text: 'Pay Now',
                onPressed: _createOrder,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Retry button — shown when payment fails
              if (_showRetry)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _retryPayment,
                ),

              const SizedBox(height: 8),

              // Session info
              if (widget.session.hasSession) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active Session',
                          style: Theme.of(context)
                              .textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        InfoRow(label: 'Order ID',   value: widget.session.orderId ?? '',   selectable: true),
                        InfoRow(label: 'Payment ID', value: widget.session.paymentId ?? '', selectable: true),
                        InfoRow(label: 'Signature',  value: widget.session.signature ?? '', selectable: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              PrimaryButton(
                text: 'Check Payment Status',
                onPressed: _checkPaymentStatus,
                isLoading: false,
              ),
              const SizedBox(height: 24),

              // Result
              if (_resultMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Result',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(_resultMessage!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!,
                      style: TextStyle(color: Colors.red[900], fontSize: 14))),
                  ]),
                ),
              ],

              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}