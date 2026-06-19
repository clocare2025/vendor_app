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
    final auth    = context.read<AuthProvider>();
    final status  = context.read<StatusProvider>();
    final orders  = context.read<OrderProvider>();
    final nav     = Navigator.of(context);
    final token   = auth.token ?? '';
    if (token.isEmpty) return;

    await status.fetchStatus(token);

    try {
      await NotificationService.instance.uploadToken(token);
      NotificationService.instance.watchTokenRefresh(token);
      NotificationService.instance.onNewOrder = (order) {
        NewOrderOverlay.push(order);
      };
      NotificationService.instance.listenForeground();
      NotificationService.instance.listenOnMessageOpenedApp();
      await NotificationService.instance.handleInitialMessage();
    } catch (_) {}

    await orders.fetchOrders(token);
    if (mounted) _showPendingOrderCards(orders);

    if (mounted && !status.isOnline) {
      await nav.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const OfflinePromptScreen(),
        ),
      );
    }
  }

  void _showPendingOrderCards(OrderProvider orders) {
    for (final o in orders.pendingOrders) {
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
      if (!notification.isExpired) NewOrderOverlay.push(notification);
    }
  }

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final orders  = context.watch<OrderProvider>();
    final pending = orders.pendingOrders.length;

    return NewOrderOverlay(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          pendingCount: pending,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int pendingCount;
  final void Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: AppStrings.home,
                index: 0,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: AppStrings.orders,
                index: 1,
                current: currentIndex,
                onTap: onTap,
                badge: pendingCount,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: AppStrings.profile,
                index: 2,
                current: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final color = selected ? AppColors.primary : AppColors.textHint;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? activeIcon : icon,
                    color: color,
                    size: 24,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.newOrder,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
