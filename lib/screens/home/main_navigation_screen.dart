import '../../providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../widgets/home/desktop_cart_panel.dart';
import '../../widgets/navigation/floating_nav_bar.dart';
import 'home_screen.dart';
import '../orders/order_history_screen.dart';
import '../chat/customer_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../../routes/app_routes.dart';
import '../common/not_found_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  final List<int> _tabHistory = [0];

  // 4 Tab Navigators (Home = 0, Orders = 1, Chat = 2, Profile = 3)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<NavigatorObserver> _tabObservers = List.generate(
    4,
    (index) => _TabNavigatorObserver(() {
      if (mounted) setState(() {});
    }),
  );

  void _onTabTapped(int index) {
    context.read<ChatProvider>().setConversationVisible(index == 2);
    _visitedTabs.add(index);
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

  void _openCart() {
    Navigator.of(context, rootNavigator: true).pushNamed('/cart');
  }

  DateTime? _lastBackPressTime;

  void _handleBackInvocation(bool didPop) {
    if (didPop) return;

    // 0. If virtual keyboard has focus, dismiss keyboard first
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
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
        context.read<ChatProvider>().setConversationVisible(_currentIndex == 2);
      });
      return;
    }

    // 3. If on any tab other than Home, return to Home tab
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        context.read<ChatProvider>().setConversationVisible(false);
        _tabHistory.clear();
        _tabHistory.add(0);
      });
      return;
    }

    // 4. On root of Home tab: Double-back-to-exit with brand snackbar
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      AppSnackbar.showInfo(
        context,
        'Press back again to exit Food Fight',
      );
      return;
    }

    // Back pressed within 2 seconds -> Exit app cleanly
    SystemNavigator.pop();
  }

  Widget _buildTabNavigator(int index, Widget rootScreen) {
    if (!_visitedTabs.contains(index)) return const SizedBox.shrink();
    return ScaffoldMessenger(
        child: Navigator(
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 840;

    // Check if the current tab's nested navigator can pop
    final currentNavState = _navigatorKeys[_currentIndex].currentState;
    final bool isNestedFlow =
        currentNavState != null && currentNavState.canPop();
    final bool shouldShowNav = !isNestedFlow &&
        _currentIndex != 2 &&
        MediaQuery.viewInsetsOf(context).bottom == 0;

    // 4 Navigation Tabs (Home | Orders | Chat | Profile)
    final tabViews = [
      _buildTabNavigator(0, const HomeScreen()),
      _buildTabNavigator(1, const OrderHistoryScreen()),
      _buildTabNavigator(
          2, CustomerChatScreen(onBack: () => _handleBackInvocation(false))),
      _buildTabNavigator(3, const ProfileScreen()),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleBackInvocation(didPop),
      child: Scaffold(
        extendBody: false,
        body: isTablet
            ? Row(
                children: [
                  FloatingNavBar(
                    currentIndex: _currentIndex,
                    onTabSelected: _onTabTapped,
                    onCartSelected: _openCart,
                    isVisible: shouldShowNav,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: tabViews,
                    ),
                  ),
                  if (screenWidth >= 1280 && _currentIndex == 0 && shouldShowNav)
                    DesktopCartPanel(onOpenCart: _openCart),
                ],
              )
            : IndexedStack(index: _currentIndex, children: tabViews),
        bottomNavigationBar: isTablet
            ? null
            : FloatingNavBar(
                currentIndex: _currentIndex,
                onTabSelected: _onTabTapped,
                onCartSelected: _openCart,
                isVisible: shouldShowNav,
              ),
      ),
    );
  }
}

/// NavigatorObserver that notifies the main scaffold whenever routes are pushed/popped
/// within any tab, allowing the nav bar to automatically hide during detail flows.
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
