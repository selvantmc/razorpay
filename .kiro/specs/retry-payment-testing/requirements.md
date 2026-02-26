# Requirements Document

## Introduction

This document defines the testing requirements for the retry payment feature in the Order Lookup Screen. The feature allows users to retry payment for unpaid orders using the Razorpay SDK integration. Testing will cover widget tests, integration tests, manual testing scenarios, and edge case handling to ensure the feature works reliably across different order states and network conditions.

## Glossary

- **Order_Lookup_Screen**: The Flutter screen widget that displays order details and provides payment retry functionality
- **Razorpay_SDK**: Third-party payment gateway SDK integrated into the app for processing payments
- **Payment_Session**: Shared state object that stores payment-related data (order ID, payment ID, signature)
- **Order_Detail**: Data model representing an order with properties like orderId, amount, status, paymentId, signature
- **Backend_API**: AWS API Gateway endpoint at https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan
- **Retry_Payment_Button**: UI button that launches Razorpay SDK for payment retry
- **Test_Suite**: Collection of automated tests (widget tests and integration tests)
- **Manual_Test_Procedure**: Step-by-step instructions for human testers to verify functionality
- **needsAction**: Boolean getter on OrderDetail that returns true when status is not 'paid', 'captured', or 'verified'
- **Auto_Verification**: Automatic payment verification triggered after successful payment completion

## Requirements

### Requirement 1: Widget Test Coverage for Retry Payment Button

**User Story:** As a developer, I want comprehensive widget tests for the retry payment button, so that I can verify the UI renders correctly based on order state.

#### Acceptance Criteria

1. WHEN an order with status 'created' is loaded, THE Test_Suite SHALL verify the Retry_Payment_Button is visible
2. WHEN an order with status 'failed' is loaded, THE Test_Suite SHALL verify the Retry_Payment_Button is visible
3. WHEN an order with status 'paid' is loaded, THE Test_Suite SHALL verify the Retry_Payment_Button is not visible
4. WHEN an order with status 'captured' is loaded, THE Test_Suite SHALL verify the Retry_Payment_Button is not visible
5. WHEN an order with status 'verified' is loaded, THE Test_Suite SHALL verify the Retry_Payment_Button is not visible
6. WHEN no order is loaded, THE Test_Suite SHALL verify the Retry_Payment_Button is not visible
7. WHEN an order with status 'authorized' is loaded, THE Test_Suite SHALL verify the Retry_Payment_Button is visible

### Requirement 2: Razorpay SDK Initialization Testing

**User Story:** As a developer, I want to verify Razorpay SDK initialization, so that I can ensure payment handlers are properly configured.

#### Acceptance Criteria

1. WHEN the Order_Lookup_Screen is initialized, THE Test_Suite SHALL verify the Razorpay_SDK is instantiated
2. WHEN the Order_Lookup_Screen is initialized, THE Test_Suite SHALL verify payment success handler is registered
3. WHEN the Order_Lookup_Screen is initialized, THE Test_Suite SHALL verify payment error handler is registered
4. WHEN the Order_Lookup_Screen is initialized, THE Test_Suite SHALL verify external wallet handler is registered
5. WHEN the Order_Lookup_Screen is disposed, THE Test_Suite SHALL verify the Razorpay_SDK resources are cleared

### Requirement 3: Retry Payment Button Interaction Testing

**User Story:** As a developer, I want to test retry payment button interactions, so that I can verify the Razorpay SDK launches with correct parameters.

#### Acceptance Criteria

1. WHEN the Retry_Payment_Button is tapped, THE Test_Suite SHALL verify the Razorpay_SDK open method is called
2. WHEN the Retry_Payment_Button is tapped, THE Test_Suite SHALL verify the order ID from Order_Detail is passed to Razorpay_SDK
3. WHEN the Retry_Payment_Button is tapped, THE Test_Suite SHALL verify the amount in paise from Order_Detail is passed to Razorpay_SDK
4. WHEN the Retry_Payment_Button is tapped, THE Test_Suite SHALL verify the Razorpay key 'rzp_test_SHXH1wQoOlA037' is included in options
5. WHEN the Retry_Payment_Button is tapped, THE Test_Suite SHALL verify the currency 'INR' is included in options

### Requirement 4: Payment Success Handler Testing

**User Story:** As a developer, I want to test the payment success handler, so that I can verify payment data is saved and auto-verification triggers.

#### Acceptance Criteria

1. WHEN Razorpay_SDK triggers payment success event, THE Test_Suite SHALL verify the order ID is saved to Payment_Session
2. WHEN Razorpay_SDK triggers payment success event, THE Test_Suite SHALL verify the payment ID is saved to Payment_Session
3. WHEN Razorpay_SDK triggers payment success event, THE Test_Suite SHALL verify the signature is saved to Payment_Session
4. WHEN Razorpay_SDK triggers payment success event, THE Test_Suite SHALL verify Auto_Verification is triggered
5. WHEN Auto_Verification completes successfully, THE Test_Suite SHALL verify a success message is displayed

### Requirement 5: Payment Error Handler Testing

**User Story:** As a developer, I want to test the payment error handler, so that I can verify error messages are displayed to users.

#### Acceptance Criteria

1. WHEN Razorpay_SDK triggers payment error event, THE Test_Suite SHALL verify an error message is displayed
2. WHEN Razorpay_SDK triggers payment error event with message 'Payment cancelled by user', THE Test_Suite SHALL verify the error message contains 'Payment failed: Payment cancelled by user'
3. WHEN Razorpay_SDK triggers payment error event, THE Test_Suite SHALL verify the error message is visible in the UI

### Requirement 6: External Wallet Handler Testing

**User Story:** As a developer, I want to test the external wallet handler, so that I can verify wallet selection is acknowledged.

#### Acceptance Criteria

1. WHEN Razorpay_SDK triggers external wallet event, THE Test_Suite SHALL verify a snackbar is displayed
2. WHEN Razorpay_SDK triggers external wallet event with wallet name 'paytm', THE Test_Suite SHALL verify the snackbar contains 'External wallet selected: paytm'

### Requirement 7: Integration Test for Complete Retry Payment Flow

**User Story:** As a developer, I want integration tests for the complete retry payment flow, so that I can verify end-to-end functionality.

#### Acceptance Criteria

1. WHEN a user enters a valid unpaid order ID and taps Fetch Order, THE Test_Suite SHALL verify the order details are displayed
2. WHEN order details are displayed for an unpaid order, THE Test_Suite SHALL verify the Retry_Payment_Button appears
3. WHEN the Retry_Payment_Button is tapped, THE Test_Suite SHALL verify the Razorpay_SDK is invoked
4. WHEN payment succeeds in Razorpay_SDK, THE Test_Suite SHALL verify verification is automatically triggered
5. WHEN verification completes, THE Test_Suite SHALL verify the result is displayed in the Result section

### Requirement 8: Manual Testing Procedure for Retry Payment

**User Story:** As a QA tester, I want a manual testing procedure, so that I can verify the retry payment feature works in a real environment.

#### Acceptance Criteria

1. THE Manual_Test_Procedure SHALL include steps to create an unpaid order using the Payment Screen
2. THE Manual_Test_Procedure SHALL include steps to navigate to Order Lookup Screen and fetch the unpaid order
3. THE Manual_Test_Procedure SHALL include steps to verify the Retry_Payment_Button is visible
4. THE Manual_Test_Procedure SHALL include steps to tap the Retry_Payment_Button and complete payment
5. THE Manual_Test_Procedure SHALL include steps to verify auto-verification triggers after payment success
6. THE Manual_Test_Procedure SHALL include steps to verify the order status updates after successful payment
7. THE Manual_Test_Procedure SHALL include steps to test payment cancellation scenario
8. THE Manual_Test_Procedure SHALL include steps to test payment failure scenario

### Requirement 9: Edge Case Testing for Network Failures

**User Story:** As a developer, I want tests for network failure scenarios, so that I can verify the app handles connectivity issues gracefully.

#### Acceptance Criteria

1. WHEN fetching an order fails due to network timeout, THE Test_Suite SHALL verify an error message 'Request timed out. Please try again.' is displayed
2. WHEN fetching an order fails due to no internet connection, THE Test_Suite SHALL verify an error message 'No internet connection.' is displayed
3. WHEN auto-verification fails due to network error, THE Test_Suite SHALL verify an error message is displayed
4. WHEN auto-verification fails, THE Test_Suite SHALL verify the user can manually retry verification

### Requirement 10: State Management Testing for Tab Switching

**User Story:** As a developer, I want to test state clearing when switching tabs, so that I can verify error messages don't persist incorrectly.

#### Acceptance Criteria

1. WHEN an error message is displayed in Order_Lookup_Screen, THE Test_Suite SHALL verify calling clearLocalData clears the error message
2. WHEN a result message is displayed in Order_Lookup_Screen, THE Test_Suite SHALL verify calling clearLocalData clears the result message
3. WHEN clearLocalData is called, THE Test_Suite SHALL verify the order details remain visible
4. WHEN the user switches to another tab and back, THE Test_Suite SHALL verify clearLocalData is invoked

### Requirement 11: Testing for Multiple Order Status Scenarios

**User Story:** As a developer, I want tests covering all order status values, so that I can verify the UI behaves correctly for each status.

#### Acceptance Criteria

1. FOR ALL status values in ['created', 'authorized', 'failed'], THE Test_Suite SHALL verify needsAction returns true
2. FOR ALL status values in ['paid', 'captured', 'verified'], THE Test_Suite SHALL verify needsAction returns false
3. WHEN an order has status 'created', THE Test_Suite SHALL verify both Retry_Payment_Button and Verify_Payment button are visible
4. WHEN an order has status 'paid', THE Test_Suite SHALL verify no action buttons are visible
5. WHEN an order has status 'authorized', THE Test_Suite SHALL verify Verify_Payment button is visible but Retry_Payment_Button is not visible

### Requirement 12: Mock Testing for Razorpay SDK Interactions

**User Story:** As a developer, I want mock-based tests for Razorpay SDK, so that I can test payment flows without real payment processing.

#### Acceptance Criteria

1. THE Test_Suite SHALL provide a mock implementation of Razorpay_SDK for testing
2. WHEN testing payment success, THE Test_Suite SHALL use the mock to simulate PaymentSuccessResponse
3. WHEN testing payment failure, THE Test_Suite SHALL use the mock to simulate PaymentFailureResponse
4. WHEN testing external wallet, THE Test_Suite SHALL use the mock to simulate ExternalWalletResponse
5. THE Test_Suite SHALL verify all Razorpay_SDK method calls without making real payment requests

### Requirement 13: Testing Payment Amount Handling

**User Story:** As a developer, I want to verify payment amounts are handled correctly, so that I can ensure amounts in paise are passed to Razorpay without conversion.

#### Acceptance Criteria

1. WHEN an order has amount 50000 paise, THE Test_Suite SHALL verify the Razorpay_SDK receives amount 50000
2. WHEN an order has amount 100 paise, THE Test_Suite SHALL verify the Razorpay_SDK receives amount 100
3. THE Test_Suite SHALL verify no amount conversion occurs when passing to Razorpay_SDK
4. WHEN the order details are displayed, THE Test_Suite SHALL verify the formatted amount shows rupees with 2 decimal places

### Requirement 14: Verification Button Conditional Display Testing

**User Story:** As a developer, I want to test when verification and status check buttons appear, so that I can verify they only show for orders needing action.

#### Acceptance Criteria

1. WHEN an order with needsAction true is loaded, THE Test_Suite SHALL verify the Verify_Payment button is visible
2. WHEN an order with needsAction true is loaded, THE Test_Suite SHALL verify the Check_Payment_Status button is visible
3. WHEN an order with needsAction false is loaded, THE Test_Suite SHALL verify the Verify_Payment button is not visible
4. WHEN an order with needsAction false is loaded, THE Test_Suite SHALL verify the Check_Payment_Status button is not visible
5. WHEN an order with status 'paid' is loaded, THE Test_Suite SHALL verify the Actions section is not displayed

### Requirement 15: Testing Error Message Display and Clearing

**User Story:** As a developer, I want to test error message lifecycle, so that I can verify errors are displayed and cleared appropriately.

#### Acceptance Criteria

1. WHEN an API error occurs, THE Test_Suite SHALL verify the error message is displayed in a red error card
2. WHEN an error message is displayed, THE Test_Suite SHALL verify it includes an error icon
3. WHEN a new fetch operation starts, THE Test_Suite SHALL verify previous error messages are cleared
4. WHEN a new action operation starts, THE Test_Suite SHALL verify previous error messages are cleared
5. WHEN an error message contains 'Exception: ' prefix, THE Test_Suite SHALL verify the prefix is removed from display

### Requirement 16: Manual Test Documentation for Different Payment Methods

**User Story:** As a QA tester, I want documentation for testing different payment methods, so that I can verify retry payment works with cards, UPI, and wallets.

#### Acceptance Criteria

1. THE Manual_Test_Procedure SHALL include steps to test retry payment with test credit card
2. THE Manual_Test_Procedure SHALL include steps to test retry payment with test UPI ID
3. THE Manual_Test_Procedure SHALL include steps to test retry payment with test debit card
4. THE Manual_Test_Procedure SHALL include steps to test retry payment with external wallet selection
5. THE Manual_Test_Procedure SHALL include expected results for each payment method

### Requirement 17: Testing Loading States During Retry Payment

**User Story:** As a developer, I want to test loading indicators, so that I can verify users see appropriate feedback during async operations.

#### Acceptance Criteria

1. WHEN fetching an order, THE Test_Suite SHALL verify the Fetch_Order button shows a loading indicator
2. WHEN auto-verification is in progress, THE Test_Suite SHALL verify the Verify_Payment button shows a loading indicator
3. WHEN checking payment status, THE Test_Suite SHALL verify the Check_Payment_Status button shows a loading indicator
4. WHEN the Retry_Payment_Button is tapped, THE Test_Suite SHALL verify no loading indicator appears on the button
5. WHEN an operation completes, THE Test_Suite SHALL verify the loading indicator is removed

### Requirement 18: Round-Trip Property Testing for Payment Flow

**User Story:** As a developer, I want property-based tests for the payment flow, so that I can verify data integrity throughout the retry payment process.

#### Acceptance Criteria

1. FOR ALL valid Order_Detail objects with needsAction true, THE Test_Suite SHALL verify opening Razorpay and completing payment results in Payment_Session containing matching order ID
2. FOR ALL successful payment responses, THE Test_Suite SHALL verify the payment ID in Payment_Session matches the payment ID from Razorpay_SDK
3. FOR ALL successful payment responses, THE Test_Suite SHALL verify the signature in Payment_Session matches the signature from Razorpay_SDK
4. FOR ALL orders fetched from Backend_API, THE Test_Suite SHALL verify the Order_Detail object can be serialized and deserialized without data loss

### Requirement 19: Testing Razorpay Options Configuration

**User Story:** As a developer, I want to verify Razorpay options are configured correctly, so that I can ensure all required parameters are passed.

#### Acceptance Criteria

1. WHEN opening Razorpay_SDK, THE Test_Suite SHALL verify the options include key 'rzp_test_SHXH1wQoOlA037'
2. WHEN opening Razorpay_SDK, THE Test_Suite SHALL verify the options include currency 'INR'
3. WHEN opening Razorpay_SDK, THE Test_Suite SHALL verify the options include name 'Nourisha Pay'
4. WHEN opening Razorpay_SDK, THE Test_Suite SHALL verify the options include description 'Payment for order'
5. WHEN opening Razorpay_SDK, THE Test_Suite SHALL verify the options include prefill contact and email
6. WHEN opening Razorpay_SDK, THE Test_Suite SHALL verify the options include the correct order_id from Order_Detail
7. WHEN opening Razorpay_SDK, THE Test_Suite SHALL verify the options include the correct amount from Order_Detail

### Requirement 20: Manual Testing for App State Preservation

**User Story:** As a QA tester, I want to test app state preservation, so that I can verify retry payment handles app lifecycle events correctly.

#### Acceptance Criteria

1. THE Manual_Test_Procedure SHALL include steps to minimize the app during payment and verify state is preserved
2. THE Manual_Test_Procedure SHALL include steps to rotate the device during payment and verify the flow continues
3. THE Manual_Test_Procedure SHALL include steps to receive a phone call during payment and verify the app recovers
4. THE Manual_Test_Procedure SHALL include steps to verify payment data persists after app backgrounding
5. THE Manual_Test_Procedure SHALL include expected behavior for each app lifecycle scenario
