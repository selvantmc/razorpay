import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/delivery_subscription_service.dart';
import '../services/location_service.dart';
import '../features/payment/services/local_notification_service.dart';
import 'menu_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late DeliverySubscriptionService _deliverySubscription;
  StreamSubscription<Map<String, dynamic>>? _streamSub;
  double? _deliveryLat;
  double? _deliveryLng;
  String _deliveryStatus = 'confirmed';
  String? _partnerId;
  bool _isSubscribed = false;
  double? _customerLat;
  double? _customerLng;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    // Parse initial values from order
    _deliveryStatus = widget.order['delivery_status']?.toString() ?? 'confirmed';
    
    if (widget.order['delivery_lat'] != null) {
      _deliveryLat = (widget.order['delivery_lat'] as num).toDouble();
    }
    if (widget.order['delivery_lng'] != null) {
      _deliveryLng = (widget.order['delivery_lng'] as num).toDouble();
    }

    // Load customer coordinates
    try {
      final location = await LocationService().getSavedLocation();
      if (location != null) {
        setState(() {
          _customerLat = location.latitude;
          _customerLng = location.longitude;
        });
      }
    } catch (e) {
      print('Failed to load customer location: $e');
    }

    // Create delivery subscription service
    _deliverySubscription = DeliverySubscriptionService();

    // Listen to delivery updates
    _streamSub = _deliverySubscription.deliveryUpdates.listen((update) {
      if (!mounted) return;

      setState(() {
        _deliveryStatus = update['delivery_status']?.toString() ?? _deliveryStatus;
        
        if (update['delivery_lat'] != null) {
          _deliveryLat = (update['delivery_lat'] as num).toDouble();
        }
        if (update['delivery_lng'] != null) {
          _deliveryLng = (update['delivery_lng'] as num).toDouble();
        }
        
        _partnerId = update['partner_id']?.toString();
      });

      // Show notifications
      final status = update['delivery_status']?.toString();
      if (status == 'nearby') {
        LocalNotificationService().showDeliveryNotification(
          title: 'Delivery Partner Nearby! 📍',
          body: 'Your order is almost there!',
          orderId: widget.order['order_id']?.toString() ?? '',
        );
      }
      if (status == 'delivered') {
        LocalNotificationService().showDeliveryNotification(
          title: 'Order Delivered! 🎉',
          body: 'Enjoy your meal!',
          orderId: widget.order['order_id']?.toString() ?? '',
        );
        _deliverySubscription.cancelAllSubscriptions();
      }
    });

    // Subscribe to delivery updates
    try {
      await _deliverySubscription.subscribeToDelivery(
        widget.order['order_id']?.toString() ?? '',
      );
      setState(() => _isSubscribed = true);
    } catch (e) {
      print('Failed to subscribe to delivery updates: $e');
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _deliverySubscription.dispose();
    super.dispose();
  }

  String _calcDistanceKm() {
    if (_deliveryLat == null || _customerLat == null) return '?';
    
    // Simple Euclidean approximation
    final dlat = (_deliveryLat! - _customerLat!).abs() * 111;
    final dlng = (_deliveryLng! - _customerLng!).abs() * 111;
    final d = math.sqrt(dlat * dlat + dlng * dlng);
    
    return d < 1 ? '${(d * 1000).toInt()}m' : '${d.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track Order',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.order['order_id']?.toString() ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _DeliveryMap(
              deliveryLat: _deliveryLat,
              deliveryLng: _deliveryLng,
              customerLat: _customerLat,
              customerLng: _customerLng,
              calcDistance: _calcDistanceKm,
            ),
            const SizedBox(height: 16),
            _StatusStepper(currentStatus: _deliveryStatus),
            const SizedBox(height: 16),
            _StatusCard(
              status: _deliveryStatus,
              partnerId: _partnerId,
              isSubscribed: _isSubscribed,
            ),
            const SizedBox(height: 16),
            if (_deliveryStatus == 'delivered') const _BackToMenuButton(),
          ],
        ),
      ),
    );
  }
}

// Private widget: Delivery Map (custom, no Google Maps)
class _DeliveryMap extends StatelessWidget {
  final double? deliveryLat;
  final double? deliveryLng;
  final double? customerLat;
  final double? customerLng;
  final String Function() calcDistance;

  const _DeliveryMap({
    required this.deliveryLat,
    required this.deliveryLng,
    required this.customerLat,
    required this.customerLng,
    required this.calcDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Center content
            Center(
              child: deliveryLat != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '🛵',
                          style: TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Delivery Partner',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${deliveryLat!.toStringAsFixed(4)}, ${deliveryLng!.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        if (customerLat != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '~${calcDistance()} from you',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '📍',
                          style: TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for partner location...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
            ),
            // Live dot indicator
            if (deliveryLat != null)
              const Positioned(
                top: 12,
                right: 12,
                child: _LiveDot(),
              ),
          ],
        ),
      ),
    );
  }
}

// Private widget: Pulsing live dot
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> {
  bool _isLarge = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) {
        setState(() {
          _isLarge = !_isLarge;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: _isLarge ? 10 : 8,
      height: _isLarge ? 10 : 8,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Private widget: Status stepper
class _StatusStepper extends StatelessWidget {
  final String currentStatus;

  const _StatusStepper({required this.currentStatus});

  static const List<String> _steps = [
    'confirmed',
    'preparing',
    'picked_up',
    'nearby',
    'delivered',
  ];

  static const List<IconData> _stepIcons = [
    Icons.check_circle_outline,
    Icons.restaurant,
    Icons.delivery_dining,
    Icons.location_on,
    Icons.home,
  ];

  static const List<String> _stepLabels = [
    'Confirmed',
    'Preparing',
    'Picked Up',
    'Nearby',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(currentStatus);
    final activeIndex = currentIndex >= 0 ? currentIndex : 0;

    return Container(
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
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connecting line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < activeIndex
                    ? Colors.green
                    : Colors.grey[200],
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < activeIndex;
            final isActive = stepIndex == activeIndex;
            final isPending = stepIndex > activeIndex;

            Color circleColor;
            Color iconColor;
            if (isCompleted) {
              circleColor = Colors.green;
              iconColor = Colors.white;
            } else if (isActive) {
              circleColor = const Color(0xFFFF6B35);
              iconColor = Colors.white;
            } else {
              circleColor = Colors.grey[200]!;
              iconColor = Colors.grey[400]!;
            }

            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : _stepIcons[stepIndex],
                    color: iconColor,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: Text(
                    _stepLabels[stepIndex],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 10,
                      color: stepIndex <= activeIndex
                          ? const Color(0xFF0F172A)
                          : Colors.grey[400],
                      fontWeight: stepIndex == activeIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}

// Private widget: Status card
class _StatusCard extends StatelessWidget {
  final String status;
  final String? partnerId;
  final bool isSubscribed;

  const _StatusCard({
    required this.status,
    required this.partnerId,
    required this.isSubscribed,
  });

  static const Map<String, (String, String, String)> _statusData = {
    'confirmed': ('🎉', 'Order Confirmed!', 'Getting ready to prepare your food'),
    'preparing': ('👨‍🍳', 'Being Prepared', 'Chef is working on your order'),
    'picked_up': ('🛵', 'On the Way!', 'Delivery partner has picked up your order'),
    'nearby': ('📍', 'Almost There!', 'Delivery partner is nearby'),
    'delivered': ('🏠', 'Delivered!', 'Enjoy your meal 🎉'),
  };

  @override
  Widget build(BuildContext context) {
    final data = _statusData[status] ?? ('📦', 'Order Status', 'Tracking your order');
    final emoji = data.$1;
    final title = data.$2;
    final subtitle = data.$3;

    return Container(
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
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (partnerId != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Partner: $partnerId',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isSubscribed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const _LiveDot(),
                  const SizedBox(width: 8),
                  Text(
                    'Live tracking active',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Private widget: Back to menu button
class _BackToMenuButton extends StatelessWidget {
  const _BackToMenuButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final savedLocation = await LocationService().getSavedLocation();
          if (savedLocation != null && context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => MenuScreen(location: savedLocation),
              ),
              (route) => false,
            );
          }
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
    );
  }
}
