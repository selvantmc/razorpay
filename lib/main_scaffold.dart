import 'package:flutter/material.dart';
import 'models/payment_session.dart';
import 'screens/payment_screen.dart';
import 'screens/order_lookup_screen.dart';

/// Root navigation container managing screen transitions and bottom navigation bar.
///
/// This widget provides the main navigation structure with:
/// - Bottom navigation bar with two tabs (Payment and Orders)
/// - State preservation when switching between screens
/// - Shared PaymentSession instance across both screens
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final PaymentSession _session = PaymentSession();
  final GlobalKey<State<PaymentScreen>> _paymentScreenKey = GlobalKey();
  final GlobalKey<State<OrderLookupScreen>> _orderLookupScreenKey = GlobalKey();

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
