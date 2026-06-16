import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  final List<Map<String, String>> _tabs = const [
    {'label': 'All', 'value': 'all'},
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Active', 'value': 'active'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      if (provider.orders.isEmpty) provider.fetchOrders();
    });
  }

  void selectTab(String value) {
    Provider.of<OrderProvider>(context, listen: false).setFilter(value);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.allOrders)),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final isSelected = orderProvider.filterStatus == tab['value'];
                  return GestureDetector(
                    onTap: () => selectTab(tab['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tab['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: orderProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orderProvider.orders.isEmpty
                      ? const Center(
                          child: Text('No orders found', style: TextStyle(color: AppColors.textHint)),
                        )
                      : RefreshIndicator(
                          onRefresh: () => orderProvider.fetchOrders(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: orderProvider.orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final order = orderProvider.orders[index];
                              return OrderCard(
                                order: order,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
