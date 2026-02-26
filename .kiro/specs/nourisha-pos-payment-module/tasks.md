# Implementation Plan: Nourisha POS Payment Module

## Overview

This implementation plan breaks down the Nourisha POS Payment Module into incremental, testable steps. The approach prioritizes security (no Key_Secret in client code), clean architecture (separation of concerns), and resilience (payment reconciliation). Each task builds on previous work, with testing integrated throughout to catch errors early.

The module will be implemented in Flutter/Dart following Material 3 design guidelines and organized under `lib/features/payment/` to maintain clean project structure.

## Tasks

- [x] 1. Set up project dependencies and module structure
  - Add `razorpay_flutter` dependency to pubspec.yaml with version constraint (^1.3.0 or latest)
  - Add `shared_preferences` dependency for state persistence
  - Create directory structure: `lib/features/payment/models/`, `lib/features/payment/services/`, `lib/features/payment/screens/`
  - Create test directory structure mirroring lib: `test/features/payment/`
  - _Requirements: 10.1, 10.5, 7.1, 7.2, 7.3_

- [ ] 2. Implement payment data models
  - [x] 2.1 Create payment_models.dart with all model classes
    - Implement `PaymentStatus` enum (pending, success, failed, unknown)
    - Implement `OrderResponse` class with fromJson/toJson methods
    - Implement `PaymentResult` class with factory constructors (success, failure, externalWallet)
    - Implement `PaymentStatusResponse` class with fromJson/toJson methods
    - _Requirements: 7.4, 8.2, 8.4, 8.6_
  
  - [ ]* 2.2 Write unit tests for payment models
    - Test OrderResponse serialization/deserialization
    - Test PaymentResult factory constructors
    - Test PaymentStatusResponse parsing
    - Test edge cases: null values, empty strings, malformed JSON
    - _Requirements: 7.4_

- [ ] 3. Implement mock backend API service
  - [x] 3.1 Create backend_api_service.dart with mock implementations
    - Implement `createOrder()` method returning mock OrderResponse
    - Implement `verifyPayment()` method returning mock boolean
    - Implement `checkPaymentStatus()` method returning mock PaymentStatusResponse
    - Add TODO comments marking each method for production replacement
    - Include inline security comments explaining backend holds Key_Secret
    - _Requirements: 1.3, 1.4, 1.5, 7.5, 7.6, 8.1, 8.3, 8.5_
  
  - [ ]* 3.2 Write unit tests for backend API service
    - Test createOrder returns valid OrderResponse structure
    - Test verifyPayment returns boolean
    - Test checkPaymentStatus returns valid PaymentStatusResponse
    - Test mock response structures match API contracts
    - _Requirements: 8.7_
  
  - [ ]* 3.3 Write property test for API response completeness
    - **Property 16: API Response Completeness**
    - **Validates: Requirements 8.2, 8.4, 8.6**
    - Generate random inputs, verify all required fields present in responses

- [x] 4. Checkpoint - Verify data layer
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement payment service core logic
  - [x] 5.1 Create payment_service.dart with Razorpay integration
    - Define RAZORPAY_KEY_ID constant with placeholder value and TODO comment
    - Implement constructor accepting BackendApiService and SharedPreferences
    - Implement `_initializeRazorpay()` method to create Razorpay instance
    - Register callback handlers: `_handlePaymentSuccess`, `_handlePaymentError`, `_handleExternalWallet`
    - Implement `dispose()` method to clean up Razorpay instance
    - Add inline security comments explaining Key_ID vs Key_Secret separation
    - _Requirements: 1.1, 1.2, 1.6, 3.5, 7.7, 9.1, 9.2, 10.2, 10.3_
  
  - [x] 5.2 Implement openCheckout() payment flow
    - Call `_backendApi.createOrder()` with amount and reference
    - Persist Order_ID to SharedPreferences before launching Razorpay
    - Build Razorpay options map with Key_ID, amount, order_id, Nourisha branding
    - Call `_razorpay.open(options)` to launch checkout
    - Handle order creation errors with try-catch
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 5.2_
  
  - [x] 5.3 Implement payment callback handlers
    - `_handlePaymentSuccess`: Extract paymentId, orderId, signature; create PaymentResult; persist to SharedPreferences
    - `_handlePaymentError`: Extract error code and description; create PaymentResult; persist status
    - `_handleExternalWallet`: Extract wallet name; create PaymentResult
    - _Requirements: 3.6, 3.7, 3.8, 4.3, 4.4, 4.5_
  
  - [x] 5.4 Implement checkStatus() for payment reconciliation
    - Retrieve last Order_ID and Payment_ID from SharedPreferences
    - Call `_backendApi.checkPaymentStatus()` with stored identifiers
    - Return PaymentStatusResponse
    - _Requirements: 6.2, 6.3, 6.5_
  
  - [x] 5.5 Implement SharedPreferences persistence helpers
    - `_saveOrderId()`, `_getLastOrderId()`
    - `_savePaymentId()`, `_getLastPaymentId()`
    - `_savePaymentStatus()`, `_getLastPaymentStatus()`
    - _Requirements: 5.2, 5.3_

- [ ]* 6. Write property tests for payment service
  - [ ]* 6.1 Property test: Backend API delegation
    - **Property 1: Backend API Delegation for Secure Operations**
    - **Validates: Requirements 1.3, 1.4, 1.5**
    - Generate random amounts, verify backend called for all secure operations
  
  - [ ]* 6.2 Property test: Payment flow triggers order creation
    - **Property 2: Payment Flow Triggers Backend Order Creation**
    - **Validates: Requirements 3.1**
    - Generate random amounts and references, verify createOrder called with correct params
  
  - [ ]* 6.3 Property test: Order response extraction
    - **Property 3: Order Response Extraction**
    - **Validates: Requirements 3.2**
    - Generate random order responses, verify Order_ID extracted correctly
  
  - [ ]* 6.4 Property test: Razorpay checkout parameters
    - **Property 4: Razorpay Checkout Launch with Correct Parameters**
    - **Validates: Requirements 3.3**
    - Generate random Order_IDs, verify Razorpay launched with correct options
  
  - [ ]* 6.5 Property test: Callback data capture
    - **Property 5, 6, 7: Success/Error/Wallet Callback Captures**
    - **Validates: Requirements 3.6, 3.7, 3.8**
    - Simulate random callbacks, verify all required fields captured
  
  - [ ]* 6.6 Property test: State persistence round trip
    - **Property 10: Order ID Persistence and Restoration**
    - **Validates: Requirements 5.2, 5.3**
    - Generate random Order_IDs, persist, clear, restore, verify equality

- [ ]* 7. Write unit tests for payment service
  - Test Razorpay SDK initialization in constructor
  - Test openCheckout() with mocked backend
  - Test callback handlers with sample data
  - Test checkStatus() calls backend with correct parameters
  - Test dispose() cleans up Razorpay instance
  - Test error handling for backend failures
  - _Requirements: 7.7, 7.8, 10.2, 10.3_

- [x] 8. Checkpoint - Verify service layer
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Implement POS screen UI
  - [x] 9.1 Create razorpay_pos_screen.dart StatefulWidget
    - Create screen with AppBar title "Nourisha POS – Payment"
    - Initialize PaymentService in initState with SharedPreferences and BackendApiService
    - Implement dispose() to clean up controllers and payment service
    - _Requirements: 2.1, 7.2_
  
  - [x] 9.2 Implement amount and reference input fields
    - Add TextEditingController for amount with large font size (32sp)
    - Add rupee symbol prefix to amount field
    - Add TextEditingController for optional reference field
    - Use OutlinedBorder for Material 3 styling
    - _Requirements: 2.2, 2.3, 2.4_
  
  - [x] 9.3 Implement Pay Now button
    - Create ElevatedButton with large padding (vertical: 20dp)
    - Set font size to 24sp for button text
    - Implement `_handlePayNow()` method to validate input and call payment service
    - Show loading indicator while processing
    - Handle errors with SnackBar messages
    - _Requirements: 2.5, 3.1_
  
  - [x] 9.4 Implement Check Payment Status button
    - Create OutlinedButton with padding (vertical: 16dp)
    - Set font size to 18sp for button text
    - Implement `_handleCheckStatus()` method to call payment service
    - Show loading indicator while checking
    - _Requirements: 6.1, 6.2_
  
  - [x] 9.5 Implement response display panel
    - Create scrollable Container with border
    - Implement `_formatJson()` helper using JsonEncoder.withIndent
    - Implement `_getStatusColor()` to map PaymentStatus to colors (green/red/orange)
    - Update border color based on payment status
    - Display formatted JSON response in monospace font
    - _Requirements: 4.1, 4.2, 4.6, 4.7, 4.8_
  
  - [x] 9.6 Implement state management and UI updates
    - Add state variables: `_responseText`, `_currentStatus`, `_isProcessing`
    - Implement `_displayResult()` to update UI with PaymentResult
    - Implement `_displayStatusResponse()` to update UI with status check results
    - Ensure setState() called for all UI updates
    - _Requirements: 4.3, 4.4, 4.5, 6.4_

- [ ]* 10. Write widget tests for POS screen
  - Test screen renders with correct title
  - Test amount input field exists and accepts numeric input
  - Test reference input field exists
  - Test Pay Now button exists and is tappable
  - Test Check Payment Status button exists
  - Test response panel displays formatted JSON
  - Test status color changes based on PaymentStatus
  - Test error messages display in SnackBar
  - _Requirements: 2.1, 2.2, 2.4, 2.5, 6.1_

- [ ]* 11. Write property tests for UI components
  - [ ]* 11.1 Property test: Touch target minimum size
    - **Property 15: Touch Target Minimum Size**
    - **Validates: Requirements 2.7**
    - Verify all interactive elements meet 48x48 dp minimum
  
  - [ ]* 11.2 Property test: JSON formatting validity
    - **Property 8: Payment Response JSON Formatting**
    - **Validates: Requirements 4.2**
    - Generate random payment responses, verify JSON is parseable
  
  - [ ]* 11.3 Property test: State persistence
    - **Property 9: Payment State Persistence**
    - **Validates: Requirements 4.3, 4.4, 4.5**
    - Generate random payment operations, verify state persisted
  
  - [ ]* 11.4 Property test: Backend error display
    - **Property 11: Backend Error Display**
    - **Validates: Requirements 5.5**
    - Generate random backend errors, verify displayed in UI
  
  - [ ]* 11.5 Property test: Status check updates UI
    - **Property 14: Status Retrieval Updates UI**
    - **Validates: Requirements 6.4**
    - Generate random status responses, verify UI updates

- [x] 12. Checkpoint - Verify UI layer
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Integration and wiring
  - [x] 13.1 Create payment module entry point
    - Create `lib/features/payment/payment_module.dart` exporting all public APIs
    - Export RazorpayPosScreen widget
    - Export PaymentService for advanced use cases
    - Export all model classes
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [x] 13.2 Add navigation route to main.dart
    - Import payment module
    - Add route to RazorpayPosScreen
    - Test navigation from main app
    - _Requirements: 2.1_
  
  - [x] 13.3 Update pubspec.yaml with final configuration
    - Verify all dependencies present with correct versions
    - Add package description and metadata
    - _Requirements: 10.1, 10.5_

- [ ]* 14. Write integration tests
  - Test end-to-end payment flow with mocked Razorpay
  - Test app restart recovery scenario
  - Test status check after lost callback
  - Test multiple payment attempts
  - Test error recovery flows
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.5_

- [ ]* 15. Write property tests for API contracts
  - [ ]* 15.1 Property test: API parameter acceptance
    - **Property 18: API Contract Parameter Acceptance**
    - **Validates: Requirements 8.1, 8.3, 8.5**
    - Generate random valid inputs, verify no parameter validation errors
  
  - [ ]* 15.2 Property test: Mock response structure validity
    - **Property 17: Mock Backend Response Structure Validity**
    - **Validates: Requirements 8.7**
    - Verify mock responses match production API contracts
  
  - [ ]* 15.3 Property test: Status parsing correctness
    - **Property 13: Payment Status Parsing**
    - **Validates: Requirements 6.3**
    - Generate random status responses, verify parsed into valid enum values

- [x] 16. Final checkpoint and documentation
  - Ensure all tests pass (unit, widget, property, integration)
  - Verify code coverage ≥ 80%
  - Run `flutter analyze` and fix any issues
  - Run `dart format .` to format all code
  - Add inline documentation comments to public APIs
  - Verify security: no Key_Secret in codebase
  - Ask the user if questions arise or if ready for production deployment

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (minimum 100 iterations each)
- Unit tests validate specific examples and edge cases
- Security is validated throughout: no Key_Secret in client code, all sensitive operations via backend
- Module is designed to be drop-in ready for any Flutter app
- Mock backend clearly marked with TODO comments for production replacement
