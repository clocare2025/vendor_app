import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _cityName = TextEditingController();
  final _pincode = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _phoneNumber.dispose();
    _cityName.dispose();
    _pincode.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final mobile = _phoneNumber.text.trim();
    final success = await auth.requestRegistrationOtp(
      name: _fullName.text.trim(),
      mobile: mobile,
      cityName: _cityName.text.trim(),
      pincode: _pincode.text.trim(),
      address: _addressController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpScreen(phone: mobile)),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Vendor Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register your laundry business to get started',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                // CustomTextField(
                //   controller: _businessNameController,
                //   label: AppStrings.businessName,
                //   hint: 'e.g. Sparkle Laundry Co.',
                //   prefixIcon: Icons.store_outlined,
                //   validator: (v) => v == null || v.isEmpty ? 'Business name is required' : null,
                // ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _fullName,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _phoneNumber,
                  label: AppStrings.phone,
                  hint: '+91 98765 43210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Phone number is required';
                    if (v.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _cityName,
                  label: 'City',
                  hint: 'City',
                  prefixIcon: Icons.location_city_outlined,
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'City is required';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _pincode,
                  label: 'Pincode',
                  hint: 'Enter pincode',
                  prefixIcon: Icons.location_city_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Pincode is required';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _addressController,
                  label: AppStrings.address,
                  hint: 'Enter your business address',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: 'Create a password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: AppStrings.confirmPassword,
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => CustomButton(
                    text: AppStrings.signUp,
                    isLoading: auth.isLoading,
                    onPressed: _handleRegister,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.alreadyHaveAccount,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        AppStrings.signIn,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
