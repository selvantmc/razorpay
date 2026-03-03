# Quick Testing Checklist

Use this checklist for rapid verification of the local order persistence and sync system.

## Pre-Flight Checks
- [ ] Backend Lambda deployed and accessible
- [ ] AppSync GraphQL configured
- [ ] Razorpay webhook configured
- [ ] App has valid Razorpay Key_ID
- [ ] Device/emulator has internet connection

## Core Functionality Tests

### 1. Happy Path (5 min)
- [ ] Create order → Pay → Status updates to "paid" within 20 seconds
- [ ] Subscription auto-cancels after payment
- [ ] Notification appears (if app in background)
- [ ] Order persists after app restart

### 2. App Restart with Pending Order (3 min)
- [ ] Create pending order (don't complete payment)
- [ ] Restart app
- [ ] Console shows resubscription to pending order
- [ ] Complete payment → Status updates correctly

### 3. Timeout Fallback (2 min)
- [ ] Disable/delay subscription updates
- [ ] Complete payment
- [ ] After 20 seconds, polling kicks in
- [ ] Status updates via polling

### 4. Offline Mode (2 min)
- [ ] Complete payment while online
- [ ] Enable airplane mode
- [ ] Restart app
- [ ] Order history accessible from local storage

### 5. Payment Failure (2 min)
- [ ] Initiate payment
- [ ] Cancel or trigger failure
- [ ] Error logged correctly
- [ ] Status reflects failure (if webhook updates)

## Requirements Coverage

### Requirement 3.1: Local Order Creation ✓
- [ ] Order created locally before Razorpay opens
- [ ] Status: "pending"
- [ ] Saved to Hive

### Requirement 3.2: Subscription Establishment ✓
- [ ] Subscription created before payment
- [ ] Console logs confirm subscription established

### Requirement 3.3: Verifying State ✓
- [ ] "Verifying payment..." shown after Razorpay callback
- [ ] Order NOT marked as paid from callback

### Requirement 3.7: Timeout Fallback ✓
- [ ] 20-second timeout implemented
- [ ] Polling triggered after timeout
- [ ] Status updated from polling result

### Requirement 4.1: Resubscription on Restart ✓
- [ ] Pending orders queried on app start
- [ ] Subscriptions re-established
- [ ] Console logs confirm resubscription

### Requirement 4.2: Subscription Logic ✓
- [ ] Same subscription logic used for initial and resubscription
- [ ] No duplicate subscriptions

### Requirement 6.1: Notifications ✓
- [ ] Notification shown when status → "paid"
- [ ] Notification shown when status → "failed"
- [ ] No notification if app in foreground

## Console Log Verification

Look for these key log messages:

### App Startup
```
✓ App initialization: Found X pending orders
✓ App initialization: Resubscribing to order order_XXXXX
✓ SubscriptionService: Subscription established for order_XXXXX
✓ App initialization: Resubscription complete
```

### Payment Flow
```
✓ SubscriptionService: Successfully subscribed to order order_XXXXX
✓ 💳 Razorpay callback received - Verifying payment...
✓ SubscriptionService: Received update for order order_XXXXX
✓ SubscriptionService: Successfully updated order order_XXXXX with status paid
✓ SubscriptionService: Order order_XXXXX reached final status paid, cancelling subscription
```

### Timeout Fallback
```
✓ ⏱️ Subscription timeout - Falling back to polling
✓ ✅ Payment status polled: paid
```

### Errors (Expected in Some Scenarios)
```
✓ Warning: Discarded stale update for order... (timestamp conflict)
✓ SubscriptionService: Failed to subscribe... (retry logic)
✓ 🔴 Razorpay Payment Error: (payment failure)
```

## Quick Smoke Test (2 min)

Minimal test to verify system is working:

1. [ ] Launch app (no errors)
2. [ ] Initiate payment (₹10)
3. [ ] Complete payment with test card
4. [ ] Status updates to "paid" within 20 seconds
5. [ ] Restart app (order still shows "paid")

**Result:** PASS / FAIL

## Issues Found

| Issue | Severity | Requirement | Status |
|-------|----------|-------------|--------|
|       |          |             |        |
|       |          |             |        |
|       |          |             |        |

## Sign-Off

**Tested by:** _____________  
**Date:** _____________  
**Result:** PASS / FAIL / BLOCKED  
**Notes:** _____________
