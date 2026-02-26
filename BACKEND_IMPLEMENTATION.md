# Backend Implementation Guide for Razorpay Integration

## 🎯 Critical: Backend is REQUIRED for Razorpay to Work

The Flutter app currently uses **MOCK MODE** which creates fake order IDs. Razorpay rejects these, causing the "Uh! oh! Something went wrong" error.

**You MUST implement a real backend** to create valid Razorpay orders.

---

## 📋 Backend Requirements

### Security Architecture
- Backend holds Razorpay **Key_Secret** (NEVER in Flutter app)
- Flutter app only has **Key_ID** (public key)
- All Razorpay API calls requiring Key_Secret happen on backend

### Required Endpoints

1. **POST /api/payments/create-order** - Create Razorpay order
2. **POST /api/payments/verify** - Verify payment signature
3. **GET /api/payments/status** - Check payment status

---

## 🔧 Implementation Examples

### Node.js + Express Implementation

```javascript
const express = require('express');
const Razorpay = require('razorpay');
const crypto = require('crypto');

const app = express();
app.use(express.json());

// Initialize Razorpay with your credentials
const razorpay = new Razorpay({
  key_id: 'rzp_test_YOUR_KEY_ID',
  key_secret: 'YOUR_KEY_SECRET' // NEVER expose this to Flutter
});

// 1. Create Order Endpoint
app.post('/api/payments/create-order', async (req, res) => {
  try {
    const { amount, currency, receipt } = req.body;

    // Validate input
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    // Create Razorpay order
    const order = await razorpay.orders.create({
      amount: amount, // amount in paise
      currency: currency || 'INR',
      receipt: receipt || `receipt_${Date.now()}`,
      payment_capture: 1 // Auto capture
    });

    // Return order details to Flutter app
    res.status(201).json({
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
      receipt: order.receipt
    });

  } catch (error) {
    console.error('Order creation failed:', error);
    res.status(500).json({ 
      error: 'Order creation failed',
      message: error.message 
    });
  }
});

// 2. Verify Payment Endpoint
app.post('/api/payments/verify', async (req, res) => {
  try {
    const { order_id, payment_id, signature } = req.body;

    // Generate expected signature
    const body = order_id + '|' + payment_id;
    const expectedSignature = crypto
      .createHmac('sha256', razorpay.key_secret)
      .update(body)
      .digest('hex');

    // Compare signatures
    const isValid = expectedSignature === signature;

    if (isValid) {
      // Payment is authentic - update your database
      console.log('✅ Payment verified:', payment_id);
      res.json({ verified: true, payment_id });
    } else {
      console.log('❌ Invalid signature');
      res.status(400).json({ verified: false, error: 'Invalid signature' });
    }

  } catch (error) {
    console.error('Verification failed:', error);
    res.status(500).json({ 
      verified: false,
      error: 'Verification failed' 
    });
  }
});

// 3. Check Payment Status Endpoint
app.get('/api/payments/status', async (req, res) => {
  try {
    const { order_id, payment_id } = req.query;

    if (payment_id) {
      // Fetch payment details from Razorpay
      const payment = await razorpay.payments.fetch(payment_id);
      
      res.json({
        order_id: payment.order_id,
        payment_id: payment.id,
        status: payment.status,
        amount: payment.amount,
        currency: payment.currency,
        method: payment.method,
        paid_at: payment.created_at
      });
    } else if (order_id) {
      // Fetch order details
      const order = await razorpay.orders.fetch(order_id);
      
      res.json({
        order_id: order.id,
        payment_id: null,
        status: order.status,
        amount: order.amount,
        currency: order.currency,
        paid_at: null
      });
    } else {
      res.status(400).json({ error: 'order_id or payment_id required' });
    }

  } catch (error) {
    console.error('Status check failed:', error);
    res.status(500).json({ 
      error: 'Status check failed',
      message: error.message 
    });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Backend running on port ${PORT}`);
});
```

### PHP Implementation

```php
<?php
require 'vendor/autoload.php';

use Razorpay\Api\Api;

// Initialize Razorpay
$api = new Api('rzp_test_YOUR_KEY_ID', 'YOUR_KEY_SECRET');

// 1. Create Order Endpoint
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $_SERVER['REQUEST_URI'] === '/api/payments/create-order') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $amount = $input['amount'] ?? 0;
    $currency = $input['currency'] ?? 'INR';
    $receipt = $input['receipt'] ?? 'receipt_' . time();
    
    if ($amount <= 0) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid amount']);
        exit;
    }
    
    try {
        $order = $api->order->create([
            'amount' => $amount,
            'currency' => $currency,
            'receipt' => $receipt,
            'payment_capture' => 1
        ]);
        
        http_response_code(201);
        echo json_encode([
            'order_id' => $order->id,
            'amount' => $order->amount,
            'currency' => $order->currency,
            'receipt' => $order->receipt
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'error' => 'Order creation failed',
            'message' => $e->getMessage()
        ]);
    }
    exit;
}

// 2. Verify Payment Endpoint
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $_SERVER['REQUEST_URI'] === '/api/payments/verify') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $order_id = $input['order_id'];
    $payment_id = $input['payment_id'];
    $signature = $input['signature'];
    
    $body = $order_id . '|' . $payment_id;
    $expectedSignature = hash_hmac('sha256', $body, 'YOUR_KEY_SECRET');
    
    $isValid = hash_equals($expectedSignature, $signature);
    
    echo json_encode(['verified' => $isValid]);
    exit;
}

// 3. Check Payment Status Endpoint
if ($_SERVER['REQUEST_METHOD'] === 'GET' && $_SERVER['REQUEST_URI'] === '/api/payments/status') {
    $payment_id = $_GET['payment_id'] ?? null;
    $order_id = $_GET['order_id'] ?? null;
    
    try {
        if ($payment_id) {
            $payment = $api->payment->fetch($payment_id);
            echo json_encode([
                'order_id' => $payment->order_id,
                'payment_id' => $payment->id,
                'status' => $payment->status,
                'amount' => $payment->amount,
                'currency' => $payment->currency
            ]);
        } elseif ($order_id) {
            $order = $api->order->fetch($order_id);
            echo json_encode([
                'order_id' => $order->id,
                'payment_id' => null,
                'status' => $order->status,
                'amount' => $order->amount,
                'currency' => $order->currency
            ]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit;
}
?>
```

---

## 🚀 Deployment Steps

### 1. Install Dependencies

**Node.js:**
```bash
npm install express razorpay cors
```

**PHP:**
```bash
composer require razorpay/razorpay
```

### 2. Set Environment Variables

```bash
export RAZORPAY_KEY_ID=rzp_test_YOUR_KEY_ID
export RAZORPAY_KEY_SECRET=YOUR_KEY_SECRET
```

### 3. Enable CORS (for Flutter web testing)

**Node.js:**
```javascript
const cors = require('cors');
app.use(cors());
```

**PHP:**
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');
```

### 4. Deploy Backend

Options:
- **Heroku**: `git push heroku main`
- **AWS Lambda**: Use serverless framework
- **DigitalOcean**: Deploy on droplet
- **Local Testing**: `node server.js` or `php -S localhost:3000`

### 5. Update Flutter App

In `lib/features/payment/screens/razorpay_pos_screen.dart`:

```dart
final backendApi = BackendApiService(
  baseUrl: 'https://your-backend-url.com', // Your deployed backend URL
  useMockMode: false, // ✅ Enable real mode
);
```

---

## ✅ Testing Checklist

### Backend Testing (Use Postman/curl)

1. **Test Order Creation:**
```bash
curl -X POST https://your-backend-url.com/api/payments/create-order \
  -H "Content-Type: application/json" \
  -d '{"amount": 10000, "currency": "INR", "receipt": "test_001"}'
```

Expected response:
```json
{
  "order_id": "order_MXXXXXxxxxxx",
  "amount": 10000,
  "currency": "INR",
  "receipt": "test_001"
}
```

2. **Test Payment Verification:**
```bash
curl -X POST https://your-backend-url.com/api/payments/verify \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "order_XXXXXX",
    "payment_id": "pay_XXXXXX",
    "signature": "generated_signature"
  }'
```

3. **Test Status Check:**
```bash
curl "https://your-backend-url.com/api/payments/status?order_id=order_XXXXXX"
```

### Flutter App Testing

1. Update backend URL in Flutter app
2. Set `useMockMode: false`
3. Add valid Razorpay Key_ID
4. Run `flutter clean && flutter pub get`
5. Run `flutter run`
6. Test payment flow:
   - Enter amount (e.g., 100 for ₹100)
   - Click "Pay Now"
   - Razorpay dialog should open successfully
   - Complete test payment
   - Verify success callback

---

## 🔒 Security Best Practices

1. **Never expose Key_Secret** in Flutter code or version control
2. **Use environment variables** for sensitive credentials
3. **Validate all inputs** on backend before calling Razorpay
4. **Implement rate limiting** to prevent abuse
5. **Log all transactions** for audit trail
6. **Use HTTPS only** for production
7. **Verify webhook signatures** if using Razorpay webhooks

---

## 📞 Support

- Razorpay Docs: https://razorpay.com/docs/api/
- Razorpay Support: https://razorpay.com/support/
- Test Cards: https://razorpay.com/docs/payments/payments/test-card-details/
