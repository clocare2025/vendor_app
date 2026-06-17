class ApiConstants {
  ApiConstants._();

  // static const String baseUrl = 'https://api.spinovo.in';
  // static const String baseUrl = 'http://10.0.2.2:3003'; // Android emulator
  static const String baseUrl = 'http://192.168.0.125:3003'; // Physical device
  static const String _vendorBase = '$baseUrl/api/vendor/v1';

  // Auth
  static const String signup = '$_vendorBase/auth/signup';
  static const String login = '$_vendorBase/auth/login';
  static const String sendOtp = '$_vendorBase/auth/send-otp';
  static const String profile = '$_vendorBase/profile';

  // KYC
  static const String kycSubmit = '$_vendorBase/kyc/submit';
  static const String kycStatus = '$_vendorBase/kyc/status';

  // Onboarding
  static const String onboardingStatus = '$_vendorBase/onboarding/status';
  static const String onboardingServicesSelect = '$_vendorBase/onboarding/services/select';
  static const String onboardingServicesSelected = '$_vendorBase/onboarding/services/selected';
  static const String onboardingSubmit = '$_vendorBase/onboarding/submit';

  // Services & prices
  static const String serviceList = '$_vendorBase/services';
  static const String priceList = '$_vendorBase/prices';
  static String serviceCategories(String serviceId) =>
      '$_vendorBase/services/$serviceId/categories';
  static String priceDetail(String id) => '$_vendorBase/prices/$id';
}

class AppConstants {
  static String token = 'thisismytoken';
}
