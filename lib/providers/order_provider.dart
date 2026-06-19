import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/orders_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrdersService? ordersService})
      : _service = ordersService ?? OrdersService();

  final OrdersService _service;

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

  // ── Complete ──────────────────────────────────────────────────────────────

  Future<bool> completeOrder(String token, String id) async {
    _isActing = true;
    notifyListeners();
    try {
      await _service.completeOrder(token, id);
      _patch(id, (o) => o.copyWith(
            status: 'completed',
            processingCompletedAt: DateTime.now(),
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
