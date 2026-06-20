import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/status_provider.dart';
import '../../widgets/online_toggle.dart';
import '../auth/login_screen.dart';
import '../home/my_services_screen.dart';
import 'bank_details_screen.dart';
import 'earnings_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor    = context.watch<AuthProvider>().vendor;
    final statusPvd = context.watch<StatusProvider>();
    final auth      = context.read<AuthProvider>();
    final kycStatus = vendor?.kycStatus ?? 'not_submitted';
    final isActive  = vendor?.accountIsActive == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient SliverAppBar with vendor identity ─────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            collapsedHeight: kToolbarHeight,
            backgroundColor: AppColors.primaryGrad2,
            automaticallyImplyLeading: false,
            actions: [
              OnlineToggle(statusPvd: statusPvd, token: auth.token ?? ''),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (ctx, constraints) {
                final collapsed = constraints.maxHeight <=
                    kToolbarHeight + MediaQuery.of(ctx).padding.top + 10;
                return FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  titlePadding:
                      const EdgeInsets.only(left: 20, bottom: 14),
                  title: collapsed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  Colors.white.withAlpha(40),
                              child: Text(
                                vendor?.name.isNotEmpty == true
                                    ? vendor!.name[0].toUpperCase()
                                    : 'V',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              vendor?.name.isNotEmpty == true
                                  ? vendor!.name.split(' ').first
                                  : 'Profile',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : null,
                  background: Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.headerGradient),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 80, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Avatar + name row
                            Row(
                              children: [
                                // Avatar circle
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(25),
                                    border: Border.all(
                                        color: Colors.white.withAlpha(80),
                                        width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      vendor?.name.isNotEmpty == true
                                          ? vendor!.name[0].toUpperCase()
                                          : 'V',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendor?.name.isNotEmpty == true
                                            ? vendor!.name
                                            : 'Vendor',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.3),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        vendor?.mobile ?? '',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withAlpha(180),
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      // Account status pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.white.withAlpha(30)
                                              : AppColors.warning
                                                  .withAlpha(60),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: isActive
                                                  ? Colors.white
                                                      .withAlpha(60)
                                                  : AppColors.warning
                                                      .withAlpha(120)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isActive
                                                  ? Icons.verified_rounded
                                                  : Icons
                                                      .hourglass_empty_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isActive
                                                  ? 'Verified'
                                                  : 'Pending Verification',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                _StatsCard(vendor: vendor),
                const SizedBox(height: 16),

                // KYC banner
                if (kycStatus != 'not_submitted')
                  _KycBanner(kycStatus: kycStatus, vendor: vendor),
                if (kycStatus != 'not_submitted')
                  const SizedBox(height: 16),

                // Quick actions grid
                _QuickActionsGrid(context: context),
                const SizedBox(height: 16),

                // My Services preview
                _ServicesPreview(vendor: vendor),
                const SizedBox(height: 16),

                // Menu list
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.edit_outlined,
                      title: AppStrings.editProfile,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ProfileEditScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.local_laundry_service_outlined,
                      title: 'My Services',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const MyServicesScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.account_balance_outlined,
                      title: 'Bank Details',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const BankDetailsScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: AppStrings.earnings,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const EarningsScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Logout
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _confirmLogout,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout,
                                size: 20, color: AppColors.error),
                          ),
                          const SizedBox(width: 14),
                          const Text(AppStrings.logout,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final Vendor? vendor;
  const _StatsCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _statItem('₹${(vendor?.walletBalance ?? 0).toStringAsFixed(0)}',
              'Wallet'),
          _divider(),
          _statItem(
              '${vendor?.currentLoad ?? 0}/${vendor?.orderCapacity ?? 0}',
              'Order Load'),
          _divider(),
          _statItem(
              '${vendor?.currentGarmentLoad ?? 0}/${vendor?.garmentCapacity ?? 0}',
              'Garments'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 32, color: AppColors.divider);
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
        subtitle = 'Documents being verified.';
        break;
      case 'rejected':
        color = AppColors.error; bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA); icon = Icons.warning_amber_rounded;
        title = 'KYC Rejected';
        subtitle = vendor?.kycRejectionReason.isNotEmpty == true
            ? vendor!.kycRejectionReason
            : 'Please fix and resubmit.';
        break;
      case 'approved':
        color = AppColors.accent; bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0); icon = Icons.verified_rounded;
        title = 'Account Active';
        subtitle = 'Verified and ready to receive orders.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final BuildContext context;
  const _QuickActionsGrid({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final items = [
      _QuickAction(Icons.edit_outlined, 'Edit Profile', AppColors.primary,
          AppColors.primaryLight,
          () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ProfileEditScreen()))),
      _QuickAction(Icons.local_laundry_service_outlined, 'My Services',
          const Color(0xFF7C3AED), const Color(0xFFF5F3FF),
          () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const MyServicesScreen()))),
      _QuickAction(Icons.account_balance_outlined, 'Bank Details',
          const Color(0xFF0369A1), const Color(0xFFE0F2FE),
          () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const BankDetailsScreen()))),
      _QuickAction(Icons.account_balance_wallet_outlined, 'Earnings',
          AppColors.accent, const Color(0xFFF0FDF4),
          () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const EarningsScreen()))),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        return Material(
          color: item.bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: item.color.withAlpha(40)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: item.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 18, color: item.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _QuickAction(
      this.icon, this.label, this.color, this.bg, this.onTap);
}

// ── Services Preview ──────────────────────────────────────────────────────────

class _ServicesPreview extends StatelessWidget {
  final Vendor? vendor;
  const _ServicesPreview({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final services = vendor?.selectedServices ?? [];
    if (services.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Active Services',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyServicesScreen())),
                child: const Text('Manage',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_laundry_service_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(s.service,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.onTap});
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: AppColors.primary),
                ),
                title: Text(item.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}
