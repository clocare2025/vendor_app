import 'package:flutter/material.dart';
import '../../models/vendor_model.dart';
import '../main_screen.dart';
import 'kyc_personal_screen.dart';

/// Decides where a vendor lands after login / OTP / app launch.
///
/// Only vendors who have never submitted KYC are sent to the KYC flow.
/// Everyone else (submitted, approved, rejected) lands on MainScreen and sees
/// context-appropriate banners on the HomeScreen.
Widget vendorLandingScreen(Vendor? vendor) {
  if ((vendor?.kycStatus ?? 'not_submitted') == 'not_submitted') {
    return const KycPersonalScreen();
  }
  return MainScreen();
}
