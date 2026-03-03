import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/order_detail.dart';
import '../services/local_storage_service.dart';

/// A reactive widget that displays order status from local storage.
///
/// This widget automatically updates when the order status changes in Hive.
/// It uses ValueListenableBuilder to watch the Hive box and reactively
/// rebuild when the order data is updated.
///
/// Status colors:
/// - pending: Grey (#9E9E9E)
/// - processing: Blue (#2196F3)
/// - paid: Green (#4CAF50)
/// - failed: Red (#F44336)
class StatusBadge extends StatelessWidget {
  final String orderId;
  final double? fontSize;
  final EdgeInsets? padding;
  final LocalStorageService? localStorageService;

  const StatusBadge({
    required this.orderId,
    this.fontSize,
    this.padding,
    this.localStorageService,
    super.key,
  });

  /// Returns the appropriate color based on the status value
  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    
    switch (statusLower) {
      case 'pending':
        return const Color(0xFF9E9E9E); // Grey
      case 'processing':
        return const Color(0xFF2196F3); // Blue
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'failed':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey for unknown status
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the Hive box for orders
    final ordersBox = Hive.box<OrderDetail>('orders');
    
    return ValueListenableBuilder<Box<OrderDetail>>(
      valueListenable: ordersBox.listenable(),
      builder: (context, box, widget) {
        // Query the order from the box
        final order = box.get(orderId);
        
        // If order not found, show unknown status
        if (order == null) {
          return _buildBadge('unknown', fontSize, padding);
        }
        
        // Build badge with current status
        return _buildBadge(order.status, fontSize, padding);
      },
    );
  }

  /// Builds the badge UI with the given status
  Widget _buildBadge(String status, double? fontSize, EdgeInsets? padding) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
