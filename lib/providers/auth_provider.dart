import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vender_app/api/auth_api.dart';
import 'package:vender_app/core/constants/api_constants.dart';
import 'package:vender_app/models/otp_model.dart';
import 'package:vender_app/models/vendor_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  String? _token;
  Vendor? _vendor;
  bool _isLoading = false;
  String? _errorMessage;

  // Signup details + OTP held in memory while a registration OTP is pending
  // verification (set by [requestRegistrationOtp], consumed by
  // [verifyOtpAndRegister]).
  Map<String, String>? _pendingSignup;
  String? _pendingOtpCode;

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

      final response = await _authApi.userLogin(mobile, password);
      if (response.status == true &&
          response.data?.vendor?.accessToken != null) {
        _vendor = response.data!.vendor;
        _token = _vendor!.accessToken;
        final prefs = await SharedPreferences.getInstance();
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
        _pendingOtpCode = response.data?.otpData?.otpCode;
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

      if (otp.isEmpty || otp != _pendingOtpCode) {
        _errorMessage = 'Invalid OTP, please try again';
        return false;
      }

      final response = await _authApi.userSignup(
        pending['name']!,
        pending['mobile']!,
        pending['cityName']!,
        pending['pincode']!,
        pending['address']!,
        pending['password']!,
      );
      if (response.status == true &&
          response.data?.vendor?.accessToken != null) {
        _vendor = response.data!.vendor;
        _token = _vendor!.accessToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.token, _token!);
        _pendingSignup = null;
        _pendingOtpCode = null;
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
        _pendingOtpCode = response.data?.otpData?.otpCode;
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

  Future<void> logout() async {
    _token = null;
    _vendor = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.token);
    notifyListeners();
  }
}
