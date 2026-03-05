import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'amplifyconfiguration.dart';
import 'main_scaffold.dart';
import 'features/payment/services/local_storage_service.dart';
import 'features/payment/services/subscription_service.dart';
import 'features/payment/services/local_notification_service.dart';
import 'models/order_detail.dart';
import 'models/delivery_location.dart';
import 'services/location_service.dart';
import 'screens/location_screen.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Hive FIRST before anything else
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(OrderDetailAdapter());
  }
  await Hive.openBox<OrderDetail>('orders');

  // Configure Amplify
  await _configureAmplify();

  // Initialize services
  final localStorageService      = LocalStorageService();
  final localNotificationService = LocalNotificationService();
  final subscriptionService      = SubscriptionService(
    localStorageService:      localStorageService,
    localNotificationService: localNotificationService,
  );

  // LocalStorageService.initialize() will now skip re-init since box is already open
  await localStorageService.initialize();
  await localNotificationService.initialize();

  // Resubscribe to pending orders
  final pendingOrders = await localStorageService.getPendingOrders();
  for (final order in pendingOrders) {
    try {
      await subscriptionService.subscribeToOrder(order.orderId);
    } catch (e) {
      debugPrint('Failed to resubscribe to ${order.orderId}: $e');
    }
  }

  // Check for saved delivery location
  final locationService = LocationService();
  final savedLocation = await locationService.getSavedLocation();

  runApp(MyApp(savedLocation: savedLocation));
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAPI());
    await Amplify.configure(amplifyconfig);
    debugPrint('✅ Amplify configured successfully');
  } on AmplifyAlreadyConfiguredException {
    debugPrint('Amplify already configured');
  } catch (e) {
    debugPrint('❌ Amplify configuration error: $e');
  }
}

class MyApp extends StatelessWidget {
  final DeliveryLocation? savedLocation;

  const MyApp({super.key, this.savedLocation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nourisha Pay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: savedLocation != null
          ? MenuScreen(location: savedLocation!)
          : const LocationScreen(),
    );
  }
}