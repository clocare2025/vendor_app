import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.active:
        return AppColors.statusActive;
      case OrderStatus.completed:
        return AppColors.statusCompleted;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final liveOrder = orderProvider.orders.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    );

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.orderDetails)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${liveOrder.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(liveOrder.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      liveOrder.status.name.toUpperCase(),
                      style: TextStyle(color: _statusColor(liveOrder.status), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.customer, style: Theme.of(context).textTheme.titleMedium),
                      _infoRow(Icons.person_outline, 'Name', liveOrder.customerName),
                      _infoRow(Icons.phone_outlined, 'Phone', liveOrder.customerPhone),
                      _infoRow(Icons.location_on_outlined, 'Address', liveOrder.customerAddress),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.orderDetails, style: Theme.of(context).textTheme.titleMedium),
                      _infoRow(Icons.local_laundry_service_outlined, AppStrings.service, liveOrder.serviceName),
                      _infoRow(Icons.checklist_outlined, 'Items', liveOrder.items.join(', ')),
                      _infoRow(Icons.currency_rupee_rounded, AppStrings.amount, '₹${liveOrder.amount.toStringAsFixed(0)}'),
                      _infoRow(
                        Icons.access_time,
                        'Created',
                        DateFormat('MMM d, yyyy • h:mm a').format(liveOrder.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (liveOrder.status == OrderStatus.pending)
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: AppStrings.reject,
                        isOutlined: true,
                        onPressed: () {
                          orderProvider.updateOrderStatus(liveOrder.id, OrderStatus.cancelled);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: AppStrings.accept,
                        onPressed: () => orderProvider.updateOrderStatus(liveOrder.id, OrderStatus.active),
                      ),
                    ),
                  ],
                )
              else if (liveOrder.status == OrderStatus.active)
                CustomButton(
                  text: AppStrings.markComplete,
                  color: AppColors.accent,
                  onPressed: () => orderProvider.updateOrderStatus(liveOrder.id, OrderStatus.completed),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
