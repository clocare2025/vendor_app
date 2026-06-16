import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/orders_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrdersService? ordersService}) : _ordersService = ordersService ?? OrdersService();

  final OrdersService _ordersService;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _filterStatus = 'all';

  List<OrderModel> get orders => _filterStatus == 'all'
      ? _orders
      : _orders.where((o) => o.status.name == _filterStatus).toList();

  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;

  List<OrderModel> get pendingOrders => _orders.where((o) => o.status == OrderStatus.pending).toList();
  List<OrderModel> get activeOrders => _orders.where((o) => o.status == OrderStatus.active).toList();
  List<OrderModel> get completedOrders => _orders.where((o) => o.status == OrderStatus.completed).toList();

  double get totalRevenue =>
      _orders.where((o) => o.status == OrderStatus.completed).fold(0.0, (sum, o) => sum + o.amount);

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _ordersService.fetchOrders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(status: newStatus);
    notifyListeners();
    await _ordersService.updateOrderStatus(orderId, newStatus);
  }
}
