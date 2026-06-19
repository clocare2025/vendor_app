import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/status_provider.dart';
import '../../widgets/online_toggle.dart';
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
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
    final vendor    = context.watch<AuthProvider>().vendor;
    final orders    = context.watch<OrderProvider>();
    final statusPvd = context.watch<StatusProvider>();
    final auth      = context.read<AuthProvider>();
    final kycStatus = vendor?.kycStatus ?? 'not_submitted';
    final active    = vendor?.accountIsActive == true;
    final pending   = orders.pendingOrders.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        displacement: 100,
        onRefresh: () async {
          await auth.getProfile();
          await orders.fetchOrders(auth.token ?? '');
        },
        child: CustomScrollView(
          slivers: [
            // ── Pinned gradient SliverAppBar ───────────────────────────────
            SliverAppBar(
              expandedHeight: active ? 200 : 160,
              collapsedHeight: 70,
              pinned: true,
              floating: false,
              backgroundColor: AppColors.primaryGrad2,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isCollapsed = constraints.maxHeight <=
                      kToolbarHeight + MediaQuery.of(ctx).padding.top + 10;
                  return FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _HomeHeader(
                      greeting:  _greeting,
                      vendor:    vendor,
                      pending:   pending,
                      active:    active,
                    ),
                    title: isCollapsed
                        ? Text(
                            vendor?.name.isNotEmpty == true
                                ? 'Hi, ${vendor!.name.split(' ').first} 👋'
                                : 'Home',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                    titlePadding:
                        const EdgeInsets.only(left: 20, bottom: 16),
                  );
                },
              ),
              actions: [
                _OnlineToggle(statusPvd: statusPvd, token: auth.token ?? ''),
              ],
            ),

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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _StatsRow(orders: orders),
                ),
              ),

            // ── Section header ─────────────────────────────────────────────
            if (active)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                  child: Row(
                    children: [
                      const Text('Recent Orders',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => MainScreen.switchToOrdersTab(context),
                        child: const Text('View All',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
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
                SliverToBoxAdapter(child: _EmptyOrders())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final o = orders.orders[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OrderCard(
                            order: o,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(order: o)),
                            ),
                          ),
                        );
                      },
                      childCount: orders.orders.take(5).length,
                    ),
                  ),
                ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ── Online / Offline toggle pill (reusable) ───────────────────────────────────

class _OnlineToggle extends StatelessWidget {
  final StatusProvider statusPvd;
  final String token;

  const _OnlineToggle({required this.statusPvd, required this.token});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: statusPvd.loading ? null : () => statusPvd.toggle(token),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: statusPvd.isOnline
              ? const Color(0xFF16A34A)
              : Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusPvd.isOnline
                ? const Color(0xFF16A34A)
                : Colors.white.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusPvd.loading)
              const SizedBox(
                width: 8, height: 8,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 1.5),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: statusPvd.isOnline ? Colors.white : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              statusPvd.isOnline ? 'Online' : 'Offline',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expanding header inside FlexibleSpaceBar ──────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final Vendor? vendor;
  final int pending;
  final bool active;

  const _HomeHeader({
    required this.greeting,
    required this.vendor,
    required this.pending,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 76, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(greeting,
              style: TextStyle(
                  color: Colors.white.withAlpha(180), fontSize: 13)),
          const SizedBox(height: 3),
          Text(
            vendor?.name.isNotEmpty == true ? vendor!.name : 'Vendor',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3),
          ),
          if (active) ...[
            const SizedBox(height: 14),
            if (pending > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.newOrder,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '$pending new order${pending > 1 ? 's' : ''} waiting!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 13),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: Colors.white70, size: 15),
                  ),
                  const SizedBox(width: 10),
                  const Text('All orders handled',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final OrderProvider orders;
  const _StatsRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(label: 'New', value: '${orders.pendingOrders.length}',
            icon: Icons.inbox_rounded, color: AppColors.newOrder,
            bg: const Color(0xFFFFF7ED)),
        const SizedBox(width: 10),
        _StatCard(label: 'Active', value: '${orders.activeOrders.length}',
            icon: Icons.autorenew_rounded, color: AppColors.primary,
            bg: AppColors.primaryLight),
        const SizedBox(width: 10),
        _StatCard(label: 'Done', value: '${orders.completedOrders.length}',
            icon: Icons.task_alt_rounded, color: AppColors.accent,
            bg: const Color(0xFFF0FDF4)),
        const SizedBox(width: 10),
        _StatCard(
            label: 'Earned',
            value: '₹${orders.totalRevenue.toStringAsFixed(0)}',
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFF5F3FF)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;

  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color, required this.bg,
  });

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
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: color, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── KYC Banner ────────────────────────────────────────────────────────────────

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
        color = const Color(0xFFF59E0B); bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A); icon = Icons.hourglass_top_rounded;
        title = 'KYC Under Review';
        subtitle = 'Documents being verified. You\'ll be notified once approved.';
        break;
      case 'rejected':
        color = AppColors.error; bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA); icon = Icons.warning_amber_rounded;
        title = 'KYC Rejected';
        subtitle = vendor?.kycRejectionReason.isNotEmpty == true
            ? vendor!.kycRejectionReason : 'Please fix your documents and resubmit.';
        break;
      case 'approved':
        color = AppColors.accent; bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0); icon = Icons.verified_rounded;
        title = 'Account Active';
        subtitle = 'Your account is verified and ready.';
        break;
      default:
        color = AppColors.primary; bg = AppColors.primaryLight;
        border = const Color(0xFFBFDBFE); icon = Icons.person_outline_rounded;
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
              color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
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
            Text('No orders yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            SizedBox(height: 6),
            Text('New orders assigned to you will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
