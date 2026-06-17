import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/custom_button.dart';
import 'kyc_review_screen.dart';
import 'onboarding_widgets.dart';

class KycPricingScreen extends StatefulWidget {
  const KycPricingScreen({super.key});

  @override
  State<KycPricingScreen> createState() => _KycPricingScreenState();
}

class _KycPricingScreenState extends State<KycPricingScreen> {
  // One controller per "serviceId_categoryId"
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _buildControllers();
  }

  void _buildControllers() {
    final p = context.read<OnboardingProvider>();
    for (final svc in p.selectedServices) {
      for (final cat in svc.categoryList) {
        final key = '${svc.serviceId}_${cat.categoryId}';
        _controllers[key] = TextEditingController(
          text: p.getPriceInput(svc.serviceId, cat.categoryId),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    // Sync controller values to provider
    final p = context.read<OnboardingProvider>();
    for (final entry in _controllers.entries) {
      final parts = entry.key.split('_');
      p.setPriceInput(int.parse(parts[0]), int.parse(parts[1]), entry.value.text.trim());
    }

    // Validate at least one price is filled
    bool anyFilled = _controllers.values.any((c) {
      final v = double.tryParse(c.text.trim());
      return v != null && v > 0;
    });

    if (!anyFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one price.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final ok = await p.submitAllPrices(token);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const KycReviewScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.errorMessage ?? 'Failed to save prices'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final services = p.selectedServices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Prices'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const OnboardingStepIndicator(current: 4, total: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service Pricing',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Set your price per category. Leave blank for categories you don\'t offer.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: services.length,
              itemBuilder: (_, si) {
                final svc = services[si];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service header
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_laundry_service_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            svc.service,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Categories
                    ...svc.categoryList.map((cat) {
                      final key = '${svc.serviceId}_${cat.categoryId}';
                      final ctrl = _controllers[key] ??
                          TextEditingController();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Customer price: ₹${cat.price}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      hintText: '0.00',
                                      hintStyle: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 13),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.inputBorder),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.inputBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Garment types chips
                            if (cat.typesOfClothes.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: cat.typesOfClothes
                                    .map(
                                      (g) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: AppColors.divider),
                                        ),
                                        child: Text(
                                          g,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppColors.textSecondary),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Consumer<OnboardingProvider>(
            builder: (_, prov, __) => CustomButton(
              text: 'Review & Submit',
              isLoading: prov.isLoading,
              onPressed: _next,
            ),
          ),
        ),
      ),
    );
  }
}
