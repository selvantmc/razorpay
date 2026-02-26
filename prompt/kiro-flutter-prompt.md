# Kiro Spec: Razorpay Payment Dashboard — Flutter App

## Project Overview

Build a **Flutter mobile application** (Android + iOS) that serves as a payment management dashboard integrated with a Razorpay backend hosted on AWS Lambda. The app has two main screens navigated via a **Bottom Navigation Bar**:

1. **Home** — Place a new order
2. **Orders** — Sub-tabbed screen with:
   - Check Payment Status
   - Verify Payment

All API responses are displayed in a scrollable, formatted JSON result box on each screen.

---

## Tech Stack

- **Framework**: Flutter (Dart) — latest stable channel
- **HTTP**: `http` package (`^1.2.0`)
- **State Management**: `setState` with `StatefulWidget` (no Bloc/Provider needed for this scope)
- **Navigation**: Flutter `BottomNavigationBar` for top-level, `TabBar` + `TabBarView` for Orders sub-tabs
- **JSON Display**: `Text` widget inside a scrollable `Container` with monospace font
- **Clipboard**: `flutter/services.dart` → `Clipboard.setData`

---

## pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## API Base URL

```
https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan
```

All POST requests must include the header:
```
Content-Type: application/json
```

---

## API Endpoints

| # | Method | Path | Description |
|---|--------|------|-------------|
| 1 | GET | `/check-payment-status` | Check status of an order by order_id |
| 2 | POST | `/create-order` | Create a new Razorpay order |
| 3 | POST | `/verify-payment` | Verify a completed payment signature |

> Note: `/razorpay-webhook` is called by Razorpay servers only — do NOT include it in the UI.

---

## Project File Structure

```
lib/
├── main.dart
├── api/
│   └── payment_api.dart         # All API call functions (centralised)
├── models/
│   └── api_response.dart        # Wrapper model for API results
├── screens/
│   ├── home_screen.dart         # Place Order screen
│   └── orders_screen.dart       # Orders screen with TabBar
├── tabs/
│   ├── check_status_tab.dart    # Tab 1: Check Payment Status
│   └── verify_payment_tab.dart  # Tab 2: Verify Payment
└── widgets/
    ├── result_box.dart          # Reusable JSON result display widget
    ├── primary_button.dart      # Reusable loading-aware button
    └── labeled_text_field.dart  # Reusable labeled input field
```

---

## `main.dart`

- Set up `MaterialApp` with a custom `ThemeData`
- Entry widget is `MainScaffold` — a `StatefulWidget` with a `BottomNavigationBar`
- `BottomNavigationBar` has two items:
  - Index 0: Icon `Icons.home_rounded`, Label `"Home"`
  - Index 1: Icon `Icons.receipt_long_rounded`, Label `"Orders"`
- `body` switches between `HomeScreen` and `OrdersScreen` based on selected index
- Use `IndexedStack` to preserve state when switching tabs

### Theme

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF4F46E5)), // Indigo
  useMaterial3: true,
  fontFamily: 'Roboto',
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)
```

---

## `api/payment_api.dart`

Centralise all HTTP calls. Each method returns a `Map<String, dynamic>` on success or throws an `Exception` with a descriptive message on failure.

```dart
class PaymentApi {
  static const String _baseUrl =
      'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan';

  /// POST /create-order
  /// Body: { "amount": number }
  /// Returns: { "success": true, "orderId": "...", "amount": ..., "currency": "INR" }
  static Future<Map<String, dynamic>> createOrder(double amount) async { ... }

  /// GET /check-payment-status?order_id=<orderId>
  /// Returns: { "success": true, "orderId": "...", "payments": [...] }
  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async { ... }

  /// POST /verify-payment
  /// Body: { "razorpay_order_id", "razorpay_payment_id", "razorpay_signature" }
  /// Returns: { "success": true/false, "message": "...", ... }
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async { ... }
}
```

### Error Handling Rules (inside each method)

- If `response.statusCode` is not 2xx → parse the body and throw `Exception(body['message'] ?? 'Request failed')`
- On `SocketException` → throw `Exception('Network error. Check your internet connection.')`
- On `TimeoutException` → throw `Exception('Request timed out. Please try again.')`
- On JSON parse error → throw `Exception('Unexpected server response.')`
- Set a timeout of **15 seconds** on all requests using `.timeout(Duration(seconds: 15))`

---

## `models/api_response.dart`

```dart
class ApiResponse {
  final Map<String, dynamic>? data;  // Parsed JSON on success
  final String? error;               // Error message on failure
  final bool isLoading;

  const ApiResponse({this.data, this.error, this.isLoading = false});

  factory ApiResponse.loading() => ApiResponse(isLoading: true);
  factory ApiResponse.success(Map<String, dynamic> data) => ApiResponse(data: data);
  factory ApiResponse.error(String message) => ApiResponse(error: message);
}
```

---

## Screen 1 — `HomeScreen` (`home_screen.dart`)

### Purpose
Allow the user to create a new Razorpay order by entering an amount.

### UI Layout

```
AppBar: "Place an Order"

Body (SingleChildScrollView > Column, padding: 20):
  ┌─────────────────────────────────┐
  │  Card (rounded, elevated)       │
  │                                 │
  │  Text: "Create New Order"       │
  │  (subtitle: "Enter amount in ₹")│
  │                                 │
  │  LabeledTextField               │
  │    Label: "Amount (₹)"          │
  │    Hint: "e.g. 500"             │
  │    Keyboard: number             │
  │    Validator: required, > 0     │
  │                                 │
  │  SizedBox(height: 16)           │
  │                                 │
  │  PrimaryButton                  │
  │    Label: "Create Order"        │
  │    onPressed: _createOrder()    │
  │                                 │
  └─────────────────────────────────┘

  SizedBox(height: 24)

  ResultBox(response: _response)
```

### State Variables

```dart
final _amountController = TextEditingController();
final _formKey = GlobalKey<FormState>();
ApiResponse _response = ApiResponse();
```

### `_createOrder()` Method

```dart
Future<void> _createOrder() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _response = ApiResponse.loading());
  try {
    final amount = double.parse(_amountController.text.trim());
    final data = await PaymentApi.createOrder(amount);
    setState(() => _response = ApiResponse.success(data));
    // Copy orderId to clipboard and show SnackBar
    if (data['orderId'] != null) {
      await Clipboard.setData(ClipboardData(text: data['orderId']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ID copied to clipboard!')),
      );
    }
  } catch (e) {
    setState(() => _response = ApiResponse.error(e.toString()));
  }
}
```

### Validation Rules

- Amount must not be empty
- Amount must be a valid number greater than 0
- Show inline validation error below the field

---

## Screen 2 — `OrdersScreen` (`orders_screen.dart`)

### Purpose
Container screen with a `TabBar` at the top for two tools.

### UI Layout

```dart
DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: AppBar(
      title: Text('Orders'),
      bottom: TabBar(
        tabs: [
          Tab(icon: Icon(Icons.search), text: 'Check Status'),
          Tab(icon: Icon(Icons.verified_rounded), text: 'Verify Payment'),
        ],
      ),
    ),
    body: TabBarView(
      children: [
        CheckStatusTab(),
        VerifyPaymentTab(),
      ],
    ),
  ),
)
```

---

## Tab 1 — `CheckStatusTab` (`tabs/check_status_tab.dart`)

### Purpose
Look up payments associated with a Razorpay order ID.

### UI Layout

```
SingleChildScrollView > Column (padding: 20):
  ┌─────────────────────────────────┐
  │  Card (rounded, elevated)       │
  │                                 │
  │  Text: "Check Payment Status"   │
  │                                 │
  │  LabeledTextField               │
  │    Label: "Order ID"            │
  │    Hint: "order_xxxxx"          │
  │    Keyboard: text               │
  │    Validator: required          │
  │                                 │
  │  SizedBox(height: 16)           │
  │                                 │
  │  PrimaryButton                  │
  │    Label: "Check Status"        │
  │                                 │
  └─────────────────────────────────┘

  SizedBox(height: 24)
  ResultBox(response: _response)
```

### State Variables

```dart
final _orderIdController = TextEditingController();
final _formKey = GlobalKey<FormState>();
ApiResponse _response = ApiResponse();
```

### `_checkStatus()` Method

```dart
Future<void> _checkStatus() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _response = ApiResponse.loading());
  try {
    final data = await PaymentApi.checkPaymentStatus(
      _orderIdController.text.trim()
    );
    setState(() => _response = ApiResponse.success(data));
  } catch (e) {
    setState(() => _response = ApiResponse.error(e.toString()));
  }
}
```

---

## Tab 2 — `VerifyPaymentTab` (`tabs/verify_payment_tab.dart`)

### Purpose
Verify the authenticity of a completed Razorpay payment using three IDs.

### UI Layout

```
SingleChildScrollView > Column (padding: 20):
  ┌─────────────────────────────────┐
  │  Card (rounded, elevated)       │
  │                                 │
  │  Text: "Verify Payment"         │
  │                                 │
  │  LabeledTextField               │
  │    Label: "Razorpay Order ID"   │
  │    Hint: "order_xxxxx"          │
  │                                 │
  │  LabeledTextField               │
  │    Label: "Razorpay Payment ID" │
  │    Hint: "pay_xxxxx"            │
  │                                 │
  │  LabeledTextField               │
  │    Label: "Razorpay Signature"  │
  │    Hint: "Paste signature here" │
  │    maxLines: 3                  │
  │                                 │
  │  Row:                           │
  │    PrimaryButton "Verify"       │
  │    OutlinedButton "Clear"       │
  │                                 │
  └─────────────────────────────────┘

  SizedBox(height: 24)
  ResultBox(response: _response)
```

### `_verifyPayment()` Method

```dart
Future<void> _verifyPayment() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _response = ApiResponse.loading());
  try {
    final data = await PaymentApi.verifyPayment(
      orderId: _orderIdController.text.trim(),
      paymentId: _paymentIdController.text.trim(),
      signature: _signatureController.text.trim(),
    );
    setState(() => _response = ApiResponse.success(data));
  } catch (e) {
    setState(() => _response = ApiResponse.error(e.toString()));
  }
}
```

### `_clearForm()` Method
Clears all three text controllers and resets `_response` to `ApiResponse()`.

### ResultBox Border Colour Logic
- If `response.data?['success'] == true` → green border (`Colors.green.shade400`)
- If `response.data?['success'] == false` OR `response.error != null` → red border (`Colors.red.shade400`)
- Otherwise → neutral grey border

---

## Shared Widget 1 — `ResultBox` (`widgets/result_box.dart`)

### Props

```dart
class ResultBox extends StatelessWidget {
  final ApiResponse response;
  const ResultBox({required this.response, super.key});
}
```

### Rendering Logic

| State | Display |
|-------|---------|
| `isLoading == true` | Animated shimmer/loading indicator (use `LinearProgressIndicator` at top + pulsing grey container) |
| `error != null` | Red-bordered container, red icon + error message at top, raw error text below |
| `data != null` | Styled container with JSON text + Copy button |
| Empty (default) | Muted grey container: `"Response will appear here..."` in italic |

### JSON Display

```dart
// Inside ResultBox when data is present:
Container(
  width: double.infinity,
  constraints: BoxConstraints(maxHeight: 400),
  decoration: BoxDecoration(
    color: Color(0xFF1E1E1E),         // Dark background for JSON
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _borderColor),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header row: "Response" label + Copy button
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Response', style: TextStyle(color: Colors.white70, fontSize: 12)),
            IconButton(
              icon: Icon(Icons.copy, color: Colors.white70, size: 18),
              onPressed: () => _copyToClipboard(context),
            ),
          ],
        ),
      ),
      Divider(color: Colors.white12, height: 1),
      // Scrollable JSON body
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SelectableText(
            _prettyJson,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.greenAccent.shade100,
            ),
          ),
        ),
      ),
    ],
  ),
)
```

Use `JsonEncoder.withIndent('  ')` from `dart:convert` to pretty-print the JSON.

---

## Shared Widget 2 — `PrimaryButton` (`widgets/primary_button.dart`)

```dart
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  // When isLoading is true:
  // - Disable onPressed
  // - Replace label with SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
  // Full-width ElevatedButton with rounded corners (borderRadius: 12)
}
```

---

## Shared Widget 3 — `LabeledTextField` (`widgets/labeled_text_field.dart`)

```dart
class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
}
```

Renders a `Column` with a bold label `Text` above an `OutlineInputBorder` `TextFormField`.

---

## Android Configuration

In `android/app/src/main/AndroidManifest.xml`, ensure internet permission is present:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## iOS Configuration

In `ios/Runner/Info.plist`, no special config needed for HTTPS calls. Ensure `NSAppTransportSecurity` is not blocking the API domain.

---

## Validation Rules Summary

| Field | Rule |
|-------|------|
| Amount | Required, must be a number, must be > 0 |
| Order ID | Required, must not be empty, trim whitespace |
| Payment ID | Required, must not be empty, trim whitespace |
| Signature | Required, must not be empty |

---

## UX Details

- `TextEditingController`s must be disposed in `dispose()` to prevent memory leaks
- Use `Form` + `GlobalKey<FormState>` for all forms
- After successful order creation, show a `SnackBar`: `"Order created! ID copied to clipboard."`
- After successful payment verification, show a `SnackBar` with a green background: `"Payment verified successfully!"`
- After failed verification, show a `SnackBar` with a red background: `"Verification failed. Check your inputs."`
- All screens should be scrollable so they work on small screens and when the keyboard is open (use `SingleChildScrollView`)
- Use `resizeToAvoidBottomInset: true` on all Scaffolds

---

## Out of Scope (Do NOT implement)

- Razorpay Flutter SDK / checkout popup
- `/razorpay-webhook` endpoint (server-side only)
- User authentication or login screens
- Local database or persistence
- Push notifications
- Any payment processing logic — the app only calls the 3 REST endpoints

---

## Deliverables

Kiro should generate the following files:

```
pubspec.yaml
lib/
├── main.dart
├── api/
│   └── payment_api.dart
├── models/
│   └── api_response.dart
├── screens/
│   ├── home_screen.dart
│   └── orders_screen.dart
├── tabs/
│   ├── check_status_tab.dart
│   └── verify_payment_tab.dart
└── widgets/
    ├── result_box.dart
    ├── primary_button.dart
    └── labeled_text_field.dart
```

---

## Quick-Start Commands

```bash
flutter pub get
flutter run                   # Run on connected device/emulator
flutter build apk --release   # Android release build
flutter build ios --release   # iOS release build
```
