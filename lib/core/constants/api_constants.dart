class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://103.12.192.35:3003';
  static const String _vendorBase = '$baseUrl/api/vendor/v1';

  static const String signup = '$_vendorBase/auth/signup';
  static const String login = '$_vendorBase/auth/login';
  static const String sendOtp = '$_vendorBase/auth/send-otp';
  static const String profile = '$_vendorBase/profile';
}

class AppConstants {
  static String token = 'thisismytoken';
}
