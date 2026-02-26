class OrderDetail {
  final String orderId;
  final int amount; // in paise
  final String status;
  final String? paymentId;
  final String? signature;
  final int createdAt; // Unix timestamp
  final int? updatedAt; // Unix timestamp
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  OrderDetail({
    required this.orderId,
    required this.amount,
    required this.status,
    this.paymentId,
    this.signature,
    required this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
  });

  /// Returns formatted amount with ₹ symbol and 2 decimal places
  String get formattedAmount {
    return '₹${(amount / 100).toStringAsFixed(2)}';
  }

  /// Returns true when status requires user action (not paid, captured, or verified)
  bool get needsAction {
    return status != 'paid' && status != 'captured' && status != 'verified';
  }

  /// Returns human-readable formatted timestamp
  String get formattedCreatedAt {
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Factory constructor for parsing JSON with null-safe defaults
  /// Factory constructor for parsing JSON with null-safe defaults
factory OrderDetail.fromJson(Map<String, dynamic> json) {
  // Helper function to parse timestamp (handles both int and String)
  int parseTimestamp(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      // Try to parse ISO 8601 string to Unix timestamp
      try {
        final dateTime = DateTime.parse(value);
        return dateTime.millisecondsSinceEpoch ~/ 1000;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  return OrderDetail(
    orderId: json['order_id'] ?? '',
    amount: json['amount'] ?? 0,
    status: json['status'] ?? 'unknown',
    paymentId: json['payment_id'],
    signature: json['signature'],
    createdAt: parseTimestamp(json['created_at']),
    updatedAt: json['updated_at'] != null ? parseTimestamp(json['updated_at']) : null,
    customerName: json['customer_name'],
    customerEmail: json['customer_email'],
    customerPhone: json['customer_phone'],
  );
}

}
