import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/custom_button.dart';
import 'onboarding_widgets.dart';
import 'pending_screen.dart';

class KycReviewScreen extends StatelessWidget {
  const KycReviewScreen({super.key});

  Future<void> _submit(BuildContext context) async {
    final p = context.read<OnboardingProvider>();
    final token = context.read<AuthProvider>().token!;
    final ok = await p.finalSubmit(token);
    if (!context.mounted) return;

    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const KycPendingScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.errorMessage ?? 'Submission failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Submit'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const OnboardingStepIndicator(current: 4, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Personal Details'),
                  _ReviewCard(children: [
                    _row('Name', auth.vendor?.name ?? '—'),
                    _row('Mobile', auth.vendor?.mobile ?? '—'),
                    _row('Gender', p.gender),
                    _row('Date of Birth', p.dob),
                    _row('City', auth.vendor?.cityName ?? '—'),
                    _row('Pincode', auth.vendor?.pincode ?? '—'),
                    _row('Address', auth.vendor?.address ?? '—'),
                  ]),
                  const SizedBox(height: 16),

                  _sectionTitle('KYC Documents'),
                  _ReviewCard(children: [
                    _row('ID Proof Type', p.idProofType),
                    _row('ID Proof Number', p.idProofNumber),
                    _photoRow('Profile Photo', p.profilePic != null),
                    _photoRow('ID Proof Photo', p.idProofPic != null),
                  ]),
                  const SizedBox(height: 16),

                  _sectionTitle('Selected Services'),
                  _ReviewCard(
                    children: p.selectedServices.isEmpty
                        ? [const Text('No services selected',
                            style: TextStyle(color: AppColors.textHint))]
                        : p.selectedServices
                            .map((s) => _row('', s.service,
                                isServiceItem: true))
                            .toList(),
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle('Your Prices'),
                  ...p.selectedServices.map((svc) {
                    final catPrices = svc.categoryList
                        .where((c) {
                          final v = double.tryParse(
                            p.getPriceInput(svc.serviceId, c.categoryId),
                          );
                          return v != null && v > 0;
                        })
                        .toList();

                    if (catPrices.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(svc.service,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                        _ReviewCard(
                          children: catPrices
                              .map((c) => _row(
                                    c.category,
                                    '₹${p.getPriceInput(svc.serviceId, c.categoryId)}',
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Once submitted, our team will review your application. You will be notified when your account is approved.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Consumer<OnboardingProvider>(
                    builder: (ctx, prov, _) => CustomButton(
                      text: 'Submit Application',
                      isLoading: prov.isLoading,
                      onPressed: () => _submit(ctx),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary)),
      );

  Widget _row(String label, String value, {bool isServiceItem = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: isServiceItem
            ? Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(label,
                        style: const TextStyle(color: AppColors.textSecondary,
                            fontSize: 13)),
                  ),
                  Expanded(
                    child: Text(value.isEmpty ? '—' : value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            fontSize: 13)),
                  ),
                ],
              ),
      );

  Widget _photoRow(String label, bool uploaded) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Icon(
              uploaded ? Icons.check_circle : Icons.cancel,
              color: uploaded ? AppColors.accent : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              uploaded ? 'Uploaded' : 'Missing',
              style: TextStyle(
                  color: uploaded ? AppColors.accent : AppColors.error,
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
            ),
          ],
        ),
      );
}

class _ReviewCard extends StatelessWidget {
  final List<Widget> children;
  const _ReviewCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
