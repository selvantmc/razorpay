import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api/payment_api.dart';

class DeliveryPartnerScreen extends StatefulWidget {
  const DeliveryPartnerScreen({super.key});

  @override
  State<DeliveryPartnerScreen> createState() => _DeliveryPartnerScreenState();
}

class _DeliveryPartnerScreenState extends State<DeliveryPartnerScreen> {
  final _partnerIdController = TextEditingController(text: 'partner_001');
  final _orderIdController = TextEditingController();
  String _partnerId = 'partner_001';
  String? _activeOrderId;
  double? _currentLat;
  double? _currentLng;
  bool _isTrackingGPS = false;
  String _currentStatus = 'confirmed';
  bool _isUpdating = false;
  String? _statusMessage;
  Timer? _gpsTimer;
  StreamSubscription<Position>? _locationSub;

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _locationSub?.cancel();
    _partnerIdController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _startDelivery() async {
    _partnerId = _partnerIdController.text.trim();
    final orderId = _orderIdController.text.trim();

    if (_partnerId.isEmpty || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter both Partner ID and Order ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _activeOrderId = orderId;
    });

    await _updateStatus('preparing');
    await _startGPSTracking();
  }

  Future<void> _startGPSTracking() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
      if (_activeOrderId != null) {
        _sendLocationUpdate();
      }
    });

    // Backup timer every 5 seconds
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_activeOrderId != null && _currentLat != null) {
        _sendLocationUpdate();
      }
    });

    setState(() => _isTrackingGPS = true);
  }

  Future<void> _stopGPSTracking() async {
    _gpsTimer?.cancel();
    _locationSub?.cancel();
    setState(() {
      _isTrackingGPS = false;
      _gpsTimer = null;
      _locationSub = null;
    });
  }

  Future<void> _sendLocationUpdate() async {
    if (_activeOrderId == null || _currentLat == null || _currentLng == null) {
      return;
    }

    try {
      final response = await PaymentApi.updateDeliveryLocation(
        orderId: _activeOrderId!,
        partnerId: _partnerId,
        lat: _currentLat!,
        lng: _currentLng!,
      );

      if (response['is_nearby'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer is nearby! 📍'),
            backgroundColor: Color(0xFFFF6B35),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Failed to send location update: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_activeOrderId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await PaymentApi.updateOrderStatus(
        orderId: _activeOrderId!,
        partnerId: _partnerId,
        deliveryStatus: newStatus,
      );

      setState(() {
        _currentStatus = newStatus;
        _isUpdating = false;
        _statusMessage = 'Status updated to $newStatus';
      });

      if (newStatus == 'delivered') {
        await _stopGPSTracking();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status: $newStatus'),
            backgroundColor: const Color(0xFFFF6B35),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Partner',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              _isTrackingGPS ? '🟢 GPS Active' : '⚫ GPS Off',
              style: TextStyle(
                fontSize: 12,
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
            // Section 1: Setup Card
            _buildSetupCard(),

            // Section 2: GPS Status Card
            if (_isTrackingGPS) ...[
              const SizedBox(height: 16),
              _buildGPSStatusCard(),
            ],

            // Section 3: Status Buttons Card
            if (_activeOrderId != null) ...[
              const SizedBox(height: 16),
              _buildStatusButtonsCard(),
            ],

            // Section 4: Active Order Info Card
            if (_activeOrderId != null) ...[
              const SizedBox(height: 16),
              _buildActiveOrderCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetupCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setup',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _partnerIdController,
            decoration: InputDecoration(
              labelText: 'Partner ID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _orderIdController,
            decoration: InputDecoration(
              labelText: 'Order ID to Deliver',
              hintText: 'order_XXXXXXXXXX',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.receipt_long),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startDelivery,
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
                'Start Delivery',
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
  }

  Widget _buildGPSStatusCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LiveDot(),
              const SizedBox(width: 8),
              const Text(
                'GPS Tracking Active',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_currentLat != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lat: ${_currentLat!.toStringAsFixed(6)}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Lng: ${_currentLng!.toStringAsFixed(6)}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _stopGPSTracking,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Stop GPS'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtonsCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Status',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _StatusButton(
            label: 'Preparing 👨‍🍳',
            isActive: _currentStatus == 'preparing',
            activeColor: Colors.blue,
            onTap: () => _updateStatus('preparing'),
            isLoading: _isUpdating,
          ),
          const SizedBox(height: 8),
          _StatusButton(
            label: 'Picked Up 🛵',
            isActive: _currentStatus == 'picked_up',
            activeColor: Colors.purple,
            onTap: () => _updateStatus('picked_up'),
            isLoading: _isUpdating,
          ),
          const SizedBox(height: 8),
          _StatusButton(
            label: 'Nearby 📍',
            isActive: _currentStatus == 'nearby',
            activeColor: const Color(0xFFFF6B35),
            onTap: () => _updateStatus('nearby'),
            isLoading: _isUpdating,
          ),
          const SizedBox(height: 8),
          _StatusButton(
            label: 'Delivered ✓',
            isActive: _currentStatus == 'delivered',
            activeColor: Colors.green,
            onTap: () => _updateStatus('delivered'),
            isLoading: _isUpdating,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Delivery',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _activeOrderId!,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Status: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _currentStatus,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Partner: $_partnerId',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Private widget: Live dot (reused from order_tracking_screen)
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

// Private widget: Status button
class _StatusButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _StatusButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    } else {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[600],
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
  }
}
