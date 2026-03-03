import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/order_detail.dart';

/// Service for managing local order persistence using Hive
///
/// This service provides CRUD operations for OrderDetail records with
/// timestamp-based conflict resolution. All orders are stored in a Hive box
/// named 'orders' with orderId as the key.
class LocalStorageService {
  static const String _ordersBoxName = 'orders';
  Box<OrderDetail>? _ordersBox;

  /// Initialize Hive and open the orders box
  ///
  /// This method must be called before any other operations.
  /// It registers the OrderDetailAdapter and opens the orders box.
  ///
  /// Throws [HiveError] if initialization fails.
  Future<void> initialize() async {
    try {
      // Initialize Hive for Flutter (only if not already initialized)
      if (!Hive.isBoxOpen(_ordersBoxName)) {
        // Only call initFlutter if Hive hasn't been initialized yet
        if (Hive.isAdapterRegistered(0)) {
          // Hive is already initialized (e.g., in tests with Hive.init())
          // Skip initFlutter
        } else {
          // Normal app initialization
          await Hive.initFlutter();
        }
      }
      
      // Register the OrderDetail adapter if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(OrderDetailAdapter());
      }
      
      // Open the orders box
      _ordersBox = await Hive.openBox<OrderDetail>(_ordersBoxName);
    } catch (e) {
      throw HiveError('Failed to initialize LocalStorageService: $e');
    }
  }

  /// Get the orders box, throwing if not initialized
  Box<OrderDetail> get _box {
    if (_ordersBox == null) {
      throw HiveError('LocalStorageService not initialized. Call initialize() first.');
    }
    return _ordersBox!;
  }

  /// Save a new order to local storage
  ///
  /// Uses orderId as the key. If an order with the same orderId exists,
  /// it will be overwritten.
  ///
  /// Throws [HiveError] if save operation fails.
  Future<void> saveOrder(OrderDetail order) async {
    try {
      await _box.put(order.orderId, order);
    } catch (e) {
      throw HiveError('Failed to save order ${order.orderId}: $e');
    }
  }

  /// Get order by orderId
  ///
  /// Returns the OrderDetail if found, null otherwise.
  Future<OrderDetail?> getOrder(String orderId) async {
    try {
      return _box.get(orderId);
    } catch (e) {
      throw HiveError('Failed to get order $orderId: $e');
    }
  }

  /// Get all orders
  ///
  /// Returns a list of all OrderDetail records in storage.
  /// Useful for displaying order history.
  Future<List<OrderDetail>> getAllOrders() async {
    try {
      return _box.values.toList();
    } catch (e) {
      throw HiveError('Failed to get all orders: $e');
    }
  }

  /// Get all pending orders (status: pending or processing)
  ///
  /// Returns orders that are awaiting payment confirmation.
  /// Used for resubscription on app restart.
  Future<List<OrderDetail>> getPendingOrders() async {
    try {
      return _box.values
          .where((order) => order.status == 'pending' || order.status == 'processing')
          .toList();
    } catch (e) {
      throw HiveError('Failed to get pending orders: $e');
    }
  }

  /// Update an existing order with timestamp checking
  ///
  /// Performs atomic read-compare-write operation:
  /// 1. Read current record
  /// 2. Compare updatedAt timestamps
  /// 3. Write only if new timestamp is newer
  ///
  /// Returns true if update was applied, false if discarded (stale data).
  ///
  /// Throws [HiveError] if update operation fails.
  Future<bool> updateOrder(OrderDetail order) async {
  try {
    final currentOrder = await getOrder(order.orderId);

    if (currentOrder == null) {
      await saveOrder(order);
      return true;
    }

    // ✅ CHANGE > to >= so equal timestamps still update
    if (order.updatedAt >= currentOrder.updatedAt) {
      await _box.put(order.orderId, order);
      return true;
    } else {
      print('Warning: Discarded stale update for order ${order.orderId}. '
          'Current updatedAt: ${currentOrder.updatedAt}, '
          'Received updatedAt: ${order.updatedAt}');
      return false;
    }
  } catch (e) {
    throw HiveError('Failed to update order ${order.orderId}: $e');
  }
}

  /// Delete an order by orderId
  ///
  /// Used for cleanup and testing purposes.
  ///
  /// Throws [HiveError] if delete operation fails.
  Future<void> deleteOrder(String orderId) async {
    try {
      await _box.delete(orderId);
    } catch (e) {
      throw HiveError('Failed to delete order $orderId: $e');
    }
  }

  /// Close the Hive box
  ///
  /// Should be called when the service is no longer needed.
  Future<void> close() async {
    try {
      await _ordersBox?.close();
      _ordersBox = null;
    } catch (e) {
      throw HiveError('Failed to close LocalStorageService: $e');
    }
  }
}
