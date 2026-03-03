import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service for managing local notifications related to payment status changes.
///
/// This service handles:
/// - Initialization of notification plugin and permissions
/// - Showing notifications for payment success/failure
/// - Checking if app is in foreground to avoid duplicate notifications
///
/// This is a singleton to ensure consistent foreground state tracking across the app.
///
/// Requirements: 6.1, 6.2, 6.3, 6.4
class LocalNotificationService {
  // Singleton pattern
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  
  factory LocalNotificationService() {
    return _instance;
  }
  
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isAppInForeground = true;

  /// Check if app is currently in foreground
  bool get isAppInForeground => _isAppInForeground;

  /// Set app foreground state (should be called from app lifecycle observer)
  set isAppInForeground(bool value) {
    _isAppInForeground = value;
  }

  /// Initialize notification plugin and request permissions
  ///
  /// Sets up:
  /// - Android notification channel with high importance
  /// - iOS notification permissions
  /// - Notification tap handlers
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('LocalNotificationService already initialized');
      return;
    }

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      await _createNotificationChannel();

      // Request permissions for iOS
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('LocalNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize LocalNotificationService: $e');
      rethrow;
    }
  }

  /// Create Android notification channel for payment updates
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'payment_updates',
      'Payment Updates',
      description: 'Notifications for payment status changes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('Created notification channel: payment_updates');
  }

  /// Request notification permissions (primarily for iOS)
  Future<void> _requestPermissions() async {
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Requested iOS notification permissions');
    }

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      debugPrint('Requested Android notification permissions');
    }
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    // TODO: Navigate to order details screen
    // This will be implemented when integrating with navigation
    // Expected payload format: orderId
    if (response.payload != null) {
      debugPrint('Navigate to order: ${response.payload}');
    }
  }

  /// Show notification for payment success
  ///
  /// Only shows if app is in background to avoid duplicate notifications
  /// when user is viewing the payment screen.
  ///
  /// Requirements: 6.1, 6.3, 6.5, 6.6
  Future<void> showPaymentSuccessNotification({
    required String orderId,
    required int amount,
  }) async {
    if (!_isInitialized) {
      debugPrint('Cannot show notification: service not initialized');
      return;
    }

    if (_isAppInForeground) {
      debugPrint('Skipping notification: app is in foreground');
      return;
    }

    final formattedAmount = _formatAmount(amount);

    const androidDetails = AndroidNotificationDetails(
      'payment_updates',
      'Payment Updates',
      channelDescription: 'Notifications for payment status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      orderId.hashCode, // Use orderId hash as notification ID
      'Payment Successful',
      'Your payment of $formattedAmount has been confirmed',
      notificationDetails,
      payload: orderId,
    );

    debugPrint('Showed payment success notification for order: $orderId');
  }

  /// Show notification for payment failure
  ///
  /// Only shows if app is in background to avoid duplicate notifications
  /// when user is viewing the payment screen.
  ///
  /// Requirements: 6.2, 6.4, 6.5, 6.6
  Future<void> showPaymentFailureNotification({
    required String orderId,
    required int amount,
  }) async {
    if (!_isInitialized) {
      debugPrint('Cannot show notification: service not initialized');
      return;
    }

    if (_isAppInForeground) {
      debugPrint('Skipping notification: app is in foreground');
      return;
    }

    final formattedAmount = _formatAmount(amount);

    const androidDetails = AndroidNotificationDetails(
      'payment_updates',
      'Payment Updates',
      channelDescription: 'Notifications for payment status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      orderId.hashCode, // Use orderId hash as notification ID
      'Payment Failed',
      'Your payment of $formattedAmount could not be processed',
      notificationDetails,
      payload: orderId,
    );

    debugPrint('Showed payment failure notification for order: $orderId');
  }

  /// Format amount in paise to rupees with ₹ symbol
  ///
  /// Example: 10000 paise → ₹100.00
  String _formatAmount(int amountInPaise) {
    final amountInRupees = amountInPaise / 100;
    return '₹${amountInRupees.toStringAsFixed(2)}';
  }
}
