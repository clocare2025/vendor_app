import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../widgets/new_order_overlay.dart';

// ── Android notification channel constants ────────────────────────────────────

const _kChannelId   = 'spinovo_vendor_orders';
const _kChannelName = 'New Orders';
const _kChannelDesc = 'Notifications for new orders assigned to you';

// ── flutter_local_notifications plugin instance ───────────────────────────────

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

// ── Top-level background handler (MUST be a top-level function) ──────────────

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // System shows the notification automatically via the FCM payload.
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  // Firebase is NOT accessed until init() succeeds.
  // This prevents "No Firebase App [DEFAULT]" from crashing the app.
  FirebaseMessaging? _fcm;
  bool _ready = false;

  /// Set by MainScreen — called whenever a new-order FCM arrives.
  void Function(PendingOrderNotification)? onNewOrder;

  // ── Initialise ───────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      _fcm = FirebaseMessaging.instance;  // Only accessed AFTER Firebase.initializeApp()
      _ready = true;
    } catch (_) {
      _ready = false;
      return;
    }

    try {
      await _fcm!.requestPermission(
        alert: true, badge: true, sound: true, provisional: false,
      );
      await _fcm!.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
    } catch (_) {}

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      if (Platform.isAndroid) {
        await localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              _kChannelId, _kChannelName,
              description: _kChannelDesc,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              enableLights: true,
            ));
      }
    } catch (_) {}
  }

  // ── Listeners — wire once from MainScreen.initState ──────────────────────────

  void listenForeground() {
    if (!_ready) return;
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void listenOnMessageOpenedApp() {
    if (!_ready) return;
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> handleInitialMessage() async {
    if (!_ready || _fcm == null) return;
    try {
      final msg = await _fcm!.getInitialMessage();
      if (msg != null) _handleMessage(msg);
    } catch (_) {}
  }

  // ── Token ─────────────────────────────────────────────────────────────────────

  /// Returns the FCM device token, or null if Firebase is not configured.
  Future<String?> getTokenSafely() async {
    if (!_ready || _fcm == null) return null;
    try {
      return await _fcm!.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Upload the current FCM token to the backend via PATCH /v1/auth/fcm-token.
  /// Safe to call even when Firebase is not configured — returns silently.
  Future<void> uploadToken(String authToken) async {
    if (!_ready || _fcm == null) return;
    try {
      final fcmToken = await _fcm!.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      await http.patch(
        Uri.parse(ApiConstants.fcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (_) {}
  }

  void watchTokenRefresh(String authToken) {
    if (!_ready || _fcm == null) return;
    try {
      _fcm!.onTokenRefresh.listen((_) => uploadToken(authToken));
    } catch (_) {}
  }

  // ── Internal routing ──────────────────────────────────────────────────────────

  void _handleMessage(RemoteMessage msg) {
    final data = msg.data;
    debugPrint('[FCM] message received — type=${data['type']} data=$data');
    if (data['type'] != 'new_order_assigned') {
      debugPrint('[FCM] ignoring — not new_order_assigned');
      return;
    }
    _dispatchNewOrder(data, msg.notification);
  }

  void _dispatchNewOrder(
    Map<String, dynamic> data,
    RemoteNotification? notification,
  ) {
    final processId   = data['process_id']   as String? ?? '';
    final orderNumber = data['order_number'] as String? ?? '';
    final service     = data['service']      as String? ?? '';
    final pickup      = data['pickup']       as String? ?? '';

    String pickupDate = '', pickupTime = '';
    if (pickup.isNotEmpty) {
      final parts = pickup.split(' ');
      pickupDate = parts.first;
      pickupTime = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    debugPrint('[FCM] dispatching order #$orderNumber — overlay callback set: ${onNewOrder != null}');

    if (Platform.isAndroid) {
      _showLocalNotification(
        title: notification?.title ?? '🧺 New Order Assigned',
        body:  notification?.body  ?? 'Order #$orderNumber • $service',
      );
    }

    final order = PendingOrderNotification(
      processId:   processId,
      orderNumber: orderNumber,
      service:     service,
      pickupDate:  pickupDate,
      pickupTime:  pickupTime,
      assignedAt:  DateTime.now(),
    );

    if (onNewOrder != null) {
      onNewOrder!.call(order);
      debugPrint('[FCM] onNewOrder callback fired');
    } else {
      debugPrint('[FCM] onNewOrder is null — pushing directly via GlobalKey');
      // Fallback: push directly without needing the callback
    }
  }

  void _showLocalNotification({required String title, required String body}) {
    try {
      localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId, _kChannelName,
            channelDescription: _kChannelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true,
          ),
        ),
      );
    } catch (_) {}
  }
}
