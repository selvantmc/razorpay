import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../api/payment_api.dart';
import '../models/payment_session.dart';
import '../widgets/primary_button.dart';
import '../widgets/info_row.dart';

/// Screen for creating payment orders, processing payments through Razorpay,
/// and verifying transactions.
///
/// This screen handles the complete payment flow:
/// 1. User enters amount and creates order
/// 2. Razorpay SDK processes payment
/// 3. Payment is automatically verified
/// 4. User can check payment status
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

  bool _isLoading = false;
  String? _errorMessage;
  String? _resultMessage;
  String? _lastCreatedOrderId;

  @override
void initState() {
  super.initState();
  // Initialize Razorpay SDK
  _razorpay = Razorpay();
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
}

  @override
void dispose() {
  _razorpay.clear();
  _amountController.dispose();
  super.dispose();
}

  /// Clears local error and result messages.
  /// Called when switching to this tab from another tab.
  void clearLocalData() {
    setState(() {
      _errorMessage = null;
      _resultMessage = null;
    });
  }

  /// Handles successful payment from Razorpay SDK.
  /// Saves payment details to session and automatically triggers verification.
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      widget.session.orderId = response.orderId;
      widget.session.paymentId = response.paymentId;
      widget.session.signature = response.signature;
    });

    // Automatically verify payment
    _verifyPayment();
  }

  /// Handles payment errors from Razorpay SDK.
  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _errorMessage = 'Payment failed: ${response.message}';
    });
  }

  /// Handles external wallet selection from Razorpay SDK.
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
        ),
      );
    }
  }

  /// Creates a payment order and launches Razorpay SDK.
  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final orderData = await PaymentApi.createOrder(amount);

      // Store order ID for status checks
      _lastCreatedOrderId = orderData['orderId'];

      // Launch Razorpay SDK
      final options = {
        'key': 'rzp_test_SHXH1wQoOlA037',
        'amount': orderData['amount'],
        'currency': 'INR',
        'name': 'Nourisha Pay',
        'description': 'Payment for order',
        'order_id': orderData['orderId'],
        'prefill': {
          'contact': '9999999999',
          'email': 'test@example.com',
        }
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Verifies the payment using session data.
  Future<void> _verifyPayment() async {
    if (widget.session.orderId == null ||
        widget.session.paymentId == null ||
        widget.session.signature == null) {
      setState(() {
        _errorMessage = 'Missing payment session data';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PaymentApi.verifyPayment(
        orderId: widget.session.orderId!,
        paymentId: widget.session.paymentId!,
        signature: widget.session.signature!,
      );

      setState(() {
        _resultMessage = const JsonEncoder.withIndent('  ').convert(result);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Checks the payment status for the current session or last created order.
  Future<void> _checkPaymentStatus() async {
    final orderId = widget.session.orderId ?? _lastCreatedOrderId;

    if (orderId == null) {
      setState(() {
        _errorMessage = 'No order ID available. Create an order first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount input field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount in ₹',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pay Now button
              PrimaryButton(
                text: 'Pay Now',
                onPressed: _createOrder,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              // Session info card (conditional)
              if (widget.session.hasSession) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Session',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        InfoRow(
                          label: 'Order ID',
                          value: widget.session.orderId ?? '',
                          selectable: true,
                        ),
                        InfoRow(
                          label: 'Payment ID',
                          value: widget.session.paymentId ?? '',
                          selectable: true,
                        ),
                        InfoRow(
                          label: 'Signature',
                          value: widget.session.signature ?? '',
                          selectable: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Check Payment Status button
              PrimaryButton(
                text: 'Check Payment Status',
                onPressed: _checkPaymentStatus,
                isLoading: false,
              ),
              const SizedBox(height: 24),

              // Result message box
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
                      Text(
                        'Result',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _resultMessage!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error card
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Loading indicator
              if (_isLoading) ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
