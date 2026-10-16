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
import '../../routes/app_routes.dart';
import '../common/not_found_screen.dart';

import '../../providers/app_update_provider.dart';
import '../../widgets/app_update_bottom_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    // Defer update check until 2.5s after the first routed screen is fully displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        final updateProv = context.read<AppUpdateProvider>();
        updateProv.checkForUpdateThrottled().then((_) {
          if (!mounted) return;
          if (updateProv.hasUpdate) {
            AppUpdateBottomSheet.show(context);
          }
        });
      });
    });
  }

  // Per-tab navigator keys to preserve per-tab Navigator back-button behavior
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<NavigatorObserver> _tabObservers = List.generate(
    5,
    (index) => _TabNavigatorObserver(() {
      if (mounted) setState(() {});
    }),
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

  DateTime? _lastBackPressTime;

  void _handleBackInvocation(bool didPop) {
    if (didPop) return;

    // 0. If virtual keyboard has focus, dismiss keyboard first
    if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    // 1. Check if the current tab's navigator can pop a nested screen
    final currentNavigatorState = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigatorState != null && currentNavigatorState.canPop()) {
      currentNavigatorState.pop();
      return;
    }

    // 2. Otherwise back through tab history
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _currentIndex = _tabHistory.last;
      });
      return;
    }

    // 3. If on any tab other than Home, return to Home tab
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _tabHistory.clear();
        _tabHistory.add(0);
      });
      return;
    }

    // 4. On root of Home tab: Double-back-to-exit with snackbar
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exit_to_app_rounded, color: AppColors.brandMaroon, size: 20),
              SizedBox(width: 10),
              Text(
                'Press back again to exit Food Fight',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandMaroon),
              ),
            ],
          ),
          backgroundColor: AppColors.brandYellow,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        ),
      );
      return;
    }

    // Back pressed within 2 seconds -> Exit app cleanly
    SystemNavigator.pop();
  }

  Widget _buildTabNavigator(int index, Widget rootScreen) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: [_tabObservers[index]],
      onGenerateRoute: (routeSettings) {
        if (routeSettings.name == null || routeSettings.name == '/') {
          return MaterialPageRoute(
            settings: routeSettings,
            builder: (context) => rootScreen,
          );
        }

        final builder = AppRoutes.routes[routeSettings.name];
        if (builder != null) {
          return MaterialPageRoute(
            settings: routeSettings,
            builder: builder,
          );
        }

        return MaterialPageRoute(
          settings: routeSettings,
          builder: (context) => NotFoundScreen(routeName: routeSettings.name),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 840;

    // Check if the current tab's nested navigator can pop (i.e. inside detail flows like checkout/tracking)
    final currentNavState = _navigatorKeys[_currentIndex].currentState;
    final bool isNestedFlow = currentNavState != null && currentNavState.canPop();
    final bool isCartTab = _currentIndex == 2;
    final bool shouldShowFloatingNav = !isTablet && _isNavVisible && !isNestedFlow && !isCartTab;

    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final double cartPillBottomOffset = shouldShowFloatingNav
        ? (104.0 + safeBottom)
        : (18.0 + safeBottom);

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

                    // Floating Cart Bar (shows cleanly above nav bar on Home screen when cart has items)
                    if (_currentIndex == 0 && cart.itemCount > 0)
                      FloatingCartBar(
                        onTap: () => _onTabTapped(2),
                        bottomOffset: cartPillBottomOffset,
                      ),
                  ],
                ),
          bottomNavigationBar: isTablet
              ? null
              : FloatingNavBar(
                  currentIndex: _currentIndex,
                  onTabSelected: _onTabTapped,
                  onCartSelected: () => _onTabTapped(2),
                  isVisible: shouldShowFloatingNav,
                ),
        ),
      ),
    );
  }
}

/// NavigatorObserver that notifies the main scaffold whenever routes are pushed/popped
/// within any tab, allowing the floating nav bar to automatically hide during detail flows.
class _TabNavigatorObserver extends NavigatorObserver {
  final VoidCallback onNavigationChanged;
  _TabNavigatorObserver(this.onNavigationChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => onNavigationChanged());
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => onNavigationChanged());
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => onNavigationChanged());
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => onNavigationChanged());
  }
}
