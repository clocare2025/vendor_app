import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild every second so the countdown ticks
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Status badge style ──────────────────────────────────────────────────────

  _BadgeStyle _badge(String status) {
    switch (status) {
      case 'assigned':
        return _BadgeStyle('New Order', AppColors.statusPending, const Color(0xFFFFFBEB));
      case 'accepted':
        return _BadgeStyle('Accepted', AppColors.statusActive, const Color(0xFFEFF6FF));
      case 'picked_up':
        return _BadgeStyle('Picked Up', const Color(0xFF7C3AED), const Color(0xFFF5F3FF));
      case 'processing':
        return _BadgeStyle('Processing', const Color(0xFF0284C7), const Color(0xFFE0F2FE));
      case 'completed':
        return _BadgeStyle('OTP Pending', const Color(0xFFF59E0B), const Color(0xFFFFFBEB));
      case 'inward_done':
        return _BadgeStyle('Completed', AppColors.accent, const Color(0xFFF0FDF4));
      case 'rejected':
        return _BadgeStyle('Rejected', AppColors.error, const Color(0xFFFEF2F2));
      default:
        return _BadgeStyle('Unknown', AppColors.textHint, AppColors.background);
    }
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  Future<String?> _rejectDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a reason (optional):',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            ...[
              'Out of service area',
              'Capacity full',
              'Technical issue',
              'Vendor unavailable',
            ].map((r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(r, style: const TextStyle(fontSize: 13)),
                  onTap: () {
                    ctrl.text = r;
                    Navigator.pop(ctx, r);
                  },
                )),
            const Divider(),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'Custom reason...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String body, Color btnColor) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: btnColor),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ==
        true;
  }

  // ── Action handlers ─────────────────────────────────────────────────────────

  Future<void> _accept(OrderModel o) async {
    final p = context.read<OrderProvider>();
    final token = context.read<AuthProvider>().token!;
    final ok = await p.acceptOrder(token, o.id);
    if (!mounted) return;
    _snack(ok ? 'Order accepted!' : (p.error ?? 'Failed'),
        ok ? AppColors.statusCompleted : AppColors.error);
  }

  Future<void> _reject(OrderModel o) async {
    final reason = await _rejectDialog();
    if (!mounted || reason == null) return;
    final p = context.read<OrderProvider>();
    final token = context.read<AuthProvider>().token!;
    final ok = await p.rejectOrder(token, o.id, reason: reason);
    if (!mounted) return;
    _snack(ok ? 'Order rejected.' : (p.error ?? 'Failed'),
        ok ? AppColors.textSecondary : AppColors.error);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _pickup(OrderModel o) async {
    final confirmed = await _confirm(
      'Confirm Pickup',
      'Confirm you have collected the order from the warehouse. The service timer will start now.',
      const Color(0xFF7C3AED),
    );
    if (!confirmed || !mounted) return;
    final p = context.read<OrderProvider>();
    final token = context.read<AuthProvider>().token!;
    final ok = await p.pickupOrder(token, o.id);
    if (!mounted) return;
    _snack(ok ? 'Pickup confirmed! Timer started.' : (p.error ?? 'Failed'),
        ok ? const Color(0xFF7C3AED) : AppColors.error);
  }

  Future<void> _startProcessing(OrderModel o) async {
    final confirmed = await _confirm(
      'Start Processing',
      'Confirm you are starting to process this order.',
      const Color(0xFF0284C7),
    );
    if (!confirmed || !mounted) return;
    final p = context.read<OrderProvider>();
    final token = context.read<AuthProvider>().token!;
    final ok = await p.startProcessing(token, o.id);
    if (!mounted) return;
    _snack(ok ? 'Processing started!' : (p.error ?? 'Failed'),
        ok ? const Color(0xFF0284C7) : AppColors.error);
  }

  Future<void> _complete(OrderModel o) async {
    final confirmed = await _confirm(
      'Return to Warehouse',
      'Confirm processing is done. An OTP will be generated — show it to the supervisor to confirm garment return.',
      const Color(0xFF1E40AF),
    );
    if (!confirmed || !mounted) return;

    final p     = context.read<OrderProvider>();
    final auth  = context.read<AuthProvider>();
    final token = auth.token!;

    final otp = await p.completeProcessingWithOtp(token, o.id);
    if (!mounted) return;

    if (otp != null && otp.isNotEmpty) {
      _showOtpSheet(o, otp);
    } else {
      _snack(p.error ?? 'Failed to complete processing', AppColors.error);
    }
  }

  void _showOtpSheet(OrderModel o, String otp) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OtpBottomSheet(
        processId:   o.id,
        orderNumber: o.orderNumber,
        service:     o.serviceName,
        initialOtp:  otp,
        onVerified:  () {
          Navigator.of(context).pop(); // close sheet
          // Refresh the order so it shows inward_done state
          final auth = context.read<AuthProvider>();
          context.read<OrderProvider>().fetchOrders(auth.token ?? '');
        },
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final o = context.select<OrderProvider, OrderModel>((p) =>
        p.orders.firstWhere((x) => x.id == widget.order.id,
            orElse: () => widget.order));
    final isActing = context.watch<OrderProvider>().isActing;
    final badge = _badge(o.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(o.orderNumber.isNotEmpty
            ? '#${o.orderNumber}'
            : '#${o.id}'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status + progress stepper ─────────────────────────────────
              _StatusBanner(o: o, badge: badge),
              const SizedBox(height: 16),

              // ── Service countdown timer (visible when timer is running) ───
              if ((o.timerRunning || o.isCompleted) && o.serviceDeadline != null)
                _TimerCard(o: o),
              if ((o.timerRunning || o.isCompleted) && o.serviceDeadline != null)
                const SizedBox(height: 16),

              // ── Service info ──────────────────────────────────────────────
              _sectionTitle('Service Details'),
              _card([
                _row(Icons.local_laundry_service_outlined, 'Service', o.serviceName),
                if (o.category.isNotEmpty)
                  _row(Icons.category_outlined, 'Category', o.category),
                _row(Icons.currency_rupee_rounded, 'Your Earnings',
                    '₹${o.vendorAmount.toStringAsFixed(0)}',
                    valueColor: AppColors.primary),
                if (o.serviceDuration.isNotEmpty)
                  _row(Icons.timer_outlined, 'Service Duration', o.serviceDuration),
              ]),
              const SizedBox(height: 16),

              // ── Timeline ──────────────────────────────────────────────────
              _sectionTitle('Timeline'),
              _card([
                _row(Icons.schedule_rounded, 'Assigned',
                    _fmt(o.assignedAt)),
                if (o.pickupAt != null || o.pickupTimeSlot.isNotEmpty)
                  _row(Icons.directions_car_outlined, 'Customer Pickup Slot',
                      _pickupStr(o)),
                if (o.acceptedAt != null)
                  _row(Icons.check_circle_outline, 'Accepted', _fmt(o.acceptedAt!)),
                if (o.pickedUpAt != null)
                  _row(Icons.inventory_2_outlined, 'Picked Up', _fmt(o.pickedUpAt!)),
                if (o.processingStartedAt != null)
                  _row(Icons.play_circle_outline, 'Processing Started',
                      _fmt(o.processingStartedAt!)),
                if (o.processingCompletedAt != null)
                  _row(Icons.task_alt_rounded, 'Processing Completed',
                      _fmt(o.processingCompletedAt!),
                      valueColor: AppColors.statusCompleted),
              ]),
              const SizedBox(height: 16),

              // ── Items ─────────────────────────────────────────────────────
              if (o.items.isNotEmpty) ...[
                _sectionTitle('Items & Vendor Prices'),
                _ItemsTable(o: o),
                const SizedBox(height: 16),
              ],

              // ── Reject reason ─────────────────────────────────────────────
              if (o.isRejected &&
                  o.rejectReason != null &&
                  o.rejectReason!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rejection Reason',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.error)),
                            const SizedBox(height: 4),
                            Text(o.rejectReason!,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Action buttons ────────────────────────────────────────────
              if (isActing)
                const Center(child: CircularProgressIndicator())
              else
                _ActionButtons(
                  o: o,
                  onAccept: () => _accept(o),
                  onReject: () => _reject(o),
                  onPickup: () => _pickup(o),
                  onStartProcessing: () => _startProcessing(o),
                  onComplete: () => _complete(o),
                  onShowOtp: (o.isInwardPending && o.inwardOtp != null)
                      ? () => _showOtpSheet(o, o.inwardOtp!)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ──────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary)),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(children: children),
      );

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(height: 2),
                  Text(value.isEmpty ? '—' : value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: valueColor != null
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: valueColor ?? AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      );

  String _fmt(DateTime dt) => DateFormat('EEE, MMM d • h:mm a').format(dt.toLocal());

  String _pickupStr(OrderModel o) {
    final parts = <String>[];
    if (o.pickupAt != null) parts.add(DateFormat('EEE, MMM d').format(o.pickupAt!.toLocal()));
    if (o.pickupTimeSlot.isNotEmpty) parts.add(o.pickupTimeSlot);
    return parts.join(' • ');
  }
}

// ── Status Banner + Stepper ───────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final OrderModel o;
  final _BadgeStyle badge;
  const _StatusBanner({required this.o, required this.badge});

  static const _steps = [
    _Step('Assigned',   'assigned'),
    _Step('Accepted',   'accepted'),
    _Step('Picked Up',  'picked_up'),
    _Step('Processing', 'processing'),
    _Step('OTP',        'completed'),    // processing done, awaiting supervisor OTP
    _Step('Completed',  'inward_done'), // OTP verified → job done
  ];

  int get _currentIdx {
    final statuses = _steps.map((s) => s.key).toList();
    final idx = statuses.indexOf(o.status);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIdx;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge.color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badge.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badge.color.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: badge.color),
                    const SizedBox(width: 6),
                    Text(badge.label,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: badge.color)),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, h:mm a').format(o.assignedAt.toLocal()),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          if (!o.isRejected) ...[
            const SizedBox(height: 14),
            Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final done = stepIdx < idx;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: done ? AppColors.primary : AppColors.divider,
                    ),
                  );
                }
                final stepIdx = i ~/ 2;
                final done = stepIdx <= idx;
                final active = stepIdx == idx;
                return Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: done ? AppColors.primary : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done ? AppColors.primary : AppColors.divider,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _steps[stepIdx].label,
                      style: TextStyle(
                        fontSize: 9,
                        color: done ? AppColors.primary : AppColors.textHint,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Service Countdown Timer ───────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final OrderModel o;
  const _TimerCard({required this.o});

  @override
  Widget build(BuildContext context) {
    final deadline = o.serviceDeadline;
    if (deadline == null) return const SizedBox.shrink();

    // ── Completed state — timer must NOT keep running ────────────────────────
    if (o.isCompleted) {
      final completedAt = o.processingCompletedAt;
      final onTime = completedAt == null || !completedAt.isAfter(deadline);
      final bgColor = onTime ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
      final borderColor = onTime ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
      final color = onTime ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              onTime ? Icons.task_alt_rounded : Icons.check_circle_outline,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onTime ? 'Completed On Time' : 'Completed (Late)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color),
                  ),
                  if (completedAt != null)
                    Text(
                      'Finished: ${DateFormat('h:mm a, MMM d').format(completedAt.toLocal())}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  Text(
                    'Deadline was: ${DateFormat('h:mm a, MMM d').format(deadline.toLocal())}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Active timer (picked_up or processing) ───────────────────────────────
    final remaining = deadline.difference(DateTime.now());
    final isOverdue = remaining.isNegative;
    final isWarning = !isOverdue && remaining.inMinutes < 60;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (isOverdue) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      textColor = AppColors.error;
      icon = Icons.warning_amber_rounded;
      label = 'OVERDUE';
    } else if (isWarning) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFFF59E0B);
      icon = Icons.timer_outlined;
      label = 'Almost Due';
    } else {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF16A34A);
      icon = Icons.timer_outlined;
      label = 'On Track';
    }

    final abs = remaining.abs();
    final hh = abs.inHours.toString().padLeft(2, '0');
    final mm = (abs.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (abs.inSeconds % 60).toString().padLeft(2, '0');
    final display = isOverdue ? '-$hh:$mm:$ss' : '$hh:$mm:$ss';

    final totalSecs = o.serviceDurationHours * 3600;
    final usedSecs = totalSecs - remaining.inSeconds;
    final progress = totalSecs > 0
        ? (usedSecs / totalSecs).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: textColor)),
              const Spacer(),
              Text(
                isOverdue ? 'Overdue by' : 'Time remaining',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            display,
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Started',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
              Text(
                o.pickedUpAt != null
                    ? DateFormat('h:mm a').format(o.pickedUpAt!.toLocal())
                    : '',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint),
              ),
              Text(
                'Due ${DateFormat('h:mm a, MMM d').format(deadline.toLocal())}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Items Table ───────────────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final OrderModel o;
  const _ItemsTable({required this.o});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Item', style: _hStyle)),
                SizedBox(width: 8),
                Text('Qty', style: _hStyle),
                SizedBox(width: 20),
                Text('Price', style: _hStyle),
                SizedBox(width: 16),
                Text('Total', style: _hStyle),
              ],
            ),
          ),
          ...o.items.map((item) => Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.divider))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Category name + qty / price / total ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text('${item.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                              '₹${item.vendorPrice.toStringAsFixed(0)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                              '₹${item.total.toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                    // ── Garment / cloth type chips ──
                    if (item.typesOfClothes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.typesOfClothes
                            .map((cloth) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.divider),
                                  ),
                                  child: Text(
                                    cloth,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              )),
          // Total row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider, width: 2))),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Total Earnings',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary))),
                Text('₹${o.vendorAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _hStyle = TextStyle(
      fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary);
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final OrderModel o;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onPickup;
  final VoidCallback onStartProcessing;
  final VoidCallback onComplete;
  final VoidCallback? onShowOtp; // re-opens the OTP bottom sheet

  const _ActionButtons({
    required this.o,
    required this.onAccept,
    required this.onReject,
    required this.onPickup,
    required this.onStartProcessing,
    required this.onComplete,
    this.onShowOtp,
  });

  @override
  Widget build(BuildContext context) {
    if (o.isAssigned) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    if (o.isAccepted) {
      return _fullBtn(
        icon: Icons.inventory_2_outlined,
        label: 'Pickup Done — Start Timer',
        color: const Color(0xFF7C3AED),
        onPressed: onPickup,
      );
    }

    if (o.isPickedUp) {
      return _fullBtn(
        icon: Icons.play_circle_outline_rounded,
        label: 'Start Processing',
        color: const Color(0xFF0284C7),
        onPressed: onStartProcessing,
      );
    }

    if (o.isProcessing || (o.isPickedUp && !o.isAccepted)) {
      return _fullBtn(
        icon: Icons.warehouse_outlined,
        label: 'Done — Return to Warehouse',
        color: const Color(0xFF1E40AF),
        onPressed: onComplete,
      );
    }

    // Inward pending — waiting indicator + single button to show OTP sheet
    if (o.isInwardPending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Waiting indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Waiting for supervisor to verify OTP…',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Show OTP button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onShowOtp,
              icon: const Icon(Icons.key_rounded, size: 18),
              label: const Text('Show OTP to Supervisor',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _fullBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _BadgeStyle {
  final String label;
  final Color color;
  final Color bgColor;
  const _BadgeStyle(this.label, this.color, this.bgColor);
}

class _Step {
  final String label;
  final String key;
  const _Step(this.label, this.key);
}

// ── OTP Bottom Sheet ──────────────────────────────────────────────────────────
// Shows the 6-digit inward OTP. Polls every 10 s to detect supervisor
// verification, then shows the "Received ✅" confirmation and calls onVerified.

class _OtpBottomSheet extends StatefulWidget {
  final String processId;
  final String orderNumber;
  final String service;
  final String initialOtp;
  final VoidCallback onVerified;

  const _OtpBottomSheet({
    required this.processId,
    required this.orderNumber,
    required this.service,
    required this.initialOtp,
    required this.onVerified,
  });

  @override
  State<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<_OtpBottomSheet> {
  late String _otp;
  bool _verified = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _otp = widget.initialOtp;
    // Poll every 10 s to detect supervisor verification
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkVerified(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    if (_verified || !mounted) return;
    final token = context.read<AuthProvider>().token ?? '';
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.orderDetail(widget.processId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != true) return;
      // Safe null-aware map access (no ?. on dynamic map)
      final data  = body['data']  is Map ? body['data']  as Map<String, dynamic> : null;
      final order = data != null && data['order'] is Map
          ? data['order'] as Map<String, dynamic>
          : null;
      if (order != null && order['inward_otp_verified'] == true && mounted) {
        setState(() => _verified = true);
        _pollTimer?.cancel();
      }
    } catch (_) {}
  }

  void _copyOtp() {
    Clipboard.setData(ClipboardData(text: _otp));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP copied'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (_verified) ...[
            // ── Verified ──────────────────────────────────────────────────
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF16A34A), size: 64),
            const SizedBox(height: 14),
            const Text('Garments Received!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D))),
            const SizedBox(height: 8),
            const Text(
              'Supervisor verified the OTP.\nGarments are confirmed back in the warehouse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            // ── OTP display ───────────────────────────────────────────────
            // Order info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.orderNumber.isNotEmpty
                            ? '#${widget.orderNumber}'
                            : 'Order',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                      if (widget.service.isNotEmpty)
                        Text(widget.service,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Text('Processing Done',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A))),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Show this OTP to your supervisor',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text(
              'Supervisor enters this in the admin panel to confirm return.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Big OTP digits — tap to copy
            GestureDetector(
              onTap: _copyOtp,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    // 6 digit boxes — Expanded so they never overflow
                    Row(
                      children: List.generate(_otp.length, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withAlpha(40)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _otp[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.copy_rounded,
                            color: Colors.white38, size: 13),
                        const SizedBox(width: 4),
                        Text('Tap to copy',
                            style: TextStyle(
                                color: Colors.white.withAlpha(100),
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Waiting status
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 15, height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Waiting for supervisor to verify in admin panel…',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
