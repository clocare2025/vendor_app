import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/my_services_screen.dart';
import 'bank_details_screen.dart';
import 'earnings_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color ?? AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthProvider>().vendor;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (vendor?.name.isNotEmpty ?? false)
                          ? vendor!.name[0].toUpperCase()
                          : 'V',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    (vendor?.name.isNotEmpty ?? false)
                        ? vendor!.name
                        : 'Vendor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor?.mobile ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (vendor?.accountIsActive ?? false)
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.statusPending.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (vendor?.accountIsActive ?? false)
                              ? Icons.verified
                              : Icons.hourglass_empty_rounded,
                          size: 14,
                          color: (vendor?.accountIsActive ?? false)
                              ? AppColors.accent
                              : AppColors.statusPending,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (vendor?.accountIsActive ?? false)
                              ? 'Verified'
                              : 'Pending Verification',
                          style: TextStyle(
                            color: (vendor?.accountIsActive ?? false)
                                ? AppColors.accent
                                : AppColors.statusPending,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    _statItem(
                      '₹${(vendor?.walletBalance ?? 0).toStringAsFixed(0)}',
                      'Wallet',
                    ),
                    const VerticalDivider(width: 1),
                    _statItem(
                      '${vendor?.currentLoad ?? 0}/${vendor?.orderCapacity ?? 0}',
                      'Order Load',
                    ),
                    const VerticalDivider(width: 1),
                    _statItem(
                      '${vendor?.currentGarmentLoad ?? 0}/${vendor?.garmentCapacity ?? 0}',
                      'Garment Load',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── KYC Status Banner ──────────────────────────────────────────
            Builder(builder: (context) {
              final kycStatus = vendor?.kycStatus ?? 'not_submitted';
              final isActive = vendor?.accountIsActive == true;
              if (kycStatus == 'submitted') {
                return _KycBanner(
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  title: 'KYC Under Review',
                  subtitle:
                      'Your documents are being verified. You\'ll be notified once approved.',
                );
              } else if (kycStatus == 'rejected') {
                return _KycBanner(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  title: 'KYC Rejected',
                  subtitle: vendor?.kycRejectionReason.isNotEmpty == true
                      ? vendor!.kycRejectionReason
                      : 'Your application was rejected. Please fix and resubmit.',
                );
              } else if (kycStatus == 'approved' && isActive) {
                return _KycBanner(
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  title: 'Account Active',
                  subtitle: 'Your account is verified. You can receive orders.',
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Details',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.location_city_outlined,
                      'City',
                      vendor?.cityName ?? '-',
                    ),
                    _detailRow(
                      Icons.pin_drop_outlined,
                      'Pincode',
                      vendor?.pincode ?? '-',
                    ),
                    _detailRow(
                      Icons.location_on_outlined,
                      'Address',
                      vendor?.address ?? '-',
                    ),
                    _detailRow(
                      Icons.assignment_turned_in_outlined,
                      'Registration',
                      (vendor?.registrationStatus.isNotEmpty ?? false)
                          ? vendor!.registrationStatus
                          : '-',
                    ),
                    if (vendor?.activeServices.isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: vendor!.activeServices
                            .map(
                              (s) => Chip(
                                label: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppColors.primaryLight,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── My Services Section ──────────────────────────────────────
            _ServicesSection(vendor: vendor),

            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _menuTile(
                      context,
                      icon: Icons.edit_outlined,
                      title: AppStrings.editProfile,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      context,
                      icon: Icons.local_laundry_service_outlined,
                      title: AppStrings.services,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyServicesScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      context,
                      icon: Icons.account_balance_outlined,
                      title: 'Bank Details',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    _menuTile(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      title: AppStrings.earnings,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EarningsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: _menuTile(
                context,
                icon: Icons.logout,
                title: AppStrings.logout,
                color: AppColors.error,
                onTap: () => _confirmLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
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
  const _KycBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
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
        ],
      ),
    );
  }
}

// ── Services Section ──────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final Vendor? vendor;
  const _ServicesSection({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final services = vendor?.selectedServices ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyServicesScreen()),
              ),
              icon: const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Manage',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: services.isEmpty
              ? Column(
                  children: [
                    const Icon(
                      Icons.local_laundry_service_outlined,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No services added yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add the services you offer and set your prices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyServicesScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Services'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...services.map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(76),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_laundry_service_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.service,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyServicesScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add More',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
