# Nourisha Flutter — My Orders, Order Tracking, Delivery Partner Screens

You are a Flutter developer working on an existing project called **Nourisha**.
You have been given the full source code. Read every file path carefully before writing code.

---

## PROJECT STRUCTURE (actual paths)

```
lib/
├── amplifyconfiguration.dart
├── main.dart
├── main_scaffold.dart
├── api/
│   └── payment_api.dart          ← add new methods here
├── models/
│   ├── cart.dart                 (Cart, CartItem)
│   ├── delivery_location.dart    (latitude, longitude, fullAddress, city, pincode, isServiceable)
│   ├── menu_item.dart            (MenuItem, MenuData)
│   ├── order_detail.dart         (OrderDetail — Hive model, typeId:0)
│   └── order_detail.g.dart
├── features/payment/
│   ├── services/
│   │   ├── local_notification_service.dart   ← singleton, showPaymentSuccessNotification(orderId, amount)
│   │   ├── local_storage_service.dart
│   │   └── subscription_service.dart         ← mirror this pattern exactly
│   └── widgets/
│       └── status_badge.dart
├── screens/
│   ├── cart_screen.dart          ← update _placeOrder() only
│   ├── location_screen.dart
│   ├── menu_screen.dart          ← add receipt icon + long press
│   ├── order_lookup_screen.dart
│   └── payment_screen.dart
├── services/
│   └── location_service.dart     ← getSavedLocation()→DeliveryLocation?, saveLocation(), clearLocation()
└── widgets/
    ├── glassy_card.dart
    ├── info_row.dart
    ├── primary_button.dart
    └── status_badge.dart
```

---

## EXISTING CODE FACTS (read these carefully)

**PaymentApi** (`lib/api/payment_api.dart`):
- `static const String baseUrl = 'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan'`
- `static const Duration timeout = Duration(seconds: 15)`
- Existing: `createOrder(double amount)`, `verifyPayment(...)`, `checkPaymentStatus(String)`, `getOrder(String)`
- All methods use `http.post/get` with `{'Content-Type': 'application/json'}` headers
- Error handling pattern: catch TimeoutException, SocketException, then rethrow

**SubscriptionService** (`lib/features/payment/services/subscription_service.dart`):
- Has `StreamController<Map<String,dynamic>>.broadcast()` named `_updateController`
- Public stream: `Stream<Map<String,dynamic>> get orderUpdates => _updateController.stream`
- `subscribeToOrder(String orderId)` — retries 3x with 5s delay
- `_handleSubscriptionUpdate` — parses `event.data`, decodes JSON, extracts `['onOrderUpdated']`
- Pushes to `_updateController.add(map)` after parsing
- Debug logs format: `'🔔 RAW subscription event received for $orderId'`

**LocalNotificationService** (`lib/features/payment/services/local_notification_service.dart`):
- Singleton: `factory LocalNotificationService() => _instance`
- `showPaymentSuccessNotification({required String orderId, required int amount})`
- Channel id: `'payment_updates'`

**OrderDetail** (`lib/models/order_detail.dart`):
- Fields: orderId, razorpayOrderId, amount(int paise), currency, status, paymentId, signature,
  createdAt(int unix), updatedAt(int unix), isSynced, customerName, customerEmail, customerPhone
- `formattedAmount` getter: `'₹${(amount / 100).toStringAsFixed(2)}'`
- `needsAction` getter: status != 'paid' && != 'captured' && != 'verified'
- `formattedCreatedAt` getter: `'DD/MM/YYYY HH:MM'`

**DeliveryLocation** (`lib/models/delivery_location.dart`):
- Fields: `latitude`, `longitude`, `fullAddress`, `city`, `pincode`, `isServiceable`
- `toJson()` / `fromJson()` available

**CartScreen** (`lib/screens/cart_screen.dart`):
- `_placeOrder()` currently calls `PaymentApi.createOrder(widget.cart.grandTotal)`
- Has `widget.location` (DeliveryLocation) available
- Razorpay key: `'rzp_test_SHXH1wQoOlA037'`
- `_deliveryFee = 40.0`, `_platformFee = 5.0`

**MenuScreen** (`lib/screens/menu_screen.dart`):
- SliverAppBar with orange gradient, `'🍽️ Nourisha'` title
- Location shown in top row with 'Change' TextButton
- No actions currently in AppBar

**AppSync** (`lib/amplifyconfiguration.dart`):
- Endpoint: `https://m36lkdm42jbwrouj6clu67pi2m.appsync-api.ap-south-1.amazonaws.com/graphql`
- Auth: `API_KEY`
- API name in config: `nourisha-orders-api`

**pubspec.yaml packages available**:
```yaml
razorpay_flutter: ^1.3.7
shared_preferences: ^2.2.2
http: ^1.1.0
flutter_animate: ^4.5.0
hive: ^2.2.3
hive_flutter: ^1.1.0
flutter_local_notifications: ^17.0.0
amplify_api: ^2.0.0
amplify_flutter: ^2.0.0
geolocator: ^13.0.0
geocoding: ^3.0.0
```
**NOTE: google_maps_flutter is NOT in pubspec.yaml.**
Use a custom painter or simple coordinate display instead of Google Maps.
Do NOT add google_maps_flutter to the code — it will break the build.

---

## BACKEND ENDPOINTS (already deployed)

Base URL: `https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan`

```
GET  /get-my-orders?device_id={device_id}&limit=20
  Response: {
    success: bool,
    orders: [{
      order_id, amount, currency, status,
      delivery_status, delivery_lat, delivery_lng,
      partner_id, payment_id, created_at, updated_at,
      delivery_updated_at, customer_details
    }]
  }

POST /update-delivery-location
  Body: { order_id, partner_id, lat, lng }
  Response: { success, order_id, delivery_status, is_nearby, lat, lng }
  Note: Lambda auto-sets delivery_status="nearby" if within 500m of customer

POST /update-order-status
  Body: { order_id, partner_id, delivery_status }
  delivery_status values: confirmed / preparing / picked_up / nearby / delivered
  Response: { success, order_id, delivery_status }

POST /create-order  (UPDATED — now accepts extra fields)
  Body: {
    amount: double,
    device_id: string,
    delivery_lat_customer: double,
    delivery_lng_customer: double,
    delivery_address: string
  }
  Response: { success, orderId, amount, currency }
```

**AppSync new subscription**:
```graphql
subscription OnDeliveryUpdated($order_id: String) {
  onDeliveryUpdated(order_id: $order_id) {
    key
    order_id
    delivery_lat
    delivery_lng
    delivery_status
    partner_id
    updated_at
  }
}
```

---

## DESIGN SYSTEM

```dart
// Colors
const Color kOrange      = Color(0xFFFF6B35);
const Color kOrangeLight = Color(0xFFFFF5F0);
const Color kBg          = Color(0xFFF1F5F9);
const Color kCard        = Colors.white;
const Color kTextDark    = Color(0xFF0F172A);
const Color kTextMuted   = Color(0xFF64748B);
const Color kBorder      = Color(0xFFE2E8F0);

// Card decoration
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 8, offset: Offset(0, 2),
  )],
)

// Orange button style
ElevatedButton.styleFrom(
  backgroundColor: Color(0xFFFF6B35),
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  elevation: 0,
)
```

Rules:
- No state management packages — StatefulWidget + setState only
- No separate widget files — all private widgets (`_WidgetName`) in same file as screen
- No google_maps_flutter — NOT in pubspec
- const constructors everywhere possible
- Handle loading / error / empty states explicitly

---

## TASK: CREATE 5 NEW FILES + MODIFY 3 EXISTING FILES

---

### NEW FILE 1: `lib/services/device_service.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _key = 'nourisha_device_id';

  /// Returns a stable device ID. Generates a UUID-like string on first call,
  /// then returns the same value forever from SharedPreferences.
  /// Do NOT use the uuid package — generate manually:
  ///   final id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${(math.Random().nextInt(999999)).toString().padLeft(6,'0')}';
  static Future<String> getDeviceId() async { ... }
}
```

---

### NEW FILE 2: `lib/services/delivery_subscription_service.dart`

Mirror `lib/features/payment/services/subscription_service.dart` EXACTLY for structure.

Key differences from SubscriptionService:
- NO dependency on LocalStorageService or LocalNotificationService
- Constructor: `DeliverySubscriptionService()` — no required params
- GraphQL document extracts `['onDeliveryUpdated']` instead of `['onOrderUpdated']`
- Stream name: `deliveryUpdates` (not `orderUpdates`)
- StreamController field: `_deliveryController`
- No Hive storage — just parse and push to stream
- No auto-cancel on final status

GraphQL subscription document (copy exactly):
```graphql
subscription OnDeliveryUpdated($order_id: String) {
  onDeliveryUpdated(order_id: $order_id) {
    key
    order_id
    delivery_lat
    delivery_lng
    delivery_status
    partner_id
    updated_at
  }
}
```

Debug logs:
```dart
print('🚴 RAW delivery event received for $orderId');
print('   hasErrors: ${event.hasErrors}');
print('   data: ${event.data}');
print('🚴 Delivery update: status=${map['delivery_status']}, lat=${map['delivery_lat']}, lng=${map['delivery_lng']}');
```

Methods (same signatures as SubscriptionService):
- `Future<void> subscribeToDelivery(String orderId)` — 3 attempts, 5s retry
- `Future<void> cancelSubscription(String orderId)`
- `Future<void> cancelAllSubscriptions()`
- `void dispose()`

---

### NEW FILE 3: `lib/screens/my_orders_screen.dart`

StatefulWidget. No constructor params needed.

**State fields:**
```dart
List<Map<String, dynamic>> _orders = [];
bool _isLoading = false;
String? _errorMessage;
String? _deviceId;
late Razorpay _razorpay;
String? _retryOrderId;  // tracks which order is being retried
```

**initState:**
1. Init Razorpay, register all 3 event handlers
2. `DeviceService.getDeviceId()` → save to `_deviceId`
3. `_fetchOrders()`

**dispose:** `_razorpay.clear()`

**_fetchOrders():**
```
GET /get-my-orders?device_id={_deviceId}&limit=20
setState _orders = response['orders'] as List
Sort by created_at descending (newest first)
```

**_retryPayment(Map order):**
1. Call `PaymentApi.createOrderWithDetails(...)` — new method you add to payment_api.dart
2. Open Razorpay with returned orderId
3. On success: call `PaymentApi.verifyPayment(...)` then `_fetchOrders()`

**Razorpay handlers:**
- `_handlePaymentSuccess` → verifyPayment → _fetchOrders
- `_handlePaymentError` → show snackbar with error
- `_handleExternalWallet` → show snackbar

**UI:**

AppBar:
```dart
AppBar(
  backgroundColor: Color(0xFFFF6B35),
  foregroundColor: Colors.white,
  title: Text('My Orders', style: TextStyle(fontWeight: FontWeight.w800)),
  actions: [
    IconButton(icon: Icon(Icons.refresh), onPressed: _fetchOrders)
  ],
)
```

Body states:
- Loading: `Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))`
- Error: centered Column with error text + orange 'Retry' button
- Empty: centered Column with '📦' (fontSize 64) + 'No orders yet' + 'Start Ordering' button (pops screen)
- List: `ListView.builder` with `_OrderCard` widgets, padding `EdgeInsets.all(16)`, bottom padding 80

**`_OrderCard` private widget:**

Constructor: `({required Map<String,dynamic> order, required VoidCallback onTrack, required VoidCallback onRetry})`

Layout: white card, 16px radius, 12px bottom margin, 16px padding

```
Row 1: [order_id monospace grey 12px, maxWidth 180, ellipsis] --- [_PaymentBadge] [4px] [_DeliveryBadge]
Row 2 (8px top): [₹{amount} bold 16px dark] --- [created_at formatted 'DD MMM YYYY' 12px grey]
Row 3 (12px top): action area
```

Action area logic (in order of priority):
1. If `delivery_status == 'delivered'`:
   → green Container 'Delivered ✓', no button
   → padding: h16 v8, border radius 8, green[50] bg, green border, green[700] text bold

2. Else if `status` in ['paid','captured','verified'] AND `delivery_status` NOT in ['delivered']:
   → full-width orange ElevatedButton 'Track Order 🚴'
   → onTap: onTrack()

3. Else if `status` in ['created','failed'] OR `status == null`:
   → full-width orange ElevatedButton 'Pay Now'
   → onTap: onRetry()

4. Else (paid but delivery_status is null or 'confirmed'):
   → grey text 'Preparing your order...' centered, 13px

Amount display: orders from backend have `amount` in rupees (not paise).
Display as: `'₹${(order['amount'] ?? 0).toInt()}'`

Date formatting helper (private method in screen file):
```dart
String _formatDate(dynamic value) {
  if (value == null) return '';
  try {
    final dt = DateTime.parse(value.toString());
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month-1]} ${dt.year}';
  } catch (_) { return value.toString(); }
}
```

**`_PaymentBadge` private widget:**
Input: `String? status`
```
paid/captured/verified → green bg/border/text, '✓ Paid'
failed                 → red,   'Failed'
created                → orange, 'Pending'
other/null             → grey,   status ?? 'Unknown'
```
Style: 6px h-padding, 3px v-padding, 4px border radius, 11px font, FontWeight.w700
bg = color[50], border = color, text = color[700]

**`_DeliveryBadge` private widget:**
Input: `String? status`
```
confirmed  → grey    'Confirmed'
preparing  → blue    'Preparing 👨‍🍳'
picked_up  → purple  'On the way 🛵'
nearby     → orange  'Nearby 📍'
delivered  → green   'Delivered ✓'
null/''    → SizedBox.shrink()
```
Same style as _PaymentBadge.

---

### NEW FILE 4: `lib/screens/order_tracking_screen.dart`

StatefulWidget. Constructor: `({required Map<String,dynamic> order})`

**NOTE: No Google Maps. Use a custom visual instead.**

**State fields:**
```dart
late DeliverySubscriptionService _deliverySubscription;
StreamSubscription<Map<String,dynamic>>? _streamSub;
double? _deliveryLat;
double? _deliveryLng;
String _deliveryStatus = 'confirmed';
String? _partnerId;
bool _isSubscribed = false;
double? _customerLat;
double? _customerLng;
```

**initState:**
1. Parse `_deliveryStatus` from `widget.order['delivery_status'] ?? 'confirmed'`
2. Parse existing `_deliveryLat/Lng` from `widget.order['delivery_lat/lng']`
3. Load customer coords: `LocationService().getSavedLocation()` → save lat/lng
4. Create `DeliverySubscriptionService()`
5. Listen to `_deliverySubscription.deliveryUpdates`:
   ```dart
   _streamSub = _deliverySubscription.deliveryUpdates.listen((update) {
     if (!mounted) return;
     setState(() {
       _deliveryStatus = update['delivery_status'] ?? _deliveryStatus;
       if (update['delivery_lat'] != null)
         _deliveryLat = (update['delivery_lat'] as num).toDouble();
       if (update['delivery_lng'] != null)
         _deliveryLng = (update['delivery_lng'] as num).toDouble();
       _partnerId = update['partner_id'];
     });
     // Show notification if nearby or delivered
     if (update['delivery_status'] == 'nearby') {
       LocalNotificationService().showDeliveryNotification(
         title: 'Delivery Partner Nearby! 📍',
         body: 'Your order is almost there!',
         orderId: widget.order['order_id'],
       );
     }
     if (update['delivery_status'] == 'delivered') {
       LocalNotificationService().showDeliveryNotification(
         title: 'Order Delivered! 🎉',
         body: 'Enjoy your meal!',
         orderId: widget.order['order_id'],
       );
       _deliverySubscription.cancelAllSubscriptions();
     }
   });
   ```
6. `_deliverySubscription.subscribeToDelivery(widget.order['order_id'])`
7. `setState(() => _isSubscribed = true)`

Note: `LocalNotificationService` does not have `showDeliveryNotification` yet.
Add this method to the existing LocalNotificationService:
```dart
Future<void> showDeliveryNotification({
  required String title,
  required String body,
  required String orderId,
}) async {
  // same pattern as showPaymentSuccessNotification
  // channel: 'payment_updates' (already exists)
  // always show regardless of _isAppInForeground
  // notification id: orderId.hashCode + 1000
}
```

**dispose:**
```dart
_streamSub?.cancel();
_deliverySubscription.dispose();
```

**UI Structure:**

```
Scaffold(backgroundColor: Color(0xFFF1F5F9))
  AppBar:
    backgroundColor: Color(0xFF0F172A)
    white title: 'Track Order'
    subtitle: order_id (monospace, 11px, grey[400])
    leading: back arrow white

  Body: SingleChildScrollView, padding 16
    Column children:

    1. _DeliveryMap widget (custom, no google maps)
    2. SizedBox(height: 16)
    3. _StatusStepper widget
    4. SizedBox(height: 16)  
    5. _StatusCard widget
    6. SizedBox(height: 16)
    7. if delivered: _BackToMenuButton
```

**`_DeliveryMap` private widget** (replaces Google Maps):
White card, 16px radius, height 200px
Content: Stack
  - Background: Container with gradient
    LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)])
  - Center content:
    if _deliveryLat != null:
      Column(mainAxisAlignment: center):
        Text('🛵', fontSize: 48)
        SizedBox(8)
        Text('Delivery Partner', color: white, bold)
        Text('${_deliveryLat!.toStringAsFixed(4)}, ${_deliveryLng!.toStringAsFixed(4)}',
             color: grey[400], 11px, monospace)
        SizedBox(4)
        if _customerLat != null: calculate and show distance:
          Text('~${_calcDistanceKm()} km from you', color: orange, 13px)
    else:
      Column(mainAxisAlignment: center):
        Text('📍', fontSize: 48)
        SizedBox(8)
        Text('Waiting for partner location...', color: grey[400], 13px)
  - Positioned(top:12, right:12):
      _LiveDot() widget (pulsing green dot, only if _deliveryLat != null)

Distance calculation helper:
```dart
String _calcDistanceKm() {
  if (_deliveryLat == null || _customerLat == null) return '?';
  // simple Euclidean approximation good enough for display
  final dlat = (_deliveryLat! - _customerLat!).abs() * 111;
  final dlng = (_deliveryLng! - _customerLng!).abs() * 111;
  final d = math.sqrt(dlat*dlat + dlng*dlng);
  return d < 1 ? '${(d*1000).toInt()}m' : '${d.toStringAsFixed(1)}km';
}
```
Add `import 'dart:math' as math;`

**`_LiveDot` private widget:**
AnimatedContainer pulsing between 10x10 and 8x8, duration 800ms, curve easeInOut
Use StatefulWidget with Timer that toggles size.
Green circle, no border.

**`_StatusStepper` private widget:**
Input: `String currentStatus`

5 steps in order: `['confirmed', 'preparing', 'picked_up', 'nearby', 'delivered']`

Step index of currentStatus = steps.indexOf(currentStatus), default 0

Layout: Row, steps connected by Expanded(Container(height:2))

Each step:
```
Column:
  Stack(alignment: center):
    // Connecting line is in parent Row
    Container(32x32, shape circle):
      if stepIndex < currentIndex → green, Icon(check, white, 16)
      if stepIndex == currentIndex → orange, step icon white 16
      if stepIndex > currentIndex → grey[200], step icon grey[400] 16
  SizedBox(4)
  Text(stepLabel, 10px, center, 2 lines max)
    color: stepIndex <= currentIndex ? kTextDark : grey[400]
    fontWeight: stepIndex == currentIndex ? w700 : w500
```

Step icons:
```dart
const stepIcons = [
  Icons.check_circle_outline,  // confirmed
  Icons.restaurant,             // preparing
  Icons.delivery_dining,        // picked_up
  Icons.location_on,            // nearby
  Icons.home,                   // delivered
];
const stepLabels = ['Confirmed', 'Preparing', 'Picked Up', 'Nearby', 'Delivered'];
```

**`_StatusCard` private widget:**
Input: `String status, String? partnerId`

White card, 16px radius, 16px padding

Content:
```
Row:
  _statusEmoji (48px text)   SizedBox(16)   Column:
                                              Text(statusTitle, 16px bold dark)
                                              SizedBox(4)
                                              Text(statusSubtitle, 13px grey)
                                              if partnerId != null:
                                                SizedBox(4)
                                                Text('Partner: $partnerId', 11px grey[400])
```

Status text map:
```dart
const statusData = {
  'confirmed': ('🎉', 'Order Confirmed!', 'Getting ready to prepare your food'),
  'preparing': ('👨‍🍳', 'Being Prepared', 'Chef is working on your order'),
  'picked_up': ('🛵', 'On the Way!', 'Delivery partner has picked up your order'),
  'nearby':    ('📍', 'Almost There!', 'Delivery partner is nearby'),
  'delivered': ('🏠', 'Delivered!', 'Enjoy your meal 🎉'),
};
```

Below the row, if `_isSubscribed`:
```dart
Padding(
  padding: EdgeInsets.only(top: 12),
  child: Row(children: [
    _LiveDot(),
    SizedBox(8),
    Text('Live tracking active', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
  ]),
)
```

**`_BackToMenuButton` private widget:**
Full-width orange button 'Back to Menu'
onTap: `Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => MenuScreen(location: savedLocation!)),
  (route) => false,
)`
(needs to load savedLocation first — do it in the button tap handler)

---

### NEW FILE 5: `lib/screens/delivery_partner_screen.dart`

StatefulWidget. No constructor params.

**State fields:**
```dart
final _partnerIdController = TextEditingController(text: 'partner_001');
final _orderIdController   = TextEditingController();
String _partnerId          = 'partner_001';
String? _activeOrderId;
double? _currentLat;
double? _currentLng;
bool   _isTrackingGPS      = false;
String _currentStatus      = 'confirmed';
bool   _isUpdating         = false;
String? _statusMessage;
Timer?  _gpsTimer;
StreamSubscription<Position>? _locationSub;
```

**initState:** just super.initState()

**dispose:**
```dart
_gpsTimer?.cancel();
_locationSub?.cancel();
_partnerIdController.dispose();
_orderIdController.dispose();
```

**_startDelivery():**
1. Set `_partnerId = _partnerIdController.text.trim()`
2. Set `_activeOrderId = _orderIdController.text.trim()`
3. If either empty: show snackbar 'Enter both Partner ID and Order ID'
4. Call `_updateStatus('preparing')`
5. Call `_startGPSTracking()`

**_startGPSTracking():**
```dart
final permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied || 
    permission == LocationPermission.deniedForever) {
  // show snackbar, return
  return;
}

_locationSub = Geolocator.getPositionStream(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  ),
).listen((position) {
  setState(() {
    _currentLat = position.latitude;
    _currentLng = position.longitude;
  });
  if (_activeOrderId != null) _sendLocationUpdate();
});

// Backup timer every 5 seconds
_gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
  if (_activeOrderId != null && _currentLat != null) {
    _sendLocationUpdate();
  }
});

setState(() => _isTrackingGPS = true);
```

**_stopGPSTracking():**
```dart
_gpsTimer?.cancel();
_locationSub?.cancel();
setState(() {
  _isTrackingGPS = false;
  _gpsTimer = null;
  _locationSub = null;
});
```

**_sendLocationUpdate():**
```dart
await PaymentApi.updateDeliveryLocation(
  orderId:   _activeOrderId!,
  partnerId: _partnerId,
  lat:       _currentLat!,
  lng:       _currentLng!,
);
// if response['is_nearby'] == true → show snackbar 'Customer is nearby! 📍'
```

**_updateStatus(String newStatus):**
```dart
setState(() { _isUpdating = true; });
await PaymentApi.updateOrderStatus(
  orderId:        _activeOrderId!,
  partnerId:      _partnerId,
  deliveryStatus: newStatus,
);
setState(() {
  _currentStatus = newStatus;
  _isUpdating = false;
  _statusMessage = 'Status updated to $newStatus';
});
if (newStatus == 'delivered') _stopGPSTracking();
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Status: $newStatus'), backgroundColor: Color(0xFFFF6B35)),
);
```

**UI:**

AppBar:
```dart
AppBar(
  backgroundColor: Color(0xFF0F172A),
  foregroundColor: Colors.white,
  title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Delivery Partner', style: TextStyle(fontWeight: FontWeight.w800)),
    Text(
      _isTrackingGPS ? '🟢 GPS Active' : '⚫ GPS Off',
      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
    ),
  ]),
)
```

Body: `SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [...]))`

**Section 1 — Setup Card** (always visible):
White card, 16px radius, 16px padding
'Setup' label, FontWeight.w700, 15px, bottom margin 12

TextField for partner ID (`_partnerIdController`)
```dart
TextField(
  controller: _partnerIdController,
  decoration: InputDecoration(
    labelText: 'Partner ID',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    prefixIcon: Icon(Icons.person),
  ),
)
```
SizedBox(12)
TextField for order ID (`_orderIdController`)
```dart
TextField(
  controller: _orderIdController,
  decoration: InputDecoration(
    labelText: 'Order ID to Deliver',
    hintText: 'order_XXXXXXXXXX',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    prefixIcon: Icon(Icons.receipt_long),
  ),
)
```
SizedBox(16)
Full-width orange 'Start Delivery' ElevatedButton → `_startDelivery()`

**Section 2 — GPS Status Card** (only if `_isTrackingGPS`):
SizedBox(16) then white card, 16px radius, 16px padding
```
Row: [_LiveDot()] [SizedBox(8)] [Text('GPS Tracking Active', w700, 14px)]
if _currentLat != null:
  SizedBox(8)
  Text('Lat: ${_currentLat!.toStringAsFixed(6)}', monospace 12px grey)
  Text('Lng: ${_currentLng!.toStringAsFixed(6)}', monospace 12px grey)
SizedBox(12)
OutlinedButton(
  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red)),
  onPressed: _stopGPSTracking,
  child: Text('Stop GPS'),
)
```

**Section 3 — Status Buttons Card** (only if `_activeOrderId != null`):
SizedBox(16) then white card, 16px radius, 16px padding
'Update Status' label

4 buttons, each SizedBox(height:48), full width, 10px border radius, 8px gap between:

```dart
_StatusButton(
  label: 'Preparing 👨‍🍳',
  isActive: _currentStatus == 'preparing',
  activeColor: Colors.blue,
  onTap: () => _updateStatus('preparing'),
  isLoading: _isUpdating,
),
_StatusButton(label: 'Picked Up 🛵', isActive: _currentStatus == 'picked_up',
  activeColor: Colors.purple, onTap: () => _updateStatus('picked_up'), isLoading: _isUpdating),
_StatusButton(label: 'Nearby 📍', isActive: _currentStatus == 'nearby',
  activeColor: Color(0xFFFF6B35), onTap: () => _updateStatus('nearby'), isLoading: _isUpdating),
_StatusButton(label: 'Delivered ✓', isActive: _currentStatus == 'delivered',
  activeColor: Colors.green, onTap: () => _updateStatus('delivered'), isLoading: _isUpdating),
```

`_StatusButton` private widget:
- If `isActive`: ElevatedButton with `activeColor` background, white text
- If not active: OutlinedButton with grey border, grey text
- If `isLoading && isActive`: show CircularProgressIndicator(strokeWidth:2, color:white) instead of text

**Section 4 — Active Order Info Card** (only if `_activeOrderId != null`):
SizedBox(16) then white card, 16px radius, 16px padding
```
Text('Active Delivery', w700, 15px)
SizedBox(8)
SelectableText('$_activeOrderId', style: monospace 12px grey)
SizedBox(4)
Row: [Text('Status: ', grey)][Text(_currentStatus, w700, orange)]
SizedBox(4)
Text('Partner: $_partnerId', grey 13px)
```

---

### MODIFY EXISTING FILE: `lib/api/payment_api.dart`

Add these 4 static methods using the exact same pattern as existing methods:

```dart
/// Creates order with delivery details for tracking
static Future<Map<String, dynamic>> createOrderWithDetails({
  required double amount,
  required String deviceId,
  required double deliveryLat,
  required double deliveryLng,
  required String deliveryAddress,
}) async {
  // POST /create-order
  // Body: { amount, device_id, delivery_lat_customer, delivery_lng_customer, delivery_address }
  // Same error handling pattern as createOrder()
}

/// Fetches all orders for a device
static Future<List<Map<String, dynamic>>> getMyOrders(String deviceId) async {
  // GET /get-my-orders?device_id={deviceId}&limit=20
  // Returns (response['orders'] as List).cast<Map<String,dynamic>>()
}

/// Updates delivery partner location
static Future<Map<String, dynamic>> updateDeliveryLocation({
  required String orderId,
  required String partnerId,
  required double lat,
  required double lng,
}) async {
  // POST /update-delivery-location
  // Body: { order_id, partner_id, lat, lng }
  // Returns full response map (includes is_nearby field)
}

/// Updates order delivery status
static Future<void> updateOrderStatus({
  required String orderId,
  required String partnerId,
  required String deliveryStatus,
}) async {
  // POST /update-order-status
  // Body: { order_id, partner_id, delivery_status }
}
```

---

### MODIFY EXISTING FILE: `lib/screens/cart_screen.dart`

In `_placeOrder()`, change ONE line only:

FIND:
```dart
final orderData = await PaymentApi.createOrder(widget.cart.grandTotal);
```

REPLACE WITH:
```dart
final orderData = await PaymentApi.createOrderWithDetails(
  amount:            widget.cart.grandTotal,
  deviceId:          await DeviceService.getDeviceId(),
  deliveryLat:       widget.location.latitude,
  deliveryLng:       widget.location.longitude,
  deliveryAddress:   widget.location.fullAddress,
);
```

Add import at top:
```dart
import '../services/device_service.dart';
```

Do NOT change any other part of cart_screen.dart.

---

### MODIFY EXISTING FILE: `lib/screens/menu_screen.dart`

**Change 1** — Add receipt icon to SliverAppBar actions:

In the SliverAppBar widget, the current `flexibleSpace` has a `FlexibleSpaceBar` with a `background`.
The SliverAppBar currently has no `actions:` parameter.

Add `actions:` to SliverAppBar:
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.receipt_long, color: Colors.white),
    tooltip: 'My Orders',
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
    ),
  ),
],
```

**Change 2** — Wrap the `'🍽️ Nourisha'` Text with GestureDetector for partner access:

FIND (in FlexibleSpaceBar background):
```dart
const Text(
  '🍽️ Nourisha',
  style: TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  ),
),
```

REPLACE WITH:
```dart
GestureDetector(
  onLongPress: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DeliveryPartnerScreen()),
  ),
  child: const Text(
    '🍽️ Nourisha',
    style: TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w800,
    ),
  ),
),
```

Add imports at top of menu_screen.dart:
```dart
import 'my_orders_screen.dart';
import 'delivery_partner_screen.dart';
```

---

## NAVIGATION FLOW

```
MenuScreen
  ├── (receipt icon tap) → MyOrdersScreen
  │       ├── (Track Order) → OrderTrackingScreen
  │       │       └── (Back to Menu, delivered) → MenuScreen
  │       └── (Pay Now) → Razorpay inline → refresh list
  └── (long press '🍽️ Nourisha') → DeliveryPartnerScreen
```

---

## CONSTRAINTS — READ BEFORE WRITING ANY CODE

1. **NO google_maps_flutter** — not in pubspec.yaml, do not import or use it
2. **NO new pubspec packages** — use only what's listed above
3. **NO separate widget files** — all private widgets in same file as screen
4. **NO state management** — StatefulWidget + setState only
5. **DO NOT modify** subscription_service.dart, local_storage_service.dart, order_detail.dart, order_detail.g.dart
6. **DO NOT change** cart_screen.dart except the ONE line in `_placeOrder()` plus import
7. **DeliverySubscriptionService** must be a COMPLETE copy of SubscriptionService pattern — same retry logic, same stream pattern, same error handling
8. **Import paths** — all screens are in `lib/screens/`, services in `lib/services/`, use relative imports
9. **Amount in My Orders** — backend returns amount in rupees not paise, display as `₹${amount.toInt()}`
10. **LocalNotificationService** is a singleton — call `LocalNotificationService()` directly, add `showDeliveryNotification` method to the existing file
