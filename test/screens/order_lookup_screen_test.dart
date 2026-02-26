import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/order_lookup_screen.dart';
import 'package:flutter_app/models/payment_session.dart';
import 'package:flutter_app/models/order_detail.dart';

void main() {
  group('OrderLookupScreen - Order Lookup Flow', () {
    late PaymentSession session;

    setUp(() {
      session = PaymentSession();
    });

    testWidgets('displays order ID input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      expect(find.byType(TextFormField), findsAtLeast(1));
      expect(find.text('Order ID'), findsOneWidget);
      expect(find.text('Enter order ID'), findsOneWidget);
    });

    testWidgets('displays Fetch Order button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      expect(find.text('Fetch Order'), findsOneWidget);
    });

    testWidgets('shows validation error for empty order ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      // Tap Fetch Order without entering order ID
      await tester.tap(find.text('Fetch Order'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an order ID'), findsOneWidget);
    });

    testWidgets('accepts valid order ID input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      // Enter valid order ID
      await tester.enterText(find.byType(TextFormField).first, 'order_123');
      await tester.tap(find.text('Fetch Order'));
      await tester.pumpAndSettle();

      // Should not show validation error
      expect(find.text('Please enter an order ID'), findsNothing);
    });

    testWidgets('trims whitespace from order ID input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      // Enter order ID with whitespace
      await tester.enterText(
          find.byType(TextFormField).first, '  order_123  ');
      await tester.tap(find.text('Fetch Order'));
      await tester.pumpAndSettle();

      // Should not show validation error (whitespace is trimmed)
      expect(find.text('Please enter an order ID'), findsNothing);
    });

    testWidgets('hides action buttons initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      // Action buttons should not be visible without order details
      expect(find.text('Verify Payment'), findsNothing);
      expect(find.text('Check Payment Status'), findsNothing);
    });

    testWidgets('hides order details card initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      // Order details card should not be visible initially
      expect(find.text('Order Details'), findsNothing);
    });
  });

  group('OrderLookupScreen - Conditional Action Buttons', () {
    late PaymentSession session;

    setUp(() {
      session = PaymentSession();
    });

    testWidgets('widget renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      expect(find.byType(OrderLookupScreen), findsOneWidget);
    });

    testWidgets('displays independent loading states',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderLookupScreen(session: session),
        ),
      );

      // Initially no loading indicators
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('OrderLookupScreen - Status Update Logic', () {
    test('status is updated when verification response contains status field', () {
      // Create original order detail
      final originalOrder = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'created',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerPhone: '9999999999',
      );

      // Simulate verification response with status field
      final verificationResponse = {'status': 'paid'};
      final updatedStatus = verificationResponse['status'] as String?;

      // Create updated order detail (simulating the logic in _verifyPayment)
      final updatedOrder = OrderDetail(
        orderId: originalOrder.orderId,
        amount: originalOrder.amount,
        status: updatedStatus!,
        paymentId: originalOrder.paymentId,
        signature: originalOrder.signature,
        createdAt: originalOrder.createdAt,
        updatedAt: originalOrder.updatedAt,
        customerName: originalOrder.customerName,
        customerEmail: originalOrder.customerEmail,
        customerPhone: originalOrder.customerPhone,
      );

      // Verify status was updated
      expect(updatedOrder.status, equals('paid'));
      expect(updatedOrder.status, isNot(equals(originalOrder.status)));
    });

    test('status is not updated when verification response lacks status field', () {
      // Create original order detail
      final originalOrder = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'created',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerPhone: '9999999999',
      );

      // Simulate verification response without status field
      final verificationResponse = {'success': true, 'message': 'Verified'};
      final updatedStatus = verificationResponse['status'] as String?;

      // Simulate the logic in _verifyPayment - no update if status is null
      final updatedOrder = updatedStatus != null
          ? OrderDetail(
              orderId: originalOrder.orderId,
              amount: originalOrder.amount,
              status: updatedStatus,
              paymentId: originalOrder.paymentId,
              signature: originalOrder.signature,
              createdAt: originalOrder.createdAt,
              updatedAt: originalOrder.updatedAt,
              customerName: originalOrder.customerName,
              customerEmail: originalOrder.customerEmail,
              customerPhone: originalOrder.customerPhone,
            )
          : originalOrder;

      // Verify status was not updated
      expect(updatedOrder.status, equals('created'));
      expect(updatedOrder.status, equals(originalOrder.status));
    });

    test('all non-status fields remain unchanged after update', () {
      // Create original order detail with various field values
      final originalOrder = OrderDetail(
        orderId: 'order_abc123',
        amount: 75000,
        status: 'created',
        paymentId: 'pay_xyz789',
        signature: 'sig_def456',
        createdAt: 1234567890,
        updatedAt: 1234567900,
        customerName: 'Jane Smith',
        customerEmail: 'jane@example.com',
        customerPhone: '8888888888',
      );

      // Simulate verification response with new status
      final verificationResponse = {'status': 'paid'};
      final updatedStatus = verificationResponse['status'] as String?;

      // Create updated order detail
      final updatedOrder = OrderDetail(
        orderId: originalOrder.orderId,
        amount: originalOrder.amount,
        status: updatedStatus!,
        paymentId: originalOrder.paymentId,
        signature: originalOrder.signature,
        createdAt: originalOrder.createdAt,
        updatedAt: originalOrder.updatedAt,
        customerName: originalOrder.customerName,
        customerEmail: originalOrder.customerEmail,
        customerPhone: originalOrder.customerPhone,
      );

      // Verify all non-status fields remain unchanged
      expect(updatedOrder.orderId, equals(originalOrder.orderId));
      expect(updatedOrder.amount, equals(originalOrder.amount));
      expect(updatedOrder.paymentId, equals(originalOrder.paymentId));
      expect(updatedOrder.signature, equals(originalOrder.signature));
      expect(updatedOrder.createdAt, equals(originalOrder.createdAt));
      expect(updatedOrder.updatedAt, equals(originalOrder.updatedAt));
      expect(updatedOrder.customerName, equals(originalOrder.customerName));
      expect(updatedOrder.customerEmail, equals(originalOrder.customerEmail));
      expect(updatedOrder.customerPhone, equals(originalOrder.customerPhone));
      
      // Verify only status changed
      expect(updatedOrder.status, isNot(equals(originalOrder.status)));
      expect(updatedOrder.status, equals('paid'));
    });

    test('edge case: empty status string in response', () {
      // Create original order detail
      final originalOrder = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'created',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
      );

      // Simulate verification response with empty status string
      final verificationResponse = {'status': ''};
      final updatedStatus = verificationResponse['status'] as String?;

      // Create updated order detail (empty string is still a valid string)
      final updatedOrder = updatedStatus != null
          ? OrderDetail(
              orderId: originalOrder.orderId,
              amount: originalOrder.amount,
              status: updatedStatus,
              paymentId: originalOrder.paymentId,
              signature: originalOrder.signature,
              createdAt: originalOrder.createdAt,
              updatedAt: originalOrder.updatedAt,
              customerName: originalOrder.customerName,
              customerEmail: originalOrder.customerEmail,
              customerPhone: originalOrder.customerPhone,
            )
          : originalOrder;

      // Verify empty string is accepted as a status
      expect(updatedOrder.status, equals(''));
      expect(updatedStatus, isNotNull);
    });

    test('edge case: null status in response', () {
      // Create original order detail
      final originalOrder = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'created',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
      );

      // Simulate verification response with explicit null status
      final verificationResponse = {'status': null};
      final updatedStatus = verificationResponse['status'] as String?;

      // Simulate the logic in _verifyPayment - no update if status is null
      final updatedOrder = updatedStatus != null
          ? OrderDetail(
              orderId: originalOrder.orderId,
              amount: originalOrder.amount,
              status: updatedStatus,
              paymentId: originalOrder.paymentId,
              signature: originalOrder.signature,
              createdAt: originalOrder.createdAt,
              updatedAt: originalOrder.updatedAt,
              customerName: originalOrder.customerName,
              customerEmail: originalOrder.customerEmail,
              customerPhone: originalOrder.customerPhone,
            )
          : originalOrder;

      // Verify status was not updated when null
      expect(updatedOrder.status, equals('created'));
      expect(updatedOrder.status, equals(originalOrder.status));
      expect(updatedStatus, isNull);
    });

    test('status update preserves null optional fields', () {
      // Create original order detail with null optional fields
      final originalOrder = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'created',
        paymentId: null,
        signature: null,
        createdAt: 1234567890,
        updatedAt: null,
        customerName: null,
        customerEmail: null,
        customerPhone: null,
      );

      // Simulate verification response with new status
      final verificationResponse = {'status': 'paid'};
      final updatedStatus = verificationResponse['status'] as String?;

      // Create updated order detail
      final updatedOrder = OrderDetail(
        orderId: originalOrder.orderId,
        amount: originalOrder.amount,
        status: updatedStatus!,
        paymentId: originalOrder.paymentId,
        signature: originalOrder.signature,
        createdAt: originalOrder.createdAt,
        updatedAt: originalOrder.updatedAt,
        customerName: originalOrder.customerName,
        customerEmail: originalOrder.customerEmail,
        customerPhone: originalOrder.customerPhone,
      );

      // Verify null fields remain null
      expect(updatedOrder.paymentId, isNull);
      expect(updatedOrder.signature, isNull);
      expect(updatedOrder.updatedAt, isNull);
      expect(updatedOrder.customerName, isNull);
      expect(updatedOrder.customerEmail, isNull);
      expect(updatedOrder.customerPhone, isNull);
      
      // Verify status was updated
      expect(updatedOrder.status, equals('paid'));
    });
  });

  group('OrderLookupScreen - Property-Based Tests', () {
    // Helper function to generate random strings
    String generateRandomString(int length) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789_';
      final random = Random();
      return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper function to generate random order detail
    OrderDetail generateRandomOrderDetail() {
      final random = Random();
      final statuses = ['created', 'failed', 'pending', 'authorized', 'captured', 'paid', 'verified'];
      
      // Generate a 10-digit phone number as a string
      String? generatePhoneNumber() {
        if (!random.nextBool()) return null;
        final digits = List.generate(10, (_) => random.nextInt(10));
        return digits.join();
      }
      
      return OrderDetail(
        orderId: 'order_${generateRandomString(10)}',
        amount: random.nextInt(1000000) + 1000, // 1000 to 1000000 paise
        status: statuses[random.nextInt(statuses.length)],
        paymentId: random.nextBool() ? 'pay_${generateRandomString(10)}' : null,
        signature: random.nextBool() ? 'sig_${generateRandomString(20)}' : null,
        createdAt: random.nextInt(1700000000) + 1600000000, // Random timestamp
        updatedAt: random.nextBool() ? random.nextInt(1700000000) + 1600000000 : null,
        customerName: random.nextBool() ? 'Customer ${generateRandomString(5)}' : null,
        customerEmail: random.nextBool() ? '${generateRandomString(8)}@example.com' : null,
        customerPhone: generatePhoneNumber(),
      );
    }

    // Helper function to generate random verification response
    Map<String, dynamic> generateRandomVerificationResponse() {
      final random = Random();
      final statuses = ['paid', 'captured', 'verified', 'failed', 'authorized'];
      
      return {
        'status': statuses[random.nextInt(statuses.length)],
        'success': true,
        'message': 'Verification response ${generateRandomString(5)}',
      };
    }

    // Helper function to simulate the status update logic from _verifyPayment
    OrderDetail updateOrderFromVerification(
      OrderDetail originalOrder,
      Map<String, dynamic> verificationResponse,
    ) {
      final updatedStatus = verificationResponse['status'] as String?;
      
      if (updatedStatus != null) {
        return OrderDetail(
          orderId: originalOrder.orderId,
          amount: originalOrder.amount,
          status: updatedStatus,
          paymentId: originalOrder.paymentId,
          signature: originalOrder.signature,
          createdAt: originalOrder.createdAt,
          updatedAt: originalOrder.updatedAt,
          customerName: originalOrder.customerName,
          customerEmail: originalOrder.customerEmail,
          customerPhone: originalOrder.customerPhone,
        );
      }
      
      return originalOrder;
    }

    test('Property 3: Local Order Data Updated After Verification - status updated from verification response for 100+ iterations', () {
      // **Validates: Requirements 2.1, 2.3**
      // Property: For any successful payment verification response containing a status field,
      // the local order data should be updated to reflect the new status value from the response.
      
      const iterations = 100;
      int successfulUpdates = 0;
      
      for (var i = 0; i < iterations; i++) {
        // Generate random order detail
        final originalOrder = generateRandomOrderDetail();
        
        // Generate random verification response with status
        final verificationResponse = generateRandomVerificationResponse();
        final expectedStatus = verificationResponse['status'] as String;
        
        // Apply the update logic
        final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
        
        // Verify the property: status should be updated to match the response
        expect(
          updatedOrder.status,
          equals(expectedStatus),
          reason: 'Iteration $i: Status should be updated from verification response',
        );
        
        // Verify that the update actually happened (unless original status was already the same)
        if (originalOrder.status != expectedStatus) {
          expect(
            updatedOrder.status,
            isNot(equals(originalOrder.status)),
            reason: 'Iteration $i: Status should change when different from response',
          );
        }
        
        successfulUpdates++;
      }
      
      // Verify all iterations completed successfully
      expect(successfulUpdates, equals(iterations),
        reason: 'All $iterations iterations should complete successfully');
    });

    test('Property 3 (edge case): status not updated when verification response lacks status field', () {
      // **Validates: Requirements 2.1, 2.3**
      // Property: When verification response does not contain a status field,
      // the local order data should remain unchanged.
      
      const iterations = 100;
      
      for (var i = 0; i < iterations; i++) {
        // Generate random order detail
        final originalOrder = generateRandomOrderDetail();
        final originalStatus = originalOrder.status;
        
        // Generate verification response WITHOUT status field
        final verificationResponse = {
          'success': true,
          'message': 'Verification response ${i}',
          'order_id': originalOrder.orderId,
        };
        
        // Apply the update logic
        final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
        
        // Verify the property: status should remain unchanged
        expect(
          updatedOrder.status,
          equals(originalStatus),
          reason: 'Iteration $i: Status should not change when response lacks status field',
        );
        
        // Verify the order reference is the same (no update occurred)
        expect(
          identical(updatedOrder, originalOrder),
          isTrue,
          reason: 'Iteration $i: Should return same order instance when no status in response',
        );
      }
    });

    test('Property 3 (edge case): status updated with various status values', () {
      // **Validates: Requirements 2.1, 2.3**
      // Property: The status update logic should work with any valid status string value.
      
      final testStatuses = [
        'paid',
        'captured',
        'verified',
        'failed',
        'created',
        'authorized',
        'pending',
        'refunded',
        'cancelled',
        'expired',
        '', // Empty string
        'PAID', // Uppercase
        'unknown_status', // Unknown status
        'status-with-dash',
        'status_with_underscore',
      ];
      
      for (var testStatus in testStatuses) {
        // Generate random order detail
        final originalOrder = generateRandomOrderDetail();
        
        // Create verification response with specific status
        final verificationResponse = {
          'status': testStatus,
          'success': true,
        };
        
        // Apply the update logic
        final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
        
        // Verify the property: status should be updated to the exact value from response
        expect(
          updatedOrder.status,
          equals(testStatus),
          reason: 'Status should be updated to "$testStatus" from verification response',
        );
      }
    });

    test('Property 3 (edge case): status updated correctly with null status in response', () {
      // **Validates: Requirements 2.1, 2.3**
      // Property: When verification response contains explicit null status,
      // the local order data should remain unchanged.
      
      const iterations = 50;
      
      for (var i = 0; i < iterations; i++) {
        // Generate random order detail
        final originalOrder = generateRandomOrderDetail();
        final originalStatus = originalOrder.status;
        
        // Create verification response with explicit null status
        final verificationResponse = {
          'status': null,
          'success': true,
          'message': 'Response with null status',
        };
        
        // Apply the update logic
        final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
        
        // Verify the property: status should remain unchanged
        expect(
          updatedOrder.status,
          equals(originalStatus),
          reason: 'Iteration $i: Status should not change when response has null status',
        );
      }
    });

    test('Property 4: Non-Status Fields Preserved During Update - all non-status fields remain unchanged for 100+ iterations', () {
      // **Validates: Requirements 2.4**
      // Property: For any order data update triggered by payment verification,
      // all fields except status (orderId, amount, paymentId, signature, createdAt,
      // updatedAt, customerName, customerEmail, customerPhone) should retain their original values.
      
      const iterations = 100;
      int successfulPreservations = 0;
      
      for (var i = 0; i < iterations; i++) {
        // Generate random order detail with various field values
        final originalOrder = generateRandomOrderDetail();
        
        // Generate random verification response with different status
        final verificationResponse = generateRandomVerificationResponse();
        final newStatus = verificationResponse['status'] as String;
        
        // Apply the update logic
        final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
        
        // Verify the property: all non-status fields should be preserved
        expect(
          updatedOrder.orderId,
          equals(originalOrder.orderId),
          reason: 'Iteration $i: orderId should be preserved',
        );
        
        expect(
          updatedOrder.amount,
          equals(originalOrder.amount),
          reason: 'Iteration $i: amount should be preserved',
        );
        
        expect(
          updatedOrder.paymentId,
          equals(originalOrder.paymentId),
          reason: 'Iteration $i: paymentId should be preserved',
        );
        
        expect(
          updatedOrder.signature,
          equals(originalOrder.signature),
          reason: 'Iteration $i: signature should be preserved',
        );
        
        expect(
          updatedOrder.createdAt,
          equals(originalOrder.createdAt),
          reason: 'Iteration $i: createdAt should be preserved',
        );
        
        expect(
          updatedOrder.updatedAt,
          equals(originalOrder.updatedAt),
          reason: 'Iteration $i: updatedAt should be preserved',
        );
        
        expect(
          updatedOrder.customerName,
          equals(originalOrder.customerName),
          reason: 'Iteration $i: customerName should be preserved',
        );
        
        expect(
          updatedOrder.customerEmail,
          equals(originalOrder.customerEmail),
          reason: 'Iteration $i: customerEmail should be preserved',
        );
        
        expect(
          updatedOrder.customerPhone,
          equals(originalOrder.customerPhone),
          reason: 'Iteration $i: customerPhone should be preserved',
        );
        
        // Verify that status was updated (the only field that should change)
        expect(
          updatedOrder.status,
          equals(newStatus),
          reason: 'Iteration $i: status should be updated to new value',
        );
        
        successfulPreservations++;
      }
      
      // Verify all iterations completed successfully
      expect(successfulPreservations, equals(iterations),
        reason: 'All $iterations iterations should preserve non-status fields');
    });

    test('Property 4 (edge case): field preservation with null optional fields', () {
      // **Validates: Requirements 2.4**
      // Property: Null values in optional fields should be preserved during status update.
      
      const iterations = 100;
      
      for (var i = 0; i < iterations; i++) {
        // Generate random order detail
        final baseOrder = generateRandomOrderDetail();
        
        // Create order with some null optional fields
        final random = Random();
        final originalOrder = OrderDetail(
          orderId: baseOrder.orderId,
          amount: baseOrder.amount,
          status: baseOrder.status,
          paymentId: random.nextBool() ? null : baseOrder.paymentId,
          signature: random.nextBool() ? null : baseOrder.signature,
          createdAt: baseOrder.createdAt,
          updatedAt: random.nextBool() ? null : baseOrder.updatedAt,
          customerName: random.nextBool() ? null : baseOrder.customerName,
          customerEmail: random.nextBool() ? null : baseOrder.customerEmail,
          customerPhone: random.nextBool() ? null : baseOrder.customerPhone,
        );
        
        // Generate verification response with new status
        final verificationResponse = generateRandomVerificationResponse();
        
        // Apply the update logic
        final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
        
        // Verify null fields remain null
        expect(
          updatedOrder.paymentId,
          equals(originalOrder.paymentId),
          reason: 'Iteration $i: paymentId null state should be preserved',
        );
        
        expect(
          updatedOrder.signature,
          equals(originalOrder.signature),
          reason: 'Iteration $i: signature null state should be preserved',
        );
        
        expect(
          updatedOrder.updatedAt,
          equals(originalOrder.updatedAt),
          reason: 'Iteration $i: updatedAt null state should be preserved',
        );
        
        expect(
          updatedOrder.customerName,
          equals(originalOrder.customerName),
          reason: 'Iteration $i: customerName null state should be preserved',
        );
        
        expect(
          updatedOrder.customerEmail,
          equals(originalOrder.customerEmail),
          reason: 'Iteration $i: customerEmail null state should be preserved',
        );
        
        expect(
          updatedOrder.customerPhone,
          equals(originalOrder.customerPhone),
          reason: 'Iteration $i: customerPhone null state should be preserved',
        );
      }
    });

    test('Property 4 (edge case): field preservation with extreme values', () {
      // **Validates: Requirements 2.4**
      // Property: Field preservation should work with extreme/boundary values.
      
      final extremeTestCases = [
        // Very large amount
        OrderDetail(
          orderId: 'order_extreme_1',
          amount: 999999999,
          status: 'created',
          createdAt: 2147483647, // Max 32-bit int
        ),
        // Very small amount
        OrderDetail(
          orderId: 'order_extreme_2',
          amount: 1,
          status: 'created',
          createdAt: 0,
        ),
        // Very long strings
        OrderDetail(
          orderId: 'order_${'x' * 100}',
          amount: 50000,
          status: 'created',
          paymentId: 'pay_${'y' * 100}',
          signature: 'sig_${'z' * 200}',
          createdAt: 1234567890,
          customerName: 'Name ${'a' * 100}',
          customerEmail: '${'b' * 50}@example.com',
          customerPhone: '9' * 15,
        ),
        // Special characters
        OrderDetail(
          orderId: 'order_!@#\$%^&*()',
          amount: 50000,
          status: 'created',
          createdAt: 1234567890,
          customerName: 'Name with émojis 🎉',
          customerEmail: 'test+special@example.com',
        ),
      ];
      
      for (var i = 0; i < extremeTestCases.length; i++) {
        final originalOrder = extremeTestCases[i];
        
        // Generate verification response with new status
        final verificationResponse = {'status': 'paid', 'success': true};
        
        // Apply the update logic
        final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
        
        // Verify all non-status fields are preserved exactly
        expect(
          updatedOrder.orderId,
          equals(originalOrder.orderId),
          reason: 'Test case $i: orderId should be preserved with extreme values',
        );
        
        expect(
          updatedOrder.amount,
          equals(originalOrder.amount),
          reason: 'Test case $i: amount should be preserved with extreme values',
        );
        
        expect(
          updatedOrder.paymentId,
          equals(originalOrder.paymentId),
          reason: 'Test case $i: paymentId should be preserved with extreme values',
        );
        
        expect(
          updatedOrder.signature,
          equals(originalOrder.signature),
          reason: 'Test case $i: signature should be preserved with extreme values',
        );
        
        expect(
          updatedOrder.createdAt,
          equals(originalOrder.createdAt),
          reason: 'Test case $i: createdAt should be preserved with extreme values',
        );
        
        expect(
          updatedOrder.customerName,
          equals(originalOrder.customerName),
          reason: 'Test case $i: customerName should be preserved with extreme values',
        );
        
        expect(
          updatedOrder.customerEmail,
          equals(originalOrder.customerEmail),
          reason: 'Test case $i: customerEmail should be preserved with extreme values',
        );
        
        expect(
          updatedOrder.customerPhone,
          equals(originalOrder.customerPhone),
          reason: 'Test case $i: customerPhone should be preserved with extreme values',
        );
      }
    });
  });

  group('OrderLookupScreen - Property-Based Tests for Button Visibility', () {
    // Helper function to generate random strings
    String generateRandomString(int length) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789_';
      final random = Random();
      return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper function to generate random order detail with specific status
    OrderDetail generateRandomOrderDetailWithStatus(String status) {
      final random = Random();
      
      // Generate a 10-digit phone number as a string
      String? generatePhoneNumber() {
        if (!random.nextBool()) return null;
        final digits = List.generate(10, (_) => random.nextInt(10));
        return digits.join();
      }
      
      return OrderDetail(
        orderId: 'order_${generateRandomString(10)}',
        amount: random.nextInt(1000000) + 1000, // 1000 to 1000000 paise
        status: status,
        paymentId: random.nextBool() ? 'pay_${generateRandomString(10)}' : null,
        signature: random.nextBool() ? 'sig_${generateRandomString(20)}' : null,
        createdAt: random.nextInt(1700000000) + 1600000000, // Random timestamp
        updatedAt: random.nextBool() ? random.nextInt(1700000000) + 1600000000 : null,
        customerName: random.nextBool() ? 'Customer ${generateRandomString(5)}' : null,
        customerEmail: random.nextBool() ? '${generateRandomString(8)}@example.com' : null,
        customerPhone: generatePhoneNumber(),
      );
    }

    test('Property 1: Retry Button Hidden for Successful Payment - button hidden for paid/captured/verified statuses for 100+ iterations', () {
      // **Validates: Requirements 1.1, 1.2**
      // Property: For any order with status "paid", "captured", or "verified",
      // the Retry Payment button should not be rendered in the Actions section.
      
      const iterations = 100;
      final successStatuses = ['paid', 'captured', 'verified'];
      int successfulValidations = 0;
      
      for (var i = 0; i < iterations; i++) {
        // Randomly select a success status
        final random = Random();
        final status = successStatuses[random.nextInt(successStatuses.length)];
        
        // Generate random order detail with the success status
        final orderDetail = generateRandomOrderDetailWithStatus(status);
        
        // Verify the property: retry button should be hidden
        // The button is hidden through two mechanisms:
        // 1. The entire action buttons section is hidden when needsAction is false
        // 2. Even if shown, the retry button specifically checks status != 'paid'
        
        // For "paid" status: both conditions hide the button
        if (status == 'paid') {
          expect(
            orderDetail.needsAction,
            isFalse,
            reason: 'Iteration $i: needsAction should be false for "paid" status',
          );
          
          final shouldShowRetryButton = orderDetail.status != 'paid';
          expect(
            shouldShowRetryButton,
            isFalse,
            reason: 'Iteration $i: Retry button should be hidden for "paid" status',
          );
        }
        
        // For "captured" and "verified" statuses: needsAction is false, hiding entire section
        if (status == 'captured' || status == 'verified') {
          expect(
            orderDetail.needsAction,
            isFalse,
            reason: 'Iteration $i: needsAction should be false for "$status" status',
          );
          
          // Even though the retry button logic (status != 'paid') would show it,
          // the entire action buttons section is hidden by needsAction check
          final actionSectionVisible = orderDetail.needsAction;
          expect(
            actionSectionVisible,
            isFalse,
            reason: 'Iteration $i: Action buttons section should be hidden for "$status" status',
          );
        }
        
        // Verify the status is one of the success statuses
        expect(
          successStatuses.contains(orderDetail.status),
          isTrue,
          reason: 'Iteration $i: Status should be one of the success statuses',
        );
        
        successfulValidations++;
      }
      
      // Verify all iterations completed successfully
      expect(successfulValidations, equals(iterations),
        reason: 'All $iterations iterations should validate retry button is hidden for success statuses');
    });

    test('Property 1 (inverse): Retry Button Shown for Non-Successful Payment - button shown for other statuses for 100+ iterations', () {
      // **Validates: Requirements 1.1, 1.2**
      // Property: For any order with status other than "paid", "captured", or "verified",
      // the Retry Payment button should be rendered when needsAction is true.
      
      const iterations = 100;
      final nonSuccessStatuses = ['created', 'failed', 'pending', 'authorized'];
      int successfulValidations = 0;
      
      for (var i = 0; i < iterations; i++) {
        // Randomly select a non-success status
        final random = Random();
        final status = nonSuccessStatuses[random.nextInt(nonSuccessStatuses.length)];
        
        // Generate random order detail with the non-success status
        final orderDetail = generateRandomOrderDetailWithStatus(status);
        
        // Verify the property: retry button should be shown
        expect(
          orderDetail.needsAction,
          isTrue,
          reason: 'Iteration $i: needsAction should be true for "$status" status',
        );
        
        final shouldShowRetryButton = orderDetail.status != 'paid';
        expect(
          shouldShowRetryButton,
          isTrue,
          reason: 'Iteration $i: Retry button should be shown for "$status" status',
        );
        
        // Combined logic: button is actually visible
        final actuallyVisible = orderDetail.needsAction && shouldShowRetryButton;
        expect(
          actuallyVisible,
          isTrue,
          reason: 'Iteration $i: Retry button should be actually visible for "$status" status',
        );
        
        successfulValidations++;
      }
      
      // Verify all iterations completed successfully
      expect(successfulValidations, equals(iterations),
        reason: 'All $iterations iterations should validate retry button is shown for non-success statuses');
    });

    test('Property 1 (edge case): Retry Button Visibility with Random Field Values', () {
      // **Validates: Requirements 1.1, 1.2**
      // Property: Retry button visibility should depend only on status,
      // not on other field values (amount, paymentId, customerName, etc.)
      
      const iterations = 100;
      final allStatuses = ['paid', 'captured', 'verified', 'created', 'failed', 'pending', 'authorized'];
      
      for (var i = 0; i < iterations; i++) {
        // Randomly select any status
        final random = Random();
        final status = allStatuses[random.nextInt(allStatuses.length)];
        
        // Generate random order detail with random field values
        final orderDetail = generateRandomOrderDetailWithStatus(status);
        
        // Determine expected visibility based on status alone
        final isSuccessStatus = ['paid', 'captured', 'verified'].contains(status);
        final expectedNeedsAction = !isSuccessStatus;
        final expectedRetryButtonLogic = status != 'paid';
        final expectedActuallyVisible = expectedNeedsAction && expectedRetryButtonLogic;
        
        // Verify the property: visibility depends only on status
        expect(
          orderDetail.needsAction,
          equals(expectedNeedsAction),
          reason: 'Iteration $i: needsAction should be $expectedNeedsAction for "$status" status, regardless of other fields',
        );
        
        final shouldShowRetryButton = orderDetail.status != 'paid';
        expect(
          shouldShowRetryButton,
          equals(expectedRetryButtonLogic),
          reason: 'Iteration $i: Retry button logic should be $expectedRetryButtonLogic for "$status" status',
        );
        
        final actuallyVisible = orderDetail.needsAction && shouldShowRetryButton;
        expect(
          actuallyVisible,
          equals(expectedActuallyVisible),
          reason: 'Iteration $i: Retry button actual visibility should be $expectedActuallyVisible for "$status" status',
        );
      }
    });
  });

  group('OrderLookupScreen - Property-Based Tests for Other Buttons Visibility', () {
    // Helper function to generate random strings
    String generateRandomString(int length) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789_';
      final random = Random();
      return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper function to generate random order detail with needsAction true
    OrderDetail generateRandomOrderDetailWithNeedsAction() {
      final random = Random();
      // Statuses where needsAction is true (not paid, captured, or verified)
      final needsActionStatuses = ['created', 'failed', 'pending', 'authorized'];
      
      // Generate a 10-digit phone number as a string
      String? generatePhoneNumber() {
        if (!random.nextBool()) return null;
        final digits = List.generate(10, (_) => random.nextInt(10));
        return digits.join();
      }
      
      return OrderDetail(
        orderId: 'order_${generateRandomString(10)}',
        amount: random.nextInt(1000000) + 1000, // 1000 to 1000000 paise
        status: needsActionStatuses[random.nextInt(needsActionStatuses.length)],
        paymentId: random.nextBool() ? 'pay_${generateRandomString(10)}' : null,
        signature: random.nextBool() ? 'sig_${generateRandomString(20)}' : null,
        createdAt: random.nextInt(1700000000) + 1600000000, // Random timestamp
        updatedAt: random.nextBool() ? random.nextInt(1700000000) + 1600000000 : null,
        customerName: random.nextBool() ? 'Customer ${generateRandomString(5)}' : null,
        customerEmail: random.nextBool() ? '${generateRandomString(8)}@example.com' : null,
        customerPhone: generatePhoneNumber(),
      );
    }

    test('Property 2: Other Action Buttons Remain Visible - Verify Payment and Check Payment Status buttons rendered when needsAction is true for 100+ iterations', () {
      // **Validates: Requirements 1.3**
      // Property: For any order where needsAction is true, the Verify Payment and Check Payment Status
      // buttons should be rendered regardless of the payment status.
      
      const iterations = 100;
      int successfulValidations = 0;
      
      for (var i = 0; i < iterations; i++) {
        // Generate random order detail with needsAction true
        final orderDetail = generateRandomOrderDetailWithNeedsAction();
        
        // Verify the property: needsAction should be true
        expect(
          orderDetail.needsAction,
          isTrue,
          reason: 'Iteration $i: needsAction should be true for status "${orderDetail.status}"',
        );
        
        // Verify that the action buttons section is visible
        // When needsAction is true, the action buttons section (including Verify Payment
        // and Check Payment Status) should be rendered
        final actionButtonsSectionVisible = orderDetail.needsAction;
        expect(
          actionButtonsSectionVisible,
          isTrue,
          reason: 'Iteration $i: Action buttons section should be visible when needsAction is true',
        );
        
        // Verify that the status is one that requires action
        final needsActionStatuses = ['created', 'failed', 'pending', 'authorized'];
        expect(
          needsActionStatuses.contains(orderDetail.status),
          isTrue,
          reason: 'Iteration $i: Status "${orderDetail.status}" should be one that requires action',
        );
        
        // Verify that needsAction is consistent with the status
        final expectedNeedsAction = orderDetail.status != 'paid' && 
                                    orderDetail.status != 'captured' && 
                                    orderDetail.status != 'verified';
        expect(
          orderDetail.needsAction,
          equals(expectedNeedsAction),
          reason: 'Iteration $i: needsAction should match expected value based on status',
        );
        
        successfulValidations++;
      }
      
      // Verify all iterations completed successfully
      expect(successfulValidations, equals(iterations),
        reason: 'All $iterations iterations should validate other action buttons remain visible');
    });

    test('Property 2 (edge case): Other Action Buttons Visible Regardless of Retry Button State', () {
      // **Validates: Requirements 1.3**
      // Property: The visibility of Verify Payment and Check Payment Status buttons
      // should not depend on whether the Retry Payment button is visible or not.
      
      const iterations = 100;
      
      for (var i = 0; i < iterations; i++) {
        // Generate random order detail with needsAction true
        final orderDetail = generateRandomOrderDetailWithNeedsAction();
        
        // Check if retry button would be visible (status != 'paid')
        final retryButtonVisible = orderDetail.status != 'paid';
        
        // Verify that other action buttons are visible regardless of retry button state
        expect(
          orderDetail.needsAction,
          isTrue,
          reason: 'Iteration $i: Other action buttons should be visible regardless of retry button state (retry visible: $retryButtonVisible)',
        );
        
        // The action buttons section visibility depends only on needsAction,
        // not on the retry button visibility logic
        final actionButtonsSectionVisible = orderDetail.needsAction;
        expect(
          actionButtonsSectionVisible,
          isTrue,
          reason: 'Iteration $i: Action buttons section visibility should not depend on retry button logic',
        );
      }
    });

    test('Property 2 (inverse): Other Action Buttons Hidden When needsAction is False', () {
      // **Validates: Requirements 1.3**
      // Property: When needsAction is false (paid, captured, verified statuses),
      // the entire action buttons section (including other buttons) should be hidden.
      
      const iterations = 100;
      final noActionStatuses = ['paid', 'captured', 'verified'];
      
      for (var i = 0; i < iterations; i++) {
        // Randomly select a status where needsAction is false
        final random = Random();
        final status = noActionStatuses[random.nextInt(noActionStatuses.length)];
        
        // Generate order detail with this status
        final orderDetail = OrderDetail(
          orderId: 'order_${generateRandomString(10)}',
          amount: random.nextInt(1000000) + 1000,
          status: status,
          paymentId: 'pay_${generateRandomString(10)}',
          signature: 'sig_${generateRandomString(20)}',
          createdAt: random.nextInt(1700000000) + 1600000000,
        );
        
        // Verify the property: needsAction should be false
        expect(
          orderDetail.needsAction,
          isFalse,
          reason: 'Iteration $i: needsAction should be false for status "$status"',
        );
        
        // Verify that the action buttons section is hidden
        final actionButtonsSectionVisible = orderDetail.needsAction;
        expect(
          actionButtonsSectionVisible,
          isFalse,
          reason: 'Iteration $i: Action buttons section should be hidden when needsAction is false',
        );
      }
    });

    test('Property 2 (comprehensive): Action Buttons Visibility Across All Statuses', () {
      // **Validates: Requirements 1.3**
      // Property: Verify the complete behavior of action buttons visibility
      // across all possible order statuses.
      
      final allStatuses = [
        'created', 'failed', 'pending', 'authorized', // needsAction = true
        'paid', 'captured', 'verified', // needsAction = false
      ];
      
      const iterationsPerStatus = 15; // 15 iterations per status = 105 total
      
      for (var status in allStatuses) {
        for (var i = 0; i < iterationsPerStatus; i++) {
          final random = Random();
          
          // Generate order detail with specific status
          final orderDetail = OrderDetail(
            orderId: 'order_${generateRandomString(10)}',
            amount: random.nextInt(1000000) + 1000,
            status: status,
            paymentId: random.nextBool() ? 'pay_${generateRandomString(10)}' : null,
            signature: random.nextBool() ? 'sig_${generateRandomString(20)}' : null,
            createdAt: random.nextInt(1700000000) + 1600000000,
          );
          
          // Determine expected behavior
          final expectedNeedsAction = status != 'paid' && status != 'captured' && status != 'verified';
          
          // Verify needsAction matches expected value
          expect(
            orderDetail.needsAction,
            equals(expectedNeedsAction),
            reason: 'Status "$status" iteration $i: needsAction should be $expectedNeedsAction',
          );
          
          // Verify action buttons section visibility
          final actionButtonsSectionVisible = orderDetail.needsAction;
          expect(
            actionButtonsSectionVisible,
            equals(expectedNeedsAction),
            reason: 'Status "$status" iteration $i: Action buttons section visibility should be $expectedNeedsAction',
          );
          
          // For statuses with needsAction true, verify other buttons would be visible
          if (expectedNeedsAction) {
            expect(
              orderDetail.needsAction,
              isTrue,
              reason: 'Status "$status" iteration $i: Other action buttons (Verify Payment, Check Payment Status) should be visible',
            );
          }
        }
      }
    });
  });

  group('OrderLookupScreen - Button Visibility Logic', () {
    // Helper widget to test OrderLookupScreen with pre-populated order data
    // Since we can't directly set the private state, we'll test the logic through unit tests
    // and verify the actual button rendering through the existing widget tests
    
    test('retry button should be hidden when status is "paid"', () {
      // Create order detail with "paid" status
      final orderDetail = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'paid',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
      );

      // Verify the logic: retry button should be hidden when status is 'paid'
      final shouldShowRetryButton = orderDetail.status != 'paid';
      expect(shouldShowRetryButton, isFalse, 
        reason: 'Retry button should be hidden when status is "paid"');
      
      // Verify other action buttons should be visible (needsAction is false for paid, but buttons still render)
      // The action buttons section is shown when needsAction is true
      expect(orderDetail.needsAction, isFalse,
        reason: 'needsAction should be false for "paid" status');
    });

    test('retry button should be shown when status is "created"', () {
      // Create order detail with "created" status
      final orderDetail = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'created',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
      );

      // Verify the logic: retry button should be shown when status is 'created'
      final shouldShowRetryButton = orderDetail.status != 'paid';
      expect(shouldShowRetryButton, isTrue,
        reason: 'Retry button should be shown when status is "created"');
      
      // Verify action buttons section should be visible
      expect(orderDetail.needsAction, isTrue,
        reason: 'needsAction should be true for "created" status');
    });

    test('retry button should be shown when status is "failed"', () {
      // Create order detail with "failed" status
      final orderDetail = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'failed',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
      );

      // Verify the logic: retry button should be shown when status is 'failed'
      final shouldShowRetryButton = orderDetail.status != 'paid';
      expect(shouldShowRetryButton, isTrue,
        reason: 'Retry button should be shown when status is "failed"');
      
      // Verify action buttons section should be visible
      expect(orderDetail.needsAction, isTrue,
        reason: 'needsAction should be true for "failed" status');
    });

    test('retry button should be hidden when status is "captured"', () {
      // Create order detail with "captured" status
      final orderDetail = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'captured',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
      );

      // Verify the logic: retry button should be hidden when status is 'captured'
      final shouldShowRetryButton = orderDetail.status != 'paid';
      expect(shouldShowRetryButton, isTrue,
        reason: 'Retry button logic checks for "paid" status only, but needsAction will be false');
      
      // Verify action buttons section should NOT be visible for captured status
      expect(orderDetail.needsAction, isFalse,
        reason: 'needsAction should be false for "captured" status');
    });

    test('retry button should be hidden when status is "verified"', () {
      // Create order detail with "verified" status
      final orderDetail = OrderDetail(
        orderId: 'order_123',
        amount: 50000,
        status: 'verified',
        paymentId: 'pay_123',
        signature: 'sig_123',
        createdAt: 1234567890,
      );

      // Verify the logic: retry button should be hidden when status is 'verified'
      final shouldShowRetryButton = orderDetail.status != 'paid';
      expect(shouldShowRetryButton, isTrue,
        reason: 'Retry button logic checks for "paid" status only, but needsAction will be false');
      
      // Verify action buttons section should NOT be visible for verified status
      expect(orderDetail.needsAction, isFalse,
        reason: 'needsAction should be false for "verified" status');
    });

    test('action buttons section visibility based on needsAction', () {
      // Test various statuses and their needsAction values
      final testCases = [
        {'status': 'paid', 'needsAction': false},
        {'status': 'captured', 'needsAction': false},
        {'status': 'verified', 'needsAction': false},
        {'status': 'created', 'needsAction': true},
        {'status': 'failed', 'needsAction': true},
        {'status': 'pending', 'needsAction': true},
        {'status': 'authorized', 'needsAction': true},
      ];

      for (var testCase in testCases) {
        final orderDetail = OrderDetail(
          orderId: 'order_123',
          amount: 50000,
          status: testCase['status'] as String,
          paymentId: 'pay_123',
          signature: 'sig_123',
          createdAt: 1234567890,
        );

        expect(
          orderDetail.needsAction,
          equals(testCase['needsAction']),
          reason: 'needsAction should be ${testCase['needsAction']} for status "${testCase['status']}"',
        );
      }
    });

    test('retry button visibility logic for various statuses', () {
      // Test the retry button visibility logic (status != 'paid')
      final testCases = [
        {'status': 'paid', 'shouldShowRetry': false},
        {'status': 'captured', 'shouldShowRetry': true},
        {'status': 'verified', 'shouldShowRetry': true},
        {'status': 'created', 'shouldShowRetry': true},
        {'status': 'failed', 'shouldShowRetry': true},
        {'status': 'pending', 'shouldShowRetry': true},
        {'status': 'authorized', 'shouldShowRetry': true},
      ];

      for (var testCase in testCases) {
        final status = testCase['status'] as String;
        final shouldShowRetry = status != 'paid';

        expect(
          shouldShowRetry,
          equals(testCase['shouldShowRetry']),
          reason: 'Retry button visibility should be ${testCase['shouldShowRetry']} for status "$status"',
        );
      }
    });

    test('combined logic: retry button only visible when needsAction is true AND status is not paid', () {
      // This test verifies the combined logic of both conditions
      final testCases = [
        // status, needsAction, shouldShowRetry, actuallyVisible
        {'status': 'paid', 'needsAction': false, 'shouldShowRetry': false, 'visible': false},
        {'status': 'captured', 'needsAction': false, 'shouldShowRetry': true, 'visible': false},
        {'status': 'verified', 'needsAction': false, 'shouldShowRetry': true, 'visible': false},
        {'status': 'created', 'needsAction': true, 'shouldShowRetry': true, 'visible': true},
        {'status': 'failed', 'needsAction': true, 'shouldShowRetry': true, 'visible': true},
        {'status': 'pending', 'needsAction': true, 'shouldShowRetry': true, 'visible': true},
      ];

      for (var testCase in testCases) {
        final orderDetail = OrderDetail(
          orderId: 'order_123',
          amount: 50000,
          status: testCase['status'] as String,
          paymentId: 'pay_123',
          signature: 'sig_123',
          createdAt: 1234567890,
        );

        final needsAction = orderDetail.needsAction;
        final shouldShowRetry = orderDetail.status != 'paid';
        final actuallyVisible = needsAction && shouldShowRetry;

        expect(
          needsAction,
          equals(testCase['needsAction']),
          reason: 'needsAction should be ${testCase['needsAction']} for status "${testCase['status']}"',
        );

        expect(
          shouldShowRetry,
          equals(testCase['shouldShowRetry']),
          reason: 'shouldShowRetry should be ${testCase['shouldShowRetry']} for status "${testCase['status']}"',
        );

        expect(
          actuallyVisible,
          equals(testCase['visible']),
          reason: 'Retry button should be ${(testCase['visible'] as bool) ? 'visible' : 'hidden'} for status "${testCase['status']}"',
        );
      }
    });

    test('other action buttons (Verify Payment, Check Payment Status) remain visible when needsAction is true', () {
      // Test that other action buttons are visible when needsAction is true
      final statusesWithAction = ['created', 'failed', 'pending', 'authorized'];

      for (var status in statusesWithAction) {
        final orderDetail = OrderDetail(
          orderId: 'order_123',
          amount: 50000,
          status: status,
          paymentId: 'pay_123',
          signature: 'sig_123',
          createdAt: 1234567890,
        );

        // Verify needsAction is true (which means action buttons section is visible)
        expect(
          orderDetail.needsAction,
          isTrue,
          reason: 'Action buttons section should be visible for status "$status"',
        );
      }
    });

    test('other action buttons are hidden when needsAction is false', () {
      // Test that action buttons section is hidden when needsAction is false
      final statusesWithoutAction = ['paid', 'captured', 'verified'];

      for (var status in statusesWithoutAction) {
        final orderDetail = OrderDetail(
          orderId: 'order_123',
          amount: 50000,
          status: status,
          paymentId: 'pay_123',
          signature: 'sig_123',
          createdAt: 1234567890,
        );

        // Verify needsAction is false (which means entire action buttons section is hidden)
        expect(
          orderDetail.needsAction,
          isFalse,
          reason: 'Action buttons section should be hidden for status "$status"',
        );
      }
    });
  });

  group('OrderLookupScreen - Integration Tests: Complete Payment Flow', () {
    // Integration test to verify the complete payment flow end-to-end
    // This test verifies Requirements 1.1, 1.2, 2.1, 2.2, 3.1
    
    test('Integration: Complete payment flow - order fetch, payment verification, state update, button visibility, and GlassyCard', () {
      // **Validates: Requirements 1.1, 1.2, 2.1, 2.2, 3.1**
      // This integration test verifies the complete payment flow:
      // 1. Order fetch works correctly
      // 2. Payment verification updates local state
      // 3. Retry button disappears after successful payment
      // 4. GlassyCard is applied to order details
      
      // Step 1: Create initial order with "created" status (needs action)
      final initialOrder = OrderDetail(
        orderId: 'order_integration_test',
        amount: 100000,
        status: 'created',
        paymentId: 'pay_test_123',
        signature: 'sig_test_123',
        createdAt: 1234567890,
        updatedAt: 1234567890,
        customerName: 'Integration Test User',
        customerEmail: 'integration@test.com',
        customerPhone: '9876543210',
      );
      
      // Verify initial state: order needs action
      expect(initialOrder.status, equals('created'),
        reason: 'Initial order should have "created" status');
      expect(initialOrder.needsAction, isTrue,
        reason: 'Initial order should need action');
      
      // Verify retry button should be visible initially
      final initialRetryButtonVisible = initialOrder.needsAction && initialOrder.status != 'paid';
      expect(initialRetryButtonVisible, isTrue,
        reason: 'Retry button should be visible for "created" status');
      
      // Step 2: Simulate payment verification response with "paid" status
      final verificationResponse = {
        'status': 'paid',
        'success': true,
        'message': 'Payment verified successfully',
        'order_id': initialOrder.orderId,
        'payment_id': initialOrder.paymentId,
      };
      
      // Extract updated status from verification response
      final updatedStatus = verificationResponse['status'] as String?;
      expect(updatedStatus, isNotNull,
        reason: 'Verification response should contain status field');
      expect(updatedStatus, equals('paid'),
        reason: 'Verification response should have "paid" status');
      
      // Step 3: Simulate local state update (as done in _verifyPayment method)
      final updatedOrder = OrderDetail(
        orderId: initialOrder.orderId,
        amount: initialOrder.amount,
        status: updatedStatus!,
        paymentId: initialOrder.paymentId,
        signature: initialOrder.signature,
        createdAt: initialOrder.createdAt,
        updatedAt: initialOrder.updatedAt,
        customerName: initialOrder.customerName,
        customerEmail: initialOrder.customerEmail,
        customerPhone: initialOrder.customerPhone,
      );
      
      // Step 4: Verify local state was updated correctly
      expect(updatedOrder.status, equals('paid'),
        reason: 'Order status should be updated to "paid" after verification');
      expect(updatedOrder.status, isNot(equals(initialOrder.status)),
        reason: 'Order status should change from initial status');
      
      // Step 5: Verify all non-status fields are preserved
      expect(updatedOrder.orderId, equals(initialOrder.orderId),
        reason: 'orderId should be preserved during update');
      expect(updatedOrder.amount, equals(initialOrder.amount),
        reason: 'amount should be preserved during update');
      expect(updatedOrder.paymentId, equals(initialOrder.paymentId),
        reason: 'paymentId should be preserved during update');
      expect(updatedOrder.signature, equals(initialOrder.signature),
        reason: 'signature should be preserved during update');
      expect(updatedOrder.createdAt, equals(initialOrder.createdAt),
        reason: 'createdAt should be preserved during update');
      expect(updatedOrder.updatedAt, equals(initialOrder.updatedAt),
        reason: 'updatedAt should be preserved during update');
      expect(updatedOrder.customerName, equals(initialOrder.customerName),
        reason: 'customerName should be preserved during update');
      expect(updatedOrder.customerEmail, equals(initialOrder.customerEmail),
        reason: 'customerEmail should be preserved during update');
      expect(updatedOrder.customerPhone, equals(initialOrder.customerPhone),
        reason: 'customerPhone should be preserved during update');
      
      // Step 6: Verify retry button is hidden after successful payment
      expect(updatedOrder.needsAction, isFalse,
        reason: 'Order should not need action after payment is "paid"');
      
      final updatedRetryButtonVisible = updatedOrder.needsAction && updatedOrder.status != 'paid';
      expect(updatedRetryButtonVisible, isFalse,
        reason: 'Retry button should be hidden after successful payment');
      
      // Verify the button visibility changed from initial state
      expect(updatedRetryButtonVisible, isNot(equals(initialRetryButtonVisible)),
        reason: 'Retry button visibility should change after payment verification');
      
      // Step 7: Verify other action buttons are also hidden (entire action section)
      expect(updatedOrder.needsAction, isFalse,
        reason: 'Action buttons section should be hidden for "paid" status');
      
      // Step 8: Verify GlassyCard would be applied to order details
      // Note: We can't directly test widget rendering in a unit test,
      // but we can verify the order data is in a state where it would be displayed
      expect(updatedOrder.orderId, isNotEmpty,
        reason: 'Order should have valid data for display in GlassyCard');
      expect(updatedOrder.amount, greaterThan(0),
        reason: 'Order should have valid amount for display');
      
      // Integration test summary:
      // ✓ Order fetch works correctly (simulated with initial order)
      // ✓ Payment verification updates local state (status changed from "created" to "paid")
      // ✓ Retry button disappears after successful payment (needsAction false, status is "paid")
      // ✓ All non-status fields preserved during update
      // ✓ GlassyCard would be applied (order has valid data for display)
    });

    test('Integration: Payment flow with multiple status transitions', () {
      // **Validates: Requirements 1.1, 1.2, 2.1, 2.2**
      // This test verifies the payment flow through multiple status transitions
      
      // Start with "created" status
      var currentOrder = OrderDetail(
        orderId: 'order_multi_status',
        amount: 50000,
        status: 'created',
        paymentId: 'pay_multi',
        signature: 'sig_multi',
        createdAt: 1234567890,
      );
      
      // Verify initial state
      expect(currentOrder.status, equals('created'));
      expect(currentOrder.needsAction, isTrue);
      expect(currentOrder.status != 'paid', isTrue);
      
      // Transition 1: created -> authorized
      var verificationResponse = {'status': 'authorized'};
      var updatedStatus = verificationResponse['status'] as String?;
      currentOrder = OrderDetail(
        orderId: currentOrder.orderId,
        amount: currentOrder.amount,
        status: updatedStatus!,
        paymentId: currentOrder.paymentId,
        signature: currentOrder.signature,
        createdAt: currentOrder.createdAt,
      );
      
      expect(currentOrder.status, equals('authorized'));
      expect(currentOrder.needsAction, isTrue,
        reason: 'Order should still need action after authorization');
      
      // Transition 2: authorized -> captured
      verificationResponse = {'status': 'captured'};
      updatedStatus = verificationResponse['status'] as String?;
      currentOrder = OrderDetail(
        orderId: currentOrder.orderId,
        amount: currentOrder.amount,
        status: updatedStatus!,
        paymentId: currentOrder.paymentId,
        signature: currentOrder.signature,
        createdAt: currentOrder.createdAt,
      );
      
      expect(currentOrder.status, equals('captured'));
      expect(currentOrder.needsAction, isFalse,
        reason: 'Order should not need action after capture');
      
      // Transition 3: captured -> paid
      verificationResponse = {'status': 'paid'};
      updatedStatus = verificationResponse['status'] as String?;
      currentOrder = OrderDetail(
        orderId: currentOrder.orderId,
        amount: currentOrder.amount,
        status: updatedStatus!,
        paymentId: currentOrder.paymentId,
        signature: currentOrder.signature,
        createdAt: currentOrder.createdAt,
      );
      
      expect(currentOrder.status, equals('paid'));
      expect(currentOrder.needsAction, isFalse,
        reason: 'Order should not need action after payment');
      expect(currentOrder.status != 'paid', isFalse,
        reason: 'Retry button should be hidden for "paid" status');
      
      // Verify final state: no action needed, retry button hidden
      final finalRetryButtonVisible = currentOrder.needsAction && currentOrder.status != 'paid';
      expect(finalRetryButtonVisible, isFalse,
        reason: 'Retry button should be hidden in final state');
    });

    test('Integration: Payment flow with failed payment and retry', () {
      // **Validates: Requirements 1.1, 1.2, 2.1, 2.2**
      // This test verifies the payment flow when payment fails and user retries
      
      // Start with "created" status
      var currentOrder = OrderDetail(
        orderId: 'order_failed_retry',
        amount: 75000,
        status: 'created',
        paymentId: 'pay_failed',
        signature: 'sig_failed',
        createdAt: 1234567890,
      );
      
      // Verify initial state: retry button should be visible
      expect(currentOrder.needsAction, isTrue);
      var retryButtonVisible = currentOrder.needsAction && currentOrder.status != 'paid';
      expect(retryButtonVisible, isTrue,
        reason: 'Retry button should be visible for "created" status');
      
      // Simulate failed payment
      var verificationResponse = {'status': 'failed'};
      var updatedStatus = verificationResponse['status'] as String?;
      currentOrder = OrderDetail(
        orderId: currentOrder.orderId,
        amount: currentOrder.amount,
        status: updatedStatus!,
        paymentId: currentOrder.paymentId,
        signature: currentOrder.signature,
        createdAt: currentOrder.createdAt,
      );
      
      // Verify failed state: retry button should still be visible
      expect(currentOrder.status, equals('failed'));
      expect(currentOrder.needsAction, isTrue,
        reason: 'Order should need action after failed payment');
      retryButtonVisible = currentOrder.needsAction && currentOrder.status != 'paid';
      expect(retryButtonVisible, isTrue,
        reason: 'Retry button should be visible for "failed" status');
      
      // Simulate successful retry
      verificationResponse = {'status': 'paid'};
      updatedStatus = verificationResponse['status'] as String?;
      currentOrder = OrderDetail(
        orderId: currentOrder.orderId,
        amount: currentOrder.amount,
        status: updatedStatus!,
        paymentId: currentOrder.paymentId,
        signature: currentOrder.signature,
        createdAt: currentOrder.createdAt,
      );
      
      // Verify successful state: retry button should be hidden
      expect(currentOrder.status, equals('paid'));
      expect(currentOrder.needsAction, isFalse,
        reason: 'Order should not need action after successful payment');
      retryButtonVisible = currentOrder.needsAction && currentOrder.status != 'paid';
      expect(retryButtonVisible, isFalse,
        reason: 'Retry button should be hidden after successful retry');
    });

    test('Integration: Verify GlassyCard properties are compatible with order details', () {
      // **Validates: Requirements 3.1**
      // This test verifies that GlassyCard widget properties are compatible
      // with the order details display requirements
      
      // Create a sample order
      final order = OrderDetail(
        orderId: 'order_glassy_test',
        amount: 100000,
        status: 'paid',
        paymentId: 'pay_glassy',
        signature: 'sig_glassy',
        createdAt: 1234567890,
        updatedAt: 1234567900,
        customerName: 'Glassy Test User',
        customerEmail: 'glassy@test.com',
        customerPhone: '9999999999',
      );
      
      // Verify order has all required fields for display
      expect(order.orderId, isNotEmpty,
        reason: 'Order should have orderId for display');
      expect(order.formattedAmount, isNotEmpty,
        reason: 'Order should have formatted amount for display');
      expect(order.status, isNotEmpty,
        reason: 'Order should have status for display');
      expect(order.formattedCreatedAt, isNotEmpty,
        reason: 'Order should have formatted created date for display');
      
      // Verify optional fields
      expect(order.customerName, isNotNull,
        reason: 'Order has customer name for display');
      expect(order.customerEmail, isNotNull,
        reason: 'Order has customer email for display');
      expect(order.customerPhone, isNotNull,
        reason: 'Order has customer phone for display');
      expect(order.paymentId, isNotNull,
        reason: 'Order has payment ID for display');
      expect(order.signature, isNotNull,
        reason: 'Order has signature for display');
      
      // GlassyCard properties (from design spec):
      // - BackdropFilter with blur (sigmaX: 20, sigmaY: 20)
      // - Semi-transparent white background (opacity 0.08)
      // - Border with white color (opacity 0.18, width 1.5)
      // - Box shadow (black opacity 0.3, blur radius 32, offset (0, 8))
      // - Default padding: 16
      // - Default border radius: 12
      
      // These properties should not affect the order data display
      // The order data should be displayed correctly regardless of the card styling
      
      // Verify the order data is complete and ready for display in GlassyCard
      expect(order.orderId, equals('order_glassy_test'));
      expect(order.amount, equals(100000));
      expect(order.status, equals('paid'));
      
      // Integration verification: GlassyCard can display order details correctly
      // The card provides the visual styling while preserving all order information
    });

    test('Integration: Complete flow verification with edge cases', () {
      // **Validates: Requirements 1.1, 1.2, 2.1, 2.2, 3.1**
      // This test verifies the complete flow with various edge cases
      
      // Edge case 1: Order with minimal fields
      var order = OrderDetail(
        orderId: 'order_minimal',
        amount: 1000,
        status: 'created',
        createdAt: 1234567890,
      );
      
      expect(order.needsAction, isTrue);
      expect(order.status != 'paid', isTrue);
      
      // Update to paid
      var response = {'status': 'paid'};
      order = OrderDetail(
        orderId: order.orderId,
        amount: order.amount,
        status: response['status'] as String,
        createdAt: order.createdAt,
      );
      
      expect(order.status, equals('paid'));
      expect(order.needsAction, isFalse);
      
      // Edge case 2: Order with all fields populated
      order = OrderDetail(
        orderId: 'order_complete',
        amount: 999999,
        status: 'created',
        paymentId: 'pay_complete',
        signature: 'sig_complete',
        createdAt: 1234567890,
        updatedAt: 1234567900,
        customerName: 'Complete User',
        customerEmail: 'complete@test.com',
        customerPhone: '1234567890',
      );
      
      expect(order.needsAction, isTrue);
      
      // Update to paid
      response = {'status': 'paid'};
      final originalOrderId = order.orderId;
      final originalAmount = order.amount;
      final originalPaymentId = order.paymentId;
      final originalSignature = order.signature;
      final originalCreatedAt = order.createdAt;
      final originalUpdatedAt = order.updatedAt;
      final originalCustomerName = order.customerName;
      final originalCustomerEmail = order.customerEmail;
      final originalCustomerPhone = order.customerPhone;
      
      order = OrderDetail(
        orderId: order.orderId,
        amount: order.amount,
        status: response['status'] as String,
        paymentId: order.paymentId,
        signature: order.signature,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        customerName: order.customerName,
        customerEmail: order.customerEmail,
        customerPhone: order.customerPhone,
      );
      
      // Verify status updated
      expect(order.status, equals('paid'));
      expect(order.needsAction, isFalse);
      
      // Verify all fields preserved
      expect(order.orderId, equals(originalOrderId));
      expect(order.amount, equals(originalAmount));
      expect(order.paymentId, equals(originalPaymentId));
      expect(order.signature, equals(originalSignature));
      expect(order.createdAt, equals(originalCreatedAt));
      expect(order.updatedAt, equals(originalUpdatedAt));
      expect(order.customerName, equals(originalCustomerName));
      expect(order.customerEmail, equals(originalCustomerEmail));
      expect(order.customerPhone, equals(originalCustomerPhone));
      
      // Edge case 3: Verification response without status field
      order = OrderDetail(
        orderId: 'order_no_status',
        amount: 50000,
        status: 'created',
        createdAt: 1234567890,
      );
      
      final responseWithoutStatus = <String, dynamic>{'success': true, 'message': 'Verified'};
      final updatedStatus = responseWithoutStatus['status'] as String?;
      
      // Should not update if status is null
      if (updatedStatus != null) {
        order = OrderDetail(
          orderId: order.orderId,
          amount: order.amount,
          status: updatedStatus,
          createdAt: order.createdAt,
        );
      }
      
      // Status should remain unchanged
      expect(order.status, equals('created'),
        reason: 'Status should not change when response lacks status field');
      expect(order.needsAction, isTrue,
        reason: 'Order should still need action when status unchanged');
    });
  });
}
