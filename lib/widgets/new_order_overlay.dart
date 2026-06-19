import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

// ── Pending order data ─────────────────────────────────────────────────────────

class PendingOrderNotification {
  final String processId;
  final String orderNumber;
  final String service;
  final String pickupDate;
  final String pickupTime;
  final DateTime assignedAt;

  PendingOrderNotification({
    required this.processId,
    required this.orderNumber,
    required this.service,
    required this.pickupDate,
    required this.pickupTime,
    required this.assignedAt,
  });

  static const _window = Duration(minutes: 20);

  Duration get timeLeft {
    final left = assignedAt.add(_window).difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isExpired => timeLeft == Duration.zero;

  double get progress => timeLeft.inSeconds / _window.inSeconds;
}

// ── Overlay host ──────────────────────────────────────────────────────────────

class NewOrderOverlay extends StatefulWidget {
  final Widget child;
  const NewOrderOverlay({super.key, required this.child});

  static NewOrderOverlayState? of(BuildContext context) =>
      context.findAncestorStateOfType<NewOrderOverlayState>();

  @override
  State<NewOrderOverlay> createState() => NewOrderOverlayState();
}

class NewOrderOverlayState extends State<NewOrderOverlay> {
  final List<PendingOrderNotification> _queue = [];

  void addOrder(PendingOrderNotification order) {
    // Don't add duplicates
    if (_queue.any((o) => o.processId == order.processId)) return;
    setState(() => _queue.add(order));
  }

  void _remove(String processId) {
    setState(() => _queue.removeWhere((o) => o.processId == processId));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_queue.isNotEmpty)
          _OrderQueueOverlay(
            queue: List.unmodifiable(_queue),
            onDismiss: _remove,
          ),
      ],
    );
  }
}

// ── Queue overlay (dark scrim + stacked cards) ────────────────────────────────

class _OrderQueueOverlay extends StatelessWidget {
  final List<PendingOrderNotification> queue;
  final void Function(String processId) onDismiss;

  const _OrderQueueOverlay({required this.queue, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    // Show the top card (last item = most recent) prominently;
    // cards behind it are peeked offset upward for a stack effect.
    final reversed = queue.reversed.toList();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withAlpha(160),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Badge: how many more orders are waiting
              if (queue.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${queue.length} orders waiting for your response',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Stacked cards — bottom ones peeked
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.70,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: reversed.asMap().entries.map((entry) {
                    final stackIdx = entry.key; // 0 = top (active) card
                    final order    = entry.value;
                    final offset   = stackIdx * 10.0;
                    final scale    = 1.0 - stackIdx * 0.025;
                    final opacity  = stackIdx == 0 ? 1.0 : (1.0 - stackIdx * 0.15).clamp(0.3, 1.0);

                    return Positioned(
                      bottom: offset,
                      left: 0, right: 0,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.bottomCenter,
                        child: Opacity(
                          opacity: opacity,
                          child: IgnorePointer(
                            ignoring: stackIdx != 0,
                            child: _OrderCard(
                              order: order,
                              isActive: stackIdx == 0,
                              onDismiss: () => onDismiss(order.processId),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single order card ─────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final PendingOrderNotification order;
  final bool isActive;
  final VoidCallback onDismiss;

  const _OrderCard({
    required this.order,
    required this.isActive,
    required this.onDismiss,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with TickerProviderStateMixin {
  // Slide-up entry animation
  late final AnimationController _slideCtrl;
  late final Animation<Offset>   _slideAnim;

  // Pulse animation on the header dot
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  // Shake animation when urgent (< 60 s)
  late final AnimationController _shakeCtrl;

  Timer? _ticker;
  bool _accepting = false;
  bool _rejecting = false;
  bool _didShake  = false;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );

    // Tick every second to update timer
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (widget.order.isExpired) _autoDismiss();
      // Shake once when < 60 s
      if (!_didShake && widget.order.timeLeft.inSeconds < 60) {
        _didShake = true;
        _shakeCtrl.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoDismiss() async {
    _ticker?.cancel();
    await _slideCtrl.reverse();
    if (mounted) widget.onDismiss();
  }

  Future<void> _accept() async {
    if (_accepting || _rejecting) return;
    setState(() => _accepting = true);
    final auth  = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    await orders.acceptOrder(auth.token ?? '', widget.order.processId);
    if (!mounted) return;
    setState(() => _accepting = false);
    await _slideCtrl.reverse();
    if (mounted) widget.onDismiss();
  }

  Future<void> _reject() async {
    if (_accepting || _rejecting) return;
    final reason = await _showRejectSheet();
    if (!mounted || reason == null) return;
    setState(() => _rejecting = true);
    final auth   = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    await orders.rejectOrder(auth.token ?? '', widget.order.processId,
        reason: reason);
    if (!mounted) return;
    setState(() => _rejecting = false);
    await _slideCtrl.reverse();
    if (mounted) widget.onDismiss();
  }

  Future<String?> _showRejectSheet() {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RejectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left    = widget.order.timeLeft;
    final urgent  = left.inSeconds < 60;
    final mins    = left.inMinutes.toString().padLeft(2, '0');
    final secs    = (left.inSeconds % 60).toString().padLeft(2, '0');

    return SlideTransition(
      position: _slideAnim,
      child: _ShakeWidget(
        controller: _shakeCtrl,
        enabled: urgent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: urgent
                      ? const Color(0xFFEF4444).withAlpha(80)
                      : Colors.black.withAlpha(50),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ───────────────────────────────────────────────────
                _CardHeader(
                  order:     widget.order,
                  urgent:    urgent,
                  mins:      mins,
                  secs:      secs,
                  pulseAnim: _pulseAnim,
                ),

                // ── Order info grid ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _InfoTile(
                          icon: Icons.receipt_long_outlined,
                          label: 'Order No.',
                          value: widget.order.orderNumber.isNotEmpty
                              ? '#${widget.order.orderNumber}' : '—',
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoTile(
                          icon: Icons.dry_cleaning_outlined,
                          label: 'Service',
                          value: widget.order.service.isNotEmpty
                              ? widget.order.service : '—',
                        )),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _InfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Pickup Date',
                          value: widget.order.pickupDate.isNotEmpty
                              ? widget.order.pickupDate : '—',
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoTile(
                          icon: Icons.access_time_rounded,
                          label: 'Pickup Time',
                          value: widget.order.pickupTime.isNotEmpty
                              ? widget.order.pickupTime : '—',
                        )),
                      ]),
                    ],
                  ),
                ),

                // ── Urgent warning ────────────────────────────────────────────
                if (urgent)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFDC2626), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Less than 1 minute left — order will expire soon!',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Action buttons ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Row(
                    children: [
                      // Reject
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              (_rejecting || _accepting) ? null : _reject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(
                                color: Color(0xFFEF4444), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _rejecting
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFEF4444),
                                  ))
                              : const Text('Decline',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              (_accepting || _rejecting) ? null : _accept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _accepting
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                              : const Text('Accept Order',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Card header with animated ring timer ─────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final PendingOrderNotification order;
  final bool urgent;
  final String mins;
  final String secs;
  final Animation<double> pulseAnim;

  const _CardHeader({
    required this.order,
    required this.urgent,
    required this.mins,
    required this.secs,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFF7F1D1D) : const Color(0xFF1E3A5F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          // Pulsing dot + label
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, _) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((pulseAnim.value * 255).toInt()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Order Assigned',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Respond before the timer runs out',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          // Countdown ring
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(58, 58),
                  painter: _RingPainter(
                    progress: order.progress,
                    urgent: urgent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$mins:$secs',
                      style: TextStyle(
                        color: urgent
                            ? const Color(0xFFFCA5A5)
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'left',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown ring painter ─────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final bool urgent;
  const _RingPainter({required this.progress, required this.urgent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 4;

    // Track
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color  = Colors.white.withAlpha(40)
        ..style  = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Progress arc (counter-clockwise fill)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color      = urgent ? const Color(0xFFFCA5A5) : const Color(0xFF22C55E)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap  = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.urgent != urgent;
}

// ── Info tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
          ]),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Shake widget ──────────────────────────────────────────────────────────────

class _ShakeWidget extends StatelessWidget {
  final AnimationController controller;
  final bool enabled;
  final Widget child;
  const _ShakeWidget({
    required this.controller,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, c) {
        final dx = sin(controller.value * pi * 6) * 6;
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: child,
    );
  }
}

// ── Reject reason bottom sheet ────────────────────────────────────────────────

class _RejectSheet extends StatefulWidget {
  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  static const _reasons = [
    'Out of service area',
    'Capacity full',
    'Technical issue',
    'Will be unavailable at pickup time',
  ];
  final _ctrl = TextEditingController();
  String? _selected;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reason for declining',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ..._reasons.map((r) => GestureDetector(
            onTap: () {
              setState(() { _selected = r; _ctrl.text = r; });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _selected == r
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selected == r
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(children: [
                Icon(
                  _selected == r
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: _selected == r
                      ? const Color(0xFFEF4444)
                      : AppColors.textHint,
                ),
                const SizedBox(width: 10),
                Text(r,
                    style: TextStyle(
                      fontSize: 13,
                      color: _selected == r
                          ? const Color(0xFFDC2626)
                          : AppColors.textPrimary,
                      fontWeight: _selected == r
                          ? FontWeight.w600
                          : FontWeight.normal,
                    )),
              ]),
            ),
          )),
          const SizedBox(height: 4),
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _selected = null),
            decoration: InputDecoration(
              hintText: 'Other reason…',
              hintStyle: const TextStyle(color: AppColors.textHint),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final reason = _ctrl.text.trim();
                Navigator.of(context).pop(
                    reason.isNotEmpty ? reason : 'Vendor declined');
              },
              child: const Text('Confirm Decline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
