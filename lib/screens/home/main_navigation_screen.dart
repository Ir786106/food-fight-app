import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import '../menu/menu_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../cart/cart_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    MenuScreen(onNavigateToCart: () => setState(() => _currentIndex = 2)),
    const CartScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final isCompact = mediaWidth < 640;
    final showLabels = mediaWidth >= 640;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.fromLTRB(12, 0, 12, isCompact ? 8 : 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isCompact ? 20 : 26),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: colorScheme.primary,
            selectedIconTheme: IconThemeData(color: colorScheme.primary),
            unselectedItemColor: colorScheme.onSurfaceVariant,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            showSelectedLabels: showLabels,
            showUnselectedLabels: showLabels,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_outlined),
                activeIcon: Icon(Icons.restaurant_menu_rounded),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: _buildCartNavIcon(count: cart.itemCount),
                activeIcon: _buildCartNavIcon(count: cart.itemCount, selected: true),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Orders',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: cart.itemCount > 0 && (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => setState(() => _currentIndex = 2),
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              label: Text('Cart (${cart.itemCount})',
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildCartNavIcon({required int count, bool selected = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = selected
        ? const Icon(Icons.shopping_cart_rounded)
        : const Icon(Icons.shopping_cart_outlined);

    if (count <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
