# 5-Minute Backend Setup Guide

## 🎯 Goal
Run a simple local server that creates valid Razorpay orders for your Flutter app.

---

## 📋 Prerequisites

You need Node.js installed. Check if you have it:
```bash
node --version
```

If not installed, download from: https://nodejs.org/ (get LTS version)

---

## 🚀 Setup Steps (5 minutes)

### Step 1: Install Dependencies (2 minutes)

Open terminal in your project folder and run:

```bash
npm init -y
npm install express razorpay cors
```

This installs the required packages.

### Step 2: Add Your Razorpay Credentials (1 minute)

Open `backend_server.js` and replace these lines (around line 11-12):

```javascript
// FROM:
key_id: 'rzp_test_YOUR_KEY_ID',
key_secret: 'YOUR_KEY_SECRET'

// TO:
key_id: 'rzp_test_XXXXXXXXXX',  // Your actual test Key_ID
key_secret: 'YYYYYYYYYYYY'       // Your actual test Key_Secret
```

**Where to find these:**
1. Go to https://razorpay.com/
2. Login to your account
3. Go to Settings → API Keys
4. Copy both test keys

### Step 3: Start the Server (10 seconds)

```bash
node backend_server.js
```

You should see:
```
╔════════════════════════════════════════════════════════════╗
║  🚀 Razorpay Backend Server Running                        ║
║  📍 URL: http://localhost:3000                             ║
╚════════════════════════════════════════════════════════════╝
```

**Keep this terminal window open!** The server needs to run while you test.

### Step 4: Find Your Computer's IP Address (1 minute)

Your phone needs to connect to your computer. Find your IP:

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" (e.g., 192.168.1.100)

**Mac/Linux:**
```bash
ifconfig
```
Look for "inet" (e.g., 192.168.1.100)

### Step 5: Update Flutter App (1 minute)

Open `lib/features/payment/screens/razorpay_pos_screen.dart`

Find this code (around line 48):
```dart
final backendApi = BackendApiService(
  baseUrl: 'https://api.nourisha.com',
  useMockMode: true,
);
```

Change to:
```dart
final backendApi = BackendApiService(
  baseUrl: 'http://YOUR_COMPUTER_IP:3000',  // Use IP from Step 4
  useMockMode: false,  // ✅ Disable mock mode
);
```

Example:
```dart
final backendApi = BackendApiService(
  baseUrl: 'http://192.168.1.100:3000',
  useMockMode: false,
);
```

### Step 6: Rebuild Flutter App

```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ Testing

1. **Test Backend First:**
   ```bash
   curl -X POST http://localhost:3000/api/payments/create-order \
     -H "Content-Type: application/json" \
     -d '{"amount": 10000, "currency": "INR"}'
   ```
   
   Expected response:
   ```json
   {
     "order_id": "order_XXXXXX",
     "amount": 10000,
     "currency": "INR"
   }
   ```

2. **Test Flutter App:**
   - Open app on your phone
   - Enter amount: 100
   - Click "Pay Now"
   - Razorpay dialog should open successfully
   - Use test card: 4111 1111 1111 1111
   - Complete payment

3. **Test Status Check:**
   - After payment, click "Check Payment Status"
   - Should show payment details from Razorpay

---

## 🐛 Troubleshooting

### Error: "Cannot connect to backend"

**Cause:** Phone can't reach your computer  
**Fix:**
1. Make sure phone and computer are on same WiFi
2. Check firewall isn't blocking port 3000
3. Verify IP address is correct

**Windows Firewall Fix:**
```bash
# Allow Node.js through firewall
netsh advfirewall firewall add rule name="Node.js Server" dir=in action=allow protocol=TCP localport=3000
```

### Error: "Order creation failed"

**Cause:** Invalid Razorpay credentials  
**Fix:**
1. Double-check Key_ID and Key_Secret in backend_server.js
2. Make sure you're using TEST keys (start with rzp_test_)
3. Check Razorpay dashboard for any account issues

### Error: "EADDRINUSE: Port 3000 already in use"

**Cause:** Another app is using port 3000  
**Fix:** Change port in backend_server.js:
```javascript
const PORT = 3001; // Use different port
```

---

## 📱 Testing Payment Failure Recovery

To test what happens when internet fails during payment:

1. **Start a payment:**
   - Enter amount
   - Click "Pay Now"
   - Razorpay dialog opens

2. **Simulate failure:**
   - Turn off WiFi/mobile data during payment
   - Or close app during payment

3. **Check status:**
   - Reopen app
   - Click "Check Payment Status"
   - Backend will query Razorpay and show actual status

This is exactly what you wanted - the app can check Razorpay's servers to see if payment actually went through, even if the callback was lost.

---

## 🔒 Security Notes

**For Testing Only:**
- This setup is for local testing only
- Don't expose this server to the internet
- Don't commit Key_Secret to git

**For Production:**
- Deploy backend to proper hosting (Heroku, AWS, etc.)
- Use environment variables for credentials
- Add authentication/authorization
- Use HTTPS only

---

## 🎯 What This Gives You

✅ **Valid Razorpay orders** - Real order_id from Razorpay  
✅ **Payment processing** - Razorpay SDK works correctly  
✅ **Status recovery** - Check payment status even if callback fails  
✅ **Internet failure handling** - Query Razorpay to verify payment  
✅ **Test mode** - No real money charged  

---

## 💡 Quick Reference

**Start server:**
```bash
node backend_server.js
```

**Stop server:**
Press `Ctrl+C` in terminal

**Test backend:**
```bash
curl http://localhost:3000/health
```

**Flutter app URL:**
```dart
baseUrl: 'http://YOUR_COMPUTER_IP:3000'
useMockMode: false
```

---

## 📞 Need Help?

If you get stuck:
1. Check backend terminal for error messages
2. Check Flutter console for error logs
3. Verify phone and computer are on same network
4. Test backend with curl first before testing Flutter app

---

**Estimated Setup Time:** 5 minutes  
**Result:** Working Razorpay payment integration with status recovery
