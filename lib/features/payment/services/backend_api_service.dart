// Backend API Service for Nourisha POS Payment Module
// SECURITY NOTE: This service represents backend API calls.
// In production, these endpoints MUST be implemented on a secure server
// that holds the Razorpay Key_Secret. The Flutter app NEVER has Key_Secret.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_models.dart';
import '../../../models/order_detail.dart';

/// Backend API service for secure payment operations
///
/// This service handles all server-side payment operations that require
/// the Razorpay Key_Secret. The client-side Flutter app only uses the
/// Key_ID for launching Razorpay checkout.
///
/// SECURITY BOUNDARY:
/// - Client (Flutter): Has Key_ID only, calls these API endpoints
/// - Server (Backend): Has Key_Secret, implements these endpoints
class BackendApiService {
  final String baseUrl;
  final bool useMockMode;

  BackendApiService({
    required this.baseUrl,
    this.useMockMode = true, // Set to false when backend is ready
  });

  /// Create a payment order on the backend
  ///
  /// AWS Lambda endpoint: /selvan/create-order
  ///
  /// The backend will:
  /// 1. Receive amount and optional reference from client
  /// 2. Create Razorpay order using Key_Secret (server-side only)
  /// 3. Return order_id to client for checkout
  ///
  /// SECURITY: Backend holds Key_Secret, client never sees it
  Future<OrderResponse> createOrder({
    required int amount,
    String? reference,
  }) async {
    if (useMockMode) {
      // MOCK MODE - For UI testing only
      // This will NOT work with real Razorpay checkout
      await Future.delayed(const Duration(milliseconds: 500));

      return OrderResponse(
        orderId: 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: 'INR',
        reference: reference,
      );
    }

    // PRODUCTION MODE - Real AWS Lambda API call
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/selvan/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': 'INR',
          'receipt': reference ?? 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Backend returns { orderId, amount, currency }
        final orderId = data['orderId'] as String;
        final orderAmount = (data['amount'] as num).toInt();
        final currency = (data['currency'] as String?) ?? 'INR';
        
        return OrderResponse(
          orderId: orderId,
          amount: orderAmount,
          currency: currency,
          reference: reference,
        );
      } else {
        throw Exception('Failed to create order: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Order creation failed: $e');
    }
  }

  /// Verify payment signature on the backend
  ///
  /// AWS Lambda endpoint: /selvan/verify-payment
  ///
  /// The backend will:
  /// 1. Receive orderId, paymentId, and signature from client
  /// 2. Verify signature using Key_Secret (server-side only)
  /// 3. Return verification result (true/false)
  ///
  /// SECURITY: Signature verification requires Key_Secret on backend
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/selvan/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Payment verification failed');
      } else {
        throw Exception('Verify payment error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment verification failed: $e');
    }
  }

  /// Check payment status via backend
  ///
  /// AWS Lambda endpoint: /selvan/check-payment-status
  ///
  /// The backend will:
  /// 1. Receive orderId or paymentId from client
  /// 2. Query Razorpay API using Key_Secret (server-side only)
  /// 3. Return current payment status and details
  ///
  /// SECURITY: Razorpay API queries require Key_Secret on backend
  Future<PaymentStatusResponse> checkPaymentStatus({
    String? orderId,
    String? paymentId,
  }) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return PaymentStatusResponse(
        orderId: orderId ?? 'order_unknown',
        paymentId: paymentId,
        status: PaymentStatus.pending,
        amount: 0,
        currency: 'INR',
      );
    }

    try {
      final queryParams = <String, String>{};
      if (orderId != null) queryParams['order_id'] = orderId;
      if (paymentId != null) queryParams['payment_id'] = paymentId;

      final uri = Uri.parse('$baseUrl/selvan/check-payment-status').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        final responseOrderId = data['order_id'] ?? data['orderId'] ?? orderId;
        final responsePaymentId = data['payment_id'] ?? data['paymentId'] ?? paymentId;
        final status = data['status'] ?? 'unknown';
        final amount = data['amount'] ?? 0;
        final currency = data['currency'] ?? 'INR';
        
        return PaymentStatusResponse(
          orderId: responseOrderId ?? 'unknown',
          paymentId: responsePaymentId,
          status: _parsePaymentStatus(status),
          amount: amount,
          currency: currency,
          paidAt: data['paid_at'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(data['paid_at'] * 1000)
              : null,
        );
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Status check failed: $e');
    }
  }

  /// Get order status from backend
  ///
  /// AWS Lambda endpoint: /selvan/get-order-status
  ///
  /// The backend will:
  /// 1. Receive orderId from client
  /// 2. Query DynamoDB or Razorpay API for current status
  /// 3. Return OrderDetail with current status and updatedAt
  ///
  /// This method provides a fallback mechanism to poll order status when
  /// subscriptions timeout or fail. It queries the backend for the current
  /// order status.
  ///
  /// SECURITY: Backend queries require Key_Secret on backend
  Future<OrderDetail> getOrderStatus({required String orderId}) async {
    if (useMockMode) {
      // MOCK MODE - For testing only
      await Future.delayed(const Duration(milliseconds: 400));
      
      return OrderDetail(
        orderId: orderId,
        razorpayOrderId: 'rzp_mock_${DateTime.now().millisecondsSinceEpoch}',
        amount: 10000, // ₹100.00 in paise
        currency: 'INR',
        status: 'paid',
        paymentId: 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: true,
      );
    }

    // PRODUCTION MODE - Real AWS Lambda API call
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/selvan/get-order-status?orderId=$orderId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderDetail.fromJson(data);
      } else {
        throw Exception('Failed to get order status: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Get order status failed: $e');
    }
  }

  PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'captured':
      case 'authorized':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'created':
      case 'attempted':
        return PaymentStatus.pending;
      default:
        return PaymentStatus.unknown;
    }
  }
}
