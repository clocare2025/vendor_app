import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 30;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _handleVerify() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _errorText = null);

    final success = await auth.verifyOtpAndRegister(_otpController.text.trim());
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorText = auth.errorMessage ?? 'Invalid OTP, please try again');
    }
  }

  Future<void> _handleResend() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.resendOtp();
    _startTimer();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent successfully')),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.sms_outlined, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(AppStrings.otpVerification, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: '${AppStrings.otpSent} ',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  children: [
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 56,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.inputBorder,
                  activeFillColor: AppColors.surface,
                  selectedFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.surface,
                ),
                enableActiveFill: true,
                onChanged: (_) {},
                onCompleted: (_) => _handleVerify(),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => CustomButton(
                  text: AppStrings.verify,
                  isLoading: auth.isLoading,
                  onPressed: _handleVerify,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        '${AppStrings.resendIn}00:${_secondsRemaining.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      )
                    : GestureDetector(
                        onTap: _handleResend,
                        child: const Text(
                          AppStrings.resendOtp,
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
