import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../api/payment_api.dart';
import '../models/payment_session.dart';
import '../models/order_detail.dart';
import '../widgets/primary_button.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';
import '../widgets/glassy_card.dart';
import '../features/payment/services/subscription_service.dart';
import '../features/payment/services/local_storage_service.dart';
import '../features/payment/services/local_notification_service.dart';

class OrderLookupScreen extends StatefulWidget {
  final PaymentSession session;

  const OrderLookupScreen({super.key, required this.session});

  @override
  State<OrderLookupScreen> createState() => _OrderLookupScreenState();
}

class _OrderLookupScreenState extends State<OrderLookupScreen> {
  final _orderIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Razorpay _razorpay;

  // Services
  late final SubscriptionService _subscriptionService;
  late final LocalStorageService _localStorageService;

  // ✅ Correctly inside State class
  StreamSubscription<Map<String, dynamic>>? _updateSubscription;

  bool _isLoading = false;
  String? _errorMessage;
  OrderDetail? _orderDetail;
  String? _actionResult;
  bool _isVerifying = false;
  bool _isCheckingStatus = false;

  @override
void initState() {
  super.initState();

  _localStorageService = LocalStorageService();

  // ✅ Create service FIRST
  _subscriptionService = SubscriptionService(
    localStorageService: _localStorageService,
    localNotificationService: LocalNotificationService(),
  );

  print('🔍 _subscriptionService hashCode in initState: ${_subscriptionService.hashCode}');
  _updateSubscription = _subscriptionService.orderUpdates.listen((update) {
    print('📡 OrderLookupScreen stream received → ${update['status']}');

    if (!mounted) return;

    final newStatus = update['status']     as String? ?? '';
    final paymentId = update['payment_id'] as String?;
    final updatedAt = update['updated_at'] as String?;

    setState(() {
      if (_orderDetail != null) {
        _orderDetail = _orderDetail!.copyWith(
          status:    newStatus,
          paymentId: paymentId ?? _orderDetail!.paymentId,
          updatedAt: updatedAt != null
              ? _parseTimestamp(updatedAt)
              : _orderDetail!.updatedAt,
        );
      }
      _actionResult = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated: $newStatus'),
          backgroundColor: _snackColor(newStatus),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  });

  // Razorpay init
  _razorpay = Razorpay();
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _handlePaymentError);
  _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
}

  @override
  void dispose() {
    _updateSubscription?.cancel();      // ✅ Cancel stream listener
    _razorpay.clear();
    _orderIdController.dispose();
    _subscriptionService.cancelAllSubscriptions();
    super.dispose();
  }

  void clearLocalData() {
    setState(() {
      _errorMessage = null;
      _actionResult = null;
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      widget.session.orderId   = response.orderId;
      widget.session.paymentId = response.paymentId;
      widget.session.signature = response.signature;
    });
    _verifyPayment();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
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

  void _openRazorpay(String orderId, int amount) {
    _razorpay.open({
      'key':         'rzp_test_SHXH1wQoOlA037',
      'amount':      amount,
      'currency':    'INR',
      'name':        'Nourisha Pay',
      'description': 'Payment for order',
      'order_id':    orderId,
      'prefill':     {'contact': '9999999999', 'email': 'test@example.com'},
    });
  }

  Future<void> _fetchOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
      _actionResult = null;
    });
  print('🔍 _subscriptionService hashCode in _fetchOrder: ${_subscriptionService.hashCode}');
    await _subscriptionService.cancelAllSubscriptions();

    try {
      final orderId     = _orderIdController.text.trim();
      final orderDetail = await PaymentApi.getOrder(orderId);

      setState(() {
        _orderDetail = orderDetail;
        _isLoading   = false;
      });

      await _localStorageService.initialize();
      await _localStorageService.saveOrder(orderDetail);
      await _subscriptionService.subscribeToOrder(orderId);

      print('✅ Subscribed to AppSync for order: $orderId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order fetched — watching for updates...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading    = false;
      });
    }
  }

  Future<void> _verifyPayment() async {
    final orderId   = widget.session.orderId   ?? _orderDetail?.orderId;
    final paymentId = widget.session.paymentId ?? _orderDetail?.paymentId;
    final signature = widget.session.signature ?? _orderDetail?.signature;

    if (orderId == null || paymentId == null || signature == null) {
      setState(() {
        _errorMessage = 'Payment ID or signature not available for verification';
      });
      return;
    }

    setState(() { _isVerifying = true; _errorMessage = null; });

    try {
      final result = await PaymentApi.verifyPayment(
        orderId:   orderId,
        paymentId: paymentId,
        signature: signature,
      );

      setState(() {
        _actionResult = const JsonEncoder.withIndent('  ').convert(result);
        _isVerifying  = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verify request sent — waiting for confirmation...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isVerifying  = false;
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_orderDetail == null) {
      setState(() => _errorMessage = 'No order loaded');
      return;
    }

    setState(() { _isCheckingStatus = true; _errorMessage = null; });

    try {
      final result = await PaymentApi.checkPaymentStatus(_orderDetail!.orderId);
      setState(() {
        _actionResult     = const JsonEncoder.withIndent('  ').convert(result);
        _isCheckingStatus = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage     = e.toString().replaceFirst('Exception: ', '');
        _isCheckingStatus = false;
      });
    }
  }

  int _parseTimestamp(String value) {
    try {
      return DateTime.parse(value).millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  Color _snackColor(String status) {
    if (['paid', 'captured', 'verified'].contains(status)) return Colors.green;
    if (status == 'failed') return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Lookup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              TextFormField(
                controller: _orderIdController,
                decoration: const InputDecoration(
                  labelText: 'Order ID',
                  hintText:  'Enter order ID',
                  border:    OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an order ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              PrimaryButton(
                text:      'Fetch Order',
                onPressed: _fetchOrder,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:        Colors.red[50],
                    border:       Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red))),
                  ]),
                ),
                const SizedBox(height: 24),
              ],

              if (_orderDetail != null) ...[
                GlassyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      InfoRow(label: 'Order ID', value: _orderDetail!.orderId, selectable: true),
                      InfoRow(label: 'Amount',   value: _orderDetail!.formattedAmount),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2,
                              child: Text('Status',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14))),
                            const SizedBox(width: 16),
                            Expanded(flex: 3,
                              child: StatusBadge(status: _orderDetail!.status)),
                          ],
                        ),
                      ),

                      InfoRow(label: 'Created', value: _orderDetail!.formattedCreatedAt),

                      if (_orderDetail!.customerName  != null)
                        InfoRow(label: 'Customer', value: _orderDetail!.customerName!),
                      if (_orderDetail!.customerEmail != null)
                        InfoRow(label: 'Email',    value: _orderDetail!.customerEmail!),
                      if (_orderDetail!.customerPhone != null)
                        InfoRow(label: 'Phone',    value: _orderDetail!.customerPhone!),
                      if (_orderDetail!.paymentId != null)
                        InfoRow(label: 'Payment ID', value: _orderDetail!.paymentId!, selectable: true),
                      if (_orderDetail!.signature != null)
                        InfoRow(label: 'Signature',  value: _orderDetail!.signature!,  selectable: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_orderDetail!.needsAction) ...[
                  const Text('Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_orderDetail!.status != 'paid') ...[
                    PrimaryButton(
                      text:      'Retry Payment',
                      onPressed: () => _openRazorpay(
                        _orderDetail!.orderId,
                        _orderDetail!.amount,
                      ),
                      isLoading: false,
                    ),
                    const SizedBox(height: 12),
                  ],

                  PrimaryButton(
                    text:      'Verify Payment',
                    onPressed: _verifyPayment,
                    isLoading: _isVerifying,
                  ),
                  const SizedBox(height: 12),

                  PrimaryButton(
                    text:      'Check Payment Status',
                    onPressed: _checkPaymentStatus,
                    isLoading: _isCheckingStatus,
                  ),
                  const SizedBox(height: 24),
                ],

                if (_actionResult != null) ...[
                  const Text('Result',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        Colors.grey[100],
                      border:       Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(_actionResult!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}