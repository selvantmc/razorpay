import 'dart:async';
import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'local_storage_service.dart';
import 'local_notification_service.dart';
import '../../../models/order_detail.dart';

class SubscriptionService {
  final LocalStorageService _localStorageService;
  final LocalNotificationService _localNotificationService;

  final Map<String, StreamSubscription<GraphQLResponse<String>>>
      _activeSubscriptions = {};

  // ✅ StreamController broadcasts updates to any listener on the main thread
  final _updateController = StreamController<Map<String, dynamic>>.broadcast();

  // ✅ Public stream — screens listen to this
  Stream<Map<String, dynamic>> get orderUpdates => _updateController.stream;

  // ✅ Keep callback for backwards compatibility
  Function(Map<String, dynamic> update)? onOrderUpdated;

  SubscriptionService({
    required LocalStorageService localStorageService,
    required LocalNotificationService localNotificationService,
  })  : _localStorageService = localStorageService,
        _localNotificationService = localNotificationService;

  int get activeSubscriptionCount => _activeSubscriptions.length;

  Future<void> subscribeToOrder(String orderId) async {
    await cancelSubscription(orderId);

    int attempts = 0;
    const maxAttempts = 3;
    const retryDelay = Duration(seconds: 5);

    while (attempts < maxAttempts) {
      attempts++;
      try {
        print('SubscriptionService: Subscribing to $orderId (attempt $attempts/$maxAttempts)');

        const subscriptionDocument = '''
          subscription OnOrderUpdated(\$order_id: String) {
            onOrderUpdated(order_id: \$order_id) {
              key
              order_id
              amount
              currency
              status
              payment_id
              created_at
              updated_at
            }
          }
        ''';

        final subscriptionRequest = GraphQLRequest<String>(
          document: subscriptionDocument,
          variables: {'order_id': orderId},
        );

        final operation = Amplify.API.subscribe(
          subscriptionRequest,
          onEstablished: () {
            print('SubscriptionService: ✅ Subscription established for $orderId');
          },
        );

        final subscription = operation.listen(
          (event) => _handleSubscriptionUpdate(orderId, event),
          onError: (error) {
            print('SubscriptionService: Error for $orderId: $error');
          },
          onDone: () {
            print('SubscriptionService: Subscription done for $orderId');
            _activeSubscriptions.remove(orderId);
          },
        );

        _activeSubscriptions[orderId] = subscription;
        print('SubscriptionService: Successfully subscribed to $orderId');
        return;

      } catch (e) {
        print('SubscriptionService: Failed attempt $attempts for $orderId: $e');
        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        } else {
          throw Exception(
            'Failed to subscribe to $orderId after $maxAttempts attempts: $e',
          );
        }
      }
    }
  }

  Future<void> _handleSubscriptionUpdate(
    String orderId,
    GraphQLResponse<String> event,
  ) async {
    print('🔔 RAW subscription event received for $orderId');
    print('   hasErrors: ${event.hasErrors}');
    print('   errors: ${event.errors}');
    print('   data: ${event.data}');

    try {
      if (event.hasErrors) {
        print('SubscriptionService: GraphQL errors: ${event.errors}');
        return;
      }

      if (event.data == null) {
        print('SubscriptionService: No data for $orderId');
        return;
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(event.data!);
      final Map<String, dynamic>? orderJson =
          jsonResponse['onOrderUpdated'] as Map<String, dynamic>?;

      if (orderJson == null) {
        print('SubscriptionService: No onOrderUpdated data for $orderId');
        return;
      }

      print('SubscriptionService: Received update — status: ${orderJson['status']}');

      final orderData = OrderDetail.fromJson(orderJson);
      final previousOrder = await _localStorageService.getOrder(orderId);
      final updated = await _localStorageService.updateOrder(orderData);

      if (updated) {
        print('SubscriptionService: Updated $orderId → ${orderData.status}');
        print('SubscriptionService: onOrderUpdated callback is ${onOrderUpdated == null ? "NULL ❌" : "SET ✅"}');

        // ✅ Push to StreamController — this reaches UI thread safely
        if (!_updateController.isClosed) {
          _updateController.add(orderJson);
          print('SubscriptionService: Event pushed to stream ✅');
        }

        // ✅ Also call direct callback as fallback
        onOrderUpdated?.call(orderJson);

        // Notification
        if (previousOrder != null &&
            !_localNotificationService.isAppInForeground) {
          final newStatus = orderData.status;
          if (['paid', 'captured', 'verified'].contains(newStatus)) {
            await _localNotificationService.showPaymentSuccessNotification(
              orderId: orderId,
              amount: orderData.amount,
            );
          }
        }

        // Auto-cancel after short delay so stream event delivers first
        if (['paid', 'captured', 'verified'].contains(orderData.status)) {
          print('SubscriptionService: Final status — cancelling subscription for $orderId');
          Future.delayed(const Duration(milliseconds: 500), () {
            cancelSubscription(orderId);
          });
        }

      } else {
        print('SubscriptionService: Stale update discarded for $orderId');
      }
    } catch (e) {
      print('SubscriptionService: Error handling update for $orderId: $e');
    }
  }

  Future<void> cancelSubscription(String orderId) async {
    final subscription = _activeSubscriptions.remove(orderId);
    if (subscription != null) {
      await subscription.cancel();
      print('SubscriptionService: Cancelled subscription for $orderId');
    }
  }

  Future<void> cancelAllSubscriptions() async {
    final orderIds = _activeSubscriptions.keys.toList();
    for (final orderId in orderIds) {
      await cancelSubscription(orderId);
    }
    print('SubscriptionService: Cancelled all ${orderIds.length} subscriptions');
  }

  void dispose() {
    _updateController.close();
    for (final sub in _activeSubscriptions.values) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
    print('SubscriptionService: Disposed');
  }
}