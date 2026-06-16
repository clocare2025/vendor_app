import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import '../../widgets/stat_card.dart';
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
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => orderProvider.fetchOrders(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        Text(
                          vendor?.name ?? 'Vendor',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                        child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(AppStrings.todayOverview, style: Theme.of(context).textTheme.titleMedium),
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
                    value: '₹${orderProvider.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee_rounded,
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.recentOrders, style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => MainScreen.switchToOrdersTab(context),
                    child: const Text(AppStrings.viewAll, style: TextStyle(color: AppColors.primary)),
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
                    child: Text('No orders yet', style: TextStyle(color: AppColors.textHint)),
                  ),
                )
              else
                ...orderProvider.orders.take(4).map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OrderCard(
                      order: order,
                      onTap: () => _openOrderDetail(context, order),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOrderDetail(BuildContext context, OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
    );
  }
}
