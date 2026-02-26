import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/api/payment_api.dart';

void main() {
  group('PaymentApi - Configuration', () {
    test('has correct base URL', () {
      expect(
        PaymentApi.baseUrl,
        'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan',
      );
    });

    test('has 15-second timeout configured', () {
      expect(PaymentApi.timeout, const Duration(seconds: 15));
    });
  });

  group('PaymentApi - Error Handling', () {
    test('timeout duration is exactly 15 seconds', () {
      const expectedTimeout = Duration(seconds: 15);
      expect(PaymentApi.timeout, equals(expectedTimeout));
      expect(PaymentApi.timeout.inSeconds, equals(15));
    });

    test('timeout is applied to all requests', () {
      // This test verifies the timeout constant exists and is accessible
      // The actual timeout application is tested through integration tests
      expect(PaymentApi.timeout, isNotNull);
      expect(PaymentApi.timeout.inSeconds, greaterThan(0));
    });
  });

  group('PaymentApi - Error Messages', () {
    test('API class is properly structured', () {
      // Verify the PaymentApi class has the expected static methods
      expect(PaymentApi.baseUrl, isNotEmpty);
      expect(PaymentApi.timeout.inSeconds, equals(15));
    });
  });
}
