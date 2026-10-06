import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/b2b_order_provider.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';
import 'b2b_order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  /// The TabController is owned by MainScreen so the AppBar tab bar and
  /// this TabBarView stay in sync without any coordination layer.
  final TabController tabCtrl;

  const OrdersScreen({super.key, required this.tabCtrl});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  Timer? _ticker;

  // Retail vs B2B toggle — both providers are fetched up front (a vendor may
  // have both kinds of assignments); this only switches which list feeds
  // the same status-filter tabs below.
  bool _showB2b = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    // Rebuild every second so service-deadline timers tick live
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _fetch() {
    final token = context.read<AuthProvider>().token ?? '';
    final retail = context.read<OrderProvider>();
    final b2b    = context.read<B2bOrderProvider>();
    if (retail.orders.isEmpty) retail.fetchOrders(token);
    if (b2b.orders.isEmpty) b2b.fetchOrders(token);
  }

  List<OrderModel> _filtered(String filter, List<OrderModel> all) {
    switch (filter) {
      case 'new':       return all.where((o) => o.isPending).toList();
      case 'active':    return all.where((o) => o.isActive).toList();
      case 'completed': return all.where((o) => o.isCompleted).toList();
      case 'cancelled':
        return all.where((o) => o.isRejected || o.isCancelled).toList();
      default:          return all;
    }
  }

  static const _filters = [
    'all', 'new', 'active', 'completed', 'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final retailProvider = context.watch<OrderProvider>();
    final b2bProvider    = context.watch<B2bOrderProvider>();
    final token = context.read<AuthProvider>().token ?? '';

    final isLoading = _showB2b ? b2bProvider.isLoading : retailProvider.isLoading;
    final error     = _showB2b ? b2bProvider.error : retailProvider.error;
    final allOrders = _showB2b ? b2bProvider.orders : retailProvider.orders;
    void onRetry() => _showB2b
        ? b2bProvider.fetchOrders(token)
        : retailProvider.fetchOrders(token);

    return Column(
      children: [
        _TypeToggle(
          showB2b: _showB2b,
          onChanged: (v) => setState(() => _showB2b = v),
        ),
        Expanded(
          child: TabBarView(
            controller: widget.tabCtrl,
            children: _filters.map((filter) {
              final orders = _filtered(filter, allOrders);

              if (isLoading) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading orders…',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              if (error != null && orders.isEmpty) {
                return _ErrorView(
                  error: error,
                  onRetry: onRetry,
                );
              }

              if (orders.isEmpty) {
                return _EmptyView(filter: filter, showB2b: _showB2b);
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => onRetry(),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return OrderCard(
                      order: o,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _showB2b
                              ? B2bOrderDetailScreen(order: o)
                              : OrderDetailScreen(order: o),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Retail / B2B segmented toggle ─────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final bool showB2b;
  final ValueChanged<bool> onChanged;
  const _TypeToggle({required this.showB2b, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _segment('Retail', !showB2b, () => onChanged(false))),
          Expanded(child: _segment('B2B', showB2b, () => onChanged(true))),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String filter;
  final bool showB2b;
  const _EmptyView({required this.filter, required this.showB2b});

  static const _labels = {
    'all': 'No orders yet',
    'new': 'No new orders',
    'active': 'No active orders',
    'completed': 'No completed orders',
    'cancelled': 'No cancelled orders',
  };

  static const _subtitles = {
    'all': 'Orders assigned to you will appear here.',
    'new': 'New orders will show up when admin assigns them.',
    'active': 'Accepted and in-progress orders appear here.',
    'completed': 'Finished orders will appear here.',
    'cancelled': 'Rejected or cancelled orders appear here.',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
                '${_labels[filter] ?? 'No orders'}${showB2b ? ' (B2B)' : ''}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              _subtitles[filter] ?? 'No orders in this category.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
