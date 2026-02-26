# Kiro Agent Prompt — Razorpay + AWS Lambda Integration Fixes

Paste this entire prompt into your Kiro agent. It covers every bug and missing piece found by auditing the full codebase.

---

## Context

This Flutter project integrates Razorpay payments through AWS Lambda APIs. The backend is already deployed and working at:

```
https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan
```

Routes:
- `POST /create-order` → creates a Razorpay order, returns `{ orderId, amount, currency }`
- `POST /verify-payment` → verifies signature, returns `{ success: true/false }`
- `GET /check-payment-status?order_id=xxx` → returns payment list for an order

---

## Issues to Fix

### 1. `backend_api_service.dart` — field name mismatch on `createOrder`

The backend returns `{ "orderId": "...", "amount": ..., "currency": "..." }` but the service tries multiple fallbacks:
```dart
final orderId = data['order_id'] ?? data['id'] ?? data['orderId'];
```
Simplify to use the correct field directly, and cast `amount` safely as it may come back as `int` or `num`:

```dart
// In createOrder(), replace the field extraction block with:
final orderId = data['orderId'] as String;
final orderAmount = (data['amount'] as num).toInt();
final currency = (data['currency'] as String?) ?? 'INR';
```

---

### 2. `backend_api_service.dart` — field name mismatch on `verifyPayment`

The service sends `order_id`, `payment_id`, `signature` but the Lambda handler expects `razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`.

In `verifyPayment()`, fix the request body:
```dart
body: jsonEncode({
  'razorpay_order_id': orderId,
  'razorpay_payment_id': paymentId,
  'razorpay_signature': signature,
}),
```

---

### 3. `payment_service.dart` — payment result is never shown after success

`_handlePaymentSuccess` is a callback fired by the Razorpay SDK. The screen polls `lastResult` with a fixed 2-second delay, which is a race condition — the callback may not have fired yet.

Fix by using a `Completer<PaymentResult>` in `PaymentService` so the screen can properly `await` the result:

In `payment_service.dart`:
```dart
import 'dart:async';

// Add inside the class:
Completer<PaymentResult>? _paymentCompleter;

// Modify openCheckout() to create a completer and return its future:
Future<PaymentResult> openCheckout({required int amount, String? reference}) async {
  _paymentCompleter = Completer<PaymentResult>();
  
  // ... existing order creation and _razorpay.open(options) code ...

  return _paymentCompleter!.future;
}

// In _handlePaymentSuccess, complete the completer:
void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  final result = PaymentResult.success(
    paymentId: response.paymentId ?? '',
    orderId: response.orderId ?? '',
    signature: response.signature ?? '',
  );
  _lastResult = result;
  await _savePaymentId(response.paymentId ?? '');
  await _savePaymentStatus(PaymentStatus.success);

  // Auto-verify with backend after successful payment
  try {
    await _backendApi.verifyPayment(
      orderId: response.orderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );
  } catch (_) {} // verification failure is non-fatal, log it

  _paymentCompleter?.complete(result);
}

// In _handlePaymentError, complete with error:
void _handlePaymentError(PaymentFailureResponse response) async {
  final result = PaymentResult.failure(
    orderId: await _getLastOrderId() ?? 'unknown',
    errorCode: response.code.toString(),
    errorDescription: response.message ?? 'Payment failed',
  );
  _lastResult = result;
  await _savePaymentStatus(PaymentStatus.failed);
  _paymentCompleter?.completeError(result);
}
```

---

### 4. `razorpay_pos_screen.dart` — update `_handlePayNow` to await the result properly

Now that `openCheckout` returns a `Future<PaymentResult>`, update the screen:

```dart
Future<void> _handlePayNow() async {
  // ... existing validation code ...

  setState(() {
    _isProcessing = true;
    _responseText = 'Creating order...';
  });

  try {
    final result = await _paymentService!.openCheckout(
      amount: amount * 100, // paise
      reference: _referenceController.text.trim(),
    );
    _displayResult(result);
  } on PaymentResult catch (failedResult) {
    _displayResult(failedResult);
  } catch (e) {
    setState(() {
      _responseText = 'Error: $e';
      _currentStatus = PaymentStatus.failed;
    });
  } finally {
    setState(() => _isProcessing = false);
  }
}
```

---

### 5. `razorpay_pos_screen.dart` — loading state message should update during order creation

After the user taps "Pay Now", show a step-by-step status so they know what's happening:

In `openCheckout()` in `payment_service.dart`, accept an optional `onStatus` callback:
```dart
Future<PaymentResult> openCheckout({
  required int amount,
  String? reference,
  void Function(String)? onStatus,
}) async {
  onStatus?.call('Creating order with backend...');
  // ... create order ...
  onStatus?.call('Opening Razorpay checkout...');
  // ... open checkout ...
}
```

Pass it from the screen:
```dart
final result = await _paymentService!.openCheckout(
  amount: amount * 100,
  reference: _referenceController.text.trim(),
  onStatus: (msg) => setState(() => _responseText = msg),
);
```

---

### 6. `AndroidManifest.xml` — add internet permission

Ensure `android/app/src/main/AndroidManifest.xml` has this line inside `<manifest>` (before `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Without this, all HTTP calls to the Lambda API will silently fail on Android.

---

### 7. `AndroidManifest.xml` — Razorpay requires `REORDER_TASKS` permission and `allowBackup`

Add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.REORDER_TASKS" />
```

And ensure `<application>` tag has:
```xml
android:allowBackup="true"
```

---

### 8. `pubspec.yaml` — pin `razorpay_flutter` to a tested version

The current `^1.3.7` is fine. Ensure it is present. If it is missing, add it under `dependencies`:
```yaml
dependencies:
  razorpay_flutter: ^1.3.7
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

Run `flutter pub get` after any pubspec change.

---

### 9. `payment_service.dart` — dispose should cancel any pending completer

In `dispose()`:
```dart
void dispose() {
  if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
    _paymentCompleter!.completeError('PaymentService disposed');
  }
  _razorpay.clear();
}
```

---

### 10. `backend_api_service.dart` — add a timeout to all HTTP calls

Network calls to Lambda have no timeout set, which can hang the UI indefinitely if the API is cold-starting.

Wrap all `http.post` and `http.get` calls with `.timeout()`:
```dart
final response = await http.post(...).timeout(
  const Duration(seconds: 15),
  onTimeout: () => throw Exception('Request timed out. Please try again.'),
);
```

---

## Summary of Changes Needed

| File | Change |
|------|--------|
| `lib/features/payment/services/backend_api_service.dart` | Fix field names for `createOrder` and `verifyPayment`, add 15s timeout |
| `lib/features/payment/services/payment_service.dart` | Use `Completer` for result, auto-verify on success, fix dispose, add `onStatus` callback |
| `lib/features/payment/screens/razorpay_pos_screen.dart` | Await result from `openCheckout`, pass `onStatus`, remove fragile 2s delay |
| `android/app/src/main/AndroidManifest.xml` | Add `INTERNET` and `REORDER_TASKS` permissions |

After all changes, test with:
```bash
flutter run -d <your-android-device>
```
Enter any amount (e.g. `100` for ₹100), tap Pay Now, and complete with Razorpay test card `4111 1111 1111 1111`.
