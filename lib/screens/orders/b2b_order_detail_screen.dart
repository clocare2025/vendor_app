import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/b2b_order_provider.dart';
import '../../widgets/order_detail_widgets.dart';

/// B2B counterpart of OrderDetailScreen — same layout/behavior, wired to
/// B2bOrderProvider (separate provider backing the separate /v1/b2b-orders
/// route family) instead of OrderProvider. Shares OrderStatusBanner /
/// OrderTimerCard / OrderItemsTable / OrderActionButtons / OrderOtpBottomSheet
/// with the retail screen via lib/widgets/order_detail_widgets.dart.
class B2bOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const B2bOrderDetailScreen({super.key, required this.order});

  @override
  State<B2bOrderDetailScreen> createState() => _B2bOrderDetailScreenState();
}

class _B2bOrderDetailScreenState extends State<B2bOrderDetailScreen> {
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
    final p = context.read<B2bOrderProvider>();
    final token = context.read<AuthProvider>().token!;
    final ok = await p.acceptOrder(token, o.id);
    if (!mounted) return;
    _snack(ok ? 'Order accepted!' : (p.error ?? 'Failed'),
        ok ? AppColors.statusCompleted : AppColors.error);
  }

  Future<void> _reject(OrderModel o) async {
    final reason = await _rejectDialog();
    if (!mounted || reason == null) return;
    final p = context.read<B2bOrderProvider>();
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
    final p = context.read<B2bOrderProvider>();
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
    final p = context.read<B2bOrderProvider>();
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

    final p     = context.read<B2bOrderProvider>();
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
      builder: (_) => OrderOtpBottomSheet(
        processId:   o.id,
        orderNumber: o.orderNumber,
        service:     o.serviceName,
        initialOtp:  otp,
        detailUrlBuilder: ApiConstants.b2bOrderDetail,
        onVerified:  () {
          Navigator.of(context).pop(); // close sheet
          // Refresh the order so it shows inward_done state
          final auth = context.read<AuthProvider>();
          context.read<B2bOrderProvider>().fetchOrders(auth.token ?? '');
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
    final o = context.select<B2bOrderProvider, OrderModel>((p) =>
        p.orders.firstWhere((x) => x.id == widget.order.id,
            orElse: () => widget.order));
    final isActing = context.watch<B2bOrderProvider>().isActing;
    final badge = orderBadgeStyle(o.status);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(o.orderNumber.isNotEmpty ? '#${o.orderNumber}' : '#${o.id}'),
            const SizedBox(width: 8),
            const _B2bTag(),
          ],
        ),
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
              OrderStatusBanner(o: o, badge: badge),
              const SizedBox(height: 16),

              // ── Service countdown timer (visible when timer is running) ───
              if ((o.timerRunning || o.isCompleted) && o.serviceDeadline != null)
                OrderTimerCard(o: o),
              if ((o.timerRunning || o.isCompleted) && o.serviceDeadline != null)
                const SizedBox(height: 16),

              // ── Company / service info ──────────────────────────────────
              _sectionTitle('Company & Service Details'),
              _card([
                if (o.customerName.isNotEmpty)
                  _row(Icons.apartment_rounded, 'Company', o.customerName),
                _row(Icons.local_laundry_service_outlined, 'Service', o.serviceName),
                if (o.customerAddress.isNotEmpty)
                  _row(Icons.location_on_outlined, 'Address', o.customerAddress),
                if (o.customerPhone.isNotEmpty)
                  _row(Icons.call_outlined, 'Site Contact', o.customerPhone),
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
                  _row(Icons.directions_car_outlined, 'Pickup Slot',
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

              // ── Items — B2B's items[].garment[] shape maps to the same
              // OrderItem fields as retail (name/quantity/vendor_price/total).
              // types_of_clothes is always [] for B2B (no per-garment cloth-type
              // breakdown exists in the B2B schema), so OrderItemsTable simply
              // omits that chip row — nothing is faked here. ──
              if (o.items.isNotEmpty) ...[
                _sectionTitle('Garments & Vendor Prices'),
                OrderItemsTable(o: o),
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
                OrderActionButtons(
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

// ── Small "B2B" tag shown next to the order number in the app bar ───────────

class _B2bTag extends StatelessWidget {
  const _B2bTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: const Text('B2B',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary)),
    );
  }
}
