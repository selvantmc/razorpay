# Implementation Plan: Post-Payment UI Update

## Overview

This implementation enhances the Order Lookup screen by hiding the retry payment button after successful payment, updating local order data immediately after verification, and applying the Glassy UI design pattern to the order details card. The changes are minimal and focused on improving the post-payment user experience while maintaining all existing functionality.

## Tasks

- [x] 1. Create GlassyCard reusable widget
  - Create `lib/widgets/glassy_card.dart` file
  - Implement GlassyCard widget with BackdropFilter (sigmaX: 20, sigmaY: 20)
  - Apply semi-transparent white background (opacity 0.08)
  - Add border with white color (opacity 0.18, width 1.5)
  - Add box shadow (black opacity 0.3, blur radius 32, offset (0, 8))
  - Support customizable padding, border radius, and border color parameters
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 1.1 Write widget tests for GlassyCard
  - Test that BackdropFilter is applied with correct blur values
  - Test that decoration properties match specifications
  - Test that child widget is rendered correctly
  - Test customizable parameters (padding, borderRadius, borderColor)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 2. Update OrderLookupScreen to use GlassyCard
  - Import GlassyCard widget in `lib/screens/order_lookup_screen.dart`
  - Replace the existing Card widget wrapping order details with GlassyCard
  - Preserve all existing order details content and layout
  - Ensure padding and styling remain consistent
  - _Requirements: 3.1, 3.6, 3.7_

- [x] 3. Update local order data after payment verification
  - [x] 3.1 Modify `_verifyPayment()` method to extract status from response
    - Extract `status` field from verification response using `result['status'] as String?`
    - Add null check before updating state
    - _Requirements: 2.1, 2.3_
  
  - [x] 3.2 Create updated OrderDetail instance with new status
    - Create new OrderDetail instance with updated status field
    - Preserve all other fields (orderId, amount, paymentId, signature, createdAt, updatedAt, customerName, customerEmail, customerPhone)
    - Update `_orderDetail` state variable within setState()
    - _Requirements: 2.1, 2.2, 2.4_

- [x] 3.3 Write unit tests for status update logic
  - Test that status is updated when verification response contains status field
  - Test that status is not updated when verification response lacks status field
  - Test that all non-status fields remain unchanged after update
  - Test edge cases (empty status string, null status)
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 3.4 Write property test for local order data update
  - **Property 3: Local Order Data Updated After Verification**
  - **Validates: Requirements 2.1, 2.3**
  - Generate random OrderDetail instances and verification responses
  - Verify status is updated from response for 100+ iterations
  - _Requirements: 2.1, 2.3_

- [x] 3.5 Write property test for field preservation
  - **Property 4: Non-Status Fields Preserved During Update**
  - **Validates: Requirements 2.4**
  - Generate random OrderDetail instances with various field values
  - Verify all non-status fields remain unchanged after status update
  - Run for 100+ iterations with different field combinations
  - _Requirements: 2.4_

- [x] 4. Verify retry button visibility logic
  - Review existing button visibility logic in OrderLookupScreen
  - Confirm that `if (_orderDetail!.status != 'paid')` condition correctly hides button
  - Verify that other action buttons (Verify Payment, Check Payment Status) remain visible
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 4.1 Write unit tests for button visibility
  - Test that retry button is hidden when status is "paid"
  - Test that retry button is shown when status is "created" or "failed"
  - Test that other action buttons remain visible regardless of payment status
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 4.2 Write property test for retry button visibility
  - **Property 1: Retry Button Hidden for Successful Payment**
  - **Validates: Requirements 1.1, 1.2**
  - Generate random OrderDetail instances with various statuses
  - Verify button is hidden for "paid", "captured", "verified" statuses
  - Run for 100+ iterations
  - _Requirements: 1.1, 1.2_

- [x] 4.3 Write property test for other buttons visibility
  - **Property 2: Other Action Buttons Remain Visible**
  - **Validates: Requirements 1.3**
  - Generate random OrderDetail instances with needsAction true
  - Verify Verify Payment and Check Payment Status buttons are rendered
  - Run for 100+ iterations
  - _Requirements: 1.3_

- [x] 5. Checkpoint - Ensure all tests pass
  - Run `flutter test` to execute all unit and widget tests
  - Verify no regressions in existing functionality
  - Ensure all tests pass, ask the user if questions arise

- [x] 6. Integration verification
  - [x] 6.1 Test complete payment flow
    - Verify order fetch works correctly
    - Verify payment verification updates local state
    - Verify retry button disappears after successful payment
    - Verify GlassyCard is applied to order details
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 3.1_
  
  - [x] 6.2 Verify existing functionality preserved
    - Test order fetching functionality
    - Test payment status checking functionality
    - Test error handling behavior
    - Test Razorpay SDK integration
    - Verify search input and fetch button behavior unchanged
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

- [x] 7. Final checkpoint - Ensure all tests pass
  - Run `flutter analyze` to check for any issues
  - Run `flutter test` to verify all tests pass
  - Ensure all tests pass, ask the user if questions arise

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- The existing button visibility logic already implements the requirement (status != 'paid'), so task 4 is primarily verification
- All property-based tests should run for minimum 100 iterations
- GlassyCard widget is reusable and can be applied to other screens in the future
- No new dependencies are required for this feature
- BackdropFilter may have performance implications on lower-end devices - consider testing during QA
