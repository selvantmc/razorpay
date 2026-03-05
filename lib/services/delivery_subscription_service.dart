import 'dart:async';
import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class DeliverySubscriptionService {
  final Map<String, StreamSubscription<GraphQLResponse<String>>>
      _activeSubscriptions = {};

  // StreamController broadcasts updates to any listener on the main thread
  final _deliveryController = StreamController<Map<String, dynamic>>.broadcast();

  // Public stream — screens listen to this
  Stream<Map<String, dynamic>> get deliveryUpdates => _deliveryController.stream;

  DeliverySubscriptionService();

  int get activeSubscriptionCount => _activeSubscriptions.length;

  Future<void> subscribeToDelivery(String orderId) async {
    await cancelSubscription(orderId);

    int attempts = 0;
    const maxAttempts = 3;
    const retryDelay = Duration(seconds: 5);

    while (attempts < maxAttempts) {
      attempts++;
      try {
        print('DeliverySubscriptionService: Subscribing to $orderId (attempt $attempts/$maxAttempts)');

        const subscriptionDocument = '''
          subscription OnDeliveryUpdated(\$order_id: String) {
            onDeliveryUpdated(order_id: \$order_id) {
              key
              order_id
              delivery_lat
              delivery_lng
              delivery_status
              partner_id
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
            print('DeliverySubscriptionService: ✅ Subscription established for $orderId');
          },
        );

        final subscription = operation.listen(
          (event) => _handleDeliveryUpdate(orderId, event),
          onError: (error) {
            print('DeliverySubscriptionService: Error for $orderId: $error');
          },
          onDone: () {
            print('DeliverySubscriptionService: Subscription done for $orderId');
            _activeSubscriptions.remove(orderId);
          },
        );

        _activeSubscriptions[orderId] = subscription;
        print('DeliverySubscriptionService: Successfully subscribed to $orderId');
        return;

      } catch (e) {
        print('DeliverySubscriptionService: Failed attempt $attempts for $orderId: $e');
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

  Future<void> _handleDeliveryUpdate(
    String orderId,
    GraphQLResponse<String> event,
  ) async {
    print('🚴 RAW delivery event received for $orderId');
    print('   hasErrors: ${event.hasErrors}');
    print('   data: ${event.data}');

    try {
      if (event.hasErrors) {
        print('DeliverySubscriptionService: GraphQL errors: ${event.errors}');
        return;
      }

      if (event.data == null) {
        print('DeliverySubscriptionService: No data for $orderId');
        return;
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(event.data!);
      final Map<String, dynamic>? deliveryJson =
          jsonResponse['onDeliveryUpdated'] as Map<String, dynamic>?;

      if (deliveryJson == null) {
        print('DeliverySubscriptionService: No onDeliveryUpdated data for $orderId');
        return;
      }

      print('🚴 Delivery update: status=${deliveryJson['delivery_status']}, lat=${deliveryJson['delivery_lat']}, lng=${deliveryJson['delivery_lng']}');

      // Push to StreamController — this reaches UI thread safely
      if (!_deliveryController.isClosed) {
        _deliveryController.add(deliveryJson);
        print('DeliverySubscriptionService: Event pushed to stream ✅');
      }

    } catch (e) {
      print('DeliverySubscriptionService: Error handling update for $orderId: $e');
    }
  }

  Future<void> cancelSubscription(String orderId) async {
    final subscription = _activeSubscriptions.remove(orderId);
    if (subscription != null) {
      await subscription.cancel();
      print('DeliverySubscriptionService: Cancelled subscription for $orderId');
    }
  }

  Future<void> cancelAllSubscriptions() async {
    final orderIds = _activeSubscriptions.keys.toList();
    for (final orderId in orderIds) {
      await cancelSubscription(orderId);
    }
    print('DeliverySubscriptionService: Cancelled all ${orderIds.length} subscriptions');
  }

  void dispose() {
    _deliveryController.close();
    for (final sub in _activeSubscriptions.values) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
    print('DeliverySubscriptionService: Disposed');
  }
}
