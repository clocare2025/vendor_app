import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _periods = ['daily', 'weekly', 'monthly'];
  final _labels  = ['Today', 'This Week', 'This Month'];

  final Map<String, _EarningsData?> _cache = {};
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _load(_periods[_tab.index]);
    });
    _load('daily');
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load(String period) async {
    if (_cache.containsKey(period)) return;
    final token = context.read<AuthProvider>().token ?? '';
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.earnings(period)),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (body['status'] == true) {
        final d = body['data'];
        setState(() {
          _cache[period] = _EarningsData(
            totalEarnings: (d['total_earnings'] as num?)?.toDouble() ?? 0,
            totalOrders:   (d['total_orders']   as num?)?.toInt()    ?? 0,
            orders: (d['orders'] as List<dynamic>? ?? [])
                .map((o) => _OrderEarning.fromJson(o as Map<String, dynamic>))
                .toList(),
          );
        });
      } else {
        setState(() => _error = body['msg'] ?? 'Failed to load earnings');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refresh() {
    final period = _periods[_tab.index];
    _cache.remove(period);
    _load(period);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _periods.map((p) => _PeriodView(
          period: p,
          data: _cache[p],
          loading: _loading && !_cache.containsKey(p),
          error: _error,
          onRetry: _refresh,
        )).toList(),
      ),
    );
  }
}

// ── Per-tab view ──────────────────────────────────────────────────────────────

class _PeriodView extends StatelessWidget {
  final String period;
  final _EarningsData? data;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _PeriodView({
    required this.period,
    required this.data,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error != null && data == null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error!, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ));
    }

    if (data == null) return const Center(child: CircularProgressIndicator());

    final d = data!;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ── Summary card ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Earnings',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text('₹${fmt.format(d.totalEarnings)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text('${d.totalOrders} order${d.totalOrders == 1 ? '' : 's'} completed',
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (d.orders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text('No completed orders',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Complete orders to see your earnings here.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else ...[
          const Text('Completed Orders',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          ...d.orders.map((o) => _OrderTile(order: o)),
        ],
      ],
    );
  }
}

// ── Order earning tile ────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final _OrderEarning order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final dateStr = order.date != null
        ? DateFormat('EEE, MMM d • h:mm a').format(order.date!.toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.task_alt_rounded,
                color: Color(0xFF16A34A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber.isNotEmpty
                      ? '#${order.orderNumber}'
                      : 'Order',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                if (order.service.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(order.service,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ],
            ),
          ),
          Text('₹${fmt.format(order.amount)}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A))),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _EarningsData {
  final double totalEarnings;
  final int totalOrders;
  final List<_OrderEarning> orders;
  const _EarningsData({
    required this.totalEarnings,
    required this.totalOrders,
    required this.orders,
  });
}

class _OrderEarning {
  final String orderNumber;
  final String service;
  final DateTime? date;
  final double amount;

  const _OrderEarning({
    required this.orderNumber,
    required this.service,
    required this.date,
    required this.amount,
  });

  factory _OrderEarning.fromJson(Map<String, dynamic> j) {
    DateTime? date;
    try { date = DateTime.parse(j['date'].toString()); } catch (_) {}
    return _OrderEarning(
      orderNumber: j['order_number']?.toString() ?? '',
      service:     j['service']?.toString()      ?? '',
      date:        date,
      amount:      (j['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
