import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/navigation/floating_nav_bar.dart';
import '../../widgets/cart/floating_cart_bar.dart';
import 'home_screen.dart';
import '../orders/order_history_screen.dart';
import '../cart/cart_screen.dart';
import '../chat/customer_chat_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];
  bool _isNavVisible = true;

  // Per-tab navigator keys to preserve per-tab Navigator back-button behavior
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Pop to first route in the current tab's navigator
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
    final isDark = theme.brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.yellowSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.brandMaroon,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Exit Food Fight?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to exit the app?',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.onYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Exit App',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onYellow),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _handleBackInvocation(bool didPop) async {
    if (didPop) return;

    // Check if the current tab's navigator can pop
    final currentNavigatorState = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigatorState != null && currentNavigatorState.canPop()) {
      currentNavigatorState.pop();
      return;
    }

    // Otherwise back through tab history
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

  Widget _buildTabNavigator(int index, Widget rootScreen) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (context) => rootScreen,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 840;

    // 5 Navigation Tabs (Home | Orders | Cart | Chat | Profile)
    final tabViews = [
      _buildTabNavigator(0, const HomeScreen()),
      _buildTabNavigator(1, const OrderHistoryScreen()),
      _buildTabNavigator(2, const CartScreen()),
      _buildTabNavigator(3, const CustomerChatScreen()),
      _buildTabNavigator(4, const ProfileScreen()),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleBackInvocation(didPop),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            // Hide on scroll down, show on scroll up
            if (notification.scrollDelta != null) {
              if (notification.scrollDelta! > 12 && _isNavVisible) {
                setState(() => _isNavVisible = false);
              } else if (notification.scrollDelta! < -12 && !_isNavVisible) {
                setState(() => _isNavVisible = true);
              }
            }
          }
          return false;
        },
        child: Scaffold(
          extendBody: true,
          body: isTablet
              ? Row(
                  children: [
                    FloatingNavBar(
                      currentIndex: _currentIndex,
                      onTabSelected: _onTabTapped,
                      onCartSelected: () => _onTabTapped(2),
                      isVisible: true,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: tabViews,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    IndexedStack(
                      index: _currentIndex,
                      children: tabViews,
                    ),

                    // Floating Cart Bar (shows above nav bar on Home screen when cart has items)
                    if (_currentIndex == 0 && cart.itemCount > 0)
                      FloatingCartBar(
                        onTap: () => _onTabTapped(2),
                        bottomOffset: 94.0,
                      ),
                  ],
                ),
          bottomNavigationBar: isTablet
              ? null
              : FloatingNavBar(
                  currentIndex: _currentIndex,
                  onTabSelected: _onTabTapped,
                  onCartSelected: () => _onTabTapped(2),
                  isVisible: _isNavVisible,
                ),
        ),
      ),
    );
  }
}
