class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.spinovo.in';
  // static const String baseUrl = 'http://10.0.2.2:3003'; // Android emulator
  // static const String baseUrl = "http://192.168.1.71:3003"; // Physical device (local Wi-Fi)
  static const String _vendorBase = '$baseUrl/api/vendor/v1';

  // Auth
  static const String signup = '$_vendorBase/auth/signup';
  static const String login = '$_vendorBase/auth/login';
  static const String sendOtp = '$_vendorBase/auth/send-otp';
  static const String fcmToken = '$_vendorBase/auth/fcm-token';
  static const String profile = '$_vendorBase/profile';
  static const String address = '$_vendorBase/address';

  // Online / Offline status
  static const String status = '$_vendorBase/status';

  // Bank details
  static const String bankDetails = '$_vendorBase/bank-details';
  static String bankDetailById(String id) => '$_vendorBase/bank-details/$id';

  // Earnings
  static String earnings(String period) =>
      '$_vendorBase/earnings?period=$period';

  // KYC
  static const String kycSubmit = '$_vendorBase/kyc/submit';
  static const String kycUpdate =
      '$_vendorBase/kyc/update'; // re-edit after rejection
  static const String kycStatus = '$_vendorBase/kyc/status';

  // Onboarding
  static const String onboardingStatus = '$_vendorBase/onboarding/status';
  static const String onboardingServicesSelect =
      '$_vendorBase/onboarding/services/select';
  static const String onboardingServicesSelected =
      '$_vendorBase/onboarding/services/selected';
  static const String onboardingSubmit = '$_vendorBase/onboarding/submit';

  // Services & prices
  static const String serviceList = '$_vendorBase/services';
  static const String priceList = '$_vendorBase/prices';
  static String serviceCategories(String serviceId) =>
      '$_vendorBase/services/$serviceId/categories';
  static String priceDetail(String id) => '$_vendorBase/prices/$id';

  // Orders
  static const String orders = '$_vendorBase/orders';
  static String orderDetail(String id) => '$_vendorBase/orders/$id';
  static String orderAccept(String id) => '$_vendorBase/orders/$id/accept';
  static String orderReject(String id) => '$_vendorBase/orders/$id/reject';
  static String orderPickup(String id) => '$_vendorBase/orders/$id/pickup';
  static String orderStartProcessing(String id) =>
      '$_vendorBase/orders/$id/start-processing';
  static String orderComplete(String id) => '$_vendorBase/orders/$id/complete';

  // Vendor Inward — complete processing (generates OTP) + re-fetch OTP
  static String orderCompleteProcessing(String id) =>
      '$_vendorBase/orders/$id/complete-processing';
  static String orderInwardOtp(String id) =>
      '$_vendorBase/orders/$id/inward-otp';

  // B2B Orders — separate route family, mirrors /orders above (see
  // vendorB2BOrderController.js in spinovo_api; kept apart from retail's
  // /orders to avoid touching the working buildOrderPayload pipeline).
  static const String b2bOrders = '$_vendorBase/b2b-orders';
  static String b2bOrderDetail(String id) => '$_vendorBase/b2b-orders/$id';
  static String b2bOrderAccept(String id) =>
      '$_vendorBase/b2b-orders/$id/accept';
  static String b2bOrderReject(String id) =>
      '$_vendorBase/b2b-orders/$id/reject';
  static String b2bOrderPickup(String id) =>
      '$_vendorBase/b2b-orders/$id/pickup';
  static String b2bOrderStartProcessing(String id) =>
      '$_vendorBase/b2b-orders/$id/start-processing';
  static String b2bOrderCompleteProcessing(String id) =>
      '$_vendorBase/b2b-orders/$id/complete-processing';
  static String b2bOrderInwardOtp(String id) =>
      '$_vendorBase/b2b-orders/$id/inward-otp';
}

class AppConstants {
  static String token = 'thisismytoken';
}
