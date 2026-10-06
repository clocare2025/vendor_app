import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/b2b_orders_service.dart';

/// Mirrors [OrderProvider] 1:1 against the separate B2B process-assignment
/// route family. Kept as its own provider (rather than merged into
/// OrderProvider) because B2B assignments live in a different backend
/// collection (b2bProcessModel) with their own list — same reasoning as the
/// backend's separate /v1/b2b-orders route family.
class B2bOrderProvider extends ChangeNotifier {
  B2bOrderProvider({B2bOrdersService? ordersService})
      : _service = ordersService ?? B2bOrdersService();

  final B2bOrdersService _service;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  bool _isActing = false;
  String _filterStatus = 'all';
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isActing => _isActing;
  String get filterStatus => _filterStatus;
  String? get error => _error;

  List<OrderModel> get orders {
    switch (_filterStatus) {
      case 'new':
        return _orders.where((o) => o.isAssigned).toList();
      case 'active':
        return _orders.where((o) => o.isActive).toList();
      case 'completed':
        return _orders.where((o) => o.isCompleted).toList();
      case 'cancelled':
        return _orders.where((o) => o.isRejected || o.isCancelled).toList();
      default:
        return List.unmodifiable(_orders);
    }
  }

  List<OrderModel> get pendingOrders => _orders.where((o) => o.isPending).toList();
  List<OrderModel> get activeOrders => _orders.where((o) => o.isActive).toList();
  List<OrderModel> get completedOrders => _orders.where((o) => o.isCompleted).toList();

  double get totalRevenue => _orders
      .where((o) => o.isCompleted)
      .fold(0.0, (sum, o) => sum + o.vendorAmount);

  // ── Filter ────────────────────────────────────────────────────────────────

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _service.fetchOrders(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Accept ────────────────────────────────────────────────────────────────

  Future<bool> acceptOrder(String token, String id) =>
      _act(id, 'accepted', () => _service.acceptOrder(token, id));

  // ── Reject ────────────────────────────────────────────────────────────────

  Future<bool> rejectOrder(String token, String id, {String? reason}) async {
    _isActing = true;
    notifyListeners();
    try {
      await _service.rejectOrder(token, id, reason);
      _patch(id, (o) => o.copyWith(status: 'rejected', rejectReason: reason));
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  // ── Pickup ────────────────────────────────────────────────────────────────

  Future<bool> pickupOrder(String token, String id) async {
    _isActing = true;
    notifyListeners();
    try {
      await _service.pickupOrder(token, id);
      final now = DateTime.now();
      _patch(id, (o) {
        final deadline = o.serviceDurationHours > 0
            ? now.add(Duration(hours: o.serviceDurationHours))
            : null;
        return o.copyWith(
          status: 'picked_up',
          pickedUpAt: now,
          serviceDeadline: deadline,
        );
      });
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  // ── Start Processing ──────────────────────────────────────────────────────

  Future<bool> startProcessing(String token, String id) async {
    _isActing = true;
    notifyListeners();
    try {
      await _service.startProcessing(token, id);
      _patch(id, (o) => o.copyWith(
            status: 'processing',
            processingStartedAt: DateTime.now(),
          ));
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  // ── Complete Processing + Generate Inward OTP ─────────────────────────────
  // Returns the OTP string on success, null on failure.

  Future<String?> completeProcessingWithOtp(String token, String id) async {
    _isActing = true;
    notifyListeners();
    try {
      final otp = await _service.completeProcessingWithOtp(token, id);
      _patch(id, (o) => o.copyWith(
            status: 'completed',
            processingCompletedAt: DateTime.now(),
            inwardOtp: otp,
            inwardOtpVerified: false,
          ));
      return otp;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<bool> _act(
      String id, String newStatus, Future<void> Function() apiCall) async {
    _isActing = true;
    notifyListeners();
    try {
      await apiCall();
      _patch(id, (o) => o.copyWith(status: newStatus));
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  void _patch(String id, OrderModel Function(OrderModel) update) {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) _orders[idx] = update(_orders[idx]);
    notifyListeners();
  }
}
