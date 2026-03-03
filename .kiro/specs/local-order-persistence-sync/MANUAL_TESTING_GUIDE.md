# Manual Testing Guide: Local Order Persistence & Sync

## Overview
This guide provides step-by-step instructions for manually testing the complete end-to-end flow of the local order persistence and synchronization system.

**Test Date:** _____________  
**Tester:** _____________  
**Device/Emulator:** _____________  
**Flutter Version:** _____________

---

## Prerequisites

### 1. Backend Setup
- [ ] Backend Lambda functions are deployed and accessible
- [ ] AppSync GraphQL API is configured
- [ ] Razorpay webhook is configured to trigger backend Lambda
- [ ] Test Razorpay account is active with valid API keys

### 2. App Configuration
- [ ] Razorpay Key_ID is configured in `payment_service.dart`
- [ ] Backend API endpoint is configured in `backend_api_service.dart`
- [ ] Amplify configuration is set up for AppSync

### 3. Testing Tools
- [ ] Device/emulator with internet connection
- [ ] Ability to toggle airplane mode (for offline testing)
- [ ] Access to backend logs (CloudWatch) for webhook verification
- [ ] Access to AppSync console for subscription monitoring

---

## Test Scenario 1: Happy Path - Create Order → Pay → Verify Subscription Update

### Objective
Verify that a successful payment flow creates a local order, establishes a subscription, receives webhook updates, and displays the correct status.

### Steps

1. **Launch the app**
   - [ ] App starts without errors
   - [ ] Check console logs for: "App initialization: Found X pending orders"
   - [ ] Check console logs for: "App initialization: Resubscription complete"

2. **Navigate to payment screen**
   - [ ] Payment screen loads successfully
   - [ ] Enter amount (e.g., ₹100)

3. **Initiate payment**
   - [ ] Click "Pay Now" button
   - [ ] Observe console logs:
     ```
     SubscriptionService: Attempting to subscribe to order order_XXXXX
     SubscriptionService: Subscription established for order_XXXXX
     SubscriptionService: Successfully subscribed to order order_XXXXX
     ```
   - [ ] Razorpay checkout opens

4. **Complete payment**
   - [ ] Use test card: 4111 1111 1111 1111
   - [ ] CVV: Any 3 digits
   - [ ] Expiry: Any future date
   - [ ] Click "Pay" in Razorpay

5. **Verify Razorpay callback**
   - [ ] Observe console log: "💳 Razorpay callback received - Verifying payment..."
   - [ ] App shows "Verifying payment..." state (if UI implemented)

6. **Verify subscription update (within 20 seconds)**
   - [ ] Observe console logs:
     ```
     SubscriptionService: Received update for order order_XXXXX
     SubscriptionService: Parsed order data - status: paid, updatedAt: XXXXX
     SubscriptionService: Successfully updated order order_XXXXX with status paid
     SubscriptionService: Order order_XXXXX reached final status paid, cancelling subscription
     SubscriptionService: Cancelled subscription for order_XXXXX
     ```
   - [ ] Payment success screen appears
   - [ ] Status badge shows "PAID" in green

7. **Verify notification (if app in background)**
   - [ ] Put app in background before payment completes
   - [ ] Complete payment
   - [ ] Notification appears: "Payment Successful - ₹100.00"
   - [ ] Tap notification
   - [ ] App navigates to order details screen

8. **Verify local storage**
   - [ ] Restart the app
   - [ ] Navigate to order history (if implemented)
   - [ ] Order appears with status "paid"
   - [ ] Order details match payment (amount, orderId, paymentId)

### Expected Results
- ✅ Order created locally with status "pending"
- ✅ Subscription established before Razorpay opens
- ✅ Subscription receives update from webhook within 20 seconds
- ✅ Local storage updated with status "paid"
- ✅ Subscription auto-cancelled after final status
- ✅ Notification shown (if app in background)
- ✅ UI updates reactively to show "PAID" status
- ✅ Order persists after app restart

### Notes
_Record any observations, issues, or unexpected behavior:_

---

## Test Scenario 2: App Restart with Pending Order → Verify Resubscription

### Objective
Verify that pending orders are automatically resubscribed when the app restarts.

### Steps

1. **Create a pending order**
   - [ ] Launch app
   - [ ] Initiate payment (amount: ₹50)
   - [ ] Razorpay checkout opens
   - [ ] **Close Razorpay without completing payment** (press back button)
   - [ ] Order remains in "pending" state

2. **Force close the app**
   - [ ] Swipe app away from recent apps
   - [ ] Or use `flutter run` and press 'q' to quit

3. **Restart the app**
   - [ ] Launch app again
   - [ ] Observe console logs:
     ```
     App initialization: Found 1 pending orders
     App initialization: Resubscribing to order order_XXXXX
     SubscriptionService: Attempting to subscribe to order order_XXXXX
     SubscriptionService: Subscription established for order_XXXXX
     App initialization: Resubscription complete
     ```

4. **Complete the payment externally**
   - [ ] If possible, trigger webhook manually via backend
   - [ ] Or create a new payment with same orderId

5. **Verify subscription receives update**
   - [ ] Observe console logs showing subscription update
   - [ ] Order status updates to "paid"
   - [ ] Notification appears (if app in background)

### Expected Results
- ✅ App queries pending orders on startup
- ✅ Subscription re-established for each pending order
- ✅ Subscription receives updates after restart
- ✅ Order status updates correctly
- ✅ No duplicate subscriptions created

### Notes
_Record any observations:_

---

## Test Scenario 3: Timeout Fallback to Polling

### Objective
Verify that if subscription doesn't receive an update within 20 seconds, the system falls back to polling `getOrderStatus`.

### Steps

1. **Simulate subscription delay**
   - [ ] Option A: Temporarily disable AppSync subscriptions in backend
   - [ ] Option B: Add artificial delay in webhook processing
   - [ ] Option C: Test with slow network connection

2. **Initiate payment**
   - [ ] Launch app
   - [ ] Start payment (amount: ₹75)
   - [ ] Complete Razorpay payment

3. **Observe timeout behavior**
   - [ ] Razorpay callback fires: "💳 Razorpay callback received - Verifying payment..."
   - [ ] Wait 20 seconds
   - [ ] Observe console log: "⏱️ Subscription timeout - Falling back to polling"
   - [ ] Observe console log: "✅ Payment status polled: paid"

4. **Verify polling result**
   - [ ] Local storage updated with polled status
   - [ ] UI shows "PAID" status
   - [ ] Payment success screen appears

### Expected Results
- ✅ System waits 20 seconds for subscription update
- ✅ After timeout, `getOrderStatus` is called
- ✅ Polled status updates local storage
- ✅ UI reflects final status
- ✅ No errors or crashes

### Notes
_Record any observations:_

---

## Test Scenario 4: Offline Mode (Local Data Access)

### Objective
Verify that the app can access locally stored order data when offline.

### Steps

1. **Create orders while online**
   - [ ] Complete 2-3 successful payments
   - [ ] Verify orders are stored locally

2. **Enable airplane mode**
   - [ ] Turn on airplane mode on device
   - [ ] Or disable Wi-Fi and mobile data

3. **Restart the app**
   - [ ] Force close and relaunch app
   - [ ] App should start without errors (may show subscription errors, which is expected)

4. **Access order history**
   - [ ] Navigate to order history screen (if implemented)
   - [ ] Or check that StatusBadge widgets display correctly
   - [ ] Verify all previously completed orders are visible
   - [ ] Verify order details are accessible

5. **Attempt new payment (should fail gracefully)**
   - [ ] Try to initiate new payment
   - [ ] Should show network error or timeout
   - [ ] App should not crash

6. **Re-enable connectivity**
   - [ ] Turn off airplane mode
   - [ ] Wait for network to reconnect
   - [ ] Verify subscriptions re-establish (check logs)

### Expected Results
- ✅ App starts successfully in offline mode
- ✅ Previously stored orders are accessible
- ✅ Order details display correctly from local storage
- ✅ StatusBadge shows correct status from Hive
- ✅ New payments fail gracefully with error message
- ✅ Subscriptions re-establish when connectivity returns

### Notes
_Record any observations:_

---

## Test Scenario 5: Payment Failure Flow

### Objective
Verify that failed payments are handled correctly with proper status updates and notifications.

### Steps

1. **Initiate payment**
   - [ ] Launch app
   - [ ] Start payment (amount: ₹25)
   - [ ] Razorpay checkout opens

2. **Trigger payment failure**
   - [ ] Use test card that triggers failure (if available)
   - [ ] Or click "Cancel" in Razorpay
   - [ ] Or press back button

3. **Verify failure handling**
   - [ ] Observe console log: "🔴 Razorpay Payment Error:"
   - [ ] Error code and message logged
   - [ ] Payment failure screen appears (if implemented)

4. **Verify local storage**
   - [ ] Order status should be "failed" (if webhook updates)
   - [ ] Or remain "pending" (if user cancelled before payment)

5. **Verify notification (if status changes to failed)**
   - [ ] If webhook updates status to "failed", notification should appear
   - [ ] Notification: "Payment Failed - ₹25.00"

### Expected Results
- ✅ Payment failure captured correctly
- ✅ Error details logged for debugging
- ✅ Local storage reflects failure status (if webhook updates)
- ✅ Notification shown for failed status (if app in background)
- ✅ UI shows appropriate error message

### Notes
_Record any observations:_

---

## Test Scenario 6: Concurrent Updates & Timestamp Conflict Resolution

### Objective
Verify that the system correctly handles concurrent updates using timestamp comparison.

### Steps

1. **Create an order**
   - [ ] Initiate payment (amount: ₹150)
   - [ ] Note the orderId from console logs

2. **Simulate stale update**
   - [ ] This requires backend manipulation or debugging tools
   - [ ] Option A: Manually trigger webhook with older timestamp
   - [ ] Option B: Use backend testing tools to send stale update

3. **Verify timestamp comparison**
   - [ ] Observe console log: "Warning: Discarded stale update for order..."
   - [ ] Local storage should NOT be updated with stale data
   - [ ] Current status should remain unchanged

4. **Send newer update**
   - [ ] Trigger webhook with newer timestamp
   - [ ] Verify update is accepted
   - [ ] Local storage updated successfully

### Expected Results
- ✅ Stale updates (older timestamp) are discarded
- ✅ Warning logged for discarded updates
- ✅ Newer updates (newer timestamp) are accepted
- ✅ Local storage maintains data consistency

### Notes
_Record any observations:_

---

## Test Scenario 7: Subscription Retry Logic

### Objective
Verify that subscription failures trigger retry logic (up to 3 attempts with 5-second delays).

### Steps

1. **Simulate subscription failure**
   - [ ] Temporarily disable AppSync endpoint
   - [ ] Or configure invalid AppSync credentials
   - [ ] Or test with no network connectivity

2. **Initiate payment**
   - [ ] Launch app
   - [ ] Start payment (amount: ₹200)

3. **Observe retry behavior**
   - [ ] Console logs should show:
     ```
     SubscriptionService: Failed to subscribe to order order_XXXXX (attempt 1/3)
     SubscriptionService: Retrying in 5 seconds...
     SubscriptionService: Failed to subscribe to order order_XXXXX (attempt 2/3)
     SubscriptionService: Retrying in 5 seconds...
     SubscriptionService: Failed to subscribe to order order_XXXXX (attempt 3/3)
     SubscriptionService: All retry attempts exhausted for order order_XXXXX
     ```

4. **Verify fallback behavior**
   - [ ] After 3 failed attempts, error is thrown
   - [ ] Payment flow should still continue (Razorpay opens)
   - [ ] Fallback to polling should work after Razorpay callback

### Expected Results
- ✅ Subscription retries up to 3 times
- ✅ 5-second delay between retries
- ✅ Error thrown after all attempts exhausted
- ✅ Payment flow continues despite subscription failure
- ✅ Polling fallback works as backup

### Notes
_Record any observations:_

---

## Test Scenario 8: Multiple Orders & Subscription Management

### Objective
Verify that the system correctly manages multiple concurrent orders and their subscriptions.

### Steps

1. **Create multiple orders**
   - [ ] Initiate payment #1 (amount: ₹50)
   - [ ] Don't complete payment, press back
   - [ ] Initiate payment #2 (amount: ₹75)
   - [ ] Don't complete payment, press back
   - [ ] Initiate payment #3 (amount: ₹100)
   - [ ] Complete this payment

2. **Verify subscription count**
   - [ ] Check console logs for active subscriptions
   - [ ] Should have 3 subscriptions initially
   - [ ] After payment #3 completes, should have 2 subscriptions (order #3 cancelled)

3. **Restart app**
   - [ ] Force close and relaunch
   - [ ] Verify resubscription to 2 pending orders (orders #1 and #2)
   - [ ] Order #3 should NOT be resubscribed (status is "paid")

4. **Complete remaining orders**
   - [ ] Complete payment for order #1
   - [ ] Verify subscription cancelled
   - [ ] Complete payment for order #2
   - [ ] Verify subscription cancelled

5. **Verify cleanup**
   - [ ] All subscriptions should be cancelled
   - [ ] No memory leaks or hanging connections

### Expected Results
- ✅ Multiple subscriptions managed correctly
- ✅ Each order has its own subscription
- ✅ Subscriptions auto-cancel on final status
- ✅ Resubscription only for pending orders
- ✅ No duplicate subscriptions
- ✅ Proper cleanup of all resources

### Notes
_Record any observations:_

---

## Performance & Resource Monitoring

### Metrics to Track

1. **Subscription Latency**
   - [ ] Time from webhook trigger to subscription update received: _______ ms
   - [ ] Expected: < 2 seconds

2. **Polling Fallback**
   - [ ] Time from Razorpay callback to polling initiated: _______ seconds
   - [ ] Expected: ~20 seconds

3. **App Startup Time**
   - [ ] Time to complete resubscription on app start: _______ ms
   - [ ] Expected: < 1 second per pending order

4. **Memory Usage**
   - [ ] Memory usage with 0 subscriptions: _______ MB
   - [ ] Memory usage with 5 subscriptions: _______ MB
   - [ ] Memory leak check: Run app for 30 minutes with multiple orders

5. **Battery Impact**
   - [ ] Battery drain with active subscriptions: _______ % per hour
   - [ ] Compare with baseline (no subscriptions)

---

## Known Issues & Limitations

Document any known issues discovered during testing:

1. **Issue:** _____________
   - **Severity:** High / Medium / Low
   - **Reproducible:** Yes / No
   - **Steps to reproduce:** _____________
   - **Workaround:** _____________

2. **Issue:** _____________
   - **Severity:** High / Medium / Low
   - **Reproducible:** Yes / No
   - **Steps to reproduce:** _____________
   - **Workaround:** _____________

---

## Test Summary

### Overall Results

- **Total Test Scenarios:** 8
- **Passed:** _______
- **Failed:** _______
- **Blocked:** _______
- **Not Tested:** _______

### Critical Issues Found
_List any critical issues that block release:_

### Recommendations
_Provide recommendations for next steps:_

---

## Sign-Off

**Tester Signature:** _____________  
**Date:** _____________  

**Reviewer Signature:** _____________  
**Date:** _____________  

---

## Appendix: Useful Commands

### Flutter Commands
```bash
# Run app with verbose logging
flutter run -v

# Run app on specific device
flutter run -d <device-id>

# Clear app data (Android)
flutter run --clear-cache

# View device logs
flutter logs
```

### Debugging Commands
```bash
# Check Hive database contents (requires dev tools)
# Use Hive browser in Flutter DevTools

# Monitor AppSync subscriptions
# Check AWS AppSync console → Queries → Subscriptions

# View backend logs
# Check AWS CloudWatch logs for Lambda functions
```

### Test Data
```
Test Card Numbers:
- Success: 4111 1111 1111 1111
- Failure: Check Razorpay test card documentation
- CVV: Any 3 digits
- Expiry: Any future date
```
