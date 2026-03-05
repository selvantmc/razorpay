import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/cart.dart';
import '../models/delivery_location.dart';
import '../api/payment_api.dart';
import '../features/payment/services/subscription_service.dart';
import '../features/payment/services/local_storage_service.dart';
import '../features/payment/services/local_notification_service.dart';
import '../models/order_detail.dart';

class CartScreen extends StatefulWidget {
  final Cart cart;
  final DeliveryLocation location;
  final VoidCallback onCartUpdated;

  const CartScreen({
    super.key,
    required this.cart,
    required this.location,
    required this.onCartUpdated,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Razorpay _razorpay;
  late SubscriptionService _subscriptionService;
  late LocalStorageService _localStorageService;
  
  bool _isPlacingOrder = false;
  bool _paymentInProgress = false;
  bool _orderCreated = false;
  bool _subscriptionActive = false;
  String? _errorMessage;
  String? _successMessage;
  String? _currentOrderId;
  OrderDetail? _currentOrder;

  static const double _deliveryFee = 40.0;
  static const double _platformFee = 5.0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Initialize services
    _localStorageService = LocalStorageService();
    _subscriptionService = SubscriptionService(
      localStorageService: _localStorageService,
      localNotificationService: LocalNotificationService(),
    );
    
    _initializeServices();
    _listenToOrderUpdates();
  }

  Future<void> _initializeServices() async {
    try {
      await _localStorageService.initialize();
    } catch (e) {
      print('Failed to initialize local storage: $e');
    }
  }

  void _listenToOrderUpdates() {
    print('CartScreen: Setting up order updates listener');
    _subscriptionService.orderUpdates.listen(
      (orderJson) {
        print('CartScreen: RAW order update received: $orderJson');
        
        if (!mounted) {
          print('CartScreen: Widget not mounted, ignoring update');
          return;
        }
        
        final status = orderJson['status'] as String?;
        final orderId = orderJson['order_id'] as String?;
        
        print('CartScreen: Received order update - status: $status, orderId: $orderId, currentOrderId: $_currentOrderId');
        
        if (orderId != _currentOrderId) {
          print('CartScreen: Order ID mismatch, ignoring update');
          return;
        }
        
        setState(() {
          // Store the order details
          _currentOrder = OrderDetail.fromJson(orderJson);
          
          if (status == 'created' || status == 'pending') {
            // Order is ready, open Razorpay
            print('CartScreen: Order status is $status - opening Razorpay');
            _subscriptionActive = false;
            _isPlacingOrder = false;
            _openRazorpay();
          } else if (status == 'cancelled' || status == 'failed') {
            // Payment cancelled or failed, show retry button
            print('CartScreen: Payment $status - showing retry button');
            _orderCreated = true;
            _subscriptionActive = false;
            _isPlacingOrder = false;
            _errorMessage = 'Payment $status. You can retry payment.';
          } else if (status == 'paid' || status == 'captured' || status == 'verified') {
            // Payment successful - clear any previous errors
            print('CartScreen: Payment confirmed via subscription (status: $status) - showing success');
            _handlePaymentVerified(orderJson['payment_id'] as String?);
          } else {
            print('CartScreen: Unknown status: $status');
          }
        });
      },
      onError: (error) {
        print('CartScreen: Error in order updates stream: $error');
      },
      onDone: () {
        print('CartScreen: Order updates stream closed');
      },
    );
  }

  @override
  void dispose() {
    if (_currentOrderId != null) {
      _subscriptionService.cancelSubscription(_currentOrderId!);
    }
    _subscriptionService.dispose();
    _razorpay.clear();
    super.dispose();
  }

  double get _grandTotalWithFees => widget.cart.grandTotal + _deliveryFee + _platformFee;

  Future<void> _placeOrder() async {
    setState(() {
      _isPlacingOrder = true;
      _errorMessage = null;
    });

    try {
      // Create order with items total only (not including fees)
      final orderData = await PaymentApi.createOrder(widget.cart.grandTotal);
      _currentOrderId = orderData['orderId'] as String;
      
      // Store order details from API response
      _currentOrder = OrderDetail(
        orderId: _currentOrderId!,
        amount: orderData['amount'] as int,
        currency: 'INR',
        status: 'created',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      setState(() {
        _orderCreated = true;
        _subscriptionActive = true;
      });

      print('CartScreen: Order created $_currentOrderId - starting subscription');
      
      // Start subscription to listen for order updates from GraphQL API
      try {
        await _subscriptionService.subscribeToOrder(_currentOrderId!);
        print('CartScreen: Subscription established successfully');
        
        // Set a timeout - if no update received in 10 seconds, open Razorpay anyway
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _subscriptionActive && _currentOrder != null && !_paymentInProgress) {
            print('CartScreen: No subscription update received - opening Razorpay as fallback');
            setState(() {
              _subscriptionActive = false;
              _isPlacingOrder = false;
            });
            _openRazorpay();
          }
        });
        
      } catch (e) {
        print('CartScreen: Subscription failed: $e');
        // If subscription fails, show error and allow retry
        setState(() {
          _isPlacingOrder = false;
          _subscriptionActive = false;
          _errorMessage = 'Failed to connect to payment service. Please check your internet connection and try again.';
        });
        return;
      }
      
      // Subscription is active - wait for backend to send order status
      // The subscription listener will handle opening Razorpay when status becomes 'created' or 'pending'
      
    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
        _orderCreated = false;
        _subscriptionActive = false;
        _errorMessage = 'Failed to create order: ${e.toString()}';
      });
    }
  }

  void _openRazorpay() {
    if (_currentOrderId == null || _currentOrder == null) {
      setState(() {
        _errorMessage = 'Cannot open payment: Order details missing';
        _isPlacingOrder = false;
      });
      return;
    }

    final options = {
      'key': 'rzp_test_SHXH1wQoOlA037',
      'amount': _currentOrder!.amount,
      'currency': 'INR',
      'name': 'Nourisha',
      'description': widget.cart.orderDescription,
      'order_id': _currentOrderId,
      'notes': {
        'delivery_address': widget.location.fullAddress,
        'item_count': widget.cart.totalItems.toString(),
      },
      'theme': {
        'color': '#FF6B35',
      },
    };

    _razorpay.open(options);
  }

  Future<void> _retryPayment() async {
    if (_currentOrder == null || _currentOrderId == null) {
      setState(() {
        _errorMessage = 'Cannot retry payment: Order details missing';
      });
      return;
    }

    setState(() {
      _isPlacingOrder = true;
      _errorMessage = null;
      _subscriptionActive = true;
    });

    print('CartScreen: Retrying payment for order $_currentOrderId');
    
    try {
      // Resubscribe to the existing order to listen for payment status updates
      await _subscriptionService.subscribeToOrder(_currentOrderId!);
      print('CartScreen: Resubscribed successfully');
      
      // For retry, open Razorpay immediately since order already exists
      // Subscription will listen for payment success/failure from backend
      setState(() {
        _isPlacingOrder = false;
      });
      
      _openRazorpay();
    } catch (e) {
      print('CartScreen: Resubscription failed: $e');
      setState(() {
        _isPlacingOrder = false;
        _subscriptionActive = false;
        _errorMessage = 'Failed to connect to payment service: ${e.toString()}';
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('CartScreen: Razorpay payment success - paymentId: ${response.paymentId}');
    print('CartScreen: Waiting for subscription to confirm payment status from backend');
    
    // Don't show success immediately - wait for subscription to receive "paid" status from backend
    // The subscription listener will call _handlePaymentVerified when backend confirms
    setState(() {
      _paymentInProgress = true;
      _isPlacingOrder = false;
    });
  }

  void _handlePaymentVerified(String? paymentId) {
    // Reset all state flags to prevent showing retry button
    setState(() {
      _orderCreated = false;
      _subscriptionActive = false;
      _isPlacingOrder = false;
      _paymentInProgress = false;
      _errorMessage = null;
    });

    widget.cart.clear();
    widget.onCartUpdated();

    if (mounted) {
      _showSuccessSheet(paymentId ?? 'N/A');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('CartScreen: Payment error - code: ${response.code}, message: ${response.message}');
    
    setState(() {
      _isPlacingOrder = false;
      _paymentInProgress = false;
      
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        // User cancelled - keep order, show "Retry Payment" button
        _orderCreated = true;
        _subscriptionActive = false;
        _errorMessage = 'Payment cancelled. You can retry payment.';
      } else {
        // Payment failed - keep order, show "Retry Payment" button
        _orderCreated = true;
        _subscriptionActive = false;
        _errorMessage = 'Payment failed: ${response.message ?? 'Unknown error'}. You can retry payment.';
      }
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isPlacingOrder = false;
      _errorMessage = 'External wallet selected: ${response.walletName}';
    });
  }

  Widget _buildBottomButton() {
    // Show "Retry Payment" button if order was created but payment failed/cancelled
    if (_orderCreated && !_subscriptionActive && !_isPlacingOrder && !_paymentInProgress) {
      return ElevatedButton(
        onPressed: _retryPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          'Retry Payment · ₹${_grandTotalWithFees.toInt()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    // Show loading state when placing order or subscription is active
    if (_isPlacingOrder || _paymentInProgress || _subscriptionActive) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _subscriptionActive ? 'Preparing order...' : 'Processing...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    // Default: Show "Place Order" button
    return ElevatedButton(
      onPressed: _placeOrder,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: Text(
        'Place Order · ₹${_grandTotalWithFees.toInt()}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showSuccessSheet(String paymentId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your food is being prepared. Delivering to ${widget.location.city}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Payment ID: $paymentId',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close sheet
                    Navigator.of(context).pop(); // Close cart screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Menu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cart.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Your Cart',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🛒',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add items from the menu',
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
                  'Browse Menu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Cart',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                fontSize: 18,
              ),
            ),
            Text(
              '${widget.cart.totalItems} ${widget.cart.totalItems == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[900],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Cart items card
          Container(
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
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.cart.items.map((cartItem) {
                  return _CartItemRow(
                    cartItem: cartItem,
                    onAdd: () {
                      setState(() {
                        widget.cart.add(cartItem.menuItem);
                      });
                      widget.onCartUpdated();
                    },
                    onRemove: () {
                      setState(() {
                        widget.cart.remove(cartItem.menuItem);
                      });
                      widget.onCartUpdated();
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Delivery address card
          Container(
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFFF6B35),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.location.fullAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bill summary card
          Container(
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
                const Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _BillRow(
                  label: 'Item Total',
                  value: widget.cart.formattedTotal,
                ),
                const SizedBox(height: 12),
                _BillRow(
                  label: 'Delivery Fee',
                  value: '₹${_deliveryFee.toInt()}',
                ),
                const SizedBox(height: 12),
                _BillRow(
                  label: 'Platform Fee',
                  value: '₹${_platformFee.toInt()}',
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '₹${_grandTotalWithFees.toInt()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: _buildBottomButton(),
          ),
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartItemRow({
    required this.cartItem,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            cartItem.menuItem.imageAsset,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.menuItem.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cartItem.menuItem.formattedPrice,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFF6B35)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    cartItem.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              cartItem.formattedTotal,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;

  const _BillRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
