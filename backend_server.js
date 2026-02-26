// Minimal Razorpay Backend Server for Testing
// This creates valid Razorpay orders so your Flutter app can process payments

const express = require('express');
const Razorpay = require('razorpay');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors()); // Allow Flutter app to connect

// ⚠️ REPLACE THESE WITH YOUR ACTUAL RAZORPAY CREDENTIALS
const razorpay = new Razorpay({
  key_id: 'rzp_test_YOUR_KEY_ID',        // Replace with your Key_ID
  key_secret: 'YOUR_KEY_SECRET'          // Replace with your Key_Secret
});

// Create Order Endpoint
app.post('/api/payments/create-order', async (req, res) => {
  try {
    const { amount, currency, receipt } = req.body;

    console.log(`📝 Creating order: ₹${amount / 100} (${amount} paise)`);

    // Create Razorpay order
    const order = await razorpay.orders.create({
      amount: amount,
      currency: currency || 'INR',
      receipt: receipt || `receipt_${Date.now()}`,
    });

    console.log(`✅ Order created: ${order.id}`);

    res.status(201).json({
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
      receipt: order.receipt
    });

  } catch (error) {
    console.error('❌ Order creation failed:', error.message);
    res.status(500).json({ 
      error: 'Order creation failed',
      message: error.message 
    });
  }
});

// Check Payment Status Endpoint
app.get('/api/payments/status', async (req, res) => {
  try {
    const { payment_id, order_id } = req.query;

    if (payment_id) {
      console.log(`🔍 Checking payment status: ${payment_id}`);
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
      console.log(`🔍 Checking order status: ${order_id}`);
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
      res.status(400).json({ error: 'payment_id or order_id required' });
    }

  } catch (error) {
    console.error('❌ Status check failed:', error.message);
    res.status(500).json({ 
      error: 'Status check failed',
      message: error.message 
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend server is running' });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║  🚀 Razorpay Backend Server Running                        ║
║                                                            ║
║  📍 URL: http://localhost:${PORT}                            ║
║  📍 From device: http://YOUR_COMPUTER_IP:${PORT}             ║
║                                                            ║
║  ✅ Ready to create Razorpay orders                        ║
╚════════════════════════════════════════════════════════════╝

⚠️  IMPORTANT: Update your Flutter app with this URL:
    - Open: lib/features/payment/screens/razorpay_pos_screen.dart
    - Change baseUrl to: 'http://YOUR_COMPUTER_IP:${PORT}'
    - Set useMockMode: false

💡 To find your computer's IP:
   Windows: ipconfig (look for IPv4 Address)
   Mac/Linux: ifconfig (look for inet)
  `);
});
