/// Nourisha POS Payment Module
///
/// A secure, reusable Flutter component for processing payments through Razorpay
/// in Point-of-Sale environments.
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_app/features/payment/payment_module.dart';
///
/// // Navigate to payment screen
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => RazorpayPosScreen()),
/// );
/// ```
///
/// ## Advanced Usage
///
/// For custom integrations, you can use the PaymentService directly:
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// final backendApi = BackendApiService(baseUrl: 'https://api.nourisha.com');
/// final paymentService = PaymentService(
///   backendApi: backendApi,
///   prefs: prefs,
/// );
///
/// await paymentService.openCheckout(
///   amount: 10000, // Amount in paise (₹100.00)
///   reference: 'Order #123',
/// );
/// ```
///
/// ## Security
///
/// This module follows security best practices:
/// - Razorpay Key_Secret is NEVER stored in client code
/// - All sensitive operations (order creation, verification) are delegated to backend
/// - Only Razorpay Key_ID is used client-side
///
library payment_module;

// Export UI components
export 'screens/razorpay_pos_screen.dart';

// Export services for advanced use cases
export 'services/payment_service.dart';
export 'services/backend_api_service.dart';

// Export all model classes
export 'models/payment_models.dart';
