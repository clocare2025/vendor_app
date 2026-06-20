import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Shown after vendor taps "Return to Warehouse" (complete-processing).
/// Displays the 6-digit OTP the supervisor scans to confirm garment return.
class InwardOtpScreen extends StatefulWidget {
  final String processId;
  final String orderNumber;
  final String service;
  final String initialOtp; // returned directly from the complete-processing call

  const InwardOtpScreen({
    super.key,
    required this.processId,
    required this.orderNumber,
    required this.service,
    required this.initialOtp,
  });

  @override
  State<InwardOtpScreen> createState() => _InwardOtpScreenState();
}

class _InwardOtpScreenState extends State<InwardOtpScreen>
    with SingleTickerProviderStateMixin {
  late String _otp;
  bool _loading = false;
  bool _verified = false;

  // Pulse animation on OTP digits
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _otp = widget.initialOtp;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Poll every 10 s to check if OTP was verified by supervisor
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    if (_verified) return;
    final token = context.read<AuthProvider>().token ?? '';
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.orderDetail(widget.processId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body);
      if (body['status'] == true) {
        final order = body['data']?['order'];
        if (order?['inward_otp_verified'] == true) {
          if (mounted) {
            setState(() => _verified = true);
            _pollTimer?.cancel();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshOtp() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token ?? '';
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.orderInwardOtp(widget.processId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body);
      if (body['status'] == true && mounted) {
        setState(() => _otp = body['data']?['inward_otp'] ?? _otp);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _copyOtp() {
    Clipboard.setData(ClipboardData(text: _otp));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP copied'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGrad2,
        foregroundColor: Colors.white,
        title: const Text('Return to Warehouse',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SafeArea(
        child: _verified ? _verifiedView() : _otpView(),
      ),
    );
  }

  Widget _otpView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Top instruction card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.warehouse_outlined,
                    color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Show this OTP to your supervisor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Supervisor will scan the code in the admin panel to confirm garments received at warehouse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withAlpha(180), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Order info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${widget.orderNumber.isNotEmpty ? widget.orderNumber : widget.processId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.service,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.newOrder.withAlpha(60)),
                  ),
                  child: const Text('Processing Done',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.newOrder)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // OTP display
          const Text('One-Time Password',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            ),
            child: GestureDetector(
              onTap: _copyOtp,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGrad2,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _otp.split('').join('  '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.copy_rounded,
                        color: Colors.white54, size: 20),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text('Tap to copy',
              style: TextStyle(fontSize: 11, color: AppColors.textHint)),

          const SizedBox(height: 36),

          // Status: waiting for supervisor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFF59E0B))),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Waiting for supervisor to verify OTP in admin panel…',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Refresh OTP button
          TextButton.icon(
            onPressed: _loading ? null : _refreshOtp,
            icon: _loading
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5))
                : const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh OTP'),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _verifiedView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 64, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 28),
          const Text('Garments Received!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                  letterSpacing: -0.3)),
          const SizedBox(height: 12),
          const Text(
            'Supervisor has verified the OTP. Garments are confirmed back in the warehouse.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil(
                  (route) => route.isFirst || route.settings.name == '/main'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Orders',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
