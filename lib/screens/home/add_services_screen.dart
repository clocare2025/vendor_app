import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/custom_button.dart';

// ── Step 1: Select Services ───────────────────────────────────────────────────

class AddServicesScreen extends StatefulWidget {
  const AddServicesScreen({super.key});

  @override
  State<AddServicesScreen> createState() => _AddServicesScreenState();
}

class _AddServicesScreenState extends State<AddServicesScreen> {
  Set<int> _alreadyActive = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final vendor = context.read<AuthProvider>().vendor;
    setState(() {
      _alreadyActive =
          (vendor?.selectedServices ?? []).map((s) => s.serviceId).toSet();
    });

    final p = context.read<OnboardingProvider>();
    p.serviceSelection.clear();
    p.priceInputs.clear();

    final token = context.read<AuthProvider>().token!;
    await p.loadServices(token);
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

    await p.loadCategoriesForSelected(token);
    await p.loadExistingPrices(token);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddServicesPricingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final newServices = p.availableServices
        .where((s) => !_alreadyActive.contains(s.serviceId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Services'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : newServices.isEmpty
              ? _AllServicesActive(onBack: () => Navigator.pop(context))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Services',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Choose the new services you want to offer. Set prices in the next step.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.selectedServices.length} selected',
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
                        itemCount: newServices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final svc = newServices[i];
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
                                      borderRadius: BorderRadius.circular(12),
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
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary),
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
                                        borderRadius: BorderRadius.circular(5)),
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
      bottomNavigationBar: newServices.isEmpty
          ? null
          : SafeArea(
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

class _AllServicesActive extends StatelessWidget {
  final VoidCallback onBack;
  const _AllServicesActive({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text(
              'All Services Added',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "You've already added all available services.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Set Prices ────────────────────────────────────────────────────────

class AddServicesPricingScreen extends StatefulWidget {
  const AddServicesPricingScreen({super.key});

  @override
  State<AddServicesPricingScreen> createState() =>
      _AddServicesPricingScreenState();
}

class _AddServicesPricingScreenState extends State<AddServicesPricingScreen> {
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

  void _next() {
    final p = context.read<OnboardingProvider>();
    for (final entry in _controllers.entries) {
      final parts = entry.key.split('_');
      p.setPriceInput(
          int.parse(parts[0]), int.parse(parts[1]), entry.value.text.trim());
    }

    final anyFilled = _controllers.values.any((c) {
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

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddServicesReviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<OnboardingProvider>().selectedServices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Prices'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Pricing',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Set your price per category. Leave blank for categories you don't offer.",
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
                    ...svc.categoryList.map((cat) {
                      final key = '${svc.serviceId}_${cat.categoryId}';
                      final ctrl =
                          _controllers[key] ?? TextEditingController();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
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
                                              color: AppColors.textSecondary),
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
          child: CustomButton(
            text: 'Review & Submit',
            isLoading: false,
            onPressed: _next,
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Review & Submit ───────────────────────────────────────────────────

class AddServicesReviewScreen extends StatelessWidget {
  const AddServicesReviewScreen({super.key});

  Future<void> _submit(BuildContext context) async {
    final p = context.read<OnboardingProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.token!;

    final ok = await p.submitAllPrices(token);
    if (!context.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.errorMessage ?? 'Failed to save prices'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await auth.getProfile();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Services submitted for review!'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Pop AddServicesReviewScreen → AddServicesPricingScreen → AddServicesScreen
    int count = 0;
    Navigator.of(context).popUntil((_) => count++ >= 3);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Submit'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Selected Services'),
            _card(
              children: p.selectedServices.isEmpty
                  ? [
                      const Text('No services selected',
                          style: TextStyle(color: AppColors.textHint))
                    ]
                  : p.selectedServices
                      .map((s) => _serviceRow(s.service))
                      .toList(),
            ),
            const SizedBox(height: 16),

            _sectionTitle('Your Prices'),
            ...p.selectedServices.map((svc) {
              final catPrices = svc.categoryList.where((c) {
                final v = double.tryParse(
                    p.getPriceInput(svc.serviceId, c.categoryId));
                return v != null && v > 0;
              }).toList();
              if (catPrices.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      svc.service,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ),
                  _card(
                    children: catPrices
                        .map((c) => _priceRow(
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
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Our team will review your new services and pricing. You'll be notified once approved.",
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
                text: 'Submit',
                isLoading: prov.isLoading,
                onPressed: () => _submit(ctx),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary),
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  Widget _serviceRow(String name) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      );

  Widget _priceRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontSize: 13),
            ),
          ],
        ),
      );
}
