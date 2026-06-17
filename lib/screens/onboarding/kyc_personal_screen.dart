import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'kyc_documents_screen.dart';
import 'onboarding_widgets.dart';

class KycPersonalScreen extends StatefulWidget {
  const KycPersonalScreen({super.key});

  @override
  State<KycPersonalScreen> createState() => _KycPersonalScreenState();
}

class _KycPersonalScreenState extends State<KycPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dobController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _altMobileController = TextEditingController();

  String? _selectedGender;
  String? _selectedIdProof;

  static const _genders = ['male', 'female', 'other'];
  static const _idProofTypes = ['Aadhar', 'PAN', 'Driving Licence', 'Voter ID'];

  @override
  void initState() {
    super.initState();
    final p = context.read<OnboardingProvider>();
    _dobController.text = p.dob;
    _idNumberController.text = p.idProofNumber;
    _emailController.text = p.email;
    _altMobileController.text = p.alternativeMobile;
    if (p.gender.isNotEmpty) _selectedGender = p.gender;
    if (p.idProofType.isNotEmpty) _selectedIdProof = p.idProofType;
  }

  @override
  void dispose() {
    _dobController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _altMobileController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final p = context.read<OnboardingProvider>();
    p.gender = _selectedGender!;
    p.dob = _dobController.text.trim();
    p.idProofType = _selectedIdProof!;
    p.idProofNumber = _idNumberController.text.trim();
    p.email = _emailController.text.trim();
    p.alternativeMobile = _altMobileController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KycDocumentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Details'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const OnboardingStepIndicator(current: 1, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 6),
                    const Text(
                      'These details are used to verify your identity.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Gender
                    _label('Gender *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: _dropDecoration('Select gender'),
                      items: _genders
                          .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                g[0].toUpperCase() + g.substring(1),
                              )))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                      validator: (v) => v == null ? 'Please select gender' : null,
                    ),
                    const SizedBox(height: 18),

                    // DOB
                    _label('Date of Birth *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: _dropDecoration('Select date of birth').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today_outlined,
                            color: AppColors.textSecondary),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Date of birth is required' : null,
                    ),
                    const SizedBox(height: 18),

                    // ID Proof Type
                    _label('ID Proof Type *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIdProof,
                      decoration: _dropDecoration('Select ID proof type'),
                      items: _idProofTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedIdProof = v),
                      validator: (v) => v == null ? 'Please select ID proof type' : null,
                    ),
                    const SizedBox(height: 18),

                    // ID Number
                    CustomTextField(
                      controller: _idNumberController,
                      label: 'ID Proof Number *',
                      hint: 'Enter your ID number',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'ID proof number is required' : null,
                    ),
                    const SizedBox(height: 18),

                    // Email (optional)
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email (Optional)',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Alt mobile (optional)
                    CustomTextField(
                      controller: _altMobileController,
                      label: 'Alternative Mobile (Optional)',
                      hint: '10-digit number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                          return 'Enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    CustomButton(text: 'Next: Upload Documents', onPressed: _next),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _dropDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

