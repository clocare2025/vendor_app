import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/status_provider.dart';
import '../services/notification_service.dart';
import '../widgets/new_order_overlay.dart';
import '../widgets/online_toggle.dart';
import 'home/home_screen.dart';
import 'home/offline_prompt_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

// ── Tab definitions for the Orders screen ────────────────────────────────────

const orderTabs = [
  _OTab('All',       'all',       Icons.grid_view_rounded),
  _OTab('New',       'new',       Icons.notifications_active_rounded),
  _OTab('Active',    'active',    Icons.loop_rounded),
  _OTab('Completed', 'completed', Icons.check_circle_outline_rounded),
  _OTab('Cancelled', 'cancelled', Icons.cancel_outlined),
];

class _OTab {
  final String label;
  final String filter;
  final IconData icon;
  const _OTab(this.label, this.filter, this.icon);
}

// ── Main screen ───────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  MainScreen() : super(key: _key);

  static final GlobalKey<_MainScreenState> _key =
      GlobalKey<_MainScreenState>();

  static void switchToOrdersTab(BuildContext context) =>
      _key.currentState?._onTabSelected(1);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Shared TabController for the Orders screen — lives here so the AppBar
  // tab bar and the screen's TabBarView stay perfectly in sync.
  late final TabController _ordersTabCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ordersTabCtrl = TabController(length: orderTabs.length, vsync: this)
      ..addListener(() {
        if (!_ordersTabCtrl.indexIsChanging) {
          context.read<OrderProvider>()
              .setFilter(orderTabs[_ordersTabCtrl.index].filter);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _ordersTabCtrl.dispose();
    super.dispose();
  }

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    final auth   = context.read<AuthProvider>();
    final status = context.read<StatusProvider>();
    final orders = context.read<OrderProvider>();
    final nav    = Navigator.of(context);
    final token  = auth.token ?? '';
    if (token.isEmpty) return;

    await status.fetchStatus(token);

    try {
      await NotificationService.instance.uploadToken(token);
      NotificationService.instance.watchTokenRefresh(token);
      NotificationService.instance.onNewOrder = (o) => NewOrderOverlay.push(o);
      NotificationService.instance.listenForeground();
      NotificationService.instance.listenOnMessageOpenedApp();
      await NotificationService.instance.handleInitialMessage();
    } catch (_) {}

    await orders.fetchOrders(token);
    if (mounted) _surfacePending(orders);

    if (mounted && !status.isOnline) {
      await nav.push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const OfflinePromptScreen(),
      ));
    }
  }

  void _surfacePending(OrderProvider orders) {
    for (final o in orders.pendingOrders) {
      final n = PendingOrderNotification(
        processId:   o.id,
        orderNumber: o.orderNumber,
        service:     o.serviceName,
        pickupDate:  o.pickupAt != null
            ? '${o.pickupAt!.day}/${o.pickupAt!.month}/${o.pickupAt!.year}'
            : '',
        pickupTime:  o.pickupTimeSlot,
        assignedAt:  o.assignedAt,
      );
      if (!n.isExpired) NewOrderOverlay.push(n);
    }
  }

  void _onTabSelected(int i) => setState(() => _currentIndex = i);

  // ── AppBar helpers ────────────────────────────────────────────────────────

  // Title row shown in collapsed / standard view
  Widget _title(AuthProvider auth, OrderProvider orders) {
    switch (_currentIndex) {
      case 0:
        final name = auth.vendor?.name ?? '';
        return Text(
          name.isNotEmpty ? 'Hi, ${name.split(' ').first} 👋' : 'Home',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        );
      case 1:
        final pending = orders.pendingOrders.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('My Orders',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            if (pending > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.newOrder,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$pending',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        );
      case 2:
        return const Text(
          'Profile',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Tab bar only visible on the Orders tab
  PreferredSizeWidget? _bottomBar(OrderProvider orders) {
    if (_currentIndex != 1) return null;
    final pending = orders.pendingOrders.length;
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        color: AppColors.primaryGrad2,
        child: TabBar(
          controller: _ordersTabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicator: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(30),
          ),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          tabs: orderTabs.map((t) {
            int badge = 0;
            if (t.filter == 'new') badge = pending;
            if (t.filter == 'active') badge = orders.activeOrders.length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 15),
                  const SizedBox(width: 6),
                  Text(t.label),
                  if (badge > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: t.filter == 'new'
                            ? AppColors.newOrder
                            : Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$badge',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final orders    = context.watch<OrderProvider>();
    final statusPvd = context.watch<StatusProvider>();
    final pending   = orders.pendingOrders.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: NewOrderOverlay(
        child: Scaffold(
          backgroundColor: AppColors.background,
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: AppColors.primaryGrad2,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient),
            ),
            title: _title(auth, orders),
            actions: [
              // Refresh button — only on Orders tab
              if (_currentIndex == 1)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () =>
                      orders.fetchOrders(auth.token ?? ''),
                  tooltip: 'Refresh',
                ),
              // Online / Offline toggle — always visible
              OnlineToggle(
                  statusPvd: statusPvd, token: auth.token ?? ''),
            ],
            bottom: _bottomBar(orders),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(),
              OrdersScreen(tabCtrl: _ordersTabCtrl),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: _currentIndex,
            pendingCount: pending,
            onTap: _onTabSelected,
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

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
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
                  label: AppStrings.home,  index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,
                  label: AppStrings.orders, index: 1, current: currentIndex, onTap: onTap,
                  badge: pendingCount),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: AppStrings.profile, index: 2, current: currentIndex, onTap: onTap),
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
    required this.icon, required this.activeIcon,
    required this.label, required this.index,
    required this.current, required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final color    = selected ? AppColors.primary : AppColors.textHint;

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
                    color: selected ? AppColors.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(selected ? activeIcon : icon,
                      color: color, size: 24),
                ),
                if (badge > 0)
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: AppColors.newOrder, shape: BoxShape.circle),
                      child: Text(badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.normal,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
