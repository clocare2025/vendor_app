import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/order_model.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import '../../widgets/stat_card.dart';
import '../main_screen.dart';
import '../onboarding/kyc_personal_screen.dart';
import '../orders/order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<OrderProvider>(context, listen: false).fetchOrders(token);
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthProvider>().vendor;
    final orderProvider = context.watch<OrderProvider>();
    final kycStatus = vendor?.kycStatus ?? 'not_submitted';
    final isActive = vendor?.accountIsActive == true;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthProvider>();
            await auth.getProfile();
            await orderProvider.fetchOrders(auth.token ?? '');
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // ── Greeting ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          vendor?.name ?? 'Vendor',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── KYC Status Banner ────────────────────────────────────────
              if (kycStatus == 'submitted')
                Row(
                  children: [
                    _KycBanner(
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor: const Color(0xFFFDE68A),
                      title: 'KYC Under Review',
                      subtitle:
                          'Your documents are being verified. You\'ll be notified once approved.',
                    ),
                    const SizedBox(height: 16),
                  ],
                )
              else if (kycStatus == 'rejected')
                _KycBanner(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  title: 'KYC Rejected',
                  subtitle: vendor?.kycRejectionReason.isNotEmpty == true
                      ? vendor!.kycRejectionReason
                      : 'Your application was rejected. Please fix and resubmit.',
                  action: TextButton.icon(
                    onPressed: () => _openFixKyc(context, vendor),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Fix & Resubmit',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                )
              else if (kycStatus == 'approved' && isActive)
                _KycBanner(
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  title: 'Account Active',
                  subtitle: 'Your account is verified. You can receive orders.',
                ),

              const SizedBox(height: 20),

              // ── Stats (only for active vendors) ─────────────────────────
              if (isActive) ...[
                Text(
                  AppStrings.todayOverview,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    StatCard(
                      title: AppStrings.pendingOrders,
                      value: '${orderProvider.pendingOrders.length}',
                      icon: Icons.hourglass_empty_rounded,
                      color: AppColors.statusPending,
                    ),
                    StatCard(
                      title: AppStrings.activeOrders,
                      value: '${orderProvider.activeOrders.length}',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.statusActive,
                    ),
                    StatCard(
                      title: AppStrings.completedOrders,
                      value: '${orderProvider.completedOrders.length}',
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusCompleted,
                    ),
                    StatCard(
                      title: AppStrings.totalRevenue,
                      value:
                          '₹${orderProvider.totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee_rounded,
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.recentOrders,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => MainScreen.switchToOrdersTab(context),
                      child: const Text(
                        AppStrings.viewAll,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (orderProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (orderProvider.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No orders yet',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ),
                  )
                else
                  ...orderProvider.orders
                      .take(4)
                      .map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OrderCard(
                            order: order,
                            onTap: () => _openOrderDetail(context, order),
                          ),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openOrderDetail(BuildContext context, OrderModel order) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
  }

  void _openFixKyc(BuildContext context, Vendor? vendor) {
    if (vendor == null) return;
    context.read<OnboardingProvider>().preloadFromVendor(vendor);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const KycPersonalScreen()));
  }
}

// ── KYC Banner ────────────────────────────────────────────────────────────────

class _KycBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final Widget? action;

  const _KycBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 6), action!],
          ],
        ),
      ),
    );
  }
}
