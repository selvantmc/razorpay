import 'package:hive/hive.dart';

part 'order_detail.g.dart';

@HiveType(typeId: 0)
class OrderDetail {
  @HiveField(0)
  final String orderId;
  
  @HiveField(1)
  final String? razorpayOrderId;
  
  @HiveField(2)
  final int amount; // in paise
  
  @HiveField(3)
  final String currency;
  
  @HiveField(4)
  final String status;
  
  @HiveField(5)
  final String? paymentId;
  
  @HiveField(6)
  final String? signature;
  
  @HiveField(7)
  final int createdAt; // Unix timestamp
  
  @HiveField(8)
  final int updatedAt; // Unix timestamp (now required)
  
  @HiveField(9)
  final bool isSynced;
  
  @HiveField(10)
  final String? customerName;
  
  @HiveField(11)
  final String? customerEmail;
  
  @HiveField(12)
  final String? customerPhone;

  OrderDetail({
    required this.orderId,
    this.razorpayOrderId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.paymentId,
    this.signature,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
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

  /// Creates a copy of this OrderDetail with the given fields replaced with new values
  OrderDetail copyWith({
    String? orderId,
    String? razorpayOrderId,
    int? amount,
    String? currency,
    String? status,
    String? paymentId,
    String? signature,
    int? createdAt,
    int? updatedAt,
    bool? isSynced,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) {
    return OrderDetail(
      orderId: orderId ?? this.orderId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      signature: signature ?? this.signature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
    );
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
    razorpayOrderId: json['razorpay_order_id'],
    amount: json['amount'] ?? 0,
    currency: json['currency'] ?? 'INR',
    status: json['status'] ?? 'unknown',
    paymentId: json['payment_id'],
    signature: json['signature'],
    createdAt: parseTimestamp(json['created_at']),
    updatedAt: parseTimestamp(json['updated_at']),
    isSynced: json['is_synced'] ?? false,
    customerName: json['customer_name'],
    customerEmail: json['customer_email'],
    customerPhone: json['customer_phone'],
  );
}

}
