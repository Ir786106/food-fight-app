import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import '../search/search_screen.dart';
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

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: AppColors.primary, size: 22),
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
          'Are you sure you want to exit the app?',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _currentIndex = _tabHistory.last;
      });
      return;
    }

    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _tabHistory.clear();
        _tabHistory.add(0);
      });
      return;
    }

    final shouldExit = await _showExitConfirmationDialog();
    if (shouldExit && mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final isCompact = mediaWidth < 640;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tabViews = const [
      HomeScreen(),
      SearchScreen(),
      CartScreen(),
      OrderHistoryScreen(),
      ProfileScreen(),
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
            margin: EdgeInsets.fromLTRB(16, 0, 16, isCompact ? 10 : 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 24),
                unselectedItemColor: colorScheme.onSurfaceVariant,
                unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 22),
                backgroundColor: colorScheme.surface,
                elevation: 0,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppColors.primary,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.search_rounded),
                    activeIcon: Icon(Icons.search_rounded),
                    label: 'Search',
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
        ),
      ),
    );
  }

  Widget _buildCartNavIcon({required int count, bool selected = false}) {
    final icon = Icon(
      selected ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
      color: selected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
      size: selected ? 24 : 22,
    );

    if (count <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
