import 'package:flutter/material.dart';

/// A widget that displays order status with color-coded styling.
/// 
/// The badge appears as a pill-shaped container with colored background
/// and white text. Colors are mapped based on status values:
/// - Green: "paid", "captured", "verified"
/// - Orange: "created", "pending"
/// - Red: "failed", "error"
/// - Grey: all other values
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  /// Returns the appropriate color based on the status value.
  Color _getStatusColor() {
    final statusLower = status.toLowerCase();
    
    if (statusLower == 'paid' || 
        statusLower == 'captured' || 
        statusLower == 'verified') {
      return Colors.green;
    } else if (statusLower == 'created' || statusLower == 'pending') {
      return Colors.orange;
    } else if (statusLower == 'failed' || statusLower == 'error') {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
