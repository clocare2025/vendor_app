import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/custom_button.dart';
import 'kyc_pricing_screen.dart';
import 'onboarding_widgets.dart';

class KycServicesScreen extends StatefulWidget {
  const KycServicesScreen({super.key});

  @override
  State<KycServicesScreen> createState() => _KycServicesScreenState();
}

class _KycServicesScreenState extends State<KycServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<OnboardingProvider>().loadServices(token);
  }

  Future<void> _next() async {
    final p = context.read<OnboardingProvider>();
    if (p.selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token!;

    // Save selection to backend
    final saved = await p.submitServiceSelection(token);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.errorMessage ?? 'Failed to save services'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Load full category data for selected services
    await p.loadCategoriesForSelected(token);
    await p.loadExistingPrices(token);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KycPricingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Services'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const OnboardingStepIndicator(current: 3, total: 4),
          Expanded(
            child: p.isLoading
                ? const Center(child: CircularProgressIndicator())
                : p.availableServices.isEmpty
                    ? _ErrorState(onRetry: _load)
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Services You Offer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Select all the laundry services you provide. You can set your prices in the next step.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.selectedServices.length} of ${p.availableServices.length} selected',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: p.availableServices.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final svc = p.availableServices[i];
                                final selected =
                                    p.serviceSelection[svc.serviceId] == true;
                                return GestureDetector(
                                  onTap: () => p.toggleService(svc.serviceId),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryLight
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.divider,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.primary
                                                : AppColors.background,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.local_laundry_service_rounded,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                svc.service,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: selected
                                                      ? AppColors.primary
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              if (svc.description.isNotEmpty)
                                                Text(
                                                  svc.description,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.textSecondary),
                                                ),
                                              if (svc.duration.isNotEmpty)
                                                Text(
                                                  '⏱ ${svc.duration}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textHint),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Checkbox(
                                          value: selected,
                                          onChanged: (_) =>
                                              p.toggleService(svc.serviceId),
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Consumer<OnboardingProvider>(
            builder: (_, prov, __) => CustomButton(
              text: 'Next: Set Prices',
              isLoading: prov.isLoading,
              onPressed: _next,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('Could not load services',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
