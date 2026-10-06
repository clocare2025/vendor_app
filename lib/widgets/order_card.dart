import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  _StatusTheme get _theme {
    // inward_done = OTP verified, garments returned → show as Completed
    if (order.isInwardDone) {
      return _StatusTheme('Completed', AppColors.accent,
          const Color(0xFFF0FDF4), Icons.task_alt_rounded);
    }
    // status=5: processing done, waiting for supervisor OTP scan
    if (order.isInwardPending) {
      return _StatusTheme('OTP Pending', const Color(0xFFF59E0B),
          const Color(0xFFFFFBEB), Icons.key_rounded);
    }
    switch (order.status) {
      case 'assigned':
        return _StatusTheme('New Order', AppColors.newOrder,
            const Color(0xFFFFF7ED), Icons.notification_important_rounded);
      case 'accepted':
        return _StatusTheme('Accepted', AppColors.primary,
            AppColors.primaryLight, Icons.check_circle_outline_rounded);
      case 'picked_up':
        return _StatusTheme('Picked Up', const Color(0xFF7C3AED),
            const Color(0xFFF5F3FF), Icons.inventory_2_outlined);
      case 'processing':
        return _StatusTheme('Processing', const Color(0xFF0369A1),
            const Color(0xFFE0F2FE), Icons.local_laundry_service_rounded);
      case 'completed':
        return _StatusTheme('Completed', AppColors.accent,
            const Color(0xFFF0FDF4), Icons.task_alt_rounded);
      case 'rejected':
        return _StatusTheme('Rejected', AppColors.error,
            const Color(0xFFFEF2F2), Icons.cancel_outlined);
      default:
        return _StatusTheme('Unknown', AppColors.textHint,
            AppColors.background, Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Coloured left border
                  Container(width: 5, color: t.color),

                  // Card body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order number + status badge
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        order.orderNumber.isNotEmpty
                                            ? '#${order.orderNumber}'
                                            : '#${order.id.substring(0, 8).toUpperCase()}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.2),
                                      ),
                                      if (order.isB2b) ...[
                                        const SizedBox(width: 6),
                                        const _B2bChip(),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(order.serviceName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            _Badge(theme: t),
                          ]),
                          const SizedBox(height: 12),

                          // Earnings + date
                          Row(children: [
                            _InfoChip(
                              icon: Icons.currency_rupee_rounded,
                              label: '₹${order.vendorAmount.toStringAsFixed(0)}',
                              color: AppColors.accent,
                              bg: const Color(0xFFF0FDF4),
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              label: DateFormat('MMM d, h:mm a')
                                  .format(order.assignedAt.toLocal()),
                              color: AppColors.textSecondary,
                              bg: AppColors.background,
                            ),
                          ]),

                          // Pickup slot
                          if (order.pickupAt != null ||
                              order.pickupTimeSlot.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoChip(
                              icon: Icons.directions_car_outlined,
                              label: _pickupLabel(),
                              color: AppColors.textSecondary,
                              bg: AppColors.background,
                            ),
                          ],

                          // ── Service deadline timer (self-ticking) ───────────
                          if (order.timerRunning &&
                              order.serviceDeadline != null) ...[
                            const SizedBox(height: 8),
                            _LiveTimerBar(
                              deadline:    order.serviceDeadline!,
                              durationHrs: order.serviceDurationHours,
                            ),
                          ],

                          // ── Warehouse received banner ────────────────────────
                          if (order.isInwardDone) ...[
                            const SizedBox(height: 10),
                            _WarehouseReceivedBanner(),
                          ],

                          // Action hint
                          if (_actionHint != null) ...[
                            const SizedBox(height: 10),
                            _ActionHint(hint: _actionHint!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _pickupLabel() {
    final parts = <String>[];
    if (order.pickupAt != null) {
      parts.add(DateFormat('MMM d').format(order.pickupAt!.toLocal()));
    }
    if (order.pickupTimeSlot.isNotEmpty) parts.add(order.pickupTimeSlot);
    return parts.join(' · ');
  }

  _HintData? get _actionHint {
    if (order.isAssigned) {
      return _HintData(Icons.touch_app_rounded, 'Tap to Accept or Reject',
          AppColors.newOrder, const Color(0xFFFFF7ED));
    }
    if (order.isAccepted) {
      return _HintData(Icons.inventory_2_outlined, 'Tap to confirm Pickup',
          const Color(0xFF7C3AED), const Color(0xFFF5F3FF));
    }
    if (order.isPickedUp) {
      return _HintData(Icons.play_circle_outline, 'Tap to Start Processing',
          const Color(0xFF0369A1), const Color(0xFFE0F2FE));
    }
    if (order.isProcessing) {
      return _HintData(Icons.warehouse_outlined, 'Tap to Return to Warehouse',
          const Color(0xFF1E40AF), const Color(0xFFEFF6FF));
    }
    if (order.isInwardPending) {
      return _HintData(Icons.pending_outlined,
          'Waiting for supervisor to scan OTP',
          const Color(0xFFF59E0B), const Color(0xFFFFFBEB));
    }
    return null;
  }
}

// ── B2B chip — small tag distinguishing B2B orders from retail in the list ──

class _B2bChip extends StatelessWidget {
  const _B2bChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: const Text('B2B',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary)),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final _StatusTheme theme;
  const _Badge({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(theme.icon, size: 12, color: theme.color),
          const SizedBox(width: 5),
          Text(theme.label,
              style: TextStyle(
                  color: theme.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Self-ticking timer bar ────────────────────────────────────────────────────
// StatefulWidget with its own Timer so it updates every second independently.

class _LiveTimerBar extends StatefulWidget {
  final DateTime deadline;
  final int durationHrs;

  const _LiveTimerBar({required this.deadline, required this.durationHrs});

  @override
  State<_LiveTimerBar> createState() => _LiveTimerBarState();
}

class _LiveTimerBarState extends State<_LiveTimerBar> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final isOverdue = remaining.isNegative;
    final abs       = remaining.abs();
    final hh  = abs.inHours.toString().padLeft(2, '0');
    final mm  = (abs.inMinutes % 60).toString().padLeft(2, '0');
    final ss  = (abs.inSeconds % 60).toString().padLeft(2, '0');
    final txt = isOverdue ? 'Overdue  -$hh:$mm:$ss' : '$hh:$mm:$ss remaining';

    final Color bar = isOverdue
        ? AppColors.error
        : remaining.inMinutes < 60
            ? AppColors.warning
            : AppColors.accent;

    final double progress = widget.durationHrs > 0
        ? (1.0 - (remaining.inSeconds / (widget.durationHrs * 3600)))
            .clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(isOverdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
              size: 13, color: bar),
          const SizedBox(width: 5),
          Text(txt,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: bar)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(bar),
          ),
        ),
      ],
    );
  }
}

// ── Warehouse received banner ─────────────────────────────────────────────────

class _WarehouseReceivedBanner extends StatelessWidget {
  const _WarehouseReceivedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
          SizedBox(width: 8),
          Text('Garments received at warehouse ✅',
              style: TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Action hint strip ─────────────────────────────────────────────────────────

class _ActionHint extends StatelessWidget {
  final _HintData hint;
  const _ActionHint({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: hint.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hint.color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(hint.icon, size: 14, color: hint.color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(hint.text,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hint.color)),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 10, color: hint.color.withAlpha(150)),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _StatusTheme {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusTheme(this.label, this.color, this.bg, this.icon);
}

class _HintData {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
  const _HintData(this.icon, this.text, this.color, this.bg);
}
