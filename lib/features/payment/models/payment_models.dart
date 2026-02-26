// Payment Models for Nourisha POS Payment Module
// This file contains all data structures for payment operations

/// Payment status enumeration
enum PaymentStatus {
  pending,
  success,
  failed,
  unknown,
}

/// Order creation response from backend
class OrderResponse {
  final String orderId;
  final int amount; // Amount in smallest currency unit (paise)
  final String currency; // e.g., "INR"
  final String? reference; // Optional order reference

  OrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.reference,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      orderId: json['orderId'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'reference': reference,
    };
  }
}

/// Payment result from Razorpay callback
class PaymentResult {
  final PaymentStatus status;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorCode;
  final String? errorDescription;
  final String? walletName;
  final DateTime timestamp;

  PaymentResult({
    required this.status,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.errorDescription,
    this.walletName,
    required this.timestamp,
  });

  factory PaymentResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) {
    return PaymentResult(
      status: PaymentStatus.success,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResult.failure({
    required String orderId,
    required String errorCode,
    required String errorDescription,
  }) {
    return PaymentResult(
      status: PaymentStatus.failed,
      orderId: orderId,
      errorCode: errorCode,
      errorDescription: errorDescription,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResult.externalWallet({
    required String walletName,
  }) {
    return PaymentResult(
      status: PaymentStatus.pending,
      walletName: walletName,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'errorCode': errorCode,
      'errorDescription': errorDescription,
      'walletName': walletName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Payment status check response from backend
class PaymentStatusResponse {
  final String orderId;
  final String? paymentId;
  final PaymentStatus status;
  final int amount;
  final String currency;
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;

  PaymentStatusResponse({
    required this.orderId,
    this.paymentId,
    required this.status,
    required this.amount,
    required this.currency,
    this.paidAt,
    this.metadata,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      orderId: json['orderId'] as String,
      paymentId: json['paymentId'] as String?,
      status: _parsePaymentStatus(json['status'] as String),
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'paymentId': paymentId,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'paidAt': paidAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'pending':
        return PaymentStatus.pending;
      default:
        return PaymentStatus.unknown;
    }
  }
}
