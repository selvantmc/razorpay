import 'package:flutter/material.dart';
import 'models/payment_session.dart';
import 'screens/payment_screen.dart';
import 'screens/order_lookup_screen.dart';
import 'features/payment/services/local_notification_service.dart';

/// Root navigation container managing screen transitions and bottom navigation bar.
///
/// This widget provides the main navigation structure with:
/// - Bottom navigation bar with two tabs (Payment and Orders)
/// - State preservation when switching between screens
/// - Shared PaymentSession instance across both screens
/// - App lifecycle tracking for notification foreground detection
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final PaymentSession _session = PaymentSession();
  final GlobalKey<State<PaymentScreen>> _paymentScreenKey = GlobalKey();
  final GlobalKey<State<OrderLookupScreen>> _orderLookupScreenKey = GlobalKey();
  final LocalNotificationService _notificationService = LocalNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update notification service foreground state based on app lifecycle
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground and visible
        _notificationService.isAppInForeground = true;
        debugPrint('App lifecycle: resumed (foreground)');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is in background or not visible
        _notificationService.isAppInForeground = false;
        debugPrint('App lifecycle: ${state.name} (background)');
        break;
    }
  }

  void _onItemTapped(int index) {
    // Clear local data when switching tabs
    if (index == 0) {
      (_paymentScreenKey.currentState as dynamic)?.clearLocalData();
    } else if (index == 1) {
      (_orderLookupScreenKey.currentState as dynamic)?.clearLocalData();
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PaymentScreen(key: _paymentScreenKey, session: _session),
          OrderLookupScreen(key: _orderLookupScreenKey, session: _session),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
