import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/status_provider.dart';
import '../services/notification_service.dart';
import '../widgets/new_order_overlay.dart';
import 'home/home_screen.dart';
import 'home/offline_prompt_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  MainScreen() : super(key: _key);

  static final GlobalKey<_MainScreenState> _key = GlobalKey<_MainScreenState>();

  static void switchToOrdersTab(BuildContext context) {
    _key.currentState?._onTabSelected(1);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // Capture all context-dependent objects BEFORE any await
    final auth    = context.read<AuthProvider>();
    final status  = context.read<StatusProvider>();
    final orders  = context.read<OrderProvider>();
    final nav     = Navigator.of(context);
    final token   = auth.token ?? '';
    if (token.isEmpty) return;

    // 1. Fetch + sync online/offline status
    await status.fetchStatus(token);

    // 2. Upload FCM token + wire listeners (no-op if Firebase not configured)
    try {
      await NotificationService.instance.uploadToken(token);
      NotificationService.instance.watchTokenRefresh(token);
      NotificationService.instance.onNewOrder = (order) {
        if (mounted) NewOrderOverlay.of(context)?.addOrder(order);
      };
      NotificationService.instance.listenForeground();
      NotificationService.instance.listenOnMessageOpenedApp();
      await NotificationService.instance.handleInitialMessage();
    } catch (_) {
      // Firebase not configured — push notifications disabled
    }

    // 4. Load orders — surface any already-assigned ones that haven't expired
    await orders.fetchOrders(token);
    if (mounted) _showPendingOrderCards(orders);

    // 5. Show offline prompt if vendor is currently offline
    if (mounted && !status.isOnline) {
      await nav.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const OfflinePromptScreen(),
        ),
      );
    }
  }

  /// For every order that is still in "assigned" state and not yet expired,
  /// push it into the overlay so the vendor can accept/reject right away.
  void _showPendingOrderCards(OrderProvider orders) {
    final overlay = NewOrderOverlay.of(context);
    if (overlay == null) return;

    for (final o in orders.pendingOrders) {
      // assignedAt is the time admin created it; use it as the window start
      final notification = PendingOrderNotification(
        processId:   o.id,
        orderNumber: o.orderNumber,
        service:     o.serviceName,
        pickupDate:  o.pickupAt != null
            ? '${o.pickupAt!.day}/${o.pickupAt!.month}/${o.pickupAt!.year}'
            : '',
        pickupTime:  o.pickupTimeSlot,
        assignedAt:  o.assignedAt,
      );
      // Skip already-expired orders
      if (!notification.isExpired) {
        overlay.addOrder(notification);
      }
    }
  }

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final status = context.watch<StatusProvider>();
    final auth   = context.read<AuthProvider>();

    return NewOrderOverlay(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            _currentIndex == 0
                ? 'Home'
                : _currentIndex == 1
                    ? 'Orders'
                    : 'Profile',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            // ── Online / Offline toggle pill ─────────────────────────────
            GestureDetector(
              onTap: status.loading
                  ? null
                  : () => status.toggle(auth.token ?? ''),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: status.isOnline
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status.loading)
                      const SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 1.5),
                      )
                    else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: status.isOnline
                              ? Colors.white
                              : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      status.isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: AppStrings.orders,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }
}
