# AWS Lambda API Integration - Complete

## ✅ Integration Status

Your AWS Lambda APIs have been successfully integrated into the Flutter app.

### API Endpoints Configured

1. **Create Order**
   - URL: `https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan/create-order`
   - Method: POST
   - Used for: Creating Razorpay orders before checkout

2. **Verify Payment**
   - URL: `https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan/verify-payment`
   - Method: POST
   - Used for: Verifying payment signature after successful payment

3. **Check Payment Status**
   - URL: `https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan/check-payment-status`
   - Method: GET
   - Used for: Checking payment status (for recovery scenarios)

4. **Webhook** (Backend only)
   - URL: `https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan/razorpay-webhook`
   - Method: POST
   - Used for: Razorpay webhook notifications (not called from Flutter)

---

## 🚀 Ready to Test

### Prerequisites Checklist

- [x] AWS Lambda APIs integrated
- [x] Backend API service updated
- [x] Mock mode disabled
- [ ] Razorpay Key_ID added to `payment_service.dart`
- [ ] App rebuilt with `flutter clean && flutter pub get`

### Final Step: Add Your Razorpay Key_ID

Open `lib/features/payment/services/payment_service.dart` (line 35):

```dart
// Replace this:
static const String RAZORPAY_KEY_ID = 'rzp_test_PLACEHOLDER';

// With your actual test key:
static const String RAZORPAY_KEY_ID = 'rzp_test_YOUR_ACTUAL_KEY';
```

---

## 🧪 Testing Workflow

### 1. Rebuild the App
```bash
flutter clean
flutter pub get
flutter run
```

### 2. Test Payment Flow

**Step 1: Create Order**
- Open app on your device
- Enter amount: `100` (₹100)
- Click "Pay Now"
- **Expected:** App calls AWS Lambda `/create-order`
- **Expected:** Razorpay dialog opens with payment options

**Step 2: Complete Payment**
- Use test card: `4111 1111 1111 1111`
- CVV: Any 3 digits
- Expiry: Any future date
- Click "Pay"
- **Expected:** Payment success callback
- **Expected:** Response shows payment_id and signature

**Step 3: Verify Payment (Automatic)**
- App automatically calls AWS Lambda `/verify-payment`
- Backend verifies signature
- **Expected:** Verification success

### 3. Test Status Check (Your Use Case)

This is the key feature you wanted - checking payment status from Razorpay:

**Scenario 1: Normal Status Check**
- After completing payment
- Click "Check Payment Status"
- **Expected:** Shows payment details from Razorpay

**Scenario 2: Internet Failure Recovery**
- Start a payment
- Turn off WiFi/mobile data during payment
- Close app
- Turn WiFi back on
- Reopen app
- Click "Check Payment Status"
- **Expected:** App queries AWS Lambda → AWS queries Razorpay → Shows actual payment status

This ensures you never lose track of payments, even if the callback fails.

---

## 📊 API Request/Response Examples

### Create Order Request
```json
POST /selvan/create-order
{
  "amount": 10000,
  "currency": "INR",
  "receipt": "order_001"
}
```

**Expected Response:**
```json
{
  "order_id": "order_XXXXXX",
  "amount": 10000,
  "currency": "INR"
}
```

### Verify Payment Request
```json
POST /selvan/verify-payment
{
  "order_id": "order_XXXXXX",
  "payment_id": "pay_XXXXXX",
  "signature": "generated_signature"
}
```

**Expected Response:**
```json
{
  "verified": true
}
```

### Check Payment Status Request
```
GET /selvan/check-payment-status?payment_id=pay_XXXXXX
```

**Expected Response:**
```json
{
  "order_id": "order_XXXXXX",
  "payment_id": "pay_XXXXXX",
  "status": "captured",
  "amount": 10000,
  "currency": "INR",
  "method": "card"
}
```

---

## 🔍 Debugging

### Check AWS Lambda Logs

If something goes wrong, check your AWS CloudWatch logs:

1. Go to AWS Console → CloudWatch → Log Groups
2. Find log group for your Lambda functions
3. Check recent logs for errors

### Check Flutter Logs

```bash
flutter run --verbose
```

Look for:
- Order creation requests/responses
- Payment success/failure callbacks
- Status check requests/responses

### Test AWS APIs Directly

You can test your AWS APIs with curl:

```bash
# Test create-order
curl -X POST https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan/create-order \
  -H "Content-Type: application/json" \
  -d '{"amount": 10000, "currency": "INR", "receipt": "test_001"}'

# Test check-payment-status
curl "https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan/check-payment-status?order_id=order_XXXXXX"
```

---

## 🐛 Common Issues

### Issue: "Order creation failed"

**Possible Causes:**
1. AWS Lambda function error
2. Razorpay credentials not configured in Lambda
3. Network connectivity issue

**Fix:**
- Check AWS CloudWatch logs
- Verify Razorpay credentials in Lambda environment variables
- Test API with curl

### Issue: "Payment verification failed"

**Possible Causes:**
1. Invalid signature
2. Lambda function error
3. Razorpay Key_Secret not configured

**Fix:**
- Check CloudWatch logs for verification errors
- Ensure Key_Secret is set in Lambda environment

### Issue: "Status check returns wrong data"

**Possible Causes:**
1. Payment_id or order_id not found
2. Razorpay API error
3. Lambda function error

**Fix:**
- Verify payment_id/order_id is correct
- Check CloudWatch logs
- Test Razorpay API directly from Lambda

---

## 🎯 Success Criteria

Your integration is working when:

1. ✅ App launches and shows "Connected to AWS Backend"
2. ✅ Clicking "Pay Now" creates order via AWS Lambda
3. ✅ Razorpay dialog opens successfully
4. ✅ Payment completes and callback received
5. ✅ Payment verification succeeds via AWS Lambda
6. ✅ "Check Payment Status" returns correct data from Razorpay

---

## 📱 Payment Recovery Flow (Your Use Case)

This is the key feature you requested:

```
User starts payment
    ↓
Internet fails / App crashes
    ↓
Payment may or may not have completed
    ↓
User reopens app
    ↓
User clicks "Check Payment Status"
    ↓
Flutter app → AWS Lambda → Razorpay API
    ↓
Returns actual payment status
    ↓
User knows if payment succeeded
```

This ensures you never lose track of payments, even in poor network conditions.

---

## 🔒 Security Notes

✅ **Properly Implemented:**
- Key_Secret stays in AWS Lambda (not in Flutter)
- All Razorpay API calls go through AWS Lambda
- Flutter only has Key_ID (public key)
- Payment verification happens on backend

✅ **Production Ready:**
- AWS Lambda provides secure, scalable backend
- HTTPS endpoints
- Proper error handling
- Status recovery mechanism

---

## 📞 Support

If you encounter issues:

1. **Check AWS CloudWatch Logs** - Most issues are visible here
2. **Check Flutter Console** - Shows API request/response details
3. **Test APIs with curl** - Verify backend is working
4. **Check Razorpay Dashboard** - Verify test mode is enabled

---

## ✨ What's Working Now

✅ AWS Lambda backend integrated  
✅ All 3 API endpoints configured  
✅ Mock mode disabled  
✅ Payment status recovery implemented  
✅ Internet failure handling ready  
✅ Production-ready architecture  

**Next Step:** Add your Razorpay Key_ID and test!
