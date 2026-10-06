import '../api/b2b_orders_api.dart';
import '../models/order_model.dart';

class B2bOrdersService {
  final B2bOrdersApi _api = B2bOrdersApi();

  Future<List<OrderModel>> fetchOrders(String token) => _api.getOrders(token);
  Future<void> acceptOrder(String token, String id) => _api.acceptOrder(token, id);
  Future<void> rejectOrder(String token, String id, String? reason) => _api.rejectOrder(token, id, reason);
  Future<void> pickupOrder(String token, String id) => _api.pickupOrder(token, id);
  Future<void> startProcessing(String token, String id) => _api.startProcessing(token, id);
  Future<String> completeProcessingWithOtp(String token, String id) => _api.completeProcessingWithOtp(token, id);
}
