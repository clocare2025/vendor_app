import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/order_model.dart';

/// Mirrors [OrdersApi] 1:1 against the separate `/v1/b2b-orders` route
/// family (see vendorB2BOrderController.js in spinovo_api). B2B has no
/// plain `/complete` endpoint — only the OTP-based complete-processing path
/// that retail's flow already uses, so that's the only "complete" method.
class B2bOrdersApi {
  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Future<List<OrderModel>> getOrders(String token) async {
    final res = await http.get(
        Uri.parse(ApiConstants.b2bOrders), headers: _headers(token));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      final list = body['data']['orders'] as List<dynamic>? ?? [];
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['msg'] ?? 'Failed to load B2B orders');
  }

  Future<OrderModel> getOrderDetail(String token, String orderId) async {
    final res = await http.get(
        Uri.parse(ApiConstants.b2bOrderDetail(orderId)),
        headers: _headers(token));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      return OrderModel.fromJson(
          body['data']['order'] as Map<String, dynamic>);
    }
    throw Exception(body['msg'] ?? 'Failed to load B2B order');
  }

  Future<void> acceptOrder(String token, String orderId) =>
      _patch(token, ApiConstants.b2bOrderAccept(orderId));

  Future<void> rejectOrder(String token, String orderId, String? reason) =>
      _patch(token, ApiConstants.b2bOrderReject(orderId),
          body: {'reason': reason ?? ''});

  Future<void> pickupOrder(String token, String orderId) =>
      _patch(token, ApiConstants.b2bOrderPickup(orderId));

  Future<void> startProcessing(String token, String orderId) =>
      _patch(token, ApiConstants.b2bOrderStartProcessing(orderId));

  /// Vendor marks processing done → backend generates 6-digit inward OTP.
  /// Returns the OTP string to display to the vendor.
  Future<String> completeProcessingWithOtp(String token, String orderId) async {
    final res = await http.patch(
      Uri.parse(ApiConstants.b2bOrderCompleteProcessing(orderId)),
      headers: _headers(token),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && json['status'] == true) {
      return json['data']?['inward_otp']?.toString() ?? '';
    }
    throw Exception(json['msg'] ?? 'Failed to complete processing');
  }

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
