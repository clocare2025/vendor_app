import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  _StatusStyle get _style {
    switch (order.status) {
      case 'assigned':
        return _StatusStyle('New Order', AppColors.statusPending,
            const Color(0xFFFFFBEB), Icons.notifications_active_rounded);
      case 'accepted':
        return _StatusStyle('Accepted', AppColors.statusActive,
            const Color(0xFFEFF6FF), Icons.check_circle_outline_rounded);
      case 'picked_up':
        return _StatusStyle('Picked Up', const Color(0xFF7C3AED),
            const Color(0xFFF5F3FF), Icons.inventory_2_outlined);
      case 'processing':
        return _StatusStyle('Processing', const Color(0xFF0284C7),
            const Color(0xFFE0F2FE), Icons.local_laundry_service_rounded);
      case 'completed':
        return _StatusStyle('Completed', AppColors.statusCompleted,
            const Color(0xFFF0FDF4), Icons.task_alt_rounded);
      case 'rejected':
        return _StatusStyle('Rejected', AppColors.error,
            const Color(0xFFFEF2F2), Icons.cancel_outlined);
      case 'cancelled':
        return _StatusStyle('Cancelled', AppColors.textHint,
            AppColors.background, Icons.block_rounded);
      default:
        return _StatusStyle('Unknown', AppColors.textHint,
            AppColors.background, Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final remaining = order.timerRunning ? order.remainingTime : null;
    final isOverdue = remaining != null && remaining.isNegative;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order number + status badge ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber.isNotEmpty
                              ? '#${order.orderNumber}'
                              : '#${order.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(order.serviceName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: s.bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: s.color.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 12, color: s.color),
                        const SizedBox(width: 4),
                        Text(s.label,
                            style: TextStyle(
                                color: s.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── Vendor amount ──
              Row(
                children: [
                  const Icon(Icons.currency_rupee_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  const Text('Your Earnings',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('₹${order.vendorAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 10),

              // ── Timing row ──
              Row(
                children: [
                  _timeChip(Icons.schedule_rounded, 'Assigned',
                      DateFormat('MMM d, h:mm a').format(order.assignedAt.toLocal())),
                  if (order.pickupAt != null ||
                      order.pickupTimeSlot.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    _timeChip(
                      Icons.directions_car_outlined,
                      'Pickup',
                      order.pickupAt != null
                          ? '${DateFormat('MMM d').format(order.pickupAt!.toLocal())}${order.pickupTimeSlot.isNotEmpty ? ' • ${order.pickupTimeSlot}' : ''}'
                          : order.pickupTimeSlot,
                    ),
                  ],
                ],
              ),

              // ── Service timer (shown on picked_up / processing) ──
              if (remaining != null) ...[
                const SizedBox(height: 10),
                _TimerChip(remaining: remaining, isOverdue: isOverdue),
              ],

              // ── "Tap to act" hint for actionable states ──
              if (order.isAssigned) ...[
                const SizedBox(height: 10),
                _hintChip(
                  Icons.touch_app_rounded,
                  'Tap to Accept or Reject',
                  const Color(0xFFFDE68A),
                  const Color(0xFFF59E0B),
                ),
              ] else if (order.isAccepted) ...[
                const SizedBox(height: 10),
                _hintChip(
                  Icons.inventory_2_outlined,
                  'Tap to confirm Pickup',
                  const Color(0xFFDDD6FE),
                  const Color(0xFF7C3AED),
                ),
              ] else if (order.isPickedUp) ...[
                const SizedBox(height: 10),
                _hintChip(
                  Icons.play_circle_outline,
                  'Tap to Start Processing',
                  const Color(0xFFBAE6FD),
                  const Color(0xFF0284C7),
                ),
              ] else if (order.isProcessing) ...[
                const SizedBox(height: 10),
                _hintChip(
                  Icons.task_alt_rounded,
                  'Tap to mark Completed',
                  const Color(0xFFBBF7D0),
                  AppColors.statusCompleted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeChip(IconData icon, String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      );

  Widget _hintChip(
          IconData icon, String text, Color bg, Color color) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      );
}

// ── Inline timer chip shown on the card ──────────────────────────────────────

class _TimerChip extends StatelessWidget {
  final Duration remaining;
  final bool isOverdue;
  const _TimerChip({required this.remaining, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final abs = remaining.abs();
    final hh = abs.inHours.toString().padLeft(2, '0');
    final mm = (abs.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (abs.inSeconds % 60).toString().padLeft(2, '0');
    final display =
        isOverdue ? 'Overdue: -$hh:$mm:$ss' : 'Timer: $hh:$mm:$ss';

    final color = isOverdue
        ? AppColors.error
        : remaining.inMinutes < 60
            ? const Color(0xFFF59E0B)
            : AppColors.statusCompleted;
    final bg = isOverdue
        ? const Color(0xFFFEF2F2)
        : remaining.inMinutes < 60
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF0FDF4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(display,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _StatusStyle(this.label, this.color, this.bgColor, this.icon);
}
