import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';
import '../services/backend_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/subscription_service.dart';
import '../services/local_notification_service.dart';
import '../models/payment_models.dart';

class RazorpayPosScreen extends StatefulWidget {
  const RazorpayPosScreen({super.key});

  @override
  State<RazorpayPosScreen> createState() => _RazorpayPosScreenState();
}

class _RazorpayPosScreenState extends State<RazorpayPosScreen>
    with TickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  PaymentService? _paymentService;

  String _responseText = '';
  PaymentStatus _currentStatus = PaymentStatus.unknown;
  bool _isProcessing = false;
  bool _isInitializing = true;

  late AnimationController _gradientController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _initializePaymentService();
  }

  Future<void> _initializePaymentService() async {
    try {
      if (kIsWeb) {
        setState(() {
          _isInitializing = false;
          _responseText = 'Note: Razorpay Flutter SDK does not support web platform.\n\n'
              'To test payment functionality:\n'
              '1. Run on Android: flutter run -d android\n'
              '2. Run on iOS: flutter run -d ios\n\n'
              'The UI is functional, but payment processing requires a mobile platform.';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final backendApi = BackendApiService(
        baseUrl: 'https://rhqxsjqj11.execute-api.ap-south-1.amazonaws.com',
        useMockMode: false,
      );

      // Initialize local storage service
      final localStorageService = LocalStorageService();
      await localStorageService.initialize();

      // Initialize notification service
      final localNotificationService = LocalNotificationService();
      await localNotificationService.initialize();

      // Initialize subscription service
      final subscriptionService = SubscriptionService(
        localStorageService: localStorageService,
        localNotificationService: localNotificationService,
      );

      // Initialize payment service with all dependencies
      final paymentService = PaymentService(
        backendApi: backendApi,
        prefs: prefs,
        localStorageService: localStorageService,
        subscriptionService: subscriptionService,
        localNotificationService: localNotificationService,
      );

      setState(() {
        _paymentService = paymentService;
        _isInitializing = false;
        _responseText = 'Ready to process payments';
      });
      
      print('✅ Payment service initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Initialization error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isInitializing = false;
        _responseText = 'Initialization error: $e';
      });
    }
  }

  Future<void> _handlePayNow() async {
    if (kIsWeb) {
      _showError('Payment processing is not available on web. Please run on Android or iOS.');
      return;
    }

    if (_paymentService == null) {
      _showError('Payment service not initialized');
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter amount');
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter valid amount');
      return;
    }

    setState(() {
      _isProcessing = true;
      _responseText = 'Initiating payment...';
    });

    try {
      final result = await _paymentService!.openCheckout(
        amount: amount,  // Send rupees, Lambda will convert to paise
        reference: _referenceController.text.trim(),
        onStatus: (msg) => setState(() => _responseText = msg),
      );
      
      _displayResult(result);
      _showResultOverlay(result, amount);
    } on PaymentResult catch (failedResult) {
      _displayResult(failedResult);
      _showResultOverlay(failedResult, amount);
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
        _currentStatus = PaymentStatus.failed;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCheckStatus() async {
    if (kIsWeb) {
      _showError('Status check is not available on web. Please run on Android or iOS.');
      return;
    }

    if (_paymentService == null) {
      _showError('Payment service not initialized');
      return;
    }

    setState(() {
      _isProcessing = true;
      _responseText = 'Checking payment status...';
    });

    try {
      final statusResponse = await _paymentService!.checkStatus();
      _displayStatusResponse(statusResponse);
    } catch (e) {
      setState(() {
        _responseText = 'Error checking status: $e';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _displayResult(PaymentResult result) {
    setState(() {
      _currentStatus = result.status;
      _responseText = _formatJson(result.toJson());
    });
  }

  void _displayStatusResponse(PaymentStatusResponse response) {
    setState(() {
      _currentStatus = response.status;
      _responseText = _formatJson(response.toJson());
    });
  }

  String _formatJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case PaymentStatus.success:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.pending:
        return Colors.orange;
      default:
        return Colors.cyan;
    }
  }

  IconData _getStatusIcon() {
    if (_isProcessing) return Icons.hourglass_top_rounded;
    switch (_currentStatus) {
      case PaymentStatus.success:
        return Icons.check_circle_rounded;
      case PaymentStatus.failed:
        return Icons.cancel_rounded;
      case PaymentStatus.pending:
        return Icons.pending_rounded;
      default:
        return Icons.terminal_rounded;
    }
  }

  String _getStatusLabel() {
    if (_isProcessing) return 'Processing…';
    switch (_currentStatus) {
      case PaymentStatus.success:
        return 'Payment Successful';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.pending:
        return 'Payment Pending';
      default:
        return 'Response';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultOverlay(PaymentResult result, int amount) {
    final isSuccess = result.status == PaymentStatus.success;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    (isSuccess ? Colors.greenAccent : Colors.redAccent)
                        .withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 80,
                    color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  Text(
                    isSuccess ? 'Payment Successful' : 'Payment Failed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess ? '₹$amount via Razorpay' : result.errorDescription ?? 'Please try again',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusBanner()
                      .animate()
                      .slideY(begin: -0.3, duration: 400.ms)
                      .fadeIn(),
                  const SizedBox(height: 24),
                  _buildAmountCard()
                      .animate()
                      .slideX(begin: -0.2, duration: 400.ms)
                      .fadeIn(),
                  const SizedBox(height: 16),
                  _buildReferenceCard()
                      .animate()
                      .slideX(begin: 0.2, duration: 500.ms, delay: 100.ms)
                      .fadeIn(),
                  const SizedBox(height: 24),
                  _buildPayNowButton()
                      .animate()
                      .slideY(begin: 0.3, duration: 400.ms, delay: 200.ms)
                      .fadeIn(),
                  const SizedBox(height: 16),
                  _buildCheckStatusButton()
                      .animate()
                      .slideY(begin: 0.3, duration: 400.ms, delay: 300.ms)
                      .fadeIn(),
                  const SizedBox(height: 24),
                  _buildResponsePanel()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: _GlassCard(
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _NourishaLoader(size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      'Nourisha POS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting to backend...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.54),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF0F0C29), const Color(0xFF302B63),
                    _gradientController.value)!,
                Color.lerp(const Color(0xFF302B63), const Color(0xFF24243E),
                    _gradientController.value)!,
                Color.lerp(const Color(0xFF24243E), const Color(0xFF0F0C29),
                    _gradientController.value)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -70,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 200,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D4FF).withOpacity(0.25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF).withOpacity(0.2),
                        blurRadius: 60,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6B9D).withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B9D).withOpacity(0.15),
                          blurRadius: 70,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nourisha POS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Powered by Razorpay · AWS Lambda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.54),
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _paymentService != null ? Colors.greenAccent : Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                    color: (_paymentService != null ? Colors.greenAccent : Colors.redAccent)
                        .withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 800.ms)
                .then()
                .shimmer(duration: 1500.ms),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.cloud_done_rounded,
            color: Colors.cyanAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AWS Lambda · ap-south-1 · Connected',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMOUNT',
            style: TextStyle(
              color: Colors.white.withOpacity(0.54),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.54),
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.24),
              ),
            ),
            cursorColor: Colors.cyanAccent,
          ),
          Divider(
            color: Colors.white.withOpacity(0.24),
            thickness: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER REFERENCE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.54),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceController,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Optional — table no, order ID…',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.24),
              ),
            ),
            cursorColor: Colors.cyanAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _handlePayNow,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white24,
          child: Center(
            child: _isProcessing
                ? const _NourishaLoader(size: 32, showText: false)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Pay Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckStatusButton() {
    return _GlassCard(
      borderColor: Colors.cyanAccent.withOpacity(0.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _handleCheckStatus,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  RotationTransition(
                    turns: _gradientController,
                    child: const Icon(
                      Icons.radar_rounded,
                      color: Colors.cyanAccent,
                      size: 24,
                    ),
                  )
                else
                  const Icon(
                    Icons.radar_rounded,
                    color: Colors.cyanAccent,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                const Text(
                  'Check Payment Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsePanel() {
    Color overlayColor = Colors.transparent;
    if (_currentStatus == PaymentStatus.success) {
      overlayColor = Colors.greenAccent.withOpacity(0.05);
    } else if (_currentStatus == PaymentStatus.failed) {
      overlayColor = Colors.redAccent.withOpacity(0.05);
    }

    return _GlassCard(
      child: Container(
        constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
        decoration: BoxDecoration(
          color: overlayColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 24,
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.05, 1.05),
                      duration: 800.ms,
                    ),
                const SizedBox(width: 12),
                Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  _responseText.isEmpty ? 'Response will appear here' : _responseText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _gradientController.dispose();
    _pulseController.dispose();
    _paymentService?.dispose();
    super.dispose();
  }
}


// Glass Card Helper Widget
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? borderColor;

  const _GlassCard({
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
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


// Nourisha Loader - Orbital Rings
class _NourishaLoader extends StatefulWidget {
  final double size;
  final bool showText;

  const _NourishaLoader({
    this.size = 64,
    this.showText = true,
  });

  @override
  State<_NourishaLoader> createState() => _NourishaLoaderState();
}

class _NourishaLoaderState extends State<_NourishaLoader>
    with TickerProviderStateMixin {
  late AnimationController _outerController;
  late AnimationController _middleController;
  late AnimationController _innerController;
  late AnimationController _pulseController;
  
  Timer? _textTimer;
  int _textIndex = 0;
  final List<String> _statusTexts = [
    'Creating Order…',
    'Opening Checkout…',
    'Verifying…',
  ];

  @override
  void initState() {
    super.initState();
    
    _outerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _middleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _innerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    if (widget.showText) {
      _textTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (mounted) {
          setState(() {
            _textIndex = (_textIndex + 1) % _statusTexts.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _outerController.dispose();
    _middleController.dispose();
    _innerController.dispose();
    _pulseController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              AnimatedBuilder(
                animation: _outerController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _outerController.value * 2 * pi,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _RingPainter(
                        color: const Color(0xFF6C63FF),
                        strokeWidth: 2,
                        arcAngle: 2 * pi,
                      ),
                    ),
                  );
                },
              ),
              // Middle ring
              AnimatedBuilder(
                animation: _middleController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_middleController.value * 2 * pi,
                    child: CustomPaint(
                      size: Size(widget.size * 0.72, widget.size * 0.72),
                      painter: _RingPainter(
                        color: const Color(0xFF00D4FF),
                        strokeWidth: 3,
                        arcAngle: 4 * pi / 3,
                      ),
                    ),
                  );
                },
              ),
              // Inner ring
              AnimatedBuilder(
                animation: _innerController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _innerController.value * 2 * pi,
                    child: CustomPaint(
                      size: Size(widget.size * 0.47, widget.size * 0.47),
                      painter: _RingPainter(
                        color: const Color(0xFFFF6B9D),
                        strokeWidth: 4,
                        arcAngle: 2 * pi / 3,
                      ),
                    ),
                  );
                },
              ),
              // Center pulsing dot
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 0.8 + (_pulseController.value * 0.4);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (widget.showText) ...[
          const SizedBox(height: 16),
          Text(
            _statusTexts[_textIndex],
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double arcAngle;

  _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.arcAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -pi / 2, arcAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
