import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';

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
    final p     = context.read<OrderProvider>();
    if (p.orders.isEmpty) p.fetchOrders(token);
  }

  List _orders(String filter, OrderProvider p) {
    switch (filter) {
      case 'new':       return p.pendingOrders;
      case 'active':    return p.activeOrders;
      case 'completed': return p.completedOrders;
      case 'cancelled':
        return p.orders.where((o) => o.isRejected || o.isCancelled).toList();
      default:          return p.orders;
    }
  }

  static const _filters = [
    'all', 'new', 'active', 'completed', 'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final token    = context.read<AuthProvider>().token ?? '';

    return TabBarView(
      controller: widget.tabCtrl,
      children: _filters.map((filter) {
        final orders = _orders(filter, provider);

        if (provider.isLoading) {
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

        if (provider.error != null && orders.isEmpty) {
          return _ErrorView(
            error: provider.error!,
            onRetry: () => provider.fetchOrders(token),
          );
        }

        if (orders.isEmpty) {
          return _EmptyView(filter: filter);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => provider.fetchOrders(token),
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
                      builder: (_) => OrderDetailScreen(order: o)),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String filter;
  const _EmptyView({required this.filter});

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
            Text(_labels[filter] ?? 'No orders',
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
