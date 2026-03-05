import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../api/payment_api.dart';
import '../services/device_service.dart';
import '../models/delivery_location.dart';
import 'order_tracking_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _deviceId;
  late Razorpay _razorpay;
  String? _retryOrderId;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _initialize();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _initialize() async {
    _deviceId = await DeviceService.getDeviceId();
    await _fetchOrders();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (_deviceId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await PaymentApi.getMyOrders(_deviceId!);
      
      // Sort by created_at descending (newest first)
      orders.sort((a, b) {
        final aTime = a['created_at']?.toString() ?? '';
        final bTime = b['created_at']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _retryPayment(Map<String, dynamic> order) async {
    setState(() {
      _retryOrderId = order['order_id']?.toString();
    });

    try {
      // Get delivery location (we need this for createOrderWithDetails)
      // For retry, we'll use dummy values since order already exists
      final orderId = order['order_id']?.toString() ?? '';
      final amount = (order['amount'] ?? 0).toDouble();

      // Open Razorpay directly with existing order
      final options = {
        'key': 'rzp_test_SHXH1wQoOlA037',
        'amount': (amount * 100).toInt(), // Convert to paise
        'currency': 'INR',
        'name': 'Nourisha',
        'description': 'Order Payment',
        'order_id': orderId,
        'theme': {
          'color': '#FF6B35',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _retryOrderId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (_retryOrderId != null) {
        await PaymentApi.verifyPayment(
          orderId: _retryOrderId!,
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
        );
      }
      
      setState(() {
        _retryOrderId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _retryOrderId = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet: ${response.walletName}'),
        ),
      );
    }
  }

  void _trackOrder(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(order: order),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '📦',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start ordering delicious food!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Ordering',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _OrderCard(
          order: order,
          onTrack: () => _trackOrder(order),
          onRetry: () => _retryPayment(order),
          formatDate: _formatDate,
        );
      },
    );
  }
}


// Private widget: Order card
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTrack;
  final VoidCallback onRetry;
  final String Function(dynamic) formatDate;

  const _OrderCard({
    required this.order,
    required this.onTrack,
    required this.onRetry,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order['order_id']?.toString() ?? '';
    final amount = order['amount'] ?? 0;
    final status = order['status']?.toString();
    final deliveryStatus = order['delivery_status']?.toString();
    final createdAt = order['created_at'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Order ID and badges
          Row(
            children: [
              Expanded(
                child: Text(
                  orderId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _PaymentBadge(status: status),
              const SizedBox(width: 4),
              _DeliveryBadge(status: deliveryStatus),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Amount and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${amount.toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                formatDate(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Action area
          _buildActionArea(status, deliveryStatus),
        ],
      ),
    );
  }

  Widget _buildActionArea(String? status, String? deliveryStatus) {
    // Priority 1: Delivered
    if (deliveryStatus == 'delivered') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Text(
          'Delivered ✓',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Priority 2: Paid and not delivered - show Track Order
    if (['paid', 'captured', 'verified'].contains(status) &&
        deliveryStatus != 'delivered') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTrack,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Track Order 🚴',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    // Priority 3: Created or failed - show Pay Now
    if (['created', 'failed'].contains(status) || status == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Pay Now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    // Priority 4: Paid but delivery status is null or confirmed
    return Text(
      'Preparing your order...',
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }
}

// Private widget: Payment badge
class _PaymentBadge extends StatelessWidget {
  final String? status;

  const _PaymentBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String label;

    switch (status) {
      case 'paid':
      case 'captured':
      case 'verified':
        bgColor = Colors.green[50]!;
        borderColor = Colors.green;
        textColor = Colors.green[700]!;
        label = '✓ Paid';
        break;
      case 'failed':
        bgColor = Colors.red[50]!;
        borderColor = Colors.red;
        textColor = Colors.red[700]!;
        label = 'Failed';
        break;
      case 'created':
        bgColor = const Color(0xFFFFF5F0);
        borderColor = const Color(0xFFFF6B35);
        textColor = const Color(0xFFFF6B35);
        label = 'Pending';
        break;
      default:
        bgColor = Colors.grey[50]!;
        borderColor = Colors.grey;
        textColor = Colors.grey[700]!;
        label = status ?? 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// Private widget: Delivery badge
class _DeliveryBadge extends StatelessWidget {
  final String? status;

  const _DeliveryBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusValue = status;
    if (statusValue == null || statusValue.isEmpty) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    String label;

    switch (statusValue) {
      case 'confirmed':
        bgColor = Colors.grey[50]!;
        borderColor = Colors.grey;
        textColor = Colors.grey[700]!;
        label = 'Confirmed';
        break;
      case 'preparing':
        bgColor = Colors.blue[50]!;
        borderColor = Colors.blue;
        textColor = Colors.blue[700]!;
        label = 'Preparing 👨‍🍳';
        break;
      case 'picked_up':
        bgColor = Colors.purple[50]!;
        borderColor = Colors.purple;
        textColor = Colors.purple[700]!;
        label = 'On the way 🛵';
        break;
      case 'nearby':
        bgColor = const Color(0xFFFFF5F0);
        borderColor = const Color(0xFFFF6B35);
        textColor = const Color(0xFFFF6B35);
        label = 'Nearby 📍';
        break;
      case 'delivered':
        bgColor = Colors.green[50]!;
        borderColor = Colors.green;
        textColor = Colors.green[700]!;
        label = 'Delivered ✓';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
