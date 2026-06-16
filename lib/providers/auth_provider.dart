import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vender_app/api/auth_api.dart';
import 'package:vender_app/core/constants/api_constants.dart';
import 'package:vender_app/models/otp_model.dart';
import 'package:vender_app/models/vendor_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.token);
    notifyListeners();
  }

  Future<OtpModel?> sendOtp(String mobile) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authApi.sendOtp(mobile);
      if (response.status == true) {
        return response;
      } else {
        _errorMessage = response.msg ?? 'Failed to send OTP';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VendorModel?> login(String mobile, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authApi.userLogin(mobile, password);
      print('login provider ddddd ${response.status} ${response.data}');
      if (response.status == true &&
          response.data?.vendor?.accessToken != null) {
        _token = response.data!.vendor!.accessToken;
        final prefs = await SharedPreferences.getInstance();
        print('prefs ${_token}');
        await prefs.setString(AppConstants.token, _token!);
        return response;
      } else {
        _errorMessage = response.msg ?? 'Login failed';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(
    String name,
    String mobile,
    String cityName,
    String pincode,
    String address,
    String password,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authApi.userSignup(
        name,
        mobile,
        cityName,
        pincode,
        address,
        password,
      );
      if (response.status == true &&
          response.data?.vendor?.accessToken != null) {
        _token = response.data!.vendor!.accessToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.token, _token!);
        return true;
      } else {
        _errorMessage = response.msg ?? 'Signup failed';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.token);
    notifyListeners();
  }
}
