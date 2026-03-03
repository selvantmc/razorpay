import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/features/payment/services/local_storage_service.dart';
import 'package:flutter_app/models/order_detail.dart';

void main() {
  late LocalStorageService service;
  late Directory testDir;

  setUp(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('hive_test_');
    
    // Initialize Hive with the test directory
    Hive.init(testDir.path);
    
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OrderDetailAdapter());
    }
    
    // Delete any existing test data
    try {
      await Hive.deleteBoxFromDisk('orders', path: testDir.path);
    } catch (_) {
      // Box might not exist, ignore
    }
    
    service = LocalStorageService();
    await service.initialize();
  });

  tearDown(() async {
    await service.close();
    
    // Clean up test directory
    try {
      await Hive.deleteBoxFromDisk('orders', path: testDir.path);
      await testDir.delete(recursive: true);
    } catch (_) {
      // Ignore cleanup errors
    }
  });

  group('LocalStorageService CRUD Operations', () {
    test('saveOrder should save an order successfully', () async {
      // Arrange
      final order = OrderDetail(
        orderId: 'test_order_1',
        amount: 10000,
        currency: 'INR',
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );

      // Act
      await service.saveOrder(order);
      final retrieved = await service.getOrder('test_order_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.orderId, equals('test_order_1'));
      expect(retrieved.amount, equals(10000));
      expect(retrieved.status, equals('pending'));
    });

    test('getOrder should return null for non-existent order', () async {
      // Act
      final result = await service.getOrder('non_existent_order');

      // Assert
      expect(result, isNull);
    });

    test('getAllOrders should return all saved orders', () async {
      // Arrange
      final order1 = OrderDetail(
        orderId: 'order_1',
        amount: 10000,
        currency: 'INR',
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );
      final order2 = OrderDetail(
        orderId: 'order_2',
        amount: 20000,
        currency: 'INR',
        status: 'paid',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: true,
      );

      // Act
      await service.saveOrder(order1);
      await service.saveOrder(order2);
      final allOrders = await service.getAllOrders();

      // Assert
      expect(allOrders.length, equals(2));
      expect(allOrders.any((o) => o.orderId == 'order_1'), isTrue);
      expect(allOrders.any((o) => o.orderId == 'order_2'), isTrue);
    });

    test('deleteOrder should remove an order', () async {
      // Arrange
      final order = OrderDetail(
        orderId: 'order_to_delete',
        amount: 10000,
        currency: 'INR',
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );
      await service.saveOrder(order);

      // Act
      await service.deleteOrder('order_to_delete');
      final retrieved = await service.getOrder('order_to_delete');

      // Assert
      expect(retrieved, isNull);
    });

    test('updateOrder should update with newer timestamp', () async {
      // Arrange
      final oldTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final newTimestamp = oldTimestamp + 10;
      
      final originalOrder = OrderDetail(
        orderId: 'order_update_test',
        amount: 10000,
        currency: 'INR',
        status: 'pending',
        createdAt: oldTimestamp,
        updatedAt: oldTimestamp,
        isSynced: false,
      );
      
      await service.saveOrder(originalOrder);

      final updatedOrder = originalOrder.copyWith(
        status: 'paid',
        updatedAt: newTimestamp,
      );

      // Act
      final result = await service.updateOrder(updatedOrder);
      final retrieved = await service.getOrder('order_update_test');

      // Assert
      expect(result, isTrue);
      expect(retrieved!.status, equals('paid'));
      expect(retrieved.updatedAt, equals(newTimestamp));
    });

    test('updateOrder should reject stale update with older timestamp', () async {
      // Arrange
      final newTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final oldTimestamp = newTimestamp - 10;
      
      final currentOrder = OrderDetail(
        orderId: 'order_stale_test',
        amount: 10000,
        currency: 'INR',
        status: 'paid',
        createdAt: oldTimestamp,
        updatedAt: newTimestamp,
        isSynced: true,
      );
      
      await service.saveOrder(currentOrder);

      final staleUpdate = currentOrder.copyWith(
        status: 'pending',
        updatedAt: oldTimestamp,
      );

      // Act
      final result = await service.updateOrder(staleUpdate);
      final retrieved = await service.getOrder('order_stale_test');

      // Assert
      expect(result, isFalse);
      expect(retrieved!.status, equals('paid')); // Should remain unchanged
      expect(retrieved.updatedAt, equals(newTimestamp));
    });

    test('getPendingOrders should return only pending and processing orders', () async {
      // Arrange
      final pendingOrder = OrderDetail(
        orderId: 'pending_order',
        amount: 10000,
        currency: 'INR',
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );
      
      final processingOrder = OrderDetail(
        orderId: 'processing_order',
        amount: 15000,
        currency: 'INR',
        status: 'processing',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );
      
      final paidOrder = OrderDetail(
        orderId: 'paid_order',
        amount: 20000,
        currency: 'INR',
        status: 'paid',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: true,
      );

      // Act
      await service.saveOrder(pendingOrder);
      await service.saveOrder(processingOrder);
      await service.saveOrder(paidOrder);
      
      final pendingOrders = await service.getPendingOrders();

      // Assert
      expect(pendingOrders.length, equals(2));
      expect(pendingOrders.any((o) => o.orderId == 'pending_order'), isTrue);
      expect(pendingOrders.any((o) => o.orderId == 'processing_order'), isTrue);
      expect(pendingOrders.any((o) => o.orderId == 'paid_order'), isFalse);
    });
  });
}
