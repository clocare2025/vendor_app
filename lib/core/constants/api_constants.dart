class ApiConstants {
  ApiConstants._();

  // static const String baseUrl = 'https://api.spinovo.in';
  // static const String baseUrl = 'http://10.0.2.2:3003'; // Android emulator
  static const String baseUrl = 'http://192.168.0.125:3003'; // Physical device
  static const String _vendorBase = '$baseUrl/api/vendor/v1';

  static const String signup = '$_vendorBase/auth/signup';
  static const String login = '$_vendorBase/auth/login';
  static const String sendOtp = '$_vendorBase/auth/send-otp';
  static const String profile = '$_vendorBase/profile';
}

class AppConstants {
  static String token = 'thisismytoken';
}
