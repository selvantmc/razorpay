# Implementation Plan: Retry Payment Testing

## Overview

This plan implements comprehensive testing for the retry payment feature in the Order Lookup Screen. The implementation covers widget tests, integration tests, property-based tests, and manual testing documentation. All tests will use mocked dependencies (Razorpay SDK and PaymentApi) to ensure fast, reliable, and isolated test execution.

## Tasks

- [x] 1. Set up test infrastructure and dependencies
  - Add mockito and build_runner to dev_dependencies in pubspec.yaml
  - Add faker package for test data generation (optional but recommended)
  - Run `flutter pub get` to install dependencies
  - _Requirements: 12.1_

- [ ] 2. Create mock implementations and test data
  - [ ] 2.1 Create mock Razorpay SDK wrapper
    - Create `test/mocks/mock_razorpay.dart` with MockRazorpay class
    - Implement RazorpayInterface abstract class for dependency injection
    - Add methods to simulate success, error, and wallet events
    - Track all SDK method calls for verification
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 12.1, 12.2, 12.3, 12.4, 12.5_
  
  - [ ] 2.2 Create mock PaymentApi
    - Create `test/mocks/mock_payment_api.dart` using mockito annotations
    - Generate mocks with `flutter pub run build_runner build`
    - _Requirements: 9.1, 9.2, 9.3_
  
  - [ ] 2.3 Create test data fixtures and generators
    - Create `test/mocks/test_data.dart` with OrderDetail fixtures
    - Implement fixed test data for all order statuses (created, failed, authorized, paid, captured, verified)
    - Implement random data generators for property-based tests
    - _Requirements: 11.1, 11.2, 18.4_

- [ ] 3. Refactor OrderLookupScreen for testability
  - [ ] 3.1 Add dependency injection for Razorpay SDK
    - Modify OrderLookupScreen constructor to accept optional RazorpayInterface parameter
    - Update _initState to use injected Razorpay or create default instance
    - Ensure backward compatibility with existing code
    - _Requirements: 2.1, 2.5_
  
  - [ ] 3.2 Add dependency injection for PaymentApi
    - Modify OrderLookupScreen to accept optional PaymentApi parameter
    - Update API calls to use injected instance or default singleton
    - _Requirements: 9.1, 9.2, 9.3_

- [ ] 4. Implement widget tests for retry button visibility
  - [ ] 4.1 Write tests for retry button visibility with unpaid orders
    - Test status 'created' shows retry button
    - Test status 'failed' shows retry button
    - Test status 'authorized' shows retry button
    - _Requirements: 1.1, 1.2, 1.7_
  
  - [ ] 4.2 Write tests for retry button hidden with paid orders
    - Test status 'paid' hides retry button
    - Test status 'captured' hides retry button
    - Test status 'verified' hides retry button
    - _Requirements: 1.3, 1.4, 1.5_
  
  - [ ] 4.3 Write test for retry button hidden when no order loaded
    - _Requirements: 1.6_
  
  - [ ]* 4.4 Write property test for retry button visibility
    - **Property 1: Retry Payment Button Visibility for Unpaid Orders**
    - **Validates: Requirements 1.1, 1.2, 1.7**

- [ ] 5. Implement widget tests for Razorpay SDK initialization
  - [ ] 5.1 Write tests for SDK initialization and handler registration
    - Test Razorpay SDK is instantiated on screen init
    - Test payment success handler is registered
    - Test payment error handler is registered
    - Test external wallet handler is registered
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 5.2 Write test for SDK cleanup on disposal
    - Test Razorpay SDK clear() is called when screen is disposed
    - _Requirements: 2.5_

- [ ] 6. Implement widget tests for retry button interactions
  - [ ] 6.1 Write tests for Razorpay SDK invocation
    - Test tapping retry button calls Razorpay open() method
    - Test order ID is passed to SDK
    - Test amount in paise is passed to SDK without conversion
    - _Requirements: 3.1, 3.2, 3.3, 13.1, 13.2, 13.3_
  
  - [ ] 6.2 Write tests for Razorpay configuration
    - Test Razorpay key 'rzp_test_SHXH1wQoOlA037' is included
    - Test currency 'INR' is included
    - Test name 'Nourisha Pay' is included
    - Test description 'Payment for order' is included
    - Test prefill contact and email are included
    - _Requirements: 3.4, 3.5, 19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7_
  
  - [ ]* 6.3 Write property test for SDK invocation
    - **Property 3: Razorpay SDK Invocation on Button Tap**
    - **Validates: Requirements 3.1**
  
  - [ ]* 6.4 Write property test for order data integrity
    - **Property 4: Order Data Passed to Razorpay SDK**
    - **Validates: Requirements 3.2, 3.3, 13.3, 19.6, 19.7**
  
  - [ ]* 6.5 Write property test for Razorpay configuration completeness
    - **Property 5: Razorpay Configuration Completeness**
    - **Validates: Requirements 3.4, 3.5, 19.1, 19.2, 19.3, 19.4, 19.5**

- [ ] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement widget tests for payment event handlers
  - [ ] 8.1 Write tests for payment success handler
    - Test order ID is saved to PaymentSession
    - Test payment ID is saved to PaymentSession
    - Test signature is saved to PaymentSession
    - Test auto-verification is triggered
    - Test success message is displayed after verification
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ] 8.2 Write tests for payment error handler
    - Test error message is displayed
    - Test error message contains payment failure details
    - Test error message is visible in UI with error icon
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 8.3 Write tests for external wallet handler
    - Test snackbar is displayed
    - Test snackbar contains wallet name
    - _Requirements: 6.1, 6.2_
  
  - [ ]* 8.4 Write property test for payment data round-trip
    - **Property 6: Payment Data Round-Trip Integrity**
    - **Validates: Requirements 4.1, 4.2, 4.3, 18.1, 18.2, 18.3**
  
  - [ ]* 8.5 Write property test for auto-verification trigger
    - **Property 7: Auto-Verification Trigger on Payment Success**
    - **Validates: Requirements 4.4**
  
  - [ ]* 8.6 Write property test for success message display
    - **Property 8: Success Message Display After Verification**
    - **Validates: Requirements 4.5**
  
  - [ ]* 8.7 Write property test for error message display
    - **Property 9: Error Message Display on Payment Failure**
    - **Validates: Requirements 5.1**
  
  - [ ]* 8.8 Write property test for wallet snackbar display
    - **Property 10: Snackbar Display on External Wallet Selection**
    - **Validates: Requirements 6.1**

- [ ] 9. Implement widget tests for action button visibility
  - [ ] 9.1 Write tests for action buttons when needsAction is true
    - Test Verify Payment button is visible
    - Test Check Payment Status button is visible
    - _Requirements: 14.1, 14.2_
  
  - [ ] 9.2 Write tests for action buttons when needsAction is false
    - Test Verify Payment button is not visible
    - Test Check Payment Status button is not visible
    - Test Actions section is not displayed for paid orders
    - _Requirements: 14.3, 14.4, 14.5_
  
  - [ ]* 9.3 Write property test for action buttons visibility
    - **Property 13: Action Buttons Visible When Action Needed**
    - **Validates: Requirements 14.1, 14.2**
  
  - [ ]* 9.4 Write property test for action buttons hidden
    - **Property 14: Action Buttons Hidden When No Action Needed**
    - **Validates: Requirements 14.3, 14.4**

- [ ] 10. Implement widget tests for error handling and display
  - [ ] 10.1 Write tests for network error handling
    - Test timeout error displays "Request timed out. Please try again."
    - Test connection error displays "No internet connection."
    - Test verification network error displays error message
    - Test manual retry is available after verification failure
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
  
  - [ ] 10.2 Write tests for error UI rendering
    - Test error message displays in red error card
    - Test error icon is visible
    - Test error prefix "Exception: " is removed from display
    - _Requirements: 15.1, 15.2, 15.5_
  
  - [ ] 10.3 Write tests for error clearing behavior
    - Test new fetch operation clears previous errors
    - Test new action operation clears previous errors
    - _Requirements: 15.3, 15.4_
  
  - [ ]* 10.4 Write property test for network error handling
    - **Property 11: Network Error Handling**
    - **Validates: Requirements 9.3**
  
  - [ ]* 10.5 Write property test for error UI rendering
    - **Property 16: Error UI Rendering**
    - **Validates: Requirements 15.1, 15.2**
  
  - [ ]* 10.6 Write property test for error clearing
    - **Property 17: Error Clearing on New Operations**
    - **Validates: Requirements 15.3, 15.4**
  
  - [ ]* 10.7 Write property test for error prefix removal
    - **Property 18: Error Message Prefix Removal**
    - **Validates: Requirements 15.5**

- [ ] 11. Implement widget tests for state management
  - [ ] 11.1 Write tests for clearLocalData behavior
    - Test clearLocalData clears error messages
    - Test clearLocalData clears result messages
    - Test clearLocalData preserves order details
    - Test tab switching invokes clearLocalData
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  
  - [ ]* 11.2 Write property test for state clearing
    - **Property 12: State Clearing Behavior**
    - **Validates: Requirements 10.1, 10.2, 10.3**

- [ ] 12. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Implement widget tests for loading states
  - [ ] 13.1 Write tests for loading indicators
    - Test fetch order button shows loading indicator during fetch
    - Test verify payment button shows loading indicator during verification
    - Test check status button shows loading indicator during status check
    - Test retry payment button does not show loading indicator
    - Test loading indicators are removed after operation completes
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_
  
  - [ ]* 13.2 Write property test for loading indicator lifecycle
    - **Property 20: Loading Indicator Lifecycle**
    - **Validates: Requirements 17.1, 17.2, 17.3, 17.5**

- [ ] 14. Implement widget tests for amount handling and display
  - [ ] 14.1 Write tests for amount display formatting
    - Test amount displays with ₹ symbol
    - Test amount displays with 2 decimal places
    - Test various amounts format correctly
    - _Requirements: 13.4_
  
  - [ ]* 14.2 Write property test for amount display
    - **Property 19: Amount Display Formatting**
    - **Validates: Requirements 13.4**

- [ ] 15. Implement widget tests for needsAction logic
  - [ ] 15.1 Write tests for needsAction correctness
    - Test needsAction returns true for 'created', 'failed', 'authorized'
    - Test needsAction returns false for 'paid', 'captured', 'verified'
    - _Requirements: 11.1, 11.2_
  
  - [ ] 15.2 Write tests for UI behavior based on needsAction
    - Test 'created' order shows both retry and verify buttons
    - Test 'paid' order shows no action buttons
    - Test 'authorized' order shows verify button but not retry button
    - _Requirements: 11.3, 11.4, 11.5_
  
  - [ ]* 15.3 Write property test for needsAction correctness
    - **Property 15: needsAction Correctness**
    - **Validates: Requirements 11.1, 11.2**

- [ ] 16. Implement integration tests for complete flows
  - [ ] 16.1 Create integration test file
    - Create `test/screens/order_lookup_screen_integration_test.dart`
    - Set up test harness with mocked dependencies
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ] 16.2 Write integration test for complete retry payment flow
    - Test entering order ID and fetching order
    - Test order details are displayed
    - Test retry button appears for unpaid order
    - Test tapping retry button invokes Razorpay SDK
    - Test payment success triggers auto-verification
    - Test verification result is displayed
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ] 16.3 Write integration test for payment cancellation flow
    - Test retry payment flow
    - Test simulating payment cancellation
    - Test error message is displayed
    - _Requirements: 5.1, 5.2_
  
  - [ ] 16.4 Write integration test for network error flow
    - Test order fetch with timeout error
    - Test error message is displayed
    - Test retry capability
    - _Requirements: 9.1, 9.2, 9.4_
  
  - [ ]* 16.5 Write property test for order serialization
    - **Property 21: Order Serialization Round-Trip**
    - **Validates: Requirements 18.4**

- [ ] 17. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 18. Create manual testing documentation
  - [ ] 18.1 Create manual test procedure file
    - Create `test/manual/retry_payment_manual_test.md`
    - Document test environment setup
    - Include Razorpay test mode configuration
    - List test payment credentials
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8_
  
  - [ ] 18.2 Document basic retry payment scenarios
    - Steps to create unpaid order
    - Steps to navigate to Order Lookup Screen
    - Steps to verify retry button visibility
    - Steps to complete payment
    - Steps to verify auto-verification
    - Steps to verify order status updates
    - Steps to test payment cancellation
    - Steps to test payment failure
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8_
  
  - [ ] 18.3 Document payment method testing procedures
    - Steps to test with test credit card (4111 1111 1111 1111)
    - Steps to test with test UPI ID (success@razorpay)
    - Steps to test with test debit card
    - Steps to test with external wallet selection
    - Expected results for each payment method
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5_
  
  - [ ] 18.4 Document app lifecycle testing procedures
    - Steps to test app minimization during payment
    - Steps to test device rotation during payment
    - Steps to test incoming phone call during payment
    - Steps to verify payment data persistence
    - Expected behavior for each scenario
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_

- [ ] 19. Configure test coverage and CI/CD integration
  - [ ] 19.1 Set up test coverage reporting
    - Configure coverage exclusions for generated code
    - Add coverage reporting script to project
    - Document how to generate and view coverage reports
    - _Requirements: All requirements (coverage validation)_
  
  - [ ] 19.2 Update CI/CD pipeline configuration
    - Add test execution step to CI pipeline
    - Add coverage reporting to CI pipeline
    - Configure quality gates (minimum coverage thresholds)
    - _Requirements: All requirements (CI validation)_

- [ ] 20. Final checkpoint and documentation
  - [ ] 20.1 Run complete test suite
    - Execute all widget tests
    - Execute all integration tests
    - Execute all property-based tests
    - Verify all tests pass
    - _Requirements: All requirements_
  
  - [ ] 20.2 Generate and review test coverage report
    - Run `flutter test --coverage`
    - Generate HTML coverage report
    - Verify minimum 90% line coverage for OrderLookupScreen
    - Verify minimum 85% branch coverage
    - _Requirements: All requirements_
  
  - [ ] 20.3 Update test documentation
    - Document how to run tests
    - Document test organization and structure
    - Document mock usage patterns
    - Document property-based testing approach
    - _Requirements: All requirements_

## Notes

- Tasks marked with `*` are optional property-based tests that can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties with 100 iterations each
- Unit/widget tests validate specific examples and edge cases
- Integration tests validate end-to-end flows with mocked dependencies
- Manual tests validate real-world scenarios with actual payment processing
- All tests use mocked Razorpay SDK and PaymentApi to ensure fast, reliable execution
- Test coverage target: 90% line coverage, 85% branch coverage for OrderLookupScreen
