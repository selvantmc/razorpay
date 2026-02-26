# Implementation Plan: Razorpay Payment Dashboard

## Overview

This implementation plan breaks down the Razorpay Payment Dashboard into discrete coding tasks. The application is a Flutter mobile application (Android + iOS) that integrates with a Razorpay backend API hosted on AWS Lambda. The implementation follows a bottom-up approach: project setup → models → API layer → shared widgets → screens/tabs → navigation → integration → testing.

## Tasks

- [ ] 1. Project setup and configuration
  - Ensure Flutter SDK is installed (run `flutter doctor`)
  - Update pubspec.yaml with http package dependency (^1.2.0)
  - Run `flutter pub get` to install dependencies
  - Create directory structure: lib/api/, lib/models/, lib/screens/, lib/tabs/, lib/widgets/
  - Configure AndroidManifest.xml with INTERNET permission
  - Verify iOS Info.plist allows HTTPS connections
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [ ] 2. Create data models
  - [ ] 2.1 Implement ApiResponse model
    - Create lib/models/api_response.dart file
    - Define ApiResponse class with data, error, and isLoading properties
    - Implement factory constructors: loading(), success(data), error(message)
    - Use Map<String, dynamic>? for data property
    - Export model
    - _Requirements: 12.1, 12.2_

- [ ] 3. API integration layer
  - [ ] 3.1 Implement PaymentApi class with HTTP methods
    - Create lib/api/payment_api.dart file
    - Define base URL constant: https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan
    - Import http package and dart:convert for JSON handling
    - Set 15-second timeout on all requests using .timeout(Duration(seconds: 15))
    - Implement error handling for SocketException, TimeoutException, and HTTP errors
    - Add Content-Type: application/json header to POST requests
    - _Requirements: 1.4, 12.1, 12.2, 12.3, 12.4, 12.5, 7.2, 7.3_

  - [ ] 3.2 Implement createOrder API method
    - Create static Future<Map<String, dynamic>> createOrder(double amount) method
    - POST to /create-order endpoint with JSON body: {"amount": amount}
    - Parse response and return Map<String, dynamic> on success
    - Throw Exception with descriptive message on failure
    - Handle network errors, timeouts, and non-2xx status codes
    - _Requirements: 2.2_

  - [ ] 3.3 Implement checkPaymentStatus API method
    - Create static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) method
    - GET from /check-payment-status?order_id=<orderId>
    - Parse response and return Map<String, dynamic> on success
    - Throw Exception with descriptive message on failure
    - Handle network errors, timeouts, and non-2xx status codes
    - _Requirements: 3.3_

  - [ ] 3.4 Implement verifyPayment API method
    - Create static Future<Map<String, dynamic>> verifyPayment method
    - Accept named parameters: orderId, paymentId, signature (all required)
    - POST to /verify-payment with JSON body containing all three fields
    - Parse response and return Map<String, dynamic> on success
    - Throw Exception with descriptive message on failure
    - Handle network errors, timeouts, and non-2xx status codes
    - _Requirements: 4.3_

  - [ ]* 3.5 Write property tests for API integration
    - **Property 1: Order Creation API Request**
    - **Validates: Requirements 2.2**
    - **Property 2: Payment Status API Request**
    - **Validates: Requirements 3.3**
    - **Property 3: Payment Verification API Request**
    - **Validates: Requirements 4.3**
    - **Property 14: API URL Construction**
    - **Validates: Requirements 12.2**
    - **Property 15: JSON Content-Type Headers**
    - **Validates: Requirements 12.4**

- [ ] 4. Shared widgets
  - [ ] 4.1 Implement LabeledTextField widget
    - Create lib/widgets/labeled_text_field.dart file
    - Create StatelessWidget accepting: label, hint, controller, keyboardType, maxLines, validator
    - Render Column with bold Text label above TextFormField
    - Use OutlineInputBorder with borderRadius 12
    - Apply Material 3 input decoration theme
    - Export widget
    - _Requirements: 9.1, 9.2, 9.3_

  - [ ] 4.2 Implement PrimaryButton widget
    - Create lib/widgets/primary_button.dart file
    - Create StatelessWidget accepting: label, onPressed, isLoading
    - When isLoading is true: disable button and show CircularProgressIndicator
    - Use full-width ElevatedButton with borderRadius 12
    - Apply Material 3 button styling
    - Export widget
    - _Requirements: 2.5, 3.6, 4.6, 8.1_

  - [ ] 4.3 Implement ResultBox widget
    - Create lib/widgets/result_box.dart file
    - Create StatelessWidget accepting ApiResponse as parameter
    - Implement four rendering states: loading, error, success (data), empty
    - For loading: show LinearProgressIndicator and pulsing grey container
    - For error: show red-bordered container with error icon and message
    - For success: show dark background (#1E1E1E) with green text (Colors.greenAccent.shade100)
    - Use JsonEncoder.withIndent('  ') for pretty-printing JSON
    - Add Copy button that uses Clipboard.setData and shows SnackBar confirmation
    - Make JSON text selectable with SelectableText
    - Use monospace font family for JSON display
    - Implement border color logic: green for success=true, red for success=false or error, grey otherwise
    - Max height constraint of 400 with SingleChildScrollView
    - Export widget
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 2.3, 3.4, 4.4_

  - [ ]* 4.4 Write property tests for shared widgets
    - **Property 8: Copy to Clipboard Functionality**
    - **Validates: Requirements 2.6, 6.5**
    - **Property 9: JSON Formatting**
    - **Validates: Requirements 6.2**

- [ ] 5. HomeScreen implementation
  - [ ] 5.1 Create HomeScreen with form state management
    - Create lib/screens/home_screen.dart file
    - Create StatefulWidget with State class
    - Add TextEditingController for amount field (dispose in dispose() method)
    - Add GlobalKey<FormState> for form validation
    - Add ApiResponse state variable initialized to ApiResponse()
    - Use Scaffold with AppBar title "Place an Order"
    - Wrap body in SingleChildScrollView with Column layout
    - Add padding of 20 around content
    - _Requirements: 2.1, 9.1, 9.2, 9.3, 9.4_

  - [ ] 5.2 Build HomeScreen UI layout
    - Create Card with rounded corners and elevation
    - Add "Create New Order" title text
    - Add subtitle "Enter amount in ₹"
    - Use LabeledTextField for amount input (label: "Amount (₹)", hint: "e.g. 500")
    - Set keyboardType to TextInputType.number
    - Add validator: required, must be number, must be > 0
    - Add SizedBox(height: 16) spacing
    - Add PrimaryButton with label "Create Order"
    - Add SizedBox(height: 24) spacing
    - Add ResultBox widget passing _response state
    - _Requirements: 2.1, 9.1, 9.2, 9.3_

  - [ ] 5.3 Implement _createOrder submission handler
    - Create async _createOrder() method
    - Validate form using _formKey.currentState!.validate()
    - Return early if validation fails
    - Set state to ApiResponse.loading()
    - Parse amount from controller text using double.parse
    - Call PaymentApi.createOrder(amount) in try block
    - On success: set state to ApiResponse.success(data)
    - If data contains orderId: copy to clipboard and show SnackBar "Order ID copied to clipboard!"
    - On error: catch exception and set state to ApiResponse.error(e.toString())
    - Wire PrimaryButton onPressed to _createOrder method
    - Pass _response.isLoading to PrimaryButton isLoading parameter
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 7.1, 7.2, 7.4, 8.2, 8.3, 8.4_

  - [ ] 5.4 Add accessibility features to HomeScreen
    - Wrap interactive widgets with Semantics where needed
    - Ensure TextField has proper label and hint properties
    - Ensure error messages are announced (Material handles this by default)
    - Verify keyboard navigation works (Flutter handles this by default)
    - Set resizeToAvoidBottomInset: true on Scaffold
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ]* 5.5 Write property tests for HomeScreen
    - **Property 4: Successful Response Display**
    - **Validates: Requirements 2.3, 3.4, 4.4**
    - **Property 5: Error Response Display**
    - **Validates: Requirements 2.4, 3.5, 4.5, 7.1, 7.2**
    - **Property 6: Loading State During Async Operations**
    - **Validates: Requirements 2.5, 3.6, 4.6, 8.1, 8.2**
    - **Property 7: Loading State Cleanup After Completion**
    - **Validates: Requirements 8.3, 8.4**

- [ ] 6. Checkpoint - Ensure HomeScreen works end-to-end
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. CheckStatusTab implementation
  - [ ] 7.1 Create CheckStatusTab with form state
    - Create lib/tabs/check_status_tab.dart file
    - Create StatefulWidget with State class
    - Add TextEditingController for orderId field (dispose in dispose() method)
    - Add GlobalKey<FormState> for form validation
    - Add ApiResponse state variable initialized to ApiResponse()
    - Wrap body in SingleChildScrollView with Column layout
    - Add padding of 20 around content
    - _Requirements: 3.1, 3.2_

  - [ ] 7.2 Build CheckStatusTab UI layout
    - Create Card with rounded corners and elevation
    - Add "Check Payment Status" title text
    - Use LabeledTextField for order ID input (label: "Order ID", hint: "order_xxxxx")
    - Set keyboardType to TextInputType.text
    - Add validator: required, must not be empty
    - Add SizedBox(height: 16) spacing
    - Add PrimaryButton with label "Check Status"
    - Add SizedBox(height: 24) spacing
    - Add ResultBox widget passing _response state
    - _Requirements: 3.1, 3.2_

  - [ ] 7.3 Implement _checkStatus submission handler
    - Create async _checkStatus() method
    - Validate form using _formKey.currentState!.validate()
    - Return early if validation fails
    - Set state to ApiResponse.loading()
    - Get trimmed orderId from controller text
    - Call PaymentApi.checkPaymentStatus(orderId) in try block
    - On success: set state to ApiResponse.success(data)
    - On error: catch exception and set state to ApiResponse.error(e.toString())
    - Wire PrimaryButton onPressed to _checkStatus method
    - Pass _response.isLoading to PrimaryButton isLoading parameter
    - _Requirements: 3.3, 3.4, 3.5, 3.6_

  - [ ] 7.4 Add accessibility features to CheckStatusTab
    - Wrap interactive widgets with Semantics where needed
    - Ensure TextField has proper label and hint properties
    - Ensure error messages are announced (Material handles this by default)
    - Verify keyboard navigation works (Flutter handles this by default)
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 8. VerifyPaymentTab implementation
  - [ ] 8.1 Create VerifyPaymentTab with form state
    - Create lib/tabs/verify_payment_tab.dart file
    - Create StatefulWidget with State class
    - Add TextEditingControllers for orderId, paymentId, signature fields (dispose all in dispose() method)
    - Add GlobalKey<FormState> for form validation
    - Add ApiResponse state variable initialized to ApiResponse()
    - Wrap body in SingleChildScrollView with Column layout
    - Add padding of 20 around content
    - _Requirements: 4.1, 4.2_

  - [ ] 8.2 Build VerifyPaymentTab UI layout
    - Create Card with rounded corners and elevation
    - Add "Verify Payment" title text
    - Use LabeledTextField for orderId (label: "Razorpay Order ID", hint: "order_xxxxx")
    - Use LabeledTextField for paymentId (label: "Razorpay Payment ID", hint: "pay_xxxxx")
    - Use LabeledTextField for signature (label: "Razorpay Signature", hint: "Paste signature here", maxLines: 3)
    - Add validator to all fields: required, must not be empty
    - Add Row with two buttons: PrimaryButton "Verify" and OutlinedButton "Clear"
    - Add SizedBox(height: 24) spacing
    - Add ResultBox widget passing _response state
    - _Requirements: 4.1, 4.2_

  - [ ] 8.3 Implement _verifyPayment submission handler
    - Create async _verifyPayment() method
    - Validate form using _formKey.currentState!.validate()
    - Return early if validation fails
    - Set state to ApiResponse.loading()
    - Get trimmed values from all three controllers
    - Call PaymentApi.verifyPayment with named parameters in try block
    - On success: set state to ApiResponse.success(data)
    - Show SnackBar with green background: "Payment verified successfully!" if success=true
    - Show SnackBar with red background: "Verification failed. Check your inputs." if success=false
    - On error: catch exception and set state to ApiResponse.error(e.toString())
    - Wire PrimaryButton onPressed to _verifyPayment method
    - Pass _response.isLoading to PrimaryButton isLoading parameter
    - _Requirements: 4.3, 4.4, 4.5, 4.6_

  - [ ] 8.4 Implement _clearForm method
    - Create _clearForm() method
    - Clear all three TextEditingControllers
    - Reset _response state to ApiResponse()
    - Wire OutlinedButton onPressed to _clearForm method
    - _Requirements: 4.1_

  - [ ] 8.5 Add accessibility features to VerifyPaymentTab
    - Wrap interactive widgets with Semantics where needed
    - Ensure all TextFields have proper label and hint properties
    - Ensure error messages are announced (Material handles this by default)
    - Verify keyboard navigation works (Flutter handles this by default)
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 9. OrdersScreen with TabBar navigation
  - [ ] 9.1 Create OrdersScreen with DefaultTabController
    - Create lib/screens/orders_screen.dart file
    - Create StatelessWidget (no state needed, tabs manage their own state)
    - Wrap in DefaultTabController with length: 2
    - Use Scaffold with AppBar
    - Set AppBar title to "Orders"
    - Add TabBar to AppBar bottom property
    - _Requirements: 3.1, 4.1, 5.1_

  - [ ] 9.2 Configure TabBar and TabBarView
    - Create TabBar with two tabs:
      - Tab 1: Icon Icons.search, text "Check Status"
      - Tab 2: Icon Icons.verified_rounded, text "Verify Payment"
    - Create TabBarView as Scaffold body with two children:
      - CheckStatusTab()
      - VerifyPaymentTab()
    - Apply Material 3 theme colors to tabs
    - _Requirements: 3.1, 4.1, 5.1_

  - [ ] 9.3 Add accessibility features to OrdersScreen
    - Ensure TabBar has proper semantics (Flutter handles this by default)
    - Verify tab navigation is keyboard accessible (Flutter handles this by default)
    - Verify focus management between tabs works correctly
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [ ] 10. Main app setup with BottomNavigationBar
  - [ ] 10.1 Create MainScaffold with bottom navigation
    - Update lib/main.dart file
    - Create MainScaffold StatefulWidget
    - Add _selectedIndex state variable (default: 0)
    - Create Scaffold with BottomNavigationBar
    - Configure BottomNavigationBar with two items:
      - Item 0: Icon Icons.home_rounded, label "Home"
      - Item 1: Icon Icons.receipt_long_rounded, label "Orders"
    - Set currentIndex to _selectedIndex
    - Set onTap to update _selectedIndex using setState
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [ ] 10.2 Implement IndexedStack for state preservation
    - Use IndexedStack as Scaffold body
    - Set index to _selectedIndex
    - Add two children: HomeScreen() and OrdersScreen()
    - This preserves state when switching between tabs
    - _Requirements: 5.4, 5.5_

  - [ ] 10.3 Configure MaterialApp with theme
    - Create MyApp StatelessWidget
    - Return MaterialApp with home: MainScaffold()
    - Set useMaterial3: true
    - Configure colorScheme with ColorScheme.fromSeed(seedColor: Color(0xFF4F46E5)) for Indigo
    - Set fontFamily to 'Roboto'
    - Configure inputDecorationTheme with OutlineInputBorder (borderRadius: 12) and contentPadding
    - _Requirements: 1.5, 9.5_

  - [ ] 10.4 Update main() entry point
    - Ensure main() function calls runApp(MyApp())
    - Verify widget tree structure is correct
    - _Requirements: 1.1_

- [ ] 11. Responsive design and polish
  - [ ] 11.1 Apply responsive layout across all screens
    - Review all screens for proper SingleChildScrollView usage
    - Ensure all Scaffolds have resizeToAvoidBottomInset: true
    - Test forms on different screen sizes (small phones, tablets)
    - Verify ResultBox scrolling works on all screen sizes
    - Verify BottomNavigationBar adapts to screen width
    - Use MediaQuery where needed for adaptive sizing
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 12. Accessibility audit
  - [ ] 12.1 Comprehensive accessibility review
    - Verify all interactive widgets have proper semantics (Material handles most by default)
    - Verify all TextFields have label and hint properties
    - Verify focus indicators are visible (Material 3 handles this)
    - Test keyboard navigation through entire app
    - Test with TalkBack (Android) screen reader if possible
    - Test with VoiceOver (iOS) screen reader if possible
    - Verify SnackBar messages are announced
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ]* 12.2 Write property tests for accessibility
    - **Property 16: Interactive Element Semantics**
    - **Validates: Requirements 10.1**
    - **Property 17: Keyboard Navigation Support**
    - **Validates: Requirements 10.2**
    - **Property 18: Focus Indicators**
    - **Validates: Requirements 10.3**
    - **Property 19: Semantic Widget Structure**
    - **Validates: Requirements 10.4**
    - **Property 20: Error Announcement to Screen Readers**
    - **Validates: Requirements 10.5**

- [ ] 13. Error handling refinement
  - [ ] 13.1 Review and enhance error handling
    - Verify all API calls have try-catch blocks
    - Verify error messages are user-friendly and descriptive
    - Verify error styling in ResultBox is consistent (red border, red icon)
    - Verify errors clear on new form submissions
    - Verify timeout errors display appropriate messages ("Request timed out. Please try again.")
    - Verify network errors display appropriate messages ("Network error. Check your internet connection.")
    - Test with airplane mode to verify network error handling
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 14. Final integration and testing
  - [ ] 14.1 End-to-end testing with backend API
    - Test order creation flow with various amounts (valid and invalid)
    - Test payment status check with valid and invalid order IDs
    - Test payment verification with valid and invalid signatures
    - Verify all success scenarios display correctly in ResultBox
    - Verify all error scenarios display correctly with appropriate messages
    - Verify loading states work correctly on all screens
    - Verify BottomNavigationBar navigation works smoothly
    - Verify TabBar navigation in OrdersScreen works smoothly
    - Verify clipboard copy functionality works and shows SnackBar
    - Test on Android device/emulator
    - Test on iOS device/simulator (if available)
    - _Requirements: 2.2, 2.3, 2.4, 3.3, 3.4, 3.5, 4.3, 4.4, 4.5_

  - [ ]* 14.2 Run all property-based tests
    - Execute all 20 property tests with minimum 100 iterations each
    - Verify all properties pass
    - Fix any failing properties
    - Document any edge cases discovered

  - [ ] 14.3 Build and deployment preparation
    - Run `flutter analyze` to check for code issues
    - Run `flutter test` to execute unit/widget tests
    - Run `flutter build apk --release` for Android release build
    - Run `flutter build ios --release` for iOS release build (requires macOS)
    - Verify build outputs are optimized and app size is reasonable
    - Test release builds on target devices
    - Check app performance and memory usage
    - _Requirements: 1.2_

- [ ] 15. Final checkpoint - Complete application review
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 1. Project setup and configuration
  - Initialize Vite project with React template using `npm create vite@latest`
  - Install dependencies: react, react-dom, react-router-dom, axios
  - Install dev dependencies: vite, @vitejs/plugin-react, tailwindcss, postcss, autoprefixer, eslint, prettier
  - Initialize TailwindCSS with `npx tailwindcss init -p`
  - Configure tailwind.config.js with content paths and custom colors (blue primary, red error, green success)
  - Create src directory structure (src/api, src/components, src/pages, src/utils, src/types)
  - Set up ESLint and Prettier configuration files
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [ ] 2. TypeScript type definitions
  - [ ] 2.1 Create TypeScript interfaces for API data
    - Create src/types/api.ts file
    - Define CreateOrderRequest, CreateOrderResponse interfaces
    - Define CheckPaymentStatusRequest, CheckPaymentStatusResponse interfaces
    - Define VerifyPaymentRequest, VerifyPaymentResponse interfaces
    - Define ErrorResponse interface
    - Export all type definitions
    - _Requirements: 12.1, 12.2_

- [ ] 3. API integration layer
  - [ ] 3.1 Configure Axios instance with base settings
    - Create src/api/axiosInstance.ts file
    - Configure Axios instance with base URL: https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com/selvan
    - Set timeout to 30000ms (30 seconds)
    - Set default Content-Type header to application/json
    - Implement response interceptor for error handling (network errors, HTTP errors, timeouts)
    - Export configured axios instance
    - _Requirements: 1.4, 12.1, 12.2, 12.3, 12.4, 12.5, 7.2, 7.3_

  - [ ] 3.2 Implement payment service API functions
    - Create src/api/paymentService.ts file
    - Implement createOrder function (POST /create-order with amount)
    - Implement checkPaymentStatus function (GET /check-payment-status with orderId query param)
    - Implement verifyPayment function (POST /verify-payment with orderId, paymentId, signature)
    - Use TypeScript interfaces for type safety
    - Export all service functions as paymentService object
    - _Requirements: 2.2, 3.3, 4.3_

  - [ ]* 3.3 Write property tests for API integration
    - **Property 1: Order Creation API Request**
    - **Validates: Requirements 2.2**
    - **Property 2: Payment Status API Request**
    - **Validates: Requirements 3.3**
    - **Property 3: Payment Verification API Request**
    - **Validates: Requirements 4.3**
    - **Property 14: API URL Construction**
    - **Validates: Requirements 12.2**
    - **Property 15: JSON Content-Type Headers**
    - **Validates: Requirements 12.4**

- [ ] 4. Form validation utilities
  - [ ] 4.1 Implement validation functions
    - Create src/utils/validation.js file
    - Implement validateAmount function (checks for required, numeric, positive values)
    - Implement validateOrderId function (checks for required field)
    - Implement validateVerificationForm function (checks all three required fields)
    - Return objects with isValid boolean and error/errors properties
    - Export all validation functions
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

  - [ ]* 4.2 Write property tests for validation
    - **Property 12: Non-Numeric Amount Validation**
    - **Validates: Requirements 11.2**
    - **Property 13: Required Field Validation**
    - **Validates: Requirements 11.5**

- [ ] 5. Shared UI components
  - [ ] 5.1 Implement LoadingSpinner component
    - Create src/components/LoadingSpinner.jsx file
    - Create functional component with no props
    - Use TailwindCSS animate-spin utility for spinner animation
    - Add ARIA role="status" and sr-only text "Loading..."
    - Center spinner with appropriate sizing
    - Export component
    - _Requirements: 2.5, 3.6, 4.6, 8.1_

  - [ ] 5.2 Implement ResultBox component
    - Create src/components/ResultBox.jsx file
    - Accept data and optional title as props
    - Use useState for copied state management
    - Format data as JSON with JSON.stringify(data, null, 2)
    - Implement copy-to-clipboard using navigator.clipboard.writeText
    - Display confirmation message when copied (update state for 2 seconds)
    - Use scrollable container with max-height and monospace font
    - Style with TailwindCSS (bg-gray-50, border, rounded corners)
    - Return null when data is null
    - Export component
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 2.3, 3.4, 4.4_

  - [ ]* 5.3 Write property tests for shared components
    - **Property 8: Copy to Clipboard Functionality**
    - **Validates: Requirements 2.6, 6.5**
    - **Property 9: JSON Formatting**
    - **Validates: Requirements 6.2**

- [ ] 6. Navbar component
  - [ ] 6.1 Implement Navbar with React Router navigation
    - Create src/components/Navbar.jsx file
    - Use NavLink from react-router-dom for Home and Orders links
    - Style with TailwindCSS (bg-blue-600, text-white, shadow-md)
    - Use NavLink's activeClassName or isActive prop for highlighting active route
    - Implement responsive layout (flex-col on mobile, flex-row on desktop with md: breakpoint)
    - Add proper ARIA labels for navigation
    - Export component
    - _Requirements: 5.1, 5.2, 5.3, 9.5_

  - [ ]* 6.2 Write property tests for navigation
    - **Property 10: SPA Navigation Without Reload**
    - **Validates: Requirements 5.2**
    - **Property 11: Active Route Highlighting**
    - **Validates: Requirements 5.3**

- [ ] 7. HomePage component for order creation
  - [ ] 7.1 Implement HomePage with form state management
    - Create src/pages/HomePage.jsx file
    - Use useState hooks for: amount, loading, error, result, validationError
    - Create form with input field for amount (type="number")
    - Add proper label with htmlFor attribute
    - Add submit button with TailwindCSS styling (bg-blue-600, hover:bg-blue-700)
    - Implement responsive layout with TailwindCSS (max-w-md mx-auto)
    - Add ARIA labels and semantic HTML (form, label, input, button)
    - Export component
    - _Requirements: 2.1, 9.1, 9.2, 9.3, 9.4_

  - [ ] 7.2 Implement form submission handler
    - Create handleSubmit async function
    - Prevent default form submission (e.preventDefault())
    - Reset error, result, and validationError states
    - Validate amount using validateAmount utility
    - Display validation errors if validation fails
    - Set loading to true and call paymentService.createOrder
    - On success: set result state and display in ResultBox
    - On error: set error state and display error message
    - Set loading to false in finally block
    - Disable submit button when loading is true
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 7.1, 7.2, 7.4, 8.2, 8.3, 8.4_

  - [ ] 7.3 Add accessibility features to HomePage
    - Ensure all inputs have associated labels with htmlFor
    - Add aria-required="true" to required inputs
    - Add aria-invalid when validation errors exist
    - Add aria-describedby linking to error messages
    - Use role="alert" for error messages
    - Add aria-live="polite" for loading states
    - Ensure keyboard navigation works (tab through form, enter to submit)
    - Add focus:ring utilities for visible focus indicators
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ]* 7.4 Write property tests for HomePage
    - **Property 4: Successful Response Display**
    - **Validates: Requirements 2.3, 3.4, 4.4**
    - **Property 5: Error Response Display**
    - **Validates: Requirements 2.4, 3.5, 4.5, 7.1, 7.2**
    - **Property 6: Loading State During Async Operations**
    - **Validates: Requirements 2.5, 3.6, 4.6, 8.1, 8.2**
    - **Property 7: Loading State Cleanup After Completion**
    - **Validates: Requirements 8.3, 8.4**

- [ ] 8. Checkpoint - Ensure HomePage works end-to-end
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. CheckPaymentStatusTab widget
  - [ ] 8.1 Implement CheckPaymentStatusTab with form state
    - Create StatefulWidget in lib/widgets/check_payment_status_tab.dart
    - Add state variables for orderId, loading, error, result, validationError
    - Implement TextEditingController for order ID field
    - Create form with TextField, proper labels, and ElevatedButton
    - Add Semantics widgets for accessibility
    - Use Material 3 components
    - _Requirements: 3.1, 3.2_

  - [ ] 8.2 Implement status check submission handler
    - Create _handleSubmit async method
    - Validate orderId using validateOrderId utility
    - Display validation errors using setState
    - Set loading state during API call
    - Call PaymentService.checkPaymentStatus with orderId
    - Handle success: display result in ResultBox widget
    - Handle errors: display error message
    - Clear loading state after completion
    - _Requirements: 3.3, 3.4, 3.5, 3.6_

  - [ ] 8.3 Add accessibility features to CheckPaymentStatusTab
    - Add Semantics labels for all interactive widgets
    - Ensure TextField has proper labels and hints
    - Add error announcements with appropriate semantics
    - Ensure keyboard navigation support
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 9. VerifyPaymentTab widget
  - [ ] 9.1 Implement VerifyPaymentTab with form state
    - Create StatefulWidget in lib/widgets/verify_payment_tab.dart
    - Add state variables for orderId, paymentId, signature, loading, error, result, validationErrors
    - Implement TextEditingControllers for all three fields
    - Create form with three TextFields, proper labels, and ElevatedButton
    - Add Semantics widgets for accessibility
    - Use Material 3 components
    - _Requirements: 4.1, 4.2_

  - [ ] 9.2 Implement verification submission handler
    - Create _handleSubmit async method
    - Validate all fields using validateVerificationForm utility
    - Display field-specific validation errors using setState
    - Set loading state during API call
    - Call PaymentService.verifyPayment with all three values
    - Handle success: display result in ResultBox widget
    - Handle errors: display error message
    - Clear loading state after completion
    - _Requirements: 4.3, 4.4, 4.5, 4.6_

  - [ ] 9.3 Add accessibility features to VerifyPaymentTab
    - Add Semantics labels for all input fields
    - Ensure all TextFields have proper labels and hints
    - Add error announcements with appropriate semantics
    - Ensure keyboard navigation support
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 10. OrdersScreen with tab navigation
  - [ ] 10.1 Implement OrdersScreen with tab state
    - Create StatefulWidget in lib/screens/orders_screen.dart
    - Use DefaultTabController for tab management
    - Implement TabBar with two tabs: "Check Payment Status" and "Verify Payment"
    - Implement TabBarView with CheckPaymentStatusTab and VerifyPaymentTab
    - Style tabs with Material 3 theme colors
    - Use Scaffold with AppBar containing TabBar
    - _Requirements: 3.1, 4.1_

  - [ ] 10.2 Add accessibility features to OrdersScreen
    - Add Semantics labels for tab navigation
    - Ensure TabBar is keyboard accessible (Flutter handles this by default)
    - Add proper semantics for tab panels
    - Ensure focus management between tabs works correctly
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [ ] 11. Root App widget and routing
  - [ ] 11.1 Implement MyApp widget with MaterialApp routing
    - Create MyApp StatelessWidget in lib/main.dart
    - Configure MaterialApp with Material 3 theme (useMaterial3: true)
    - Set up color scheme with blue as seed color
    - Define named routes for "/" (HomeScreen) and "/orders" (OrdersScreen)
    - Set initialRoute to "/"
    - Add AppNavigationBar to each screen's Scaffold
    - _Requirements: 5.4, 5.5, 1.5_

  - [ ] 11.2 Create application entry point
    - Update main() function in lib/main.dart
    - Call runApp with MyApp widget
    - Ensure proper widget tree structure
    - _Requirements: 1.1_

- [ ] 12. Responsive design implementation
  - [ ] 12.1 Apply responsive layout across all screens
    - Review all widgets for responsive design using LayoutBuilder where needed
    - Use MediaQuery for screen size detection
    - Ensure forms adapt to different screen sizes (mobile, tablet, desktop)
    - Verify AppNavigationBar works well on all screen sizes
    - Test ResultBox scrolling and sizing on different screens
    - Use Material 3 adaptive components where available
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 13. Accessibility audit and enhancements
  - [ ] 13.1 Comprehensive accessibility review
    - Verify all interactive widgets have Semantics labels
    - Verify all forms have proper TextField labels and hints
    - Verify focus indicators are visible on all focusable widgets (Material 3 handles this)
    - Verify semantic widget usage throughout (Scaffold, AppBar, Card, etc.)
    - Verify error announcements use appropriate Semantics
    - Test keyboard navigation through entire application
    - Test with TalkBack (Android) and VoiceOver (iOS) screen readers
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ]* 13.2 Write property tests for accessibility
    - **Property 16: Interactive Element ARIA Labels**
    - **Validates: Requirements 10.1**
    - **Property 17: Keyboard Navigation Support**
    - **Validates: Requirements 10.2**
    - **Property 18: Focus Indicators**
    - **Validates: Requirements 10.3**
    - **Property 19: Semantic HTML Structure**
    - **Validates: Requirements 10.4**
    - **Property 20: Error Announcement to Screen Readers**
    - **Validates: Requirements 10.5**

- [ ] 14. Error handling refinement
  - [ ] 14.1 Review and enhance error handling
    - Verify all API calls have try-catch blocks
    - Verify error messages are user-friendly
    - Verify error styling is consistent (red-50 background, red-800 text)
    - Verify errors clear on new submissions
    - Verify timeout errors display appropriate messages
    - Test network error scenarios
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 15. Final integration and testing
  - [ ] 15.1 Integration testing with backend API
    - Test order creation flow end-to-end with real API
    - Test payment status check with valid and invalid order IDs
    - Test payment verification with valid and invalid signatures
    - Verify all error scenarios display correctly
    - Verify loading states work correctly
    - Verify navigation between screens works smoothly
    - Test on Android, iOS, and Web platforms
    - _Requirements: 2.2, 2.3, 2.4, 3.3, 3.4, 3.5, 4.3, 4.4, 4.5_

  - [ ]* 15.2 Run all property-based tests
    - Execute all 20 property tests with minimum 100 iterations each
    - Verify all properties pass
    - Fix any failing properties
    - Document any edge cases discovered

  - [ ] 15.3 Build and deployment preparation
    - Run flutter build apk for Android
    - Run flutter build ios for iOS (requires macOS)
    - Run flutter build web for web deployment
    - Verify build outputs are optimized
    - Test production builds on target platforms
    - Check app size and performance
    - _Requirements: 1.2_

- [ ] 16. Final checkpoint - Complete application review
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property-based tests validate universal correctness properties (Dart property testing libraries like test_api or custom generators can be used)
- The implementation follows a bottom-up approach: models → API → widgets → screens/tabs → navigation → integration
- All widgets use Flutter best practices (StatelessWidget/StatefulWidget, const constructors, proper disposal of controllers)
- Material 3 design system is used throughout with Indigo (0xFF4F46E5) as seed color
- Accessibility is built-in from the start using proper TextField labels, hints, and Semantics where needed
- Error handling is comprehensive with 15-second timeouts, user-friendly messages, and SnackBar notifications
- Navigation uses BottomNavigationBar with IndexedStack for main screens, TabBar for Orders sub-tabs
- ResultBox displays JSON with dark background (#1E1E1E), green text, and copy-to-clipboard functionality
- All TextEditingControllers must be disposed in dispose() method to prevent memory leaks
- All forms use GlobalKey<FormState> for validation
- The app targets Android and iOS platforms primarily
