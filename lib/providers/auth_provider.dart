import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vender_app/api/auth_api.dart';
import 'package:vender_app/core/constants/api_constants.dart';
import 'package:vender_app/models/otp_model.dart';
import 'package:vender_app/models/vendor_model.dart';
import 'package:vender_app/services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  String? _token;
  Vendor? _vendor;
  bool _isLoading = false;
  String? _errorMessage;

  // Signup details held in memory while the vendor is on the OTP screen.
  // Consumed by [verifyOtpAndRegister]; cleared on success.
  Map<String, String>? _pendingSignup;

  String? get token => _token;
  Vendor? get vendor => _vendor;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  Future<void> checkAuthStatus() async {
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

      // Collect FCM token before the login request so it is saved atomically
      final fcmToken = await NotificationService.instance.getTokenSafely();
      final response = await _authApi.userLogin(
        mobile,
        password,
        fcmToken: fcmToken,
      );

      if (response.status == true &&
          response.data?.vendor?.accessToken != null) {
        _vendor = response.data!.vendor;
        _token = _vendor!.accessToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.token, _token!);
        // Fallback: if token was null during login (Firebase initialising slowly),
        // upload it separately via PATCH /v1/auth/fcm-token
        if (fcmToken == null) {
          NotificationService.instance.uploadToken(_token!);
        }
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

  /// Sends an OTP to [mobile] and stashes the signup details so they can be
  /// submitted once the OTP is confirmed in [verifyOtpAndRegister].
  Future<bool> requestRegistrationOtp({
    required String name,
    required String mobile,
    required String cityName,
    required String pincode,
    required String address,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authApi.sendOtp(mobile);
      if (response.status == true) {
        _pendingSignup = {
          'name': name,
          'mobile': mobile,
          'cityName': cityName,
          'pincode': pincode,
          'address': address,
          'password': password,
        };
        return true;
      } else {
        _errorMessage = response.msg ?? 'Failed to send OTP';
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

  /// Confirms [otp] against the pending registration and, if it matches,
  /// completes the signup that was requested via [requestRegistrationOtp].
  Future<bool> verifyOtpAndRegister(String otp) async {
    final pending = _pendingSignup;
    if (pending == null) {
      _errorMessage = 'Please request a new OTP';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Collect FCM token before signup so it is stored on the new account immediately
      final fcmToken = await NotificationService.instance.getTokenSafely();

      final response = await _authApi.userSignup(
        pending['name']!,
        pending['mobile']!,
        pending['cityName']!,
        pending['pincode']!,
        pending['address']!,
        pending['password']!,
        otp,
        fcmToken: fcmToken,
      );
      if (response.status == true &&
          response.data?.vendor?.accessToken != null) {
        _vendor = response.data!.vendor;
        _token = _vendor!.accessToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.token, _token!);
        _pendingSignup = null;
        return true;
      } else {
        _errorMessage = response.msg ?? 'Registration failed';
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

  /// Re-sends the OTP for the mobile number stashed by
  /// [requestRegistrationOtp].
  Future<bool> resendOtp() async {
    final pending = _pendingSignup;
    if (pending == null) {
      _errorMessage = 'Please start registration again';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authApi.sendOtp(pending['mobile']!);
      if (response.status == true) {
        return true;
      } else {
        _errorMessage = response.msg ?? 'Failed to resend OTP';
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

  // Fetch fresh vendor profile from backend and update local state + token
  Future<void> getProfile() async {
    if (_token == null) return;
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == true) {
          final vendorJson =
              body['data']['vendor'] as Map<String, dynamic>? ?? {};
          _vendor = Vendor.fromJson(vendorJson);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _token = null;
    _vendor = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.token);
    notifyListeners();
  }
}
