import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<int> _tabHistory = [0];

  // Independent Navigator stack for each bottom tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // If user taps the already active tab, pop it to its root
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _tabHistory.remove(index);
      _tabHistory.add(index);
      _currentIndex = index;
    });
  }

  Future<bool> _showExitConfirmationDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.exit_to_app_rounded, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Exit Food Fight?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to close the app?',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Exit App',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _handleBackInvocation(bool didPop) async {
    if (didPop) return;

    // 1. Check if the active tab has internal pushed routes to pop
    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return;
    }

    // 2. If no subroutes, navigate back through tab history
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _currentIndex = _tabHistory.last;
      });
      return;
    }

    // 3. If on a non-home tab without history, switch to home first
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _tabHistory.clear();
        _tabHistory.add(0);
      });
      return;
    }

    // 4. At true root screen (Home tab with empty stack): confirm exit
    final shouldExit = await _showExitConfirmationDialog();
    if (shouldExit && mounted) {
      SystemNavigator.pop();
    }
  }

  Widget _buildTabNavigator(int index, Widget rootWidget) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => rootWidget,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final isCompact = mediaWidth < 640;
    final showLabels = mediaWidth >= 640;
    final colorScheme = Theme.of(context).colorScheme;

    final tabViews = [
      _buildTabNavigator(0, const HomeScreen()),
      _buildTabNavigator(1, MenuScreen(onNavigateToCart: () => _onTabTapped(2))),
      _buildTabNavigator(2, const CartScreen()),
      _buildTabNavigator(3, const OrderHistoryScreen()),
      _buildTabNavigator(4, const ProfileScreen()),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleBackInvocation(didPop),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: tabViews,
        ),
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
              onTap: _onTabTapped,
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
                onPressed: () => _onTabTapped(2),
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                label: Text(
                  'Cart (${cart.itemCount})',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : null,
      ),
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
