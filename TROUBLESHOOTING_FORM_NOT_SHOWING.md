# Troubleshooting: Payment Form Not Showing

## Issue Description
After app boots, the payment form doesn't appear - stuck on loading screen.

---

## ✅ Fixes Applied

### 1. Enhanced Error Logging
Added detailed logging to initialization to help diagnose the issue:

```dart
print('✅ Payment service initialized successfully');
// OR
print('❌ Initialization error: $e');
print('Stack trace: $stackTrace');
```

### 2. Safer Initialization
Moved PaymentService creation outside setState to avoid potential issues:

```dart
final paymentService = PaymentService(
  backendApi: backendApi,
  prefs: prefs,
);

setState(() {
  _paymentService = paymentService;
  _isInitializing = false;
});
```

---

## 🔍 Diagnostic Steps

### Step 1: Check Console Logs

Run the app and watch the console:

```bash
flutter run
```

**Look for:**
- ✅ `Payment service initialized successfully` - Initialization worked
- ❌ `Initialization error: ...` - Shows what went wrong
- ❌ Stack trace - Shows where error occurred

### Step 2: Common Causes

#### Cause 1: Razorpay SDK Initialization Failure
**Symptom:** Error mentioning Razorpay or native code

**Solution:**
1. Ensure Razorpay plugin is properly installed:
   ```bash
   flutter clean
   flutter pub get
   ```
2. Rebuild the app completely
3. Check Android permissions in manifest

#### Cause 2: SharedPreferences Failure
**Symptom:** Error mentioning SharedPreferences or storage

**Solution:**
1. Check app has storage permissions
2. Try clearing app data on device
3. Reinstall the app

#### Cause 3: Network/Backend Issue
**Symptom:** Timeout or connection error

**Solution:**
1. Check device has internet connection
2. Verify AWS Lambda URL is accessible
3. Check firewall/network restrictions

#### Cause 4: Missing Razorpay Key
**Symptom:** App initializes but Razorpay fails

**Solution:**
Add your actual Razorpay Key_ID in `payment_service.dart`:
```dart
static const String RAZORPAY_KEY_ID = 'rzp_test_YOUR_ACTUAL_KEY';
```

---

## 🧪 Testing Scenarios

### Test 1: Check Loading Screen
1. Launch app
2. Should see:
   - Animated gradient background
   - Glass card with orbital loader
   - "Nourisha POS" text
   - "Connecting to backend..." text

**If stuck here:** Check console for initialization error

### Test 2: Check Main Screen
After 1-2 seconds, should see:
- App bar with "Nourisha POS"
- Status banner "AWS Lambda · Connected"
- Amount input card
- Reference input card
- Pay Now button
- Check Status button
- Response panel

**If not appearing:** Initialization failed, check logs

### Test 3: Manual Initialization Test
Add this temporary code to test initialization:

```dart
@override
void initState() {
  super.initState();
  _testInitialization();
}

Future<void> _testInitialization() async {
  print('🔍 Testing initialization...');
  
  try {
    print('1. Getting SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences OK');
    
    print('2. Creating BackendApiService...');
    final backendApi = BackendApiService(
      baseUrl: 'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com',
      useMockMode: false,
    );
    print('✅ BackendApiService OK');
    
    print('3. Creating PaymentService...');
    final paymentService = PaymentService(
      backendApi: backendApi,
      prefs: prefs,
    );
    print('✅ PaymentService OK');
    
    print('🎉 All initialization steps passed!');
  } catch (e, stack) {
    print('❌ Initialization failed at some step');
    print('Error: $e');
    print('Stack: $stack');
  }
}
```

---

## 🔧 Quick Fixes

### Fix 1: Force Initialization to Complete
If initialization is hanging, add a timeout:

```dart
Future<void> _initializePaymentService() async {
  try {
    await Future.any([
      _doInitialization(),
      Future.delayed(const Duration(seconds: 5), () {
        throw TimeoutException('Initialization timeout');
      }),
    ]);
  } catch (e) {
    print('❌ Init error: $e');
    setState(() {
      _isInitializing = false;
      _responseText = 'Initialization error: $e\n\nTap to retry';
    });
  }
}
```

### Fix 2: Add Retry Button
If initialization fails, show retry option:

```dart
if (_responseText.contains('error')) {
  ElevatedButton(
    onPressed: () {
      setState(() => _isInitializing = true);
      _initializePaymentService();
    },
    child: const Text('Retry Initialization'),
  ),
}
```

### Fix 3: Skip Razorpay Init for Testing
Temporarily disable Razorpay to test UI:

```dart
// In payment_service.dart, comment out Razorpay init:
void _initializeRazorpay() {
  // _razorpay = Razorpay();  // Temporarily disabled
  // _razorpay.on(...);
  print('⚠️ Razorpay init skipped for testing');
}
```

---

## 📱 Platform-Specific Issues

### Android
1. **Check permissions** in `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.REORDER_TASKS" />
   ```

2. **Check minSdkVersion** in `build.gradle`:
   ```gradle
   minSdk = 21  // Razorpay requires API 21+
   ```

3. **Rebuild completely**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter run
   ```

### iOS
1. **Check Info.plist** has required keys
2. **Run pod install**:
   ```bash
   cd ios
   pod install
   cd ..
   flutter run
   ```

---

## 🐛 Known Issues

### Issue 1: Razorpay Plugin Not Found
**Error:** `MissingPluginException(No implementation found for method...)`

**Fix:**
```bash
flutter clean
flutter pub get
# Restart IDE
flutter run
```

### Issue 2: Native Code Crash
**Error:** App crashes immediately on launch

**Fix:**
1. Check Android logs: `adb logcat`
2. Look for native exceptions
3. Ensure Razorpay plugin is compatible with your Flutter version

### Issue 3: Hot Reload Issues
**Error:** Form shows after full restart but not after hot reload

**Fix:**
- This is normal - always do full restart after changing initialization code
- Use `flutter run` instead of hot reload for testing

---

## ✅ Verification Checklist

After applying fixes, verify:

- [ ] App launches without crash
- [ ] Console shows "✅ Payment service initialized successfully"
- [ ] Loading screen appears with orbital loader
- [ ] Loading screen disappears after 1-2 seconds
- [ ] Main screen appears with all components
- [ ] Amount input is visible and functional
- [ ] Pay Now button is visible
- [ ] No error messages in console

---

## 🚀 Next Steps

### If Form Still Not Showing:

1. **Share console logs** - Copy full console output
2. **Check device logs** - Run `adb logcat` (Android) or Console.app (iOS)
3. **Try on different device** - Test on emulator vs physical device
4. **Check Flutter version** - Ensure compatible with Razorpay plugin

### If Form Shows But Payment Fails:

1. **Check Razorpay Key_ID** - Must be actual test key
2. **Test amount fix** - Enter ₹100, verify shows ₹100 (not ₹10,000)
3. **Check network** - Ensure device can reach AWS Lambda
4. **Review Lambda logs** - Check CloudWatch for backend errors

---

## 📞 Debug Commands

```bash
# Check Flutter setup
flutter doctor -v

# Check dependencies
flutter pub deps

# Clean everything
flutter clean
flutter pub get

# Run with verbose logging
flutter run -v

# Check device logs (Android)
adb logcat | grep -i flutter

# Check device logs (iOS)
# Open Console.app and filter by device
```

---

## 💡 Most Likely Causes

Based on common issues:

1. **70% chance**: Razorpay SDK initialization failing (missing key or plugin issue)
2. **20% chance**: SharedPreferences or storage permission issue
3. **10% chance**: Network/backend connectivity issue

**Quick test:** Add `print` statements in initialization and check console output.

---

**Status:** Enhanced logging added ✅ | Ready for debugging 🔍
