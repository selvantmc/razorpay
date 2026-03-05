import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/order_detail.dart';

/// Centralized API service for all backend communication
class PaymentApi {
  /// Base URL for AWS API Gateway endpoint
  static const String baseUrl =
      'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan';

  /// Timeout duration for all HTTP requests
  static const Duration timeout = Duration(seconds: 15);

  /// Creates a new payment order with the specified amount
  ///
  /// [amount] - Amount in rupees (will be converted to paise by backend)
  /// Returns order details including order ID
  /// Throws Exception with user-friendly message on error
  static Future<Map<String, dynamic>> createOrder(double amount) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/create-order'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'amount': amount}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Verifies payment signature after successful Razorpay payment
  ///
  /// [orderId] - Razorpay order ID
  /// [paymentId] - Razorpay payment ID
  /// [signature] - Razorpay signature for verification
  /// Returns verification result
  /// Throws Exception with user-friendly message on error
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-payment'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'order_id': orderId,
              'payment_id': paymentId,
              'signature': signature,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Checks the current payment status for an order
  ///
  /// [orderId] - Order ID to check status for
  /// Returns payment status information
  /// Throws Exception with user-friendly message on error
  static Future<Map<String, dynamic>> checkPaymentStatus(
      String orderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/check-payment-status?order_id=$orderId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Retrieves complete order details from the database
  ///
  /// [orderId] - Order ID to fetch
  /// Returns OrderDetail object with all order information
  /// Throws Exception with user-friendly message on error
  static Future<OrderDetail> getOrder(String orderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/get-order?order_id=$orderId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
final orderData = json['order'] as Map<String, dynamic>;
return OrderDetail.fromJson(orderData);
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Extracts user-friendly error message from HTTP response
  ///
  /// Attempts to parse error from response body, falls back to generic message
  static String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('error')) {
        return body['error'] as String;
      }
      if (body is Map && body.containsKey('message')) {
        return body['message'] as String;
      }
    } catch (_) {
      // If JSON parsing fails, fall through to generic message
    }
    return 'Request failed with status ${response.statusCode}';
  }

  /// Creates order with delivery details for tracking
  ///
  /// [amount] - Amount in rupees (will be converted to paise by backend)
  /// [deviceId] - Unique device identifier for order tracking
  /// [deliveryLat] - Customer delivery latitude
  /// [deliveryLng] - Customer delivery longitude
  /// [deliveryAddress] - Full delivery address string
  /// Returns order details including order ID
  /// Throws Exception with user-friendly message on error
  static Future<Map<String, dynamic>> createOrderWithDetails({
    required double amount,
    required String deviceId,
    required double deliveryLat,
    required double deliveryLng,
    required String deliveryAddress,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/create-order'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'device_id': deviceId,
              'delivery_lat_customer': deliveryLat,
              'delivery_lng_customer': deliveryLng,
              'delivery_address': deliveryAddress,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Fetches all orders for a device
  ///
  /// [deviceId] - Device ID to fetch orders for
  /// Returns list of order maps with all order details
  /// Throws Exception with user-friendly message on error
  static Future<List<Map<String, dynamic>>> getMyOrders(String deviceId) async {
    try {
      final url = '$baseUrl/get-my-orders?device_id=$deviceId&limit=20';
      print('PaymentApi: Fetching orders from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      print('PaymentApi: Response status: ${response.statusCode}');
      print('PaymentApi: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Check if orders key exists
        if (!json.containsKey('orders')) {
          print('PaymentApi: Response does not contain orders key');
          return [];
        }
        
        final orders = json['orders'];
        if (orders == null) {
          return [];
        }
        
        return (orders as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      print('PaymentApi: Error fetching orders: $e');
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Updates delivery partner location
  ///
  /// [orderId] - Order ID to update location for
  /// [partnerId] - Delivery partner ID
  /// [lat] - Current partner latitude
  /// [lng] - Current partner longitude
  /// Returns response map including is_nearby field
  /// Throws Exception with user-friendly message on error
  static Future<Map<String, dynamic>> updateDeliveryLocation({
    required String orderId,
    required String partnerId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/update-delivery-location'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'order_id': orderId,
              'partner_id': partnerId,
              'lat': lat,
              'lng': lng,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Updates order delivery status
  ///
  /// [orderId] - Order ID to update status for
  /// [partnerId] - Delivery partner ID
  /// [deliveryStatus] - New delivery status (confirmed/preparing/picked_up/nearby/delivered)
  /// Throws Exception with user-friendly message on error
  static Future<void> updateOrderStatus({
    required String orderId,
    required String partnerId,
    required String deliveryStatus,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/update-order-status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'order_id': orderId,
              'partner_id': partnerId,
              'delivery_status': deliveryStatus,
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }
}
