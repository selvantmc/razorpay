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

/// Screen for searching orders by ID and viewing detailed order information.
///
/// Allows users to:
/// - Search for orders by order ID
/// - View comprehensive order details
/// - Verify payment for orders that need action
/// - Check payment status for orders that need action
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
  
  bool _isLoading = false;
  String? _errorMessage;
  OrderDetail? _orderDetail;
  String? _actionResult;
  bool _isVerifying = false;
  bool _isCheckingStatus = false;

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
    _orderIdController.dispose();
    super.dispose();
  }

  /// Clears local error and result messages.
  /// Called when switching to this tab from another tab.
  void clearLocalData() {
    setState(() {
      _errorMessage = null;
      _actionResult = null;
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

  /// Opens Razorpay SDK for payment retry with the given order details.
  void _openRazorpay(String orderId, int amount) {
    final options = {
      'key': 'rzp_test_SHXH1wQoOlA037',
      'amount': amount,
      'currency': 'INR',
      'name': 'Nourisha Pay',
      'description': 'Payment for order',
      'order_id': orderId,
      'prefill': {
        'contact': '9999999999',
        'email': 'test@example.com',
      }
    };

    _razorpay.open(options);
  }

  /// Fetches order details from the backend using the provided order ID.
  Future<void> _fetchOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _actionResult = null;
    });

    try {
      final orderDetail = await PaymentApi.getOrder(_orderIdController.text.trim());
      
      setState(() {
        _orderDetail = orderDetail;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order fetched successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Verifies payment using the payment ID and signature from the order details.
  Future<void> _verifyPayment() async {
    if (_orderDetail == null || 
        _orderDetail!.paymentId == null || 
        _orderDetail!.signature == null) {
      setState(() {
        _errorMessage = 'Payment ID or signature not available for verification';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await PaymentApi.verifyPayment(
        orderId: _orderDetail!.orderId,
        paymentId: _orderDetail!.paymentId!,
        signature: _orderDetail!.signature!,
      );

      // Extract updated status from verification response
      final updatedStatus = result['status'] as String?;

      setState(() {
        _actionResult = const JsonEncoder.withIndent('  ').convert(result);
        
        // Update local order data with new status if available
        if (updatedStatus != null) {
          _orderDetail = OrderDetail(
            orderId: _orderDetail!.orderId,
            amount: _orderDetail!.amount,
            status: updatedStatus,
            paymentId: _orderDetail!.paymentId,
            signature: _orderDetail!.signature,
            createdAt: _orderDetail!.createdAt,
            updatedAt: _orderDetail!.updatedAt,
            customerName: _orderDetail!.customerName,
            customerEmail: _orderDetail!.customerEmail,
            customerPhone: _orderDetail!.customerPhone,
          );
        }
        
        _isVerifying = false;
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
        _isVerifying = false;
      });
    }
  }

  /// Checks the payment status for the current order.
  Future<void> _checkPaymentStatus() async {
    if (_orderDetail == null) {
      setState(() {
        _errorMessage = 'No order loaded';
      });
      return;
    }

    setState(() {
      _isCheckingStatus = true;
      _errorMessage = null;
    });

    try {
      final result = await PaymentApi.checkPaymentStatus(_orderDetail!.orderId);

      setState(() {
        _actionResult = const JsonEncoder.withIndent('  ').convert(result);
        _isCheckingStatus = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isCheckingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Lookup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order ID Input Field
              TextFormField(
                controller: _orderIdController,
                decoration: const InputDecoration(
                  labelText: 'Order ID',
                  hintText: 'Enter order ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an order ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fetch Order Button
              PrimaryButton(
                text: 'Fetch Order',
                onPressed: _fetchOrder,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              // Error Card
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Order Detail Card
              if (_orderDetail != null) ...[
                GlassyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      InfoRow(
                        label: 'Order ID',
                        value: _orderDetail!.orderId,
                        selectable: true,
                      ),
                      InfoRow(
                        label: 'Amount',
                        value: _orderDetail!.formattedAmount,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: StatusBadge(status: _orderDetail!.status),
                            ),
                          ],
                        ),
                      ),
                      InfoRow(
                        label: 'Created',
                        value: _orderDetail!.formattedCreatedAt,
                      ),
                      
                      if (_orderDetail!.customerName != null)
                        InfoRow(
                          label: 'Customer',
                          value: _orderDetail!.customerName!,
                        ),
                      if (_orderDetail!.customerEmail != null)
                        InfoRow(
                          label: 'Email',
                          value: _orderDetail!.customerEmail!,
                        ),
                      if (_orderDetail!.customerPhone != null)
                        InfoRow(
                          label: 'Phone',
                          value: _orderDetail!.customerPhone!,
                        ),
                      
                      if (_orderDetail!.paymentId != null)
                        InfoRow(
                          label: 'Payment ID',
                          value: _orderDetail!.paymentId!,
                          selectable: true,
                        ),
                      if (_orderDetail!.signature != null)
                        InfoRow(
                          label: 'Signature',
                          value: _orderDetail!.signature!,
                          selectable: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons Section (conditional on needsAction)
                if (_orderDetail!.needsAction) ...[
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_orderDetail!.status != 'paid') ...[
                    PrimaryButton(
                      text: 'Retry Payment',
                      onPressed: () => _openRazorpay(
                        _orderDetail!.orderId,
                        _orderDetail!.amount,
                      ),
                      isLoading: false,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  PrimaryButton(
                    text: 'Verify Payment',
                    onPressed: _verifyPayment,
                    isLoading: _isVerifying,
                  ),
                  const SizedBox(height: 12),
                  
                  PrimaryButton(
                    text: 'Check Payment Status',
                    onPressed: _checkPaymentStatus,
                    isLoading: _isCheckingStatus,
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Result Box
                if (_actionResult != null) ...[
                  const Text(
                    'Result',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _actionResult!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
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
