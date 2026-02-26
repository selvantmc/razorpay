# Lambda ↔ Flutter Compatibility Audit
## Nourisha POS — Full Contract Verification

---

## ✅ 1. POST /create-order

### Flutter sends:
```json
{ "amount": 10000, "currency": "INR", "receipt": "receipt_1234567890" }
```

### Lambda reads:
```js
body.amount   ✅ used
body.currency ⚠️  IGNORED — Lambda hardcodes "INR", doesn't read this field
body.receipt  ⚠️  IGNORED — Lambda hardcodes its own receipt: `nourisha_${Date.now()}`
```

### Lambda returns:
```json
{ "success": true, "orderId": "order_xxx", "amount": 100000, "currency": "INR" }
```

### Flutter reads:
```dart
data['orderId']  ✅ matches
data['amount']   ✅ matches — cast to (num).toInt() ✅
data['currency'] ✅ matches
```

### 🐛 CRITICAL BUG — Double multiplication of amount:
- Flutter sends `amount * 100` (already in paise): e.g. ₹100 → sends `10000`
- Lambda does `body.amount * 100` again → creates order for `1000000` paise = **₹10,000** instead of ₹100
- **Every order will be charged 100x the intended amount**

**Fix needed in Lambda `createOrder.mjs`:**
```js
// REMOVE the * 100 — Flutter already sends paise
amount: body.amount,   // NOT body.amount * 100
```

**OR fix in Flutter `payment_service.dart`:**
```dart
// Send rupees, not paise — let Lambda do the conversion
amount: amount,   // NOT amount * 100
```
Pick one. The Lambda convention (multiply by 100 server-side) is safer. So fix Flutter to send rupees:
```dart
// In openCheckout() call from screen:
amount: amount,   // screen already has rupee value, don't multiply
// In backend_api_service.dart createOrder body:
'amount': amount, // send as rupees, Lambda will convert to paise
```

---

## ✅ 2. POST /verify-payment

### Flutter sends:
```json
{
  "razorpay_order_id": "order_xxx",
  "razorpay_payment_id": "pay_xxx",
  "razorpay_signature": "abc123"
}
```

### Lambda reads:
```js
razorpay_order_id   ✅ matches
razorpay_payment_id ✅ matches
razorpay_signature  ✅ matches
```

### Lambda returns on success:
```json
{ "success": true, "message": "Payment verified successfully", "orderId": "...", "paymentId": "..." }
```

### Lambda returns on failure:
```json
{ "success": false, "message": "Invalid payment signature" }  // statusCode 400
```

### Flutter reads:
```dart
data['success'] == true  ✅ matches
```

### 🐛 BUG — Flutter ignores the 400 status code on failure:
```dart
if (response.statusCode == 200) {
  return data['success'] == true || data['verified'] == true;
}
return false;  // ← silently returns false for 400, no error thrown
```
When signature is invalid, Lambda returns **statusCode 400**, not 200. Flutter will hit the `return false` path — which is technically correct (returns false = not verified) but swallows the error message. The UI will show nothing useful.

**Fix in `backend_api_service.dart`:**
```dart
// Handle both 200 (verified) and 400 (invalid signature) explicitly
if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  return data['success'] == true;
} else if (response.statusCode == 400) {
  final data = jsonDecode(response.body);
  throw Exception(data['message'] ?? 'Payment verification failed');
} else {
  throw Exception('Verify payment error: ${response.statusCode}');
}
```

---

## ✅ 3. GET /check-payment-status?order_id=xxx

### Flutter sends:
```
GET /check-payment-status?order_id=order_xxx
```

### Lambda reads:
```js
params.order_id  ✅ matches — Flutter uses 'order_id' as query param key ✅
```

### Lambda returns:
```json
{
  "success": true,
  "orderId": "order_xxx",
  "payments": [ ...array of Razorpay payment objects... ]
}
```

### Flutter reads:
```dart
data['order_id'] ?? data['orderId'] ?? orderId   // ✅ 'orderId' will match
data['payment_id'] ?? data['paymentId'] ?? paymentId  // ⚠️ see below
data['status']   // 🐛 BUG — Lambda doesn't return 'status' at top level
data['amount']   // 🐛 BUG — Lambda doesn't return 'amount' at top level
data['currency'] // 🐛 BUG — Lambda doesn't return 'currency' at top level
```

### 🐛 BUG — Response shape mismatch for checkPaymentStatus:
Lambda returns a `payments` array (list of individual Razorpay payment objects), but Flutter expects flat fields like `status`, `amount`, `currency` at the top level. These don't exist — Flutter will get `null` for all of them and always show `PaymentStatus.unknown` with amount `0`.

**Fix needed in Lambda `checkPaymentStatus.mjs` — return a normalized response:**
```js
const payments = await razorpay.orders.fetchPayments(orderId);
const latestPayment = payments.items?.[0]; // most recent payment

return {
  statusCode: 200,
  body: JSON.stringify({
    success: true,
    orderId,
    paymentId: latestPayment?.id ?? null,
    status: latestPayment?.status ?? 'created',   // 'captured', 'failed', 'created'
    amount: latestPayment?.amount ?? 0,
    currency: latestPayment?.currency ?? 'INR',
    paid_at: latestPayment?.created_at ?? null,
    payments: payments.items,  // keep full array too
  }),
};
```

---

## Summary Table

| Endpoint | Field Contract | Amount Math | Response Shape |
|----------|---------------|-------------|----------------|
| `POST /create-order` | ✅ All fields match | 🔴 **100x bug** | ✅ Flutter reads correctly |
| `POST /verify-payment` | ✅ All fields match | N/A | ⚠️ 400 status swallowed |
| `GET /check-payment-status` | ✅ Query param matches | N/A | 🔴 **Shape mismatch** — flat fields missing |

---

## All Required Fixes

### Fix 1 — `checkPaymentStatus.mjs` (Lambda) — normalize response shape:
```js
export async function checkPaymentStatus(event) {
  const params = event.queryStringParameters || {};
  const orderId = params.order_id;

  if (!orderId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "order_id is required" }),
    };
  }

  const payments = await razorpay.orders.fetchPayments(orderId);
  const latest = payments.items?.[0];

  return {
    statusCode: 200,
    body: JSON.stringify({
      success: true,
      orderId,
      paymentId: latest?.id ?? null,
      status: latest?.status ?? 'created',
      amount: latest?.amount ?? 0,
      currency: latest?.currency ?? 'INR',
      paid_at: latest?.created_at ?? null,
      payments: payments.items,
    }),
  };
}
```

### Fix 2 — `createOrder.mjs` (Lambda) — remove double multiplication:
```js
const order = await razorpay.orders.create({
  amount: body.amount,   // Flutter sends paise already (amount * 100)
  currency: body.currency || "INR",
  receipt: body.receipt || `nourisha_${Date.now()}`,
});
```

### Fix 3 — `backend_api_service.dart` (Flutter) — handle 400 on verifyPayment:
```dart
if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  return data['success'] == true;
} else if (response.statusCode == 400) {
  final data = jsonDecode(response.body);
  throw Exception(data['message'] ?? 'Payment verification failed');
} else {
  throw Exception('Verify payment error: ${response.statusCode}');
}
```
