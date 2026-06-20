import '../api/orders_api.dart';
import '../models/order_model.dart';

class OrdersService {
  final OrdersApi _api = OrdersApi();

  Future<List<OrderModel>> fetchOrders(String token) => _api.getOrders(token);
  Future<void> acceptOrder(String token, String id) => _api.acceptOrder(token, id);
  Future<void> rejectOrder(String token, String id, String? reason) => _api.rejectOrder(token, id, reason);
  Future<void> pickupOrder(String token, String id) => _api.pickupOrder(token, id);
  Future<void> startProcessing(String token, String id) => _api.startProcessing(token, id);
  Future<void> completeOrder(String token, String id) => _api.completeOrder(token, id);
  Future<String> completeProcessingWithOtp(String token, String id) => _api.completeProcessingWithOtp(token, id);
}
