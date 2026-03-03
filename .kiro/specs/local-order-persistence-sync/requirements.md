# Requirements Document

## Introduction

This feature implements local order persistence with real-time subscription updates for the Flutter payment module. The system ensures that order status updates from backend webhooks are reliably synchronized to the mobile app through AppSync subscriptions, with local Hive storage providing persistence and offline capability. The webhook is the source of truth for payment status, never the Razorpay success callback.

## Glossary

- **Order_Persistence_System**: The complete system handling local storage, subscriptions, and synchronization of order data
- **Local_Storage_Service**: Hive-based service managing CRUD operations for OrderDetail records
- **Subscription_Service**: Service managing AppSync GraphQL subscriptions for real-time order updates
- **Payment_Service**: Existing service handling Razorpay payment flows (to be enhanced)
- **Backend_API_Service**: Existing service for AppSync mutations and queries (to be enhanced)
- **OrderDetail**: Data model representing an order with payment information
- **Status_Badge**: UI component displaying current order status (pending/processing/paid/failed)
- **Webhook**: Backend Lambda function triggered by Razorpay payment events
- **AppSync_Subscription**: Real-time GraphQL subscription receiving webhook-triggered updates
- **Razorpay_Callback**: Client-side success/failure callback from Razorpay SDK (not trusted)
- **Hive**: Local NoSQL database for Flutter
- **Source_of_Truth**: The authoritative data source (webhook updates via subscription)
- **Pending_Order**: Order with status "pending" or "processing" awaiting final payment confirmation
- **Timestamp_Comparison**: Comparing updatedAt fields to prevent stale data overwrites
- **Resubscription**: Re-establishing subscriptions to pending orders after app restart

## Requirements

### Requirement 1: Local Order Storage

**User Story:** As a developer, I want to persist order data locally using Hive, so that order information survives app restarts and provides offline access.

#### Acceptance Criteria

1. THE Local_Storage_Service SHALL use Hive as the storage backend
2. THE OrderDetail SHALL be annotated as a HiveType with a type adapter
3. THE OrderDetail SHALL include fields: orderId, razorpayOrderId, amount, currency, status, paymentId, updatedAt, isSynced
4. WHEN an order is created, THE Local_Storage_Service SHALL save it to Hive with status "pending"
5. WHEN an order is updated, THE Local_Storage_Service SHALL update the existing Hive record
6. THE Local_Storage_Service SHALL provide methods to retrieve orders by orderId
7. THE Local_Storage_Service SHALL provide methods to retrieve all pending orders
8. WHEN the app initializes, THE Local_Storage_Service SHALL open the Hive box before any operations

### Requirement 2: Real-Time Subscription Management

**User Story:** As a user, I want my order status to update automatically when the payment is confirmed, so that I see the latest status without manual refresh.

#### Acceptance Criteria

1. WHEN an order is created locally, THE Subscription_Service SHALL subscribe to AppSync updates for that orderId
2. THE Subscription_Service SHALL use Amplify.API.subscribe for GraphQL subscriptions
3. WHEN a subscription receives an update, THE Subscription_Service SHALL parse the order data
4. WHEN a subscription receives an update, THE Order_Persistence_System SHALL compare timestamps before updating
5. IF the received updatedAt is newer than the local updatedAt, THEN THE Order_Persistence_System SHALL update the local record
6. IF the received updatedAt is older than or equal to the local updatedAt, THEN THE Order_Persistence_System SHALL discard the update
7. WHEN creating a new subscription for an orderId, THE Subscription_Service SHALL cancel any existing subscription for that orderId
8. WHEN an order reaches final status (paid or failed), THE Subscription_Service SHALL cancel the subscription for that orderId
9. THE Subscription_Service SHALL handle subscription errors by logging and notifying the error handler

### Requirement 3: Payment Flow Integration

**User Story:** As a user, I want the system to verify my payment through the backend webhook rather than trusting the Razorpay callback, so that payment confirmation is secure and reliable.

#### Acceptance Criteria

1. WHEN Razorpay payment is initiated, THE Payment_Service SHALL create an order locally with status "pending"
2. WHEN Razorpay payment is initiated, THE Payment_Service SHALL establish a subscription for the orderId
3. WHEN Razorpay success callback fires, THE Payment_Service SHALL display "verifying" state to the user
4. WHEN Razorpay success callback fires, THE Payment_Service SHALL NOT mark the order as paid
5. WHEN a subscription update is received with status "paid", THE Order_Persistence_System SHALL update the local order
6. WHEN a subscription update is received with status "failed", THE Order_Persistence_System SHALL update the local order
7. IF no subscription update is received within 20 seconds of Razorpay callback, THEN THE Payment_Service SHALL call Backend_API_Service.getOrderStatus
8. WHEN Backend_API_Service.getOrderStatus returns a status, THE Order_Persistence_System SHALL update the local order
9. THE Payment_Service SHALL never trust Razorpay_Callback as the source of truth for payment status

### Requirement 4: App Restart and Resubscription

**User Story:** As a user, I want pending orders to continue receiving updates after I restart the app, so that I don't miss payment confirmations.

#### Acceptance Criteria

1. WHEN the app starts, THE Order_Persistence_System SHALL retrieve all pending orders from Hive
2. FOR ALL pending orders, THE Order_Persistence_System SHALL establish subscriptions
3. THE Order_Persistence_System SHALL define pending orders as those with status "pending" or "processing"
4. WHEN resubscribing, THE Subscription_Service SHALL use the same subscription logic as initial subscription
5. THE Order_Persistence_System SHALL complete resubscription before displaying the main UI

### Requirement 5: UI Status Badge Updates

**User Story:** As a user, I want to see the current payment status displayed clearly on the UI, so that I know whether my payment is pending, processing, paid, or failed.

#### Acceptance Criteria

1. THE Status_Badge SHALL display the status from the local Hive record
2. WHEN the local order status changes, THE Status_Badge SHALL update automatically
3. THE Status_Badge SHALL display "pending" with grey color
4. THE Status_Badge SHALL display "processing" with blue color
5. THE Status_Badge SHALL display "paid" with green color
6. THE Status_Badge SHALL display "failed" with red color
7. THE Status_Badge SHALL use the local Hive record as the source of truth
8. WHEN the Status_Badge is rendered, THE UI SHALL read the latest status from Local_Storage_Service

### Requirement 6: Local Notifications

**User Story:** As a user, I want to receive a notification when my payment status changes to paid or failed, so that I'm informed even if I'm not actively viewing the app.

#### Acceptance Criteria

1. WHEN an order status changes from "pending" to "paid", THE Order_Persistence_System SHALL trigger a local notification
2. WHEN an order status changes from "pending" to "failed", THE Order_Persistence_System SHALL trigger a local notification
3. WHEN an order status changes from "processing" to "paid", THE Order_Persistence_System SHALL trigger a local notification
4. WHEN an order status changes from "processing" to "failed", THE Order_Persistence_System SHALL trigger a local notification
5. IF the app is currently displaying the payment success screen, THEN THE Order_Persistence_System SHALL NOT show a notification
6. THE notification SHALL include the order amount and final status
7. WHEN a notification is tapped, THE app SHALL navigate to the order details screen

### Requirement 7: Data Consistency and Conflict Resolution

**User Story:** As a developer, I want the system to handle concurrent updates correctly, so that newer data never gets overwritten by older data.

#### Acceptance Criteria

1. THE Order_Persistence_System SHALL use the updatedAt timestamp for conflict resolution
2. WHEN comparing two order records, THE Order_Persistence_System SHALL consider the record with the later updatedAt as authoritative
3. WHEN receiving a subscription update, THE Order_Persistence_System SHALL read the current local record
4. WHEN receiving a subscription update, THE Order_Persistence_System SHALL compare updatedAt timestamps
5. IF the subscription update is older, THEN THE Order_Persistence_System SHALL discard it and log a warning
6. IF the subscription update is newer, THEN THE Order_Persistence_System SHALL update the local record
7. THE Order_Persistence_System SHALL perform timestamp comparison and update as an atomic operation

### Requirement 8: Error Handling and Resilience

**User Story:** As a user, I want the system to handle network failures and errors gracefully, so that temporary issues don't cause permanent data loss.

#### Acceptance Criteria

1. WHEN a subscription fails to establish, THE Subscription_Service SHALL log the error
2. WHEN a subscription fails to establish, THE Subscription_Service SHALL retry after 5 seconds
3. THE Subscription_Service SHALL retry subscription establishment up to 3 times
4. WHEN Hive operations fail, THE Local_Storage_Service SHALL throw descriptive exceptions
5. WHEN the 20-second timeout expires without subscription update, THE Payment_Service SHALL call getOrderStatus as fallback
6. IF getOrderStatus fails, THEN THE Payment_Service SHALL display an error message to the user
7. WHEN subscription connection is lost, THE Subscription_Service SHALL attempt to reconnect
8. THE Order_Persistence_System SHALL log all critical operations for debugging

### Requirement 9: Integration with Existing Services

**User Story:** As a developer, I want to extend existing services without breaking current functionality, so that the integration is safe and backward-compatible.

#### Acceptance Criteria

1. THE Payment_Service SHALL be enhanced to call Local_Storage_Service and Subscription_Service
2. THE Backend_API_Service SHALL be enhanced to include getOrderStatus query
3. THE OrderDetail model SHALL be enhanced with new fields while maintaining existing fields
4. THE Payment_Service SHALL maintain all existing public methods and signatures
5. THE Backend_API_Service SHALL maintain all existing public methods and signatures
6. THE Order_Persistence_System SHALL NOT restructure existing folder hierarchy
7. THE Order_Persistence_System SHALL add only Local_Storage_Service and Subscription_Service as new files
8. THE Order_Persistence_System SHALL place new services in features/payment/services/ directory

### Requirement 10: Subscription Lifecycle Management

**User Story:** As a developer, I want subscriptions to be properly cleaned up, so that the app doesn't leak resources or maintain unnecessary connections.

#### Acceptance Criteria

1. WHEN an order reaches status "paid", THE Subscription_Service SHALL cancel the subscription
2. WHEN an order reaches status "failed", THE Subscription_Service SHALL cancel the subscription
3. WHEN the app is disposed, THE Subscription_Service SHALL cancel all active subscriptions
4. THE Subscription_Service SHALL maintain a map of orderId to subscription handles
5. WHEN canceling a subscription, THE Subscription_Service SHALL remove it from the active subscriptions map
6. THE Subscription_Service SHALL provide a method to cancel all subscriptions
7. WHEN a new subscription is created for an existing orderId, THE Subscription_Service SHALL cancel the old subscription first

