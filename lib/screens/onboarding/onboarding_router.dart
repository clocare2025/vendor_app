import 'package:flutter/material.dart';
import '../../models/vendor_model.dart';
import '../main_screen.dart';
import 'kyc_personal_screen.dart';
import 'pending_screen.dart';
import 'rejected_screen.dart';

/// Decides where a vendor should land based on their KYC / onboarding status.
///
/// - approved + active   → dashboard (MainScreen)
/// - submitted           → "under review" pending screen
/// - rejected            → rejection screen (with reason, allows resubmit)
/// - not_submitted / any → start the KYC onboarding flow
///
/// Used after login, after OTP registration, and on app launch (splash) so the
/// gate is enforced everywhere.
Widget vendorLandingScreen(Vendor? vendor) {
  final kycStatus = vendor?.kycStatus ?? 'not_submitted';

  if (kycStatus == 'approved' && vendor?.accountIsActive == true) {
    return MainScreen();
  } else if (kycStatus == 'submitted') {
    return const KycPendingScreen();
  } else if (kycStatus == 'rejected') {
    return KycRejectedScreen(reason: vendor?.kycRejectionReason ?? '');
  } else {
    return const KycPersonalScreen();
  }
}
