# Kiro Spec: Nourisha Pay — Flutter App (v2)

## Overview

Update an existing Flutter payment app. The app has **two screens** accessed via a `BottomNavigationBar`:

1. **Payment Screen** (already exists — modify it) — Place an order + pay via Razorpay SDK + Check Payment Status
2. **Order Lookup Screen** (new) — Enter any Order ID, fetch full order details from DB, and take action if payment is incomplete

All API calls go through a centralised `PaymentApi` class. Payment credentials returned from the Razorpay SDK are persisted to a local `PaymentSession` object in memory so they can be reused for status checks without re-entering them.

---

## API Base URL

```
https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan
```

---

## All API Endpoints

| # | Method | Endpoint | Used On |
|---|--------|----------|---------|
| 1 | POST | `/create-order` | Payment Screen — on "Pay Now" |
| 2 | GET | `/check-payment-status?order_id=` | Payment Screen — on "Check Payment Status" button |
| 3 | POST | `/verify-payment` | Payment Screen — auto-called after Razorpay SDK success; Order Lookup Screen — manual button |
| 4 | GET | `/get-order?order_id=` | Order Lookup Screen — on "Fetch" button |

> `/razorpay-webhook` is server-side only. Never call it from the app.

---

## pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  razorpay_flutter: ^1.3.6
  shared_preferences: ^2.2.2   # for persisting last session across hot restarts (dev convenience)
```

---

## Project File Structure

```
lib/
├── main.dart
├── api/
│   └── payment_api.dart            # All HTTP calls
├── models/
│   ├── payment_session.dart        # Holds orderId, paymentId, signature in memory
│   └── order_detail.dart           # Typed model for /get-order response
├── screens/
│   ├── payment_screen.dart         # Screen 1 — place order + pay + check status
│   └── order_lookup_screen.dart    # Screen 2 — fetch order by ID + action buttons
└── widgets/
    ├── status_badge.dart           # Coloured badge for order status string
    ├── info_row.dart               # Label + value row used in order detail display
    └── primary_button.dart         # Full-width loading-aware ElevatedButton
```

---

## `main.dart`

Set up `MaterialApp` with `MainScaffold` as home.

`MainScaffold` is a `StatefulWidget` with:
- A `BottomNavigationBar` with two items:
  - Index 0: `Icons.payment_rounded` — label `"Pay"`
  - Index 1: `Icons.receipt_long_rounded` — label `"Orders"`
- Body uses `IndexedStack` with `[PaymentScreen(), OrderLookupScreen()]` to preserve state
- A shared `PaymentSession` object is instantiated once in `MainScaffold` and passed down via constructor to both screens

```dart
// Theme
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2563EB)),
  useMaterial3: true,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)
```

---

## `models/payment_session.dart`

```dart
/// Holds the credentials returned by the Razorpay SDK after a successful payment.
/// Passed by reference between screens so both can read/write the same session.
class PaymentSession {
  String? orderId;
  String? paymentId;
  String? signature;

  bool get hasSession =>
      orderId != null && paymentId != null && signature != null;

  void set({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    this.orderId   = orderId;
    this.paymentId = paymentId;
    this.signature = signature;
  }

  void clear() {
    orderId   = null;
    paymentId = null;
    signature = null;
  }
}
```

---

## `models/order_detail.dart`

Typed model representing a full order record from DynamoDB (returned by `/get-order`).

```dart
class OrderDetail {
  final String  orderId;
  final int     amount;           // in paise
  final String  currency;
  final String  status;
  final String  createdAt;
  final String? updatedAt;
  final String? paymentId;
  final String? signature;
  final Map<String, dynamic>? customerDetails;
  final Map<String, dynamic>? createOrderJson;
  final Map<String, dynamic>? paymentCapturedJson;
  final Map<String, dynamic>? paymentFailedJson;
  final Map<String, dynamic>? orderPaidJson;
  final Map<String, dynamic>? refundProcessedJson;
  final Map<String, dynamic>? refundFailedJson;
  final Map<String, dynamic>? paymentVerificationJson;
  final Map<String, dynamic>? paymentStatusJson;

  // Constructor, fromJson factory, convenience getters:

  /// Amount formatted as ₹ e.g. "₹100.00"
  String get formattedAmount => '₹${(amount / 100).toStringAsFixed(2)}';

  /// True if the order has NOT been successfully paid/verified yet
  bool get needsAction =>
      !['paid', 'captured', 'verified'].contains(status.toLowerCase());
}
```

---

## `api/payment_api.dart`

```dart
class PaymentApi {
  static const String _base =
      'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan';

  static const Duration _timeout = Duration(seconds: 15);

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// POST /create-order
  /// Body:    { "amount": <double>  }   ← amount in rupees (backend multiplies ×100)
  /// Returns: { "success": true, "orderId": "order_xxx", "amount": 50000, "currency": "INR" }
  static Future<Map<String, dynamic>> createOrder(double amount) async { ... }

  /// POST /verify-payment
  /// Body:    { "razorpay_order_id", "razorpay_payment_id", "razorpay_signature" }
  /// Returns: { "success": true/false, "message": "...", "orderId": "...", "paymentId": "..." }
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async { ... }

  /// GET /check-payment-status?order_id=<orderId>
  /// Returns: { "success": true, "orderId": "...", "payments": [...] }
  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async { ... }

  /// GET /get-order?order_id=<orderId>
  /// Returns: { "success": true, "order": { ...full DynamoDB record... } }
  static Future<Map<String, dynamic>> getOrder(String orderId) async { ... }
}
```

### Error handling rules (apply inside every method)

- Non-2xx response → parse body, throw `Exception(body['message'] ?? 'Request failed (${response.statusCode})')`
- `SocketException` → throw `Exception('No internet connection.')`
- `TimeoutException` → throw `Exception('Request timed out. Please try again.')`
- JSON parse error → throw `Exception('Unexpected server response.')`
- Always call `.timeout(_timeout)` on every request

---

## Screen 1 — `PaymentScreen`

### Purpose
The existing payment screen. Modify it to:
1. Accept amount input and call `POST /create-order`
2. Launch Razorpay SDK with the returned `orderId` and `amount`
3. On SDK success, save credentials to `PaymentSession` and auto-call `POST /verify-payment`
4. Show a "Check Payment Status" button that calls `GET /check-payment-status`

### Constructor

```dart
class PaymentScreen extends StatefulWidget {
  final PaymentSession session;
  const PaymentScreen({required this.session, super.key});
}
```

### UI Layout

```
Scaffold(
  appBar: AppBar(title: Text('Make a Payment')),
  body: SingleChildScrollView(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [

        // ── PLACE ORDER CARD ──────────────────────────────
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Order', style: titleStyle),
                SizedBox(height: 4),
                Text('Enter amount in ₹', style: subtitleStyle),
                SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: 'e.g. 100',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount is required';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a valid amount greater than 0';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                PrimaryButton(
                  label: 'Pay Now',
                  isLoading: _isCreatingOrder,
                  onPressed: _startPayment,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // ── SESSION INFO (shown only when session.hasSession) ──
        // Show a subtle info card with the current session's orderId, paymentId, signature
        // This helps the user know which order is active
        if (session.hasSession) _buildSessionCard(),

        SizedBox(height: 16),

        // ── CHECK STATUS BUTTON ───────────────────────────────
        // Always visible. Uses session.orderId if available, otherwise
        // falls back to the last successfully created orderId stored in _lastOrderId.
        // If neither is available, show a SnackBar: "No active order. Place an order first."
        PrimaryButton(
          label: 'Check Payment Status',
          isLoading: _isCheckingStatus,
          icon: Icons.search_rounded,
          onPressed: _checkStatus,
        ),

        SizedBox(height: 24),

        // ── RESULT BOX ───────────────────────────────────────
        _ResultBox(result: _result, error: _error, isLoading: _isLoadingResult),
      ],
    ),
  ),
)
```

### State Variables

```dart
final _formKey          = GlobalKey<FormState>();
final _amountController = TextEditingController();

bool   _isCreatingOrder  = false;
bool   _isCheckingStatus = false;
bool   _isLoadingResult  = false;
String? _lastOrderId;     // Set after createOrder succeeds, even before payment
String? _result;          // JSON string to display in result box
String? _error;           // Error message to display in result box
```

### `_startPayment()` Flow

```
Step 1: Validate form
Step 2: setState(_isCreatingOrder = true), clear _error
Step 3: Call PaymentApi.createOrder(amount)
        → On error: setState(_error = e.message, _isCreatingOrder = false), return
Step 4: Save orderId to _lastOrderId
Step 5: setState(_isCreatingOrder = false)
Step 6: Launch Razorpay SDK (see Razorpay SDK Integration below)
```

### Razorpay SDK Integration

```dart
// Initialise Razorpay instance in initState():
_razorpay = Razorpay();
_razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
_razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _handlePaymentError);
_razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

// In dispose():
_razorpay.clear();

// Open Razorpay checkout:
void _openRazorpay(String orderId, int amount) {
  final options = {
    'key':         'YOUR_RAZORPAY_KEY_ID',   // Replace with env/config value
    'amount':      amount,                    // Amount in paise (already multiplied by backend)
    'order_id':    orderId,
    'name':        'Nourisha',
    'description': 'Payment for order $orderId',
    'prefill': {
      'contact': '',
      'email':   '',
    },
    'external': {
      'wallets': ['paytm'],
    },
  };
  _razorpay.open(options);
}
```

### `_handlePaymentSuccess(PaymentSuccessResponse response)`

```dart
// 1. Save to session
session.set(
  orderId:   response.orderId!,
  paymentId: response.paymentId!,
  signature: response.signature!,
);

// 2. Auto-call verify-payment
setState(() => _isLoadingResult = true);
try {
  final data = await PaymentApi.verifyPayment(
    orderId:   response.orderId!,
    paymentId: response.paymentId!,
    signature: response.signature!,
  );
  setState(() {
    _result         = JsonEncoder.withIndent('  ').convert(data);
    _isLoadingResult = false;
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ Payment verified successfully!'),
      backgroundColor: Colors.green.shade600,
    ),
  );
} catch (e) {
  setState(() {
    _error           = e.toString();
    _isLoadingResult = false;
  });
}
```

### `_handlePaymentError(PaymentFailureResponse response)`

```dart
setState(() {
  _error = 'Payment failed: ${response.message ?? "Unknown error"}';
});
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('❌ Payment failed. Please try again.'),
    backgroundColor: Colors.red.shade600,
  ),
);
```

### `_handleExternalWallet(ExternalWalletResponse response)`

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('External wallet selected: ${response.walletName}')),
);
```

### `_checkStatus()` Flow

```dart
Future<void> _checkStatus() async {
  // Use session orderId first, then fall back to _lastOrderId
  final orderId = session.orderId ?? _lastOrderId;
  if (orderId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No active order. Place an order first.')),
    );
    return;
  }
  setState(() { _isCheckingStatus = true; _error = null; });
  try {
    final data = await PaymentApi.checkPaymentStatus(orderId);
    setState(() {
      _result          = JsonEncoder.withIndent('  ').convert(data);
      _isCheckingStatus = false;
    });
  } catch (e) {
    setState(() { _error = e.toString(); _isCheckingStatus = false; });
  }
}
```

### Session Info Card (`_buildSessionCard`)

```
Card with light blue/indigo tint (Colors.indigo.shade50):
  Row: Icon(Icons.info_outline) + Text "Active Session"
  InfoRow(label: 'Order ID',    value: session.orderId!)
  InfoRow(label: 'Payment ID',  value: session.paymentId!)
  InfoRow(label: 'Signature',   value: session.signature!, overflow: true)
```

---

## Screen 2 — `OrderLookupScreen`

### Purpose
Let the user enter any Razorpay Order ID, fetch its full details from DynamoDB, display them, and take action if the order is not yet paid/verified.

### Constructor

```dart
class OrderLookupScreen extends StatefulWidget {
  final PaymentSession session;
  const OrderLookupScreen({required this.session, super.key});
}
```

### UI Layout

```
Scaffold(
  appBar: AppBar(title: Text('Order Lookup')),
  body: SingleChildScrollView(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [

        // ── SEARCH CARD ───────────────────────────────────
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Fetch Order Details', style: titleStyle),
                SizedBox(height: 16),
                TextFormField(
                  controller: _orderIdController,
                  decoration: InputDecoration(
                    labelText: 'Order ID',
                    hintText: 'order_xxxxx',
                    prefixIcon: Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _orderIdController.clear(),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter an Order ID'
                      : null,
                ),
                SizedBox(height: 16),
                PrimaryButton(
                  label: 'Fetch Order',
                  icon: Icons.download_rounded,
                  isLoading: _isFetching,
                  onPressed: _fetchOrder,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24),

        // ── ORDER DETAIL CARD (shown after successful fetch) ──
        if (_order != null) _buildOrderDetailCard(_order!),

        // ── ERROR MESSAGE ─────────────────────────────────────
        if (_error != null) _buildErrorCard(_error!),
      ],
    ),
  ),
)
```

### State Variables

```dart
final _formKey            = GlobalKey<FormState>();
final _orderIdController  = TextEditingController();

bool          _isFetching          = false;
bool          _isVerifying         = false;
bool          _isCheckingStatus    = false;
OrderDetail?  _order               = null;
String?       _error               = null;
String?       _actionResult        = null;   // Result from verify/check-status actions
```

### `_fetchOrder()` Method

```dart
Future<void> _fetchOrder() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() { _isFetching = true; _error = null; _order = null; _actionResult = null; });
  try {
    final data  = await PaymentApi.getOrder(_orderIdController.text.trim());
    final order = OrderDetail.fromJson(data['order'] as Map<String, dynamic>);
    setState(() { _order = order; _isFetching = false; });
  } catch (e) {
    setState(() { _error = e.toString(); _isFetching = false; });
  }
}
```

### Order Detail Card (`_buildOrderDetailCard`)

Display a `Card` with all order fields in `InfoRow` widgets:

```
Card:
  ┌──────────────────────────────────────────┐
  │  Row:                                    │
  │    Text "Order Details"  (title)         │
  │    StatusBadge(status: order.status)     │
  │                                          │
  │  Divider                                 │
  │                                          │
  │  InfoRow(label:'Order ID',   value: ...) │
  │  InfoRow(label:'Amount',     value: order.formattedAmount) │
  │  InfoRow(label:'Currency',   value: ...) │
  │  InfoRow(label:'Created At', value: ...) │
  │  InfoRow(label:'Updated At', value: ...) │
  │  InfoRow(label:'Payment ID', value: ...) │
  │                                          │
  │  -- Customer Details (if not null) --    │
  │  Text 'Customer Details'  (section label)│
  │  InfoRow(label:'Email',    value: ...)   │
  │  InfoRow(label:'Contact',  value: ...)   │
  │                                          │
  │  ── ACTION BUTTONS (only if needsAction) ─│
  │                                          │
  │  if (order.needsAction):                 │
  │                                          │
  │    OutlinedButton  "Verify Payment"      │
  │      isLoading: _isVerifying             │
  │      onPressed: _verifyFromDb            │
  │      icon: Icons.verified_rounded        │
  │                                          │
  │    SizedBox(height: 12)                  │
  │                                          │
  │    OutlinedButton  "Check Payment Status"│
  │      isLoading: _isCheckingStatus        │
  │      onPressed: _checkStatusFromDb       │
  │      icon: Icons.search_rounded          │
  │                                          │
  │  ── ACTION RESULT (if _actionResult != null) ──│
  │  Container (dark bg, monospace font)     │
  │    SelectableText(_actionResult)         │
  │                                          │
  └──────────────────────────────────────────┘
```

### `_verifyFromDb()` Method

```dart
/// Uses order_id, payment_id, and signature fetched from DynamoDB.
/// These were stored by the webhook and/or previous verify calls.
Future<void> _verifyFromDb() async {
  final order = _order!;

  // Check we have all required fields from the DB record
  if (order.paymentId == null || order.signature == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment ID or Signature not yet available for this order. '
          'Please wait for the webhook to process or try Check Payment Status first.',
        ),
        backgroundColor: Colors.orange.shade700,
      ),
    );
    return;
  }

  setState(() { _isVerifying = true; _actionResult = null; });
  try {
    final data = await PaymentApi.verifyPayment(
      orderId:   order.orderId,
      paymentId: order.paymentId!,
      signature: order.signature!,
    );
    setState(() {
      _actionResult = JsonEncoder.withIndent('  ').convert(data);
      _isVerifying  = false;
    });
    // Also refresh the order to reflect updated status
    await _fetchOrder();
  } catch (e) {
    setState(() { _actionResult = 'Error: $e'; _isVerifying = false; });
  }
}
```

### `_checkStatusFromDb()` Method

```dart
/// Calls GET /check-payment-status using the order_id from the fetched DB record.
Future<void> _checkStatusFromDb() async {
  setState(() { _isCheckingStatus = true; _actionResult = null; });
  try {
    final data = await PaymentApi.checkPaymentStatus(_order!.orderId);
    setState(() {
      _actionResult      = JsonEncoder.withIndent('  ').convert(data);
      _isCheckingStatus  = false;
    });
  } catch (e) {
    setState(() { _actionResult = 'Error: $e'; _isCheckingStatus = false; });
  }
}
```

---

## Shared Widget — `StatusBadge`

```dart
/// A small pill badge coloured by order status.
/// 
/// Status → Color mapping:
///   "paid" | "captured" | "verified"   → green
///   "created"                          → blue
///   "failed" | "verification_failed"   → red
///   "refund_processed"                 → orange
///   "refund_failed"                    → deep orange
///   anything else                      → grey
class StatusBadge extends StatelessWidget {
  final String status;
  // Render as a Container with rounded corners, colored background (10% opacity),
  // colored border, and colored text — all derived from the status value.
}
```

---

## Shared Widget — `InfoRow`

```dart
/// A label + value row used in the order detail card.
/// Value text is selectable (SelectableText) for easy copying.
/// If overflow is true, value is shown in a smaller font and allowed to wrap.
class InfoRow extends StatelessWidget {
  final String  label;
  final String? value;
  final bool    overflow;   // default: false

  // If value is null or empty, render value as Text('—', style: muted)
}
```

---

## Shared Widget — `PrimaryButton`

```dart
/// Full-width loading-aware ElevatedButton.
/// When isLoading is true:
///   - onPressed is set to null (disables the button)
///   - Shows a Row: SizedBox(16x16 CircularProgressIndicator(strokeWidth:2)) + Text(label)
/// Accepts an optional leading icon (shown when not loading).
class PrimaryButton extends StatelessWidget {
  final String        label;
  final VoidCallback? onPressed;
  final bool          isLoading;
  final IconData?     icon;
}
```

---

## Full Payment Flow Diagram

```
USER                    FLUTTER APP                     BACKEND (Lambda)            RAZORPAY

  │── enters amount ──▶│                                    │                           │
  │                    │── POST /create-order ─────────────▶│                           │
  │                    │◀─ { orderId, amount } ─────────────│                           │
  │                    │                                    │                           │
  │                    │── razorpay.open(orderId, amount) ──────────────────────────────▶│
  │                    │                                    │                           │
  │ (completes payment)│◀── PaymentSuccessResponse ────────────────────────────────────│
  │                    │    (orderId, paymentId, signature) │                           │
  │                    │                                    │                           │
  │                    │── saves to PaymentSession ─────────│                           │
  │                    │                                    │                           │
  │                    │── POST /verify-payment ────────────▶│                           │
  │                    │◀─ { success: true } ───────────────│                           │
  │                    │                                    │                           │
  │                    │── shows SnackBar "Verified" ───────│                           │
  │                    │                                    │                           │
  │── taps "Check      │                                    │                           │
  │   Payment Status" ─▶── GET /check-payment-status ──────▶│                           │
  │                    │◀─ { payments: [...] } ─────────────│                           │
  │                    │── shows result in ResultBox ───────│                           │
```

---

## Order Lookup Flow Diagram

```
USER                    FLUTTER APP (Screen 2)           BACKEND

  │── enters order_id ─▶│                                    │
  │── taps "Fetch" ────▶│── GET /get-order?order_id= ───────▶│
  │                     │◀─ { order: { status, paymentId,    │
  │                     │             signature, ... } } ─────│
  │                     │                                    │
  │                     │── shows order detail card          │
  │                     │                                    │
  │  [if needsAction]   │                                    │
  │                     │── shows two buttons:               │
  │                     │   "Verify Payment"                 │
  │                     │   "Check Payment Status"           │
  │                     │                                    │
  │── taps "Verify" ───▶│── POST /verify-payment ────────────▶│
  │                     │   (orderId, paymentId, signature   │
  │                     │    all from DB record)             │
  │                     │◀─ { success: true/false } ─────────│
  │                     │── shows result, refreshes order    │
```

---

## Error Display

All errors must be shown in a styled error card (not just a SnackBar for errors that affect the UI flow):

```dart
Widget _buildErrorCard(String error) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade600),
        SizedBox(width: 12),
        Expanded(
          child: Text(error, style: TextStyle(color: Colors.red.shade800)),
        ),
      ],
    ),
  );
}
```

---

## `needsAction` Status Logic

The action buttons ("Verify Payment", "Check Payment Status") are shown on `OrderLookupScreen` **only** when `order.needsAction == true`.

```dart
bool get needsAction =>
    !['paid', 'captured', 'verified'].contains(status.toLowerCase());
```

So buttons appear for: `created`, `failed`, `verification_failed`, `refund_processed`, `refund_failed`, or any unknown status.
Buttons are **hidden** for: `paid`, `captured`, `verified`.

---

## Android Permissions

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## Out of Scope

- `/razorpay-webhook` — never call this from the app
- User authentication / login
- Local database or SQLite persistence
- Push notifications
- Refund initiation from the app

---

## Deliverables

```
pubspec.yaml
lib/
├── main.dart
├── api/
│   └── payment_api.dart
├── models/
│   ├── payment_session.dart
│   └── order_detail.dart
├── screens/
│   ├── payment_screen.dart
│   └── order_lookup_screen.dart
└── widgets/
    ├── status_badge.dart
    ├── info_row.dart
    └── primary_button.dart
```

---

## Quick-Start

```bash
flutter pub get
flutter run
```
