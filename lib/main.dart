import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/order_provider.dart';
import 'providers/b2b_order_provider.dart';
import 'providers/status_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/notification_service.dart';

/// Global navigator key — lets NotificationService navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional — requires google-services.json (Android) /
  // GoogleService-Info.plist (iOS) to be present. Fails silently without them.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await NotificationService.instance.init();
  } catch (_) {
    // Firebase not configured yet — push notifications disabled.
    // Add google-services.json to android/app/ and re-enable the
    // google-services Gradle plugin to activate FCM.
  }

  runApp(const VendorApp());
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => B2bOrderProvider()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
