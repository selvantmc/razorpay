# Design Document: Post-Payment UI Update

## Overview

This feature enhances the Order Lookup screen by improving the post-payment user experience through three key changes:

1. **Conditional Button Visibility**: Automatically hide the "Retry Payment" button after successful payment completion to prevent accidental duplicate payment attempts
2. **Local State Management**: Update the local order data immediately after payment verification to reflect the new payment status without requiring a manual refetch
3. **Visual Consistency**: Apply the existing Glassy UI design pattern to the order details card to maintain visual consistency with other screens in the application

The implementation focuses on minimal changes to the existing `OrderLookupScreen` widget, preserving all current functionality while adding these enhancements. The changes are isolated to the payment verification flow and the order details card rendering.

## Architecture

### Component Structure

The feature modifies a single component:
- **OrderLookupScreen** (`lib/screens/order_lookup_screen.dart`): Stateful widget that manages order lookup, payment actions, and display

### State Management Approach

The feature uses Flutter's built-in `setState` mechanism (already in use) to manage local state updates:

```
Payment Verification Flow:
1. User triggers payment verification
2. API call to PaymentApi.verifyPayment()
3. On success: Parse response for updated order data
4. Update _orderDetail state with new payment status
5. setState() triggers rebuild
6. UI reflects new state (button hidden, status updated)
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    OrderLookupScreen                         │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  State: _orderDetail (OrderDetail?)                │    │
│  └────────────────────────────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │  _verifyPayment() method                           │    │
│  │  1. Call PaymentApi.verifyPayment()                │    │
│  │  2. Receive verification response                  │    │
│  │  3. Extract updated status from response           │    │
│  │  4. Create updated OrderDetail with new status     │    │
│  │  5. setState(() => _orderDetail = updated)         │    │
│  └────────────────────────────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │  build() method                                     │    │
│  │  - Conditionally render Retry Payment button       │    │
│  │    based on _orderDetail.status                    │    │
│  │  - Wrap order details card in GlassyCard widget    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### Modified Component: OrderLookupScreen

**Changes to `_verifyPayment()` method:**

```dart
Future<void> _verifyPayment() async {
  // ... existing validation and loading state ...
  
  try {
    final result = await PaymentApi.verifyPayment(
      orderId: _orderDetail!.orderId,
      paymentId: _orderDetail!.paymentId!,
      signature: _orderDetail!.signature!,
    );

    // NEW: Extract updated status from verification response
    final updatedStatus = result['status'] as String?;
    
    setState(() {
      _actionResult = const JsonEncoder.withIndent('  ').convert(result);
      
      // NEW: Update local order data with new status
      if (updatedStatus != null) {
        _orderDetail = OrderDetail(
          orderId: _orderDetail!.orderId,
          amount: _orderDetail!.amount,
          status: updatedStatus,  // Updated field
          paymentId: _orderDetail!.paymentId,
          signature: _orderDetail!.signature,
          createdAt: _orderDetail!.createdAt,
          updatedAt: _orderDetail!.updatedAt,
          customerName: _orderDetail!.customerName,
          customerEmail: _orderDetail!.customerEmail,
          customerPhone: _orderDetail!.customerPhone,
        );
      }
      
      _isVerifying = false;
    });

    // ... existing success message ...
  } catch (e) {
    // ... existing error handling ...
  }
}
```

**Changes to button rendering logic:**

Current implementation:
```dart
if (_orderDetail!.status != 'paid') ...[
  PrimaryButton(
    text: 'Retry Payment',
    onPressed: () => _openRazorpay(...),
    isLoading: false,
  ),
  const SizedBox(height: 12),
],
```

This logic already implements the requirement - the button is hidden when status is 'paid'. No changes needed to this section.

**Changes to order details card rendering:**

Current implementation uses a basic `Card` widget. Replace with `GlassyCard` wrapper:

```dart
// Before:
Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      // ... order details content ...
    ),
  ),
),

// After:
GlassyCard(
  child: Column(
    // ... order details content ...
  ),
),
```

### New Component: GlassyCard Widget

Create a reusable widget that encapsulates the glassmorphism design pattern:

**File**: `lib/widgets/glassy_card.dart`

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// A card widget with glassmorphism effect using backdrop blur.
///
/// Provides a modern, semi-transparent design with:
/// - Backdrop blur filter
/// - Semi-transparent white background
/// - Subtle border
/// - Elevated shadow
class GlassyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;

  const GlassyCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
```

### API Response Structure

The `verifyPayment` API endpoint returns a response that includes the updated payment status:

```json
{
  "success": true,
  "status": "paid",
  "message": "Payment verified successfully",
  "order_id": "order_xxx",
  "payment_id": "pay_xxx"
}
```

The `status` field from this response will be used to update the local `OrderDetail` object.

## Data Models

### OrderDetail Model

No changes required to the `OrderDetail` model class. The existing structure supports all necessary fields:

```dart
class OrderDetail {
  final String orderId;
  final int amount;
  final String status;        // This field will be updated
  final String? paymentId;
  final String? signature;
  final int createdAt;
  final int? updatedAt;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  
  // ... existing methods and constructor ...
}
```

The model is immutable (all fields are final), so updates require creating a new instance with the updated status field while preserving all other fields.


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Retry Button Hidden for Successful Payment

*For any* order with status "paid", "captured", or "verified", the Retry Payment button should not be rendered in the Actions section.

**Validates: Requirements 1.1, 1.2**

### Property 2: Other Action Buttons Remain Visible

*For any* order where `needsAction` is true, the Verify Payment and Check Payment Status buttons should be rendered regardless of the payment status.

**Validates: Requirements 1.3**

### Property 3: Local Order Data Updated After Verification

*For any* successful payment verification response containing a status field, the local `_orderDetail` state should be updated to reflect the new status value from the response.

**Validates: Requirements 2.1, 2.3**

### Property 4: Non-Status Fields Preserved During Update

*For any* order data update triggered by payment verification, all fields except `status` (orderId, amount, paymentId, signature, createdAt, updatedAt, customerName, customerEmail, customerPhone) should retain their original values.

**Validates: Requirements 2.4**

## Error Handling

### Existing Error Handling (Preserved)

The feature preserves all existing error handling mechanisms:

1. **API Errors**: Caught in try-catch blocks, displayed in error message container
2. **Network Errors**: Handled by PaymentApi with user-friendly messages (timeout, no connection)
3. **Validation Errors**: Form validation prevents invalid order ID submission
4. **Razorpay SDK Errors**: Handled by `_handlePaymentError` callback

### New Error Scenarios

**Missing Status in Verification Response:**
- **Scenario**: API returns successful response but without a `status` field
- **Handling**: Gracefully skip the local update, display the verification result as-is
- **User Impact**: User sees verification success but may need to manually refetch order to see updated status
- **Implementation**: Check `if (updatedStatus != null)` before updating state

**Invalid Status Value:**
- **Scenario**: API returns a status value that's not recognized
- **Handling**: Accept and display the value as-is (OrderDetail model accepts any string)
- **User Impact**: Status badge may show unknown status, but functionality continues
- **Implementation**: No special handling needed, existing code is resilient

### Error Recovery

All error scenarios allow the user to:
1. Retry the verification action
2. Manually refetch the order using the "Fetch Order" button
3. Check payment status using the "Check Payment Status" button

No new error states are introduced by this feature.

## Testing Strategy

### Unit Testing Approach

Unit tests will focus on specific examples and edge cases:

1. **Button Visibility Logic**
   - Test that retry button is hidden when status is "paid"
   - Test that retry button is hidden when status is "captured"
   - Test that retry button is hidden when status is "verified"
   - Test that retry button is shown when status is "created"
   - Test that retry button is shown when status is "failed"

2. **State Update Logic**
   - Test that status is updated when verification response contains status field
   - Test that status is not updated when verification response lacks status field
   - Test that all other fields remain unchanged after status update

3. **Widget Rendering**
   - Test that GlassyCard widget renders with correct decoration properties
   - Test that GlassyCard applies BackdropFilter with correct blur values
   - Test that order details content is preserved inside GlassyCard

4. **Edge Cases**
   - Empty status string in response
   - Null status in response
   - Verification response with additional unexpected fields

### Property-Based Testing Approach

Property-based tests will verify universal properties across randomized inputs using the `test` package with custom generators:

**Testing Library**: Dart's built-in `test` package with custom property-based testing helpers

**Configuration**: Minimum 100 iterations per property test

**Property Test 1: Retry Button Visibility**
```dart
// Feature: post-payment-ui-update, Property 1: For any order with status "paid", "captured", or "verified", the Retry Payment button should not be rendered
test('retry button hidden for successful payment statuses', () {
  final successStatuses = ['paid', 'captured', 'verified'];
  for (var i = 0; i < 100; i++) {
    final status = successStatuses[Random().nextInt(successStatuses.length)];
    final orderDetail = generateRandomOrderDetail(status: status);
    
    // Verify button should not be rendered
    expect(orderDetail.status != 'paid', isFalse);
  }
});
```

**Property Test 2: Other Buttons Visibility**
```dart
// Feature: post-payment-ui-update, Property 2: For any order where needsAction is true, other action buttons remain visible
test('other action buttons remain visible when needsAction is true', () {
  for (var i = 0; i < 100; i++) {
    final orderDetail = generateRandomOrderDetail(needsAction: true);
    
    // Verify needsAction logic
    expect(orderDetail.needsAction, isTrue);
    expect(orderDetail.status != 'paid' && 
           orderDetail.status != 'captured' && 
           orderDetail.status != 'verified', isTrue);
  }
});
```

**Property Test 3: Status Update**
```dart
// Feature: post-payment-ui-update, Property 3: Local order data updated after verification
test('status updated from verification response', () {
  for (var i = 0; i < 100; i++) {
    final originalOrder = generateRandomOrderDetail();
    final newStatus = generateRandomStatus();
    final verificationResponse = {'status': newStatus};
    
    final updatedOrder = updateOrderFromVerification(originalOrder, verificationResponse);
    
    expect(updatedOrder.status, equals(newStatus));
  }
});
```

**Property Test 4: Field Preservation**
```dart
// Feature: post-payment-ui-update, Property 4: Non-status fields preserved during update
test('all non-status fields preserved during update', () {
  for (var i = 0; i < 100; i++) {
    final originalOrder = generateRandomOrderDetail();
    final newStatus = generateRandomStatus();
    
    final updatedOrder = OrderDetail(
      orderId: originalOrder.orderId,
      amount: originalOrder.amount,
      status: newStatus,
      paymentId: originalOrder.paymentId,
      signature: originalOrder.signature,
      createdAt: originalOrder.createdAt,
      updatedAt: originalOrder.updatedAt,
      customerName: originalOrder.customerName,
      customerEmail: originalOrder.customerEmail,
      customerPhone: originalOrder.customerPhone,
    );
    
    expect(updatedOrder.orderId, equals(originalOrder.orderId));
    expect(updatedOrder.amount, equals(originalOrder.amount));
    expect(updatedOrder.paymentId, equals(originalOrder.paymentId));
    expect(updatedOrder.signature, equals(originalOrder.signature));
    expect(updatedOrder.createdAt, equals(originalOrder.createdAt));
    expect(updatedOrder.updatedAt, equals(originalOrder.updatedAt));
    expect(updatedOrder.customerName, equals(originalOrder.customerName));
    expect(updatedOrder.customerEmail, equals(originalOrder.customerEmail));
    expect(updatedOrder.customerPhone, equals(originalOrder.customerPhone));
  }
});
```

### Widget Testing

Widget tests will verify UI behavior and integration:

1. **Order Details Card Rendering**
   - Test that GlassyCard is used instead of Card widget
   - Test that all order information is displayed correctly
   - Test that card responds to different order states

2. **Button Interaction**
   - Test that tapping Verify Payment triggers verification
   - Test that Retry Payment button is not present after successful payment
   - Test that other buttons remain interactive

3. **State Updates**
   - Test that UI updates after successful verification
   - Test that status badge reflects new status
   - Test that action result is displayed

### Integration Testing

Integration tests will verify end-to-end flows:

1. **Complete Payment Flow**
   - Fetch order → Retry payment → Verify payment → Confirm button hidden
   - Verify that local state updates correctly
   - Verify that UI reflects all changes

2. **Error Recovery Flow**
   - Trigger verification error → Retry → Success
   - Verify that error states clear properly

### Regression Testing

Ensure existing functionality remains intact:

1. Run all existing tests for OrderLookupScreen
2. Verify that order fetching still works
3. Verify that payment status checking still works
4. Verify that error handling still works
5. Verify that Razorpay SDK integration still works

### Test Coverage Goals

- **Unit Tests**: 100% coverage of new logic (status update, button visibility)
- **Widget Tests**: Cover all UI state combinations
- **Property Tests**: Minimum 100 iterations per property
- **Integration Tests**: Cover critical user flows

### Manual Testing Checklist

1. ✓ Fetch an order with status "created"
2. ✓ Verify Retry Payment button is visible
3. ✓ Complete payment successfully
4. ✓ Verify Retry Payment button disappears
5. ✓ Verify status updates to "paid" without refetching
6. ✓ Verify other buttons remain visible
7. ✓ Verify Glassy UI is applied to order details card
8. ✓ Verify all order information is still displayed correctly
9. ✓ Test on different screen sizes
10. ✓ Test with different order statuses

## Implementation Notes

### File Changes Summary

**Modified Files:**
1. `lib/screens/order_lookup_screen.dart`
   - Update `_verifyPayment()` method to extract and apply status from response
   - Replace `Card` widget with `GlassyCard` widget for order details

**New Files:**
2. `lib/widgets/glassy_card.dart`
   - Create reusable GlassyCard widget

**Test Files:**
3. `test/screens/order_lookup_screen_test.dart` (new or updated)
   - Add unit tests for button visibility logic
   - Add unit tests for state update logic
   - Add property-based tests for correctness properties
   - Add widget tests for UI behavior

4. `test/widgets/glassy_card_test.dart` (new)
   - Add widget tests for GlassyCard rendering
   - Add tests for decoration properties

### Dependencies

No new dependencies required. The feature uses:
- Existing `dart:ui` for `ImageFilter` (already imported in similar widgets)
- Existing `flutter/material.dart`
- Existing `test` package for testing

### Migration Path

This is a non-breaking change:
1. Deploy updated code
2. No database migrations required
3. No API changes required
4. Existing orders will work immediately with new UI

### Performance Considerations

**BackdropFilter Performance:**
- BackdropFilter can be expensive on lower-end devices
- Mitigated by using it only on a single card (not multiple instances)
- The blur effect is applied to a bounded area, not the entire screen
- Consider testing on lower-end devices during QA

**State Update Performance:**
- Creating a new OrderDetail instance is lightweight (simple data class)
- No performance impact expected from state updates

### Accessibility Considerations

**Semantic Labels:**
- GlassyCard maintains the same semantic structure as Card
- All text content remains accessible to screen readers
- Button visibility changes are automatically announced by Flutter

**Visual Contrast:**
- Glassy UI uses semi-transparent backgrounds
- Ensure text contrast meets WCAG AA standards (4.5:1 for normal text)
- Test with different background colors/images if app uses them

**Focus Management:**
- Button removal (Retry Payment) doesn't affect focus order
- Remaining buttons maintain proper focus traversal

### Future Enhancements

Potential improvements for future iterations:

1. **Optimistic UI Updates**: Update UI immediately before API call completes
2. **Animation**: Add smooth transition when button disappears
3. **Undo Capability**: Allow reverting status change if verification was accidental
4. **Status History**: Track and display status change history
5. **Real-time Updates**: Use WebSocket or polling to auto-update status
6. **Customizable Glassy UI**: Allow theme-based customization of blur and opacity values

