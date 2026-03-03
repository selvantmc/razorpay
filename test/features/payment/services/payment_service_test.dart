import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/features/payment/services/payment_service.dart';
import 'package:flutter_app/features/payment/services/backend_api_service.dart';
import 'package:flutter_app/features/payment/services/local_storage_service.dart';
import 'package:flutter_app/features/payment/services/subscription_service.dart';
import 'package:flutter_app/features/payment/services/local_notification_service.dart';
import 'package:flutter_app/features/payment/models/payment_models.dart';
import 'package:flutter_app/models/order_detail.dart';

@GenerateMocks([
  BackendApiService,
  LocalStorageService,
  SubscriptionService,
  LocalNotificationService,
])
import 'payment_service_test.mocks.dart';

void main() {
  group('PaymentService Backward Compatibility Tests', () {
    late PaymentService paymentService;
    late MockBackendApiService mockBackendApi;
    late MockLocalStorageService mockLocalStorage;
    late MockSubscriptionService mockSubscription;
    late MockLocalNotificationService mockNotification;
    late SharedPreferences prefs;

    setUp(() async {
      // Initialize SharedPreferences with in-memory store
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // Create mocks
      mockBackendApi = MockBackendApiService();
      mockLocalStorage = MockLocalStorageService();
      mockSubscription = MockSubscriptionService();
      mockNotification = MockLocalNotificationService();

      // Create service instance
      paymentService = PaymentService(
        backendApi: mockBackendApi,
        prefs: prefs,
        localStorageService: mockLocalStorage,
        subscriptionService: mockSubscription,
        localNotificationService: mockNotification,
      );
    });

    tearDown(() {
      paymentService.dispose();
    });

    group('Public API Compatibility', () {
      test('openCheckout method signature unchanged', () {
        // Verify method exists with correct signature
        expect(
          paymentService.openCheckout,
          isA<
              Future<PaymentResult> Function({
            required int amount,
            String? reference,
            void Function(String)? onStatus,
          })>(),
        );
      });

      test('checkStatus method signature unchanged', () {
        // Verify method exists with correct signature
        expect(
          paymentService.checkStatus,
          isA<Future<PaymentStatusResponse> Function()>(),
        );
      });

      test('lastResult getter unchanged', () {
        // Verify getter exists
        expect(paymentService.lastResult, isNull);
      });

      test('dispose method unchanged', () {
        // Verify method exists
        expect(paymentService.dispose, isA<void Function()>());
      });

      test('RAZORPAY_KEY_ID constant unchanged', () {
        // Verify constant exists and is accessible
        expect(PaymentService.RAZORPAY_KEY_ID, isA<String>());
        expect(PaymentService.RAZORPAY_KEY_ID.isNotEmpty, isTrue);
      });
    });

    group('Existing Payment Flow Compatibility', () {
      test('checkStatus works with existing persistence keys', () async {
        // Setup: Store order and payment IDs using old persistence keys
        await prefs.setString('last_order_id', 'order_test_123');
        await prefs.setString('last_payment_id', 'pay_test_456');

        // Mock backend response
        when(mockBackendApi.checkPaymentStatus(
          orderId: 'order_test_123',
          paymentId: 'pay_test_456',
        )).thenAnswer((_) async => PaymentStatusResponse(
              orderId: 'order_test_123',
              paymentId: 'pay_test_456',
              status: PaymentStatus.success,
              amount: 10000,
              currency: 'INR',
            ));

        // Execute
        final result = await paymentService.checkStatus();

        // Verify
        expect(result.orderId, 'order_test_123');
        expect(result.paymentId, 'pay_test_456');
        expect(result.status, PaymentStatus.success);
        verify(mockBackendApi.checkPaymentStatus(
          orderId: 'order_test_123',
          paymentId: 'pay_test_456',
        )).called(1);
      });

      test('lastResult getter returns null initially', () {
        // Verify existing behavior
        expect(paymentService.lastResult, isNull);
      });

      test('dispose cleans up resources without errors', () {
        // Verify dispose can be called multiple times safely
        expect(() => paymentService.dispose(), returnsNormally);
        expect(() => paymentService.dispose(), returnsNormally);
      });
    });

    group('Constructor Compatibility', () {
      test('can be instantiated with all required parameters', () {
        // Verify constructor works with all parameters
        final service = PaymentService(
          backendApi: mockBackendApi,
          prefs: prefs,
          localStorageService: mockLocalStorage,
          subscriptionService: mockSubscription,
          localNotificationService: mockNotification,
        );

        expect(service, isNotNull);
        expect(service, isA<PaymentService>());
        
        service.dispose();
      });
    });

    group('Error Handling Compatibility', () {
      test('openCheckout throws exception on order creation failure', () async {
        // Mock order creation failure
        when(mockBackendApi.createOrder(
          amount: anyNamed('amount'),
          reference: anyNamed('reference'),
        )).thenThrow(Exception('Network error'));

        // Mock local storage operations
        when(mockLocalStorage.saveOrder(any)).thenAnswer((_) async => {});
        when(mockSubscription.subscribeToOrder(any)).thenAnswer((_) async => {});

        // Verify exception is thrown
        expect(
          () => paymentService.openCheckout(amount: 100),
          throwsException,
        );
      });

      test('checkStatus throws exception on backend failure', () async {
        // Setup persistence
        await prefs.setString('last_order_id', 'order_test_123');

        // Mock backend failure
        when(mockBackendApi.checkPaymentStatus(
          orderId: anyNamed('orderId'),
          paymentId: anyNamed('paymentId'),
        )).thenThrow(Exception('Backend error'));

        // Verify exception is thrown
        expect(
          () => paymentService.checkStatus(),
          throwsException,
        );
      });
    });
  });
}
