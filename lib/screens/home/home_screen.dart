import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import '../main_screen.dart';
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
      final token = context.read<AuthProvider>().token ?? '';
      context.read<OrderProvider>().fetchOrders(token);
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthProvider>().vendor;
    final orders = context.watch<OrderProvider>();
    final auth = context.read<AuthProvider>();
    final kycStatus = vendor?.kycStatus ?? 'not_submitted';
    final active = vendor?.accountIsActive == true;
    final pending = orders.pendingOrders.length;

    return RefreshIndicator(
      color: AppColors.primary,
      displacement: 60,
      onRefresh: () async {
        await auth.getProfile();
        await orders.fetchOrders(auth.token ?? '');
      },
      child: CustomScrollView(
        slivers: [
          // ── Welcome header (gradient card, scrolls away) ───────────────
          // SliverToBoxAdapter(
          //   child: _WelcomeCard(
          //     greeting: _greeting,
          //     vendor:   vendor,
          //     pending:  pending,
          //     active:   active,
          //   ),
          // ),

          // ── KYC banner ─────────────────────────────────────────────────
          if (kycStatus != 'approved' || !active)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _KycBanner(kycStatus: kycStatus, vendor: vendor),
              ),
            ),

          // ── Stats row ──────────────────────────────────────────────────
          if (active)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _StatsRow(orders: orders),
              ),
            ),

          // ── Section header ─────────────────────────────────────────────
          if (active)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => MainScreen.switchToOrdersTab(context),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Order list ─────────────────────────────────────────────────
          if (active)
            if (orders.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (orders.orders.isEmpty)
              const SliverToBoxAdapter(child: _EmptyOrders())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final o = orders.orders[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderCard(
                        order: o,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: o),
                          ),
                        ),
                      ),
                    );
                  }, childCount: orders.orders.take(5).length),
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ── Welcome card (gradient, scrollable) ──────────────────────────────────────

// class _WelcomeCard extends StatelessWidget {
//   final String greeting;
//   final Vendor? vendor;
//   final int pending;
//   final bool active;

//   const _WelcomeCard({
//     required this.greeting,
//     required this.vendor,
//     required this.pending,
//     required this.active,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: AppColors.headerGradient,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primaryGrad1.withAlpha(60),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(greeting,
//                         style: TextStyle(
//                             color: Colors.white.withAlpha(180),
//                             fontSize: 13)),
//                     const SizedBox(height: 2),
//                     Text(
//                       vendor?.name.isNotEmpty == true
//                           ? vendor!.name
//                           : 'Vendor',
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: -0.3),
//                     ),
//                   ],
//                 ),
//               ),
//               // Avatar
//               Container(
//                 width: 44, height: 44,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withAlpha(25),
//                   shape: BoxShape.circle,
//                   border:
//                       Border.all(color: Colors.white.withAlpha(60), width: 2),
//                 ),
//                 child: Center(
//                   child: Text(
//                     vendor?.name.isNotEmpty == true
//                         ? vendor!.name[0].toUpperCase()
//                         : 'V',
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (active) ...[
//             const SizedBox(height: 14),
//             if (pending > 0)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 14, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: AppColors.newOrder,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.notifications_active_rounded,
//                         color: Colors.white, size: 18),
//                     const SizedBox(width: 10),
//                     Text('$pending new order${pending > 1 ? 's' : ''} waiting!',
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold)),
//                     const Spacer(),
//                     const Icon(Icons.arrow_forward_ios_rounded,
//                         color: Colors.white70, size: 13),
//                   ],
//                 ),
//               )
//             else
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withAlpha(20),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(Icons.check_circle_outline,
//                         color: Colors.white70, size: 15),
//                   ),
//                   const SizedBox(width: 10),
//                   const Text('All orders handled',
//                       style: TextStyle(color: Colors.white70, fontSize: 13)),
//                 ],
//               ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final OrderProvider orders;
  const _StatsRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(
          'New',
          '${orders.pendingOrders.length}',
          Icons.inbox_rounded,
          AppColors.newOrder,
          const Color(0xFFFFF7ED),
        ),
        const SizedBox(width: 10),
        _Stat(
          'Active',
          '${orders.activeOrders.length}',
          Icons.autorenew_rounded,
          AppColors.primary,
          AppColors.primaryLight,
        ),
        const SizedBox(width: 10),
        _Stat(
          'Done',
          '${orders.completedOrders.length}',
          Icons.task_alt_rounded,
          AppColors.accent,
          const Color(0xFFF0FDF4),
        ),
        const SizedBox(width: 10),
        _Stat(
          'Earned',
          '₹${orders.totalRevenue.toStringAsFixed(0)}',
          Icons.currency_rupee_rounded,
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;

  const _Stat(this.label, this.value, this.icon, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KYC banner ────────────────────────────────────────────────────────────────

class _KycBanner extends StatelessWidget {
  final String kycStatus;
  final Vendor? vendor;
  const _KycBanner({required this.kycStatus, required this.vendor});

  @override
  Widget build(BuildContext context) {
    Color color, bg, border;
    IconData icon;
    String title, subtitle;

    switch (kycStatus) {
      case 'submitted':
        color = const Color(0xFFF59E0B);
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        icon = Icons.hourglass_top_rounded;
        title = 'KYC Under Review';
        subtitle = 'Documents being verified.';
        break;
      case 'rejected':
        color = AppColors.error;
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        icon = Icons.warning_amber_rounded;
        title = 'KYC Rejected';
        subtitle = vendor?.kycRejectionReason.isNotEmpty == true
            ? vendor!.kycRejectionReason
            : 'Please fix your documents and resubmit.';
        break;
      case 'approved':
        color = AppColors.accent;
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        icon = Icons.verified_rounded;
        title = 'Account Active';
        subtitle = 'Verified and ready to receive orders.';
        break;
      default:
        color = AppColors.primary;
        bg = AppColors.primaryLight;
        border = const Color(0xFFBFDBFE);
        icon = Icons.person_outline_rounded;
        title = 'Complete Your KYC';
        subtitle = 'Submit documents to start receiving orders.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty orders ──────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: AppColors.textHint),
            SizedBox(height: 14),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'New orders assigned to you will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
