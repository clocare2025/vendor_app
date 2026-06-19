import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/order_model.dart';

class OrdersApi {
  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Future<List<OrderModel>> getOrders(String token) async {
    final res = await http.get(
        Uri.parse(ApiConstants.orders), headers: _headers(token));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      final list = body['data']['orders'] as List<dynamic>? ?? [];
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['msg'] ?? 'Failed to load orders');
  }

  Future<OrderModel> getOrderDetail(String token, String orderId) async {
    final res = await http.get(
        Uri.parse(ApiConstants.orderDetail(orderId)), headers: _headers(token));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      return OrderModel.fromJson(
          body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['msg'] ?? 'Failed to load order');
  }

  Future<void> acceptOrder(String token, String orderId) =>
      _patch(token, ApiConstants.orderAccept(orderId));

  Future<void> rejectOrder(String token, String orderId, String? reason) =>
      _patch(token, ApiConstants.orderReject(orderId),
          body: {'reason': reason ?? ''});

  Future<void> pickupOrder(String token, String orderId) =>
      _patch(token, ApiConstants.orderPickup(orderId));

  Future<void> startProcessing(String token, String orderId) =>
      _patch(token, ApiConstants.orderStartProcessing(orderId));

  Future<void> completeOrder(String token, String orderId) =>
      _patch(token, ApiConstants.orderComplete(orderId));

  Future<void> _patch(String token, String url,
      {Map<String, dynamic>? body}) async {
    final res = await http.patch(
      Uri.parse(url),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json['status'] != true) {
      throw Exception(json['msg'] ?? 'Request failed');
    }
  }
}
