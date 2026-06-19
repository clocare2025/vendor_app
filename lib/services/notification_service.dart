import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../widgets/new_order_overlay.dart';

// ── Android notification channel constants ─────────────────────────────────────

const _kChannelId   = 'spinovo_vendor_orders';
const _kChannelName = 'New Orders';
const _kChannelDesc = 'Notifications for new orders assigned to you';

// ── flutter_local_notifications plugin instance ────────────────────────────────

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

// ── Top-level background handler (MUST be a top-level function) ───────────────

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // System shows the notification automatically via the FCM payload.
  // No extra work needed here.
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;

  /// Set by MainScreen — called whenever a new-order FCM arrives.
  void Function(PendingOrderNotification)? onNewOrder;

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

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
  }

  // ── Listeners — call once from MainScreen.initState ────────────────────────

  void listenForeground() {
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void listenOnMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> handleInitialMessage() async {
    final msg = await _fcm.getInitialMessage();
    if (msg != null) _handleMessage(msg);
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<String?> getToken() => _fcm.getToken();

  Future<void> uploadToken(String authToken) async {
    try {
      final fcmToken = await getToken();
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
    _fcm.onTokenRefresh.listen((_) => uploadToken(authToken));
  }

  // ── Internal routing ───────────────────────────────────────────────────────

  void _handleMessage(RemoteMessage msg) {
    final data = msg.data;
    if (data['type'] != 'new_order_assigned') return;
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

    // Show foreground heads-up on Android (iOS shows natively)
    if (Platform.isAndroid) {
      _showLocalNotification(
        title: notification?.title ?? '🧺 New Order Assigned',
        body:  notification?.body  ?? 'Order #$orderNumber • $service',
      );
    }

    onNewOrder?.call(PendingOrderNotification(
      processId:   processId,
      orderNumber: orderNumber,
      service:     service,
      pickupDate:  pickupDate,
      pickupTime:  pickupTime,
      assignedAt:  DateTime.now(),
    ));
  }

  void _showLocalNotification({required String title, required String body}) {
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
  }
}
