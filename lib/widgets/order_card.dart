import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  Color get _statusColor {
    switch (order.status) {
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

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.active:
        return 'Active';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(order.serviceName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(
                    '₹${order.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(order.createdAt),
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
