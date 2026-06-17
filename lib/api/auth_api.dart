import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vender_app/core/constants/api_constants.dart';
import 'package:vender_app/models/otp_model.dart';
import 'package:vender_app/models/vendor_model.dart';

class AuthApi {
  Future<OtpModel> sendOtp(String number) async {
    final response = await http.post(
      Uri.parse(ApiConstants.sendOtp),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'mobile': number}),
    );

    if (response.statusCode == 200) {
      return OtpModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  Future<VendorModel> userSignup(
    String name,
    String mobile,
    String cityName,
    String pincode,
    String address,
    String password,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.signup),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'name': name,
        'mobile': mobile,
        'cityName': cityName,
        'pincode': pincode,
        'address': address,
        'password': password,
        'otp': otp,
      }),
    );
    print(response.body);
    if (response.statusCode == 200) {
      return VendorModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to signup: ${response.body}');
    }
  }

  Future<VendorModel> userLogin(String mobileNo, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'mobile': mobileNo, 'password': password}),
    );
    print('login api ddddd ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return VendorModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
