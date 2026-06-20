import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/status_provider.dart';
import '../../widgets/online_toggle.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';

// ─── Tab definition ──────────────────────────────────────────────────────────

class _Tab {
  final String label;
  final String filter;
  final IconData icon;
  const _Tab(this.label, this.filter, this.icon);
}

const _tabs = [
  _Tab('All', 'all', Icons.grid_view_rounded),
  _Tab('New', 'new', Icons.notifications_active_rounded),
  _Tab('Active', 'active', Icons.loop_rounded),
  _Tab('Completed', 'completed', Icons.check_circle_outline_rounded),
  _Tab('Cancelled', 'cancelled', Icons.cancel_outlined),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
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
    _tabCtrl = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          context.read<OrderProvider>().setFilter(_tabs[_tabCtrl.index].filter);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    // Tick every second so timer bars on active-order cards update live
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
    final p = context.read<OrderProvider>();
    if (p.orders.isEmpty) p.fetchOrders(token);
  }

  /// Called externally (from MainScreen) to jump to a specific tab
  void selectTab(String filter) {
    final idx = _tabs.indexWhere((t) => t.filter == filter);
    if (idx != -1) _tabCtrl.animateTo(idx);
    context.read<OrderProvider>().setFilter(filter);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final statusPvd = context.watch<StatusProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    final pending = provider.pendingOrders.length;
    final total = provider.orders.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 110,
            collapsedHeight: kToolbarHeight,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primaryGrad2,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => provider.fetchOrders(token),
                tooltip: 'Refresh',
              ),
              OnlineToggle(statusPvd: statusPvd, token: token),
            ],
            // Use LayoutBuilder so we can detect collapsed vs expanded
            // and avoid the double "My Orders" + bad titlePadding bugs.
            flexibleSpace: LayoutBuilder(
              builder: (lCtx, constraints) {
                final topPad     = MediaQuery.of(lCtx).padding.top;
                final maxH       = constraints.maxHeight;
                final minH       = kToolbarHeight + topPad;
                final collapsed  = maxH <= minH + 4;

                return Container(
                  decoration: const BoxDecoration(
                      gradient: AppColors.headerGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 100, 8),
                      child: collapsed
                          // Collapsed: single compact title row
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'My Orders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          // Expanded: full heading + subtitle
                          : Column(
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
                                const SizedBox(height: 3),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withAlpha(180),
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '$total order${total == 1 ? '' : 's'}',
                                      ),
                                      if (pending > 0) ...[
                                        const TextSpan(text: '  ·  '),
                                        TextSpan(
                                          text: '$pending new',
                                          style: const TextStyle(
                                            color: Color(0xFFFBBF24),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
            // Filter tabs pinned to bottom of AppBar
            bottom: _TabBar(
              controller: _tabCtrl,
              provider: provider,
              pending: pending,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((tab) {
            final orders = _getOrders(tab.filter, provider);
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Loading orders…',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
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
              return _EmptyView(filter: tab.label);
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

  List _getOrders(String filter, OrderProvider p) {
    switch (filter) {
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

// ─── Tab Bar ─────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final OrderProvider provider;
  final int pending;

  const _TabBar({
    required this.controller,
    required this.provider,
    required this.pending,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  int _badgeCount(String filter) {
    switch (filter) {
      case 'new':
        return pending;
      case 'active':
        return provider.activeOrders.length;
      case 'completed':
        return provider.completedOrders.length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.primaryGrad2,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(30),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        tabs: _tabs.map((t) {
          final count = _badgeCount(t.filter);
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
                      color: t.filter == 'new'
                          ? AppColors.newOrder
                          : Colors.white.withAlpha(50),
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
    );
  }
}

// ─── Empty / Error views ──────────────────────────────────────────────────────

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
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'All'
                  ? 'Orders assigned to you will appear here.'
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
