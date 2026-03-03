# Implementation Plan: Local Order Persistence and Sync

## Overview

This implementation adds local-first order persistence using Hive with real-time AppSync subscription updates. The system ensures webhook-verified payment status updates are reliably synchronized to the mobile app, with graceful fallback to polling when subscriptions timeout.

## Tasks

- [x] 1. Add dependencies and generate Hive adapter
  - Add to pubspec.yaml: hive, hive_flutter, flutter_local_notifications, amplify_api
  - Add to dev_dependencies: hive_generator, build_runner
  - Run `flutter pub get` to install dependencies
  - _Requirements: 1.1, 1.2, 9.3_

- [ ] 2. Enhance OrderDetail model with Hive annotations
  - [x] 2.1 Add Hive annotations to OrderDetail model
    - Add `@HiveType(typeId: 0)` to class
    - Add `@HiveField(n)` annotations to all fields (0-12)
    - Add new fields: razorpayOrderId (nullable), currency (default "INR"), updatedAt (required), isSynced (default false)
    - Change updatedAt from nullable to required field
    - Add `part 'order_detail.g.dart';` directive
    - _Requirements: 1.2, 1.3, 9.3_
  
  - [x] 2.2 Add copyWith method to OrderDetail
    - Implement copyWith method for all fields
    - Use for creating updated order instances
    - _Requirements: 1.5, 7.6_
  
  - [x] 2.3 Generate Hive adapter
    - Run `flutter pub run build_runner build --delete-conflicting-outputs`
    - Verify order_detail.g.dart is generated
    - _Requirements: 1.2_

- [ ] 3. Implement Local Storage Service
  - [x] 3.1 Create LocalStorageService class
    - Create file: lib/features/payment/services/local_storage_service.dart
    - Implement initialize() method to open Hive box named 'orders'
    - Register OrderDetailAdapter before opening box
    - _Requirements: 1.1, 1.8, 9.7_
  
  - [x] 3.2 Implement CRUD operations
    - Implement saveOrder(OrderDetail) - uses orderId as key
    - Implement getOrder(String orderId) - returns OrderDetail or null
    - Implement getAllOrders() - returns List<OrderDetail>
    - Implement deleteOrder(String orderId) - for cleanup
    - Add error handling with HiveError exceptions
    - _Requirements: 1.4, 1.5, 1.6_
  
  - [x] 3.3 Implement updateOrder with timestamp checking
    - Read current record from Hive
    - Compare updatedAt timestamps (new > old)
    - Write only if new timestamp is newer
    - Return bool indicating if update was applied
    - Log discarded updates with warning
    - _Requirements: 2.4, 2.5, 2.6, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_
  
  - [x] 3.4 Implement getPendingOrders query
    - Query all orders with status "pending" or "processing"
    - Return List<OrderDetail>
    - Used for resubscription on app restart
    - _Requirements: 1.7, 4.1, 4.3_
  
  - [ ]* 3.5 Write unit tests for LocalStorageService
    - Test timestamp comparison logic (newer wins, older discarded)
    - Test CRUD operations
    - Test getPendingOrders filtering
    - Mock Hive box for testing
    - _Requirements: 7.1, 7.2, 7.5, 7.6_

- [ ] 4. Implement Subscription Service
  - [x] 4.1 Create SubscriptionService class
    - Create file: lib/features/payment/services/subscription_service.dart
    - Initialize with LocalStorageService dependency
    - Maintain Map<String, StreamSubscription> for active subscriptions
    - _Requirements: 2.1, 2.2, 10.4_
  
  - [x] 4.2 Implement subscribeToOrder method
    - Use Amplify.API.subscribe() with GraphQL subscription query
    - Subscription query: onOrderUpdate(orderId: $orderId)
    - Cancel existing subscription for same orderId before creating new one
    - Store subscription in active subscriptions map
    - _Requirements: 2.1, 2.2, 2.7, 4.2, 4.4, 10.7_
  
  - [x] 4.3 Implement subscription update handler
    - Parse GraphQL response to OrderDetail
    - Call LocalStorageService.updateOrder (handles timestamp check)
    - If status is "paid" or "failed", auto-cancel subscription
    - Log all subscription events (created, updated, cancelled)
    - _Requirements: 2.3, 2.4, 2.5, 2.6, 2.8, 10.1, 10.2_
  
  - [x] 4.4 Implement retry logic for failed subscriptions
    - Retry up to 3 times on subscription failure
    - Wait 5 seconds between retry attempts
    - Log errors and retry attempts
    - _Requirements: 8.1, 8.2, 8.3, 8.7_
  
  - [x] 4.5 Implement subscription cleanup methods
    - Implement cancelSubscription(String orderId)
    - Implement cancelAllSubscriptions()
    - Remove from active subscriptions map when cancelled
    - Implement dispose() to cleanup all resources
    - _Requirements: 2.8, 10.1, 10.2, 10.3, 10.5, 10.6_
  
  - [ ]* 4.6 Write unit tests for SubscriptionService
    - Test subscription lifecycle (create, update, cancel)
    - Test retry logic
    - Test auto-cancel on final status
    - Mock Amplify.API.subscribe
    - _Requirements: 2.7, 2.8, 8.2, 8.3, 10.1, 10.2_

- [ ] 5. Implement Local Notification Service
  - [x] 5.1 Create LocalNotificationService class
    - Create file: lib/features/payment/services/local_notification_service.dart
    - Implement initialize() to setup flutter_local_notifications
    - Request notification permissions
    - Create notification channel: "payment_updates" with high importance
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [x] 5.2 Implement notification methods
    - Implement showPaymentSuccessNotification(orderId, amount)
    - Implement showPaymentFailureNotification(orderId, amount)
    - Format amount with ₹ symbol and 2 decimal places
    - Add notification tap action to navigate to order details
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.6, 6.7_
  
  - [x] 5.3 Implement foreground detection
    - Add isAppInForeground getter
    - Only show notification if app is in background
    - Prevent duplicate notifications when user is viewing payment screen
    - _Requirements: 6.5_
  
  - [ ]* 5.4 Write widget tests for notification display
    - Test notification content formatting
    - Test foreground detection logic
    - Mock flutter_local_notifications plugin
    - _Requirements: 6.1, 6.5, 6.6_

- [ ] 6. Create Status Badge Widget
  - [x] 6.1 Create StatusBadge widget
    - Create file: lib/features/payment/widgets/status_badge.dart (may already exist, enhance if needed)
    - Accept orderId, fontSize, padding as parameters
    - Use StreamBuilder or ValueListenableBuilder to watch Hive box
    - Query LocalStorageService.getOrder(orderId) on rebuild
    - _Requirements: 5.1, 5.2, 5.7, 5.8_
  
  - [x] 6.2 Implement status color mapping
    - pending: Grey (#9E9E9E)
    - processing: Blue (#2196F3)
    - paid: Green (#4CAF50)
    - failed: Red (#F44336)
    - Display status text in uppercase
    - Rounded corners with 4px radius, 8px horizontal padding, 4px vertical padding
    - _Requirements: 5.3, 5.4, 5.5, 5.6_
  
  - [ ]* 6.3 Write widget tests for StatusBadge
    - Test reactive updates when order status changes
    - Test color mapping for all statuses
    - Mock LocalStorageService
    - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 7. Checkpoint - Verify core services
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Enhance Backend API Service
  - [x] 8.1 Add getOrderStatus method to BackendApiService
    - Add method: Future<OrderDetail> getOrderStatus({required String orderId})
    - Endpoint: GET /selvan/get-order-status?orderId=xxx
    - 15-second timeout
    - Parse response to OrderDetail
    - Add mock mode support for testing
    - _Requirements: 3.7, 3.8, 8.5, 9.2, 9.5_
  
  - [ ]* 8.2 Write unit tests for getOrderStatus
    - Test successful response parsing
    - Test timeout handling
    - Test error responses
    - Mock HTTP client
    - _Requirements: 3.7, 3.8, 8.5_

- [ ] 9. Enhance Payment Service
  - [x] 9.1 Add service dependencies to PaymentService
    - Add LocalStorageService, SubscriptionService, LocalNotificationService as dependencies
    - Initialize services in constructor or init method
    - _Requirements: 9.1, 9.4_
  
  - [x] 9.2 Modify openCheckout to create local order first
    - Before calling backend, create OrderDetail with status "pending"
    - Generate orderId: 'order_${DateTime.now().millisecondsSinceEpoch}'
    - Set createdAt and updatedAt to current Unix timestamp (seconds)
    - Call LocalStorageService.saveOrder(order)
    - _Requirements: 1.4, 3.1, 3.2, 9.1_
  
  - [x] 9.3 Establish subscription before opening Razorpay
    - After saving local order, call SubscriptionService.subscribeToOrder(orderId)
    - Continue with existing Razorpay order creation and checkout
    - _Requirements: 3.2, 9.1_
  
  - [x] 9.4 Implement "verifying" state after Razorpay callback
    - When Razorpay success callback fires, show "Verifying payment..." message
    - Do NOT mark order as paid based on callback
    - Wait for subscription update or timeout
    - _Requirements: 3.3, 3.4, 3.9_
  
  - [x] 9.5 Implement 20-second timeout with polling fallback
    - After Razorpay callback, wait up to 20 seconds for subscription update
    - Check if order status is still "pending" or "processing"
    - If timeout expires, call BackendApiService.getOrderStatus(orderId)
    - Update local storage with polled status
    - Handle polling failure with user-friendly error message
    - _Requirements: 3.7, 3.8, 8.5, 8.6_
  
  - [x] 9.6 Integrate notification triggers
    - When subscription updates order to "paid", trigger LocalNotificationService.showPaymentSuccessNotification
    - When subscription updates order to "failed", trigger LocalNotificationService.showPaymentFailureNotification
    - Check if app is in foreground before showing notification
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [ ]* 9.7 Write integration tests for payment flow
    - Test complete flow: create order → subscribe → Razorpay → subscription update → notification
    - Test timeout fallback to polling
    - Test error handling
    - Mock all external services
    - _Requirements: 3.1, 3.2, 3.3, 3.7, 3.9_

- [ ] 10. Implement app startup resubscription
  - [x] 10.1 Add resubscription logic to app initialization
    - In main.dart or payment module init, call LocalStorageService.initialize()
    - Query LocalStorageService.getPendingOrders()
    - For each pending order, call SubscriptionService.subscribeToOrder(orderId)
    - Complete before showing main UI
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 9.6_
  
  - [ ]* 10.2 Write integration tests for resubscription
    - Test resubscription on app restart with pending orders
    - Test no resubscription when no pending orders
    - Mock LocalStorageService and SubscriptionService
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 11. Final integration and testing
  - [x] 11.1 Update existing UI screens to use StatusBadge
    - Replace any hardcoded status displays with StatusBadge widget
    - Ensure reactive updates work across all screens
    - _Requirements: 5.1, 5.2_
  
  - [x] 11.2 Test complete end-to-end flow
    - Manually test: create order → pay → verify subscription update → check notification
    - Test app restart with pending order → verify resubscription
    - Test timeout fallback to polling
    - Test offline mode (local data access)
    - _Requirements: 3.1, 3.2, 3.3, 3.7, 4.1, 4.2, 6.1_
  
  - [-] 11.3 Verify backward compatibility
    - Ensure existing Payment_Service public API unchanged
    - Ensure existing Backend_API_Service public API unchanged
    - Test existing payment flows still work
    - _Requirements: 9.4, 9.5_

- [ ] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The design uses Dart/Flutter, so all code should follow Flutter conventions
- Hive adapter generation (task 2.3) must complete before LocalStorageService can be used
- Services should be initialized in the correct order: LocalStorage → Subscription → Notification
- Timestamp comparison is critical for data consistency - test thoroughly
- Subscription cleanup prevents resource leaks - ensure proper disposal
