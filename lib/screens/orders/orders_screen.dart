import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  static const tabs = [
    _Tab('All', 'all', Icons.grid_view_rounded),
    _Tab('New', 'new', Icons.notifications_active_rounded),
    _Tab('Active', 'active', Icons.loop_rounded),
    _Tab('Completed', 'completed', Icons.check_circle_outline),
    _Tab('Cancelled', 'cancelled', Icons.cancel_outlined),
  ];

  late TabController tabCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    tabCtrl = TabController(length: tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();

      if (provider.orders.isEmpty) {
        provider.fetchOrders(context.read<AuthProvider>().token ?? '');
      }
    });
  }

  @override
  void dispose() {
    tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final token = context.read<AuthProvider>().token ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
        onPressed: () {
          provider.fetchOrders(token);
        },
      ),

      body: NestedScrollView(
        headerSliverBuilder: (_, __) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 100,
              collapsedHeight: 70,
              automaticallyImplyLeading: false,

              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),

                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [
                        const Text(
                          "Orders",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${provider.orders.length} Total Orders",

                          style: TextStyle(color: Colors.white.withOpacity(.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                IconButton(
                  onPressed: () {
                    provider.fetchOrders(token);
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],

              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),

                child: Container(
                  height: 60,

                  padding: const EdgeInsets.only(left: 12, bottom: 8),

                  child: TabBar(
                    controller: tabCtrl,

                    isScrollable: true,

                    indicator: BoxDecoration(
                      color: Colors.white.withOpacity(.18),

                      borderRadius: BorderRadius.circular(30),
                    ),

                    dividerColor: Colors.transparent,

                    labelColor: Colors.white,

                    unselectedLabelColor: Colors.white70,

                    tabs: tabs.map((e) {
                      return Tab(
                        child: Row(
                          children: [
                            Icon(e.icon, size: 18),

                            const SizedBox(width: 8),

                            Text(e.label),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ];
        },

        body: TabBarView(
          controller: tabCtrl,

          children: tabs.map((tab) {
            final orders = getOrders(tab.value, provider);

            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    CircularProgressIndicator(),

                    SizedBox(height: 12),

                    Text("Loading Orders..."),
                  ],
                ),
              );
            }

            if (orders.isEmpty) {
              return EmptyView(filter: tab.label);
            }

            return RefreshIndicator(
              onRefresh: () => provider.fetchOrders(token),

              child: ListView.separated(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.all(16),

                itemCount: orders.length,

                separatorBuilder: (_, __) => const SizedBox(height: 16),

                itemBuilder: (_, index) {
                  final order = orders[index];

                  return OrderCard(
                    order: order,

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List getOrders(String filter, OrderProvider p) {
    switch (filter) {
      case 'new':
        return p.pendingOrders;

      case 'active':
        return p.activeOrders;

      case 'completed':
        return p.completedOrders;

      case 'cancelled':
        return p.orders.where((e) => e.isCancelled || e.isRejected).toList();

      default:
        return p.orders;
    }
  }
}

class _Tab {
  final String label;
  final String value;
  final IconData icon;

  const _Tab(this.label, this.value, this.icon);
}

class EmptyView extends StatelessWidget {
  final String filter;

  const EmptyView({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const Icon(Icons.inbox_outlined, size: 70, color: Colors.grey),

          const SizedBox(height: 16),

          Text(
            "No $filter Orders",

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text("Orders will appear here"),
        ],
      ),
    );
  }
}
