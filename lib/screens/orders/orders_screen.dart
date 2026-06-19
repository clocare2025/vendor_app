import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/status_provider.dart';
import '../../widgets/order_card.dart';
import '../home/home_screen.dart' show _OnlineToggle;
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    _Tab(label: 'All', value: 'all', icon: Icons.grid_view_rounded),
    _Tab(
      label: 'New',
      value: 'new',
      icon: Icons.notification_important_rounded,
    ),
    _Tab(label: 'Active', value: 'active', icon: Icons.autorenew_rounded),
    _Tab(label: 'Completed', value: 'completed', icon: Icons.task_alt_rounded),
    _Tab(label: 'Cancelled', value: 'cancelled', icon: Icons.cancel_outlined),
  ];

  late final TabController _tabCtrl;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<OrderProvider>().setFilter(_tabs[_tabCtrl.index].value);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _fetch() {
    final token = context.read<AuthProvider>().token ?? '';
    final provider = context.read<OrderProvider>();
    if (provider.orders.isEmpty) provider.fetchOrders(token);
  }

  void selectTab(String value) {
    final idx = _tabs.indexWhere((t) => t.value == value);
    if (idx != -1) _tabCtrl.animateTo(idx);
    context.read<OrderProvider>().setFilter(value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final statusPvd = context.watch<StatusProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    final pending = provider.pendingOrders.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.primaryGrad2,
            automaticallyImplyLeading: false,
            expandedHeight: 100,
            collapsedHeight: kToolbarHeight,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(ctx).padding.top + 12,
                  76,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'My Orders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.orders.length} order${provider.orders.length == 1 ? '' : 's'}${pending > 0 ? ' · $pending new' : ''}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              title: const Text(
                'My Orders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            //     onPressed: () => provider.fetchOrders(token),
            //     tooltip: 'Refresh',
            //   ),
            //     _OnlineToggle(statusPvd: statusPvd, token: token),
            // ],
            // Filter tabs pinned at the bottom of the AppBar
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: AppColors.primaryGrad2,
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.only(bottom: 4),
                  tabs: _tabs.map((t) {
                    final count = _tabCount(t.value, provider, pending);
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 15),
                          const SizedBox(width: 6),
                          Text(t.label),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: t.value == 'new'
                                    ? AppColors.newOrder
                                    : Colors.white.withAlpha(60),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((t) {
            final filtered = _filteredOrders(t.value, provider);
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && filtered.isEmpty) {
              return _ErrorView(
                error: provider.error!,
                onRetry: () => provider.fetchOrders(token),
              );
            }
            if (filtered.isEmpty) {
              return _EmptyView(filter: t.label);
            }
            return RefreshIndicator(
              onRefresh: () => provider.fetchOrders(token),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final o = filtered[i];
                  return OrderCard(
                    order: o,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: o),
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _tabCount(String value, OrderProvider p, int pending) {
    switch (value) {
      case 'new':
        return pending;
      case 'active':
        return p.activeOrders.length;
      case 'completed':
        return p.completedOrders.length;
      default:
        return 0;
    }
  }

  List _filteredOrders(String value, OrderProvider p) {
    switch (value) {
      case 'new':
        return p.pendingOrders;
      case 'active':
        return p.activeOrders;
      case 'completed':
        return p.completedOrders;
      case 'cancelled':
        return p.orders.where((o) => o.isRejected || o.isCancelled).toList();
      default:
        return p.orders;
    }
  }
}

class _Tab {
  final String label;
  final String value;
  final IconData icon;
  const _Tab({required this.label, required this.value, required this.icon});
}

class _EmptyView extends StatelessWidget {
  final String filter;
  const _EmptyView({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'No $filter orders',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'All'
                  ? 'New orders assigned to you will appear here.'
                  : 'No orders in this category right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
