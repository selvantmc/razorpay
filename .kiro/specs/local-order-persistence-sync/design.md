# Design Document: Local Order Persistence and Sync

## Overview

This design implements a robust local-first architecture for order persistence with real-time synchronization via AppSync GraphQL subscriptions. The system ensures payment status updates from backend webhooks (the source of truth) are reliably delivered to the mobile app, with Hive providing local persistence and offline capability.

### Key Design Principles

1. **Webhook as Source of Truth**: Never trust Razorpay client callbacks for payment confirmation
2. **Local-First Architecture**: All order data persists locally in Hive before any network operations
3. **Real-Time Sync**: AppSync subscriptions provide instant updates when webhooks process payments
4. **Timestamp-Based Conflict Resolution**: Newer data always wins using updatedAt comparison
5. **Resilient Subscription Management**: Automatic resubscription on app restart for pending orders
6. **Graceful Degradation**: Fallback to polling if subscriptions fail or timeout

### Architecture Goals

- Zero data loss: All orders persist locally before any network operation
- Eventual consistency: Subscription updates reconcile local state with backend
- Offline capability: App functions with local data when network unavailable
- Resource efficiency: Subscriptions auto-cancel when orders reach final state
- User experience: Real-time UI updates without manual refresh

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │ Payment      │      │ Status       │                     │
│  │ Screen       │◄─────┤ Badge        │                     │
│  └──────┬───────┘      └──────▲───────┘                     │
│         │                     │                              │
│         │                     │ (reactive updates)           │
│         ▼                     │                              │
│  ┌──────────────────────────────────────┐                   │
│  │      Payment Service                 │                   │
│  │  - Razorpay integration              │                   │
│  │  - Payment flow orchestration        │                   │
│  └──────┬───────────────────────────────┘                   │
│         │                                                    │
│         ├──────────┬──────────────┬──────────────┐          │
│         ▼          ▼              ▼              ▼          │
│  ┌──────────┐ ┌─────────┐ ┌──────────────┐ ┌──────────┐   │
│  │ Local    │ │ Subscrip│ │ Backend API  │ │ Notifica │   │
│  │ Storage  │ │ tion    │ │ Service      │ │ tion     │   │
│  │ Service  │ │ Service │ │              │ │ Service  │   │
│  └────┬─────┘ └────┬────┘ └──────┬───────┘ └──────────┘   │
│       │            │             │                          │
└───────┼────────────┼─────────────┼──────────────────────────┘
        │            │             │
        ▼            ▼             ▼
   ┌────────┐  ┌──────────┐  ┌──────────┐
   │ Hive   │  │ AppSync  │  │ AppSync  │
   │ Local  │  │ GraphQL  │  │ REST     │
   │ DB     │  │ Subscrip │  │ API      │
   └────────┘  └──────────┘  └──────────┘
                     ▲
                     │ (webhook triggers)
                     │
              ┌──────────────┐
              │ Backend      │
              │ Lambda       │
              │ Webhook      │
              └──────────────┘
                     ▲
                     │
              ┌──────────────┐
              │ Razorpay     │
              │ Webhook      │
              └──────────────┘
```

### Data Flow

#### Order Creation Flow

```
1. User initiates payment
   ↓
2. Payment Service creates local order (status: "pending")
   ↓
3. Local Storage Service saves to Hive
   ↓
4. Subscription Service establishes AppSync subscription
   ↓
5. Backend API Service creates Razorpay order
   ↓
6. Razorpay checkout opens
```

#### Payment Completion Flow (Success Path)

```
1. User completes payment in Razorpay
   ↓
2. Razorpay triggers webhook to backend Lambda
   ↓
3. Lambda verifies payment signature
   ↓
4. Lambda publishes update to AppSync (status: "paid")
   ↓
5. Subscription Service receives update
   ↓
6. Timestamp comparison (new > old?)
   ↓
7. Local Storage Service updates Hive
   ↓
8. Status Badge updates reactively
   ↓
9. Notification Service shows "Payment Successful"
   ↓
10. Subscription Service cancels subscription
```

#### Fallback Flow (Subscription Timeout)

```
1. Razorpay callback fires (not trusted)
   ↓
2. Payment Service shows "Verifying..." state
   ↓
3. Wait 20 seconds for subscription update
   ↓
4. Timeout expires (no update received)
   ↓
5. Backend API Service polls getOrderStatus
   ↓
6. Local Storage Service updates with polled status
   ↓
7. UI updates with final status
```

#### App Restart Flow

```
1. App launches
   ↓
2. Local Storage Service opens Hive
   ↓
3. Query all orders with status "pending" or "processing"
   ↓
4. For each pending order:
   ├─ Subscription Service establishes subscription
   └─ Continue listening for updates
   ↓
5. Main UI displays
```

## Components and Interfaces

### 1. Local Storage Service

**File**: `lib/features/payment/services/local_storage_service.dart`

**Responsibilities**:
- Initialize and manage Hive database
- Provide CRUD operations for OrderDetail records
- Query pending orders for resubscription
- Ensure atomic read-compare-write operations

**Public Interface**:

```dart
class LocalStorageService {
  /// Initialize Hive and open orders box
  Future<void> initialize();
  
  /// Save a new order to local storage
  Future<void> saveOrder(OrderDetail order);
  
  /// Update an existing order (with timestamp check)
  Future<bool> updateOrder(OrderDetail order);
  
  /// Get order by orderId
  Future<OrderDetail?> getOrder(String orderId);
  
  /// Get all pending orders (status: pending or processing)
  Future<List<OrderDetail>> getPendingOrders();
  
  /// Get all orders (for history view)
  Future<List<OrderDetail>> getAllOrders();
  
  /// Delete an order (for testing/cleanup)
  Future<void> deleteOrder(String orderId);
  
  /// Close Hive box
  Future<void> close();
}
```

**Key Implementation Details**:

- Uses Hive box named `orders`
- OrderDetail uses orderId as the key
- `updateOrder` performs atomic read-compare-write:
  1. Read current record
  2. Compare updatedAt timestamps
  3. Write only if new timestamp is newer
  4. Return true if updated, false if discarded
- Throws `HiveError` on storage failures
- Logs all operations for debugging

### 2. Subscription Service

**File**: `lib/features/payment/services/subscription_service.dart`

**Responsibilities**:
- Manage AppSync GraphQL subscriptions
- Handle subscription lifecycle (create, cancel, cleanup)
- Parse subscription updates and trigger local storage updates
- Implement retry logic for failed subscriptions
- Maintain map of active subscriptions

**Public Interface**:

```dart
class SubscriptionService {
  /// Subscribe to order updates for a specific orderId
  Future<void> subscribeToOrder(String orderId);
  
  /// Cancel subscription for a specific orderId
  Future<void> cancelSubscription(String orderId);
  
  /// Cancel all active subscriptions
  Future<void> cancelAllSubscriptions();
  
  /// Get count of active subscriptions (for debugging)
  int get activeSubscriptionCount;
  
  /// Dispose and cleanup all resources
  void dispose();
}
```

**Key Implementation Details**:

- Uses `Amplify.API.subscribe()` for GraphQL subscriptions
- Subscription query:
  ```graphql
  subscription OnOrderUpdate($orderId: ID!) {
    onOrderUpdate(orderId: $orderId) {
      orderId
      razorpayOrderId
      amount
      currency
      status
      paymentId
      updatedAt
      isSynced
    }
  }
  ```
- Maintains `Map<String, StreamSubscription>` for active subscriptions
- Before creating new subscription, cancels existing one for same orderId
- On subscription update:
  1. Parse GraphQL response to OrderDetail
  2. Call LocalStorageService.updateOrder (handles timestamp check)
  3. If status is "paid" or "failed", auto-cancel subscription
- Retry logic: 3 attempts with 5-second delay between attempts
- Logs all subscription events (created, updated, error, cancelled)

### 3. Local Notification Service

**File**: `lib/features/payment/services/local_notification_service.dart`

**Responsibilities**:
- Show local notifications for payment status changes
- Handle notification tap navigation
- Check if app is in foreground to avoid duplicate notifications

**Public Interface**:

```dart
class LocalNotificationService {
  /// Initialize notification plugin and request permissions
  Future<void> initialize();
  
  /// Show notification for payment success
  Future<void> showPaymentSuccessNotification({
    required String orderId,
    required int amount,
  });
  
  /// Show notification for payment failure
  Future<void> showPaymentFailureNotification({
    required String orderId,
    required int amount,
  });
  
  /// Check if app is currently in foreground
  bool get isAppInForeground;
}
```

**Key Implementation Details**:

- Uses `flutter_local_notifications` package
- Notification channels:
  - Channel ID: `payment_updates`
  - Channel name: `Payment Updates`
  - Importance: High
- Notification tap action: Navigate to order details screen
- Only shows notification if app is in background
- Formats amount with ₹ symbol and 2 decimal places

### 4. Status Badge Widget

**File**: `lib/features/payment/widgets/status_badge.dart`

**Responsibilities**:
- Display current order status with color coding
- Reactively update when local storage changes
- Provide consistent status visualization across app

**Public Interface**:

```dart
class StatusBadge extends StatelessWidget {
  final String orderId;
  final double? fontSize;
  final EdgeInsets? padding;
  
  const StatusBadge({
    required this.orderId,
    this.fontSize,
    this.padding,
    super.key,
  });
}
```

**Key Implementation Details**:

- Uses `StreamBuilder` or `ValueListenableBuilder` to watch Hive box
- Queries LocalStorageService.getOrder(orderId) on each rebuild
- Status color mapping:
  - `pending`: Grey (#9E9E9E)
  - `processing`: Blue (#2196F3)
  - `paid`: Green (#4CAF50)
  - `failed`: Red (#F44336)
- Displays status text in uppercase
- Rounded corners with 4px radius
- 8px horizontal padding, 4px vertical padding

### 5. Enhanced Payment Service

**File**: `lib/features/payment/services/payment_service.dart` (existing, enhanced)

**New Dependencies**:
- LocalStorageService
- SubscriptionService
- LocalNotificationService

**Enhanced Methods**:

```dart
// Modified openCheckout method
Future<PaymentResult> openCheckout({
  required int amount,
  String? reference,
  void Function(String)? onStatus,
}) async {
  // 1. Create local order with status "pending"
  final order = OrderDetail(
    orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
    amount: amount,
    status: 'pending',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  
  // 2. Save to local storage
  await _localStorageService.saveOrder(order);
  
  // 3. Establish subscription
  await _subscriptionService.subscribeToOrder(order.orderId);
  
  // 4. Create backend order and open Razorpay
  // ... existing logic ...
  
  // 5. Wait for callback with 20-second timeout
  // 6. If timeout, poll getOrderStatus
  // ... enhanced logic ...
}
```

**Timeout and Fallback Logic**:

```dart
// After Razorpay callback fires
try {
  // Wait up to 20 seconds for subscription update
  await Future.delayed(Duration(seconds: 20));
  
  // Check if order was updated via subscription
  final currentOrder = await _localStorageService.getOrder(orderId);
  
  if (currentOrder?.status == 'pending' || currentOrder?.status == 'processing') {
    // Subscription didn't update, fallback to polling
    onStatus?.call('Verifying payment status...');
    
    final statusResponse = await _backendApi.getOrderStatus(orderId: orderId);
    
    // Update local storage with polled status
    final updatedOrder = currentOrder!.copyWith(
      status: statusResponse.status,
      paymentId: statusResponse.paymentId,
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    
    await _localStorageService.updateOrder(updatedOrder);
  }
} catch (e) {
  // Handle polling failure
  onStatus?.call('Unable to verify payment. Please check status manually.');
}
```

### 6. Enhanced Backend API Service

**File**: `lib/features/payment/services/backend_api_service.dart` (existing, enhanced)

**New Method**:

```dart
/// Get order status from backend
///
/// AWS Lambda endpoint: /selvan/get-order-status
///
/// The backend will:
/// 1. Receive orderId from client
/// 2. Query DynamoDB or Razorpay API for current status
/// 3. Return OrderDetail with current status and updatedAt
Future<OrderDetail> getOrderStatus({required String orderId}) async {
  if (useMockMode) {
    await Future.delayed(const Duration(milliseconds: 400));
    return OrderDetail(
      orderId: orderId,
      amount: 10000,
      status: 'paid',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/selvan/get-order-status?orderId=$orderId'),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timed out'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrderDetail.fromJson(data);
    } else {
      throw Exception('Failed to get order status: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Get order status failed: $e');
  }
}
```

### 7. Enhanced OrderDetail Model

**File**: `lib/models/order_detail.dart` (existing, enhanced)

**New Fields**:

```dart
class OrderDetail {
  final String orderId;
  final String? razorpayOrderId;  // NEW: Razorpay's order_id
  final int amount;
  final String currency;          // NEW: Currency code
  final String status;
  final String? paymentId;
  final String? signature;
  final int createdAt;
  final int updatedAt;            // CHANGED: Now required (not nullable)
  final bool isSynced;            // NEW: Sync status flag
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  
  // ... existing methods ...
  
  // NEW: Copy with method for updates
  OrderDetail copyWith({
    String? orderId,
    String? razorpayOrderId,
    int? amount,
    String? currency,
    String? status,
    String? paymentId,
    String? signature,
    int? createdAt,
    int? updatedAt,
    bool? isSynced,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  });
}
```

**Hive Annotations**:

```dart
import 'package:hive/hive.dart';

part 'order_detail.g.dart';

@HiveType(typeId: 0)
class OrderDetail {
  @HiveField(0)
  final String orderId;
  
  @HiveField(1)
  final String? razorpayOrderId;
  
  @HiveField(2)
  final int amount;
  
  @HiveField(3)
  final String currency;
  
  @HiveField(4)
  final String status;
  
  @HiveField(5)
  final String? paymentId;
  
  @HiveField(6)
  final String? signature;
  
  @HiveField(7)
  final int createdAt;
  
  @HiveField(8)
  final int updatedAt;
  
  @HiveField(9)
  final bool isSynced;
  
  @HiveField(10)
  final String? customerName;
  
  @HiveField(11)
  final String? customerEmail;
  
  @HiveField(12)
  final String? customerPhone;
  
  // ... constructor and methods ...
}
```

## Data Models

### OrderDetail (Enhanced)

```dart
@HiveType(typeId: 0)
class OrderDetail {
  @HiveField(0)
  final String orderId;           // Unique order identifier
  
  @HiveField(1)
  final String? razorpayOrderId;  // Razorpay's order_id (from backend)
  
  @HiveField(2)
  final int amount;               // Amount in paise (100 paise = 1 rupee)
  
  @HiveField(3)
  final String currency;          // Currency code (e.g., "INR")
  
  @HiveField(4)
  final String status;            // Order status: pending, processing, paid, failed
  
  @HiveField(5)
  final String? paymentId;        // Razorpay payment_id (after payment)
  
  @HiveField(6)
  final String? signature;        // Razorpay signature (for verification)
  
  @HiveField(7)
  final int createdAt;            // Unix timestamp (seconds)
  
  @HiveField(8)
  final int updatedAt;            // Unix timestamp (seconds) - for conflict resolution
  
  @HiveField(9)
  final bool isSynced;            // True if synced with backend
  
  @HiveField(10)
  final String? customerName;     // Optional customer information
  
  @HiveField(11)
  final String? customerEmail;
  
  @HiveField(12)
  final String? customerPhone;
}
```

**Status Values**:
- `pending`: Order created, payment not initiated
- `processing`: Payment initiated, awaiting webhook confirmation
- `paid`: Payment successful (confirmed by webhook)
- `failed`: Payment failed (confirmed by webhook or Razorpay)

**Timestamp Semantics**:
- `createdAt`: Set once when order is created locally
- `updatedAt`: Updated every time order status changes
- Both stored as Unix timestamps in seconds (not milliseconds)
- Used for conflict resolution: newer updatedAt always wins

### Subscription Update Payload

```dart
class SubscriptionUpdate {
  final String orderId;
  final String? razorpayOrderId;
  final int amount;
  final String currency;
  final String status;
  final String? paymentId;
  final int updatedAt;
  final bool isSynced;
  
  factory SubscriptionUpdate.fromGraphQL(Map<String, dynamic> data) {
    return SubscriptionUpdate(
      orderId: data['orderId'] as String,
      razorpayOrderId: data['razorpayOrderId'] as String?,
      amount: data['amount'] as int,
      currency: data['currency'] as String,
      status: data['status'] as String,
      paymentId: data['paymentId'] as String?,
      updatedAt: data['updatedAt'] as int,
      isSynced: data['isSynced'] as bool? ?? true,
    );
  }
}
```

### Notification Payload

```dart
class NotificationPayload {
  final String orderId;
  final String status;
  final int amount;
  
  String toJson() => jsonEncode({
    'orderId': orderId,
    'status': status,
    'amount': amount,
  });
  
  factory NotificationPayload.fromJson(String json) {
    final data = jsonDecode(json);
    return NotificationPayload(
      orderId: data['orderId'],
      status: data['status'],
      amount: data['amount'],
    );
  }
}
```

