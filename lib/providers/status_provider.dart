import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class StatusProvider extends ChangeNotifier {
  bool _isOnline = false;
  bool _loading = false;
  String? _error;

  bool get isOnline => _isOnline;
  bool get loading => _loading;
  String? get error => _error;

  void setOnlineLocally(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  Future<void> fetchStatus(String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.status),
        headers: _headers(token),
      );
      final body = jsonDecode(res.body);
      if (body['status'] == true) {
        _isOnline = body['data']?['isOnline'] == true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> toggle(String token, {bool? setTo}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final body = setTo != null ? jsonEncode({'isOnline': setTo}) : null;
      final res = await http.patch(
        Uri.parse(ApiConstants.status),
        headers: _headers(token),
        body: body,
      );
      final json = jsonDecode(res.body);
      if (json['status'] == true) {
        _isOnline = json['data']?['isOnline'] == true;
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = json['msg'] ?? 'Failed to update status';
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
