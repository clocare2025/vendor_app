import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import 'home/home_screen.dart';
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

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: AppStrings.home),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: AppStrings.orders),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: AppStrings.profile),
        ],
      ),
    );
  }
}
