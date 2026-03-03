import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/order_detail.dart';

void main() {
  group('OrderDetail - Model Properties', () {
    test('creates instance with all properties', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'paid',
        paymentId: 'pay_456',
        signature: 'sig_789',
        createdAt: 1705320600,
        updatedAt: 1705320700,
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerPhone: '9999999999',
      );

      expect(order.orderId, 'order_123');
      expect(order.amount, 10050);
      expect(order.status, 'paid');
      expect(order.paymentId, 'pay_456');
      expect(order.signature, 'sig_789');
      expect(order.createdAt, 1705320600);
      expect(order.updatedAt, 1705320700);
      expect(order.customerName, 'John Doe');
      expect(order.customerEmail, 'john@example.com');
      expect(order.customerPhone, '9999999999');
    });

    test('creates instance with nullable fields as null', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'created',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.paymentId, isNull);
      expect(order.signature, isNull);
      expect(order.customerName, isNull);
      expect(order.customerEmail, isNull);
      expect(order.customerPhone, isNull);
    });
  });

  group('OrderDetail - Formatted Amount', () {
    test('formats amount correctly with 2 decimal places', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'paid',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.formattedAmount, '₹100.50');
    });

    test('formats whole number amount', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10000,
        status: 'paid',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.formattedAmount, '₹100.00');
    });

    test('formats zero amount', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 0,
        status: 'created',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.formattedAmount, '₹0.00');
    });

    test('formats large amount', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 123456789,
        status: 'paid',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.formattedAmount, '₹1234567.89');
    });
  });

  group('OrderDetail - Needs Action', () {
    test('returns false for "paid" status', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'paid',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.needsAction, false);
    });

    test('returns false for "captured" status', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'captured',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.needsAction, false);
    });

    test('returns false for "verified" status', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'verified',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.needsAction, false);
    });

    test('returns true for "created" status', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'created',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.needsAction, true);
    });

    test('returns true for "pending" status', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'pending',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.needsAction, true);
    });

    test('returns true for "failed" status', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'failed',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.needsAction, true);
    });

    test('returns true for unknown status', () {
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'unknown',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      expect(order.needsAction, true);
    });
  });

  group('OrderDetail - Formatted Created At', () {
    test('formats timestamp correctly', () {
      // January 15, 2024, 14:30:00 UTC
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'paid',
        createdAt: 1705329000,
        updatedAt: 1705329000,
      );

      // The format should be DD/MM/YYYY HH:MM
      expect(order.formattedCreatedAt, matches(r'\d{2}/\d{2}/\d{4} \d{2}:\d{2}'));
    });

    test('pads single digit day and month', () {
      // A timestamp that results in single digit day/month
      final order = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'paid',
        createdAt: 1704715800, // January 8, 2024
        updatedAt: 1704715800,
      );

      final formatted = order.formattedCreatedAt;
      // Should have format DD/MM/YYYY HH:MM with padded zeros
      expect(formatted, matches(r'\d{2}/\d{2}/\d{4} \d{2}:\d{2}'));
    });
  });

  group('OrderDetail - copyWith', () {
    test('creates copy with updated status', () {
      final original = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'created',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      final updated = original.copyWith(status: 'paid');

      expect(updated.status, 'paid');
      expect(updated.orderId, original.orderId);
      expect(updated.amount, original.amount);
      expect(updated.createdAt, original.createdAt);
    });

    test('creates copy with multiple updated fields', () {
      final original = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'created',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      final updated = original.copyWith(
        status: 'paid',
        paymentId: 'pay_456',
        signature: 'sig_789',
        updatedAt: 1705320700,
        isSynced: true,
      );

      expect(updated.status, 'paid');
      expect(updated.paymentId, 'pay_456');
      expect(updated.signature, 'sig_789');
      expect(updated.updatedAt, 1705320700);
      expect(updated.isSynced, true);
      expect(updated.orderId, original.orderId);
      expect(updated.amount, original.amount);
    });

    test('creates copy with no changes when no parameters provided', () {
      final original = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'paid',
        createdAt: 1705320600,
        updatedAt: 1705320600,
        customerName: 'John Doe',
      );

      final copy = original.copyWith();

      expect(copy.orderId, original.orderId);
      expect(copy.amount, original.amount);
      expect(copy.status, original.status);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
      expect(copy.customerName, original.customerName);
    });

    test('creates copy with updated customer information', () {
      final original = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'created',
        createdAt: 1705320600,
        updatedAt: 1705320600,
      );

      final updated = original.copyWith(
        customerName: 'Jane Smith',
        customerEmail: 'jane@example.com',
        customerPhone: '8888888888',
      );

      expect(updated.customerName, 'Jane Smith');
      expect(updated.customerEmail, 'jane@example.com');
      expect(updated.customerPhone, '8888888888');
      expect(updated.orderId, original.orderId);
    });

    test('creates copy with updated sync status', () {
      final original = OrderDetail(
        orderId: 'order_123',
        amount: 10050,
        status: 'paid',
        createdAt: 1705320600,
        updatedAt: 1705320600,
        isSynced: false,
      );

      final updated = original.copyWith(isSynced: true);

      expect(updated.isSynced, true);
      expect(updated.orderId, original.orderId);
      expect(updated.status, original.status);
    });
  });

  group('OrderDetail - JSON Parsing', () {
    test('parses complete JSON correctly', () {
      final json = {
        'order_id': 'order_123',
        'amount': 10050,
        'status': 'paid',
        'payment_id': 'pay_456',
        'signature': 'sig_789',
        'created_at': 1705320600,
        'updated_at': 1705320700,
        'customer_name': 'John Doe',
        'customer_email': 'john@example.com',
        'customer_phone': '9999999999',
      };

      final order = OrderDetail.fromJson(json);

      expect(order.orderId, 'order_123');
      expect(order.amount, 10050);
      expect(order.status, 'paid');
      expect(order.paymentId, 'pay_456');
      expect(order.signature, 'sig_789');
      expect(order.createdAt, 1705320600);
      expect(order.updatedAt, 1705320700);
      expect(order.customerName, 'John Doe');
      expect(order.customerEmail, 'john@example.com');
      expect(order.customerPhone, '9999999999');
    });

    test('handles missing optional fields with null', () {
      final json = {
        'order_id': 'order_123',
        'amount': 10050,
        'status': 'created',
        'created_at': 1705320600,
      };

      final order = OrderDetail.fromJson(json);

      expect(order.orderId, 'order_123');
      expect(order.amount, 10050);
      expect(order.status, 'created');
      expect(order.createdAt, 1705320600);
      expect(order.paymentId, isNull);
      expect(order.signature, isNull);
      expect(order.updatedAt, 0); // updatedAt is required, defaults to 0
      expect(order.customerName, isNull);
      expect(order.customerEmail, isNull);
      expect(order.customerPhone, isNull);
    });

    test('uses default values for missing required fields', () {
      final json = <String, dynamic>{};

      final order = OrderDetail.fromJson(json);

      expect(order.orderId, '');
      expect(order.amount, 0);
      expect(order.status, 'unknown');
      expect(order.createdAt, 0);
    });

    test('handles null values in JSON', () {
      final json = {
        'order_id': null,
        'amount': null,
        'status': null,
        'created_at': null,
      };

      final order = OrderDetail.fromJson(json);

      expect(order.orderId, '');
      expect(order.amount, 0);
      expect(order.status, 'unknown');
      expect(order.createdAt, 0);
    });
  });
}
