# Razorpay Integration Debug Checklist

## 🔍 Root Cause Analysis Complete

### Primary Issue: Mock Order ID
**Status:** ✅ IDENTIFIED  
**Location:** `lib/features/payment/services/backend_api_service.dart`  
**Problem:** App creates fake order IDs (`order_mock_XXXXX`) that don't exist in Razorpay's system  
**Impact:** Razorpay validates order_id and rejects fake ones with "Uh! oh! Something went wrong"  
**Fix:** Implement real backend to create valid Razorpay orders (see BACKEND_IMPLEMENTATION.md)

### Secondary Issue: Missing INTERNET Permission
**Status:** ✅ FIXED  
**Location:** `android/app/src/main/AndroidManifest.xml`  
**Problem:** INTERNET permission only in debug/profile manifests, not main manifest  
**Impact:** Would break Razorpay in release builds  
**Fix:** Added `<uses-permission android:name="android.permission.INTERNET"/>` to main manifest

### Tertiary Issue: Placeholder Razorpay Key
**Status:** ⚠️ USER ACTION REQUIRED  
**Location:** `lib/features/payment/services/payment_service.dart` line 35  
**Problem:** `RAZORPAY_KEY_ID = 'rzp_test_PLACEHOLDER'`  
**Impact:** Invalid key causes Razorpay to reject checkout  
**Fix:** Replace with actual test key from Razorpay Dashboard

---

## ✅ Pre-Flight Checklist

### 1. Backend Setup (CRITICAL)
- [ ] Backend server deployed and accessible
- [ ] Razorpay Key_Secret stored securely on backend (NOT in Flutter)
- [ ] POST /api/payments/create-order endpoint implemented
- [ ] POST /api/payments/verify endpoint implemented
- [ ] GET /api/payments/status endpoint implemented
- [ ] Backend tested with Postman/curl (see BACKEND_IMPLEMENTATION.md)
- [ ] Backend returns valid order_id starting with "order_"

### 2. Flutter App Configuration
- [ ] Razorpay Key_ID replaced in `payment_service.dart` (line 35)
- [ ] Backend URL updated in `razorpay_pos_screen.dart` (line 48)
- [ ] `useMockMode: false` set in `razorpay_pos_screen.dart` (line 49)
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] No compilation errors: `flutter analyze`

### 3. Android Configuration
- [x] INTERNET permission in main AndroidManifest.xml
- [x] minSdkVersion >= 19 (handled by Flutter defaults)
- [x] Razorpay plugin in pubspec.yaml
- [ ] App rebuilt after manifest changes

### 4. Razorpay Account Setup
- [ ] Signed up at https://razorpay.com/
- [ ] Account activated (test mode)
- [ ] Test Key_ID copied from Dashboard → Settings → API Keys
- [ ] Test Key_Secret stored securely on backend
- [ ] Test mode enabled (keys start with rzp_test_)

---

## 🧪 Testing Workflow

### Phase 1: Backend Validation
```bash
# Test order creation
curl -X POST https://your-backend.com/api/payments/create-order \
  -H "Content-Type: application/json" \
  -d '{"amount": 10000, "currency": "INR", "receipt": "test_001"}'

# Expected: {"order_id": "order_XXXXXX", "amount": 10000, ...}
# If you get order_mock_XXXXX, backend is still in mock mode!
```

### Phase 2: Flutter App Testing
1. **Launch App:**
   ```bash
   flutter run
   ```

2. **Check Initialization:**
   - App should NOT show "MOCK MODE ACTIVE" message
   - If it does, `useMockMode` is still true

3. **Test Payment Flow:**
   - Enter amount: `100` (₹100)
   - Enter reference: `test_order_001`
   - Click "Pay Now"
   - **Expected:** Razorpay dialog opens with payment options
   - **If error:** Check logs for error code/message

4. **Complete Test Payment:**
   - Use test card: `4111 1111 1111 1111`
   - CVV: Any 3 digits
   - Expiry: Any future date
   - **Expected:** Success callback with payment_id

5. **Verify Response:**
   - Response panel should show:
     ```json
     {
       "status": "success",
       "paymentId": "pay_XXXXXX",
       "orderId": "order_XXXXXX",
       "signature": "..."
     }
     ```

### Phase 3: Error Handling
1. **Test Failed Payment:**
   - Use test card: `4000 0000 0000 0002` (decline card)
   - **Expected:** Error callback with failure details

2. **Test Status Check:**
   - Click "Check Payment Status"
   - **Expected:** Current payment status from backend

---

## 🐛 Common Errors & Solutions

### Error: "Uh! oh! Something went wrong"

**Possible Causes:**
1. **Mock order_id** (most common)
   - Check: Does order_id start with `order_mock_`?
   - Fix: Implement real backend

2. **Invalid Razorpay Key_ID**
   - Check: Is key still `rzp_test_PLACEHOLDER`?
   - Fix: Replace with actual test key

3. **Order doesn't exist in Razorpay**
   - Check: Backend logs for order creation errors
   - Fix: Verify backend Razorpay credentials

4. **Network issues**
   - Check: Is backend accessible from device?
   - Fix: Test backend URL in browser

### Error: "Payment service not initialized"

**Cause:** PaymentService initialization failed  
**Fix:** Check console logs for initialization errors

### Error: "Order creation failed"

**Cause:** Backend API call failed  
**Fix:** 
- Verify backend URL is correct
- Check backend logs
- Ensure backend is running
- Test backend endpoint with curl

### Error: No response after payment

**Cause:** Callback handlers not registered  
**Fix:** Verify Razorpay instance initialized in PaymentService constructor

---

## 📊 Success Criteria

### ✅ Payment Flow Working When:

1. **Order Creation:**
   - Backend returns valid order_id (starts with `order_`)
   - Amount matches request (in paise)
   - Currency is INR

2. **Razorpay Checkout:**
   - Dialog opens without errors
   - Shows "Nourisha POS" as merchant name
   - Displays correct amount
   - Shows payment options (cards, UPI, wallets)

3. **Payment Completion:**
   - Success callback triggered
   - payment_id received (starts with `pay_`)
   - signature received
   - Response displayed in app

4. **Payment Verification:**
   - Backend verifies signature successfully
   - Status check returns correct payment status
   - Transaction recorded in your database

---

## 🔧 Debug Commands

### Check Flutter Logs
```bash
flutter run --verbose
```

### Check Android Logs
```bash
adb logcat | grep -i razorpay
```

### Test Backend Connectivity
```bash
curl -v https://your-backend.com/api/payments/create-order
```

### Verify Razorpay Key
```bash
# Key should start with rzp_test_ for test mode
echo $RAZORPAY_KEY_ID
```

---

## 📞 Next Steps

### If Payment Still Fails:

1. **Capture Error Details:**
   - Check Flutter console for error logs
   - Note exact error code and message
   - Check backend logs for API errors

2. **Verify Each Component:**
   - Backend: Test with Postman
   - Flutter: Check initialization logs
   - Razorpay: Verify account status

3. **Contact Support:**
   - Razorpay Support: https://razorpay.com/support/
   - Include: error code, order_id, timestamp
   - Attach: backend logs, Flutter logs

---

## 🎯 Final Validation

Run this complete test:

```bash
# 1. Clean build
flutter clean
flutter pub get

# 2. Rebuild app
flutter run

# 3. Test payment
# - Enter amount: 100
# - Click Pay Now
# - Complete payment with test card
# - Verify success response

# 4. Check status
# - Click Check Payment Status
# - Verify payment shows as captured/authorized
```

**Success = Razorpay dialog opens → Payment completes → Success callback received**

---

## 📝 Implementation Status

- [x] Android INTERNET permission added
- [x] HTTP package added to pubspec.yaml
- [x] Backend API service updated with real HTTP calls
- [x] Error logging improved
- [x] Mock mode flag added
- [ ] Backend server deployed (USER ACTION REQUIRED)
- [ ] Razorpay Key_ID replaced (USER ACTION REQUIRED)
- [ ] useMockMode set to false (USER ACTION REQUIRED)
- [ ] End-to-end payment tested (PENDING BACKEND)
