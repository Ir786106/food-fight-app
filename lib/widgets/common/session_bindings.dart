import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_update_provider.dart';
import '../app_update_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../services/fcm_service.dart';
import '../../core/utils/app_snackbar.dart';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
String? _navigationSession;
GlobalKey<NavigatorState> navigatorKeyForSession(String? userId) {
  final session = userId ?? 'guest';
  if (_navigationSession != session) {
    _navigationSession = session;
    appNavigatorKey = GlobalKey<NavigatorState>();
  }
  return appNavigatorKey;
}

class SessionBindings extends StatefulWidget {
  final Widget child;
  const SessionBindings({super.key, required this.child});
  @override
  State<SessionBindings> createState() => _SessionBindingsState();
}

class _SessionBindingsState extends State<SessionBindings> with WidgetsBindingObserver {
  Timer? _updateTimer;
  String? _promptedUpdateTag;
  bool _checkingUpdate = false;

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate || !mounted) return;
    _checkingUpdate = true;
    try {
      final provider = context.read<AppUpdateProvider>();
      await provider.checkForUpdateThrottled();
      final release = provider.availableRelease;
      final prefs = await SharedPreferences.getInstance();
      final navigator = appNavigatorKey.currentState;
      if (!mounted || navigator == null || release == null ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
          _promptedUpdateTag == release.tagName) return;
      _promptedUpdateTag = release.tagName;
      await AppUpdateBottomSheet.show(
        navigator.context,
        autoDownload: prefs.getBool(autoDownloadUpdatesPreference) ?? false,
      );
    } finally {
      _checkingUpdate = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_checkForUpdate());
  }

  @override
  void initState() {
    super.initState();
    if (kReleaseMode && AppUpdateProvider.supported) {
      WidgetsBinding.instance.addObserver(this);
      _updateTimer = Timer(const Duration(seconds: 3), _checkForUpdate);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      context.read<NotificationProvider>().watchNotifications(user.id);
      if (user.isCustomer) {
        context.read<ChatProvider>().streamCustomerChats(user.id);
        context.read<OrderProvider>().watchCustomerOrders(user.id);
        context.read<LoyaltyProvider>().watchAccount(user.id);
      } else if (user.can('chats')) {
        context.read<ChatProvider>().streamAdminChats(user.branchId ?? '', isSuperAdmin: user.isSuperAdmin);
      }
      FcmService.onOpen = (data) {
        if (!mounted) return;
        final nav = appNavigatorKey.currentState;
        if (nav == null) return;
        final chatId = data['chatId']?.toString();
        final orderId = data['orderId']?.toString() ?? data['referenceId']?.toString();
        if (chatId != null) {
          nav.pushNamed(user.isAdmin ? '/admin/chats' : '/chat', arguments: {'chatId': chatId});
        } else if (orderId != null) {
          nav.pushNamed(user.isRider ? '/rider' : user.isAdmin ? '/admin/orders' : '/order-tracking', arguments: orderId);
        } else {
          nav.pushNamed('/notifications');
        }
      };
      FcmService.onForeground = (title, data) {
        final screen = appNavigatorKey.currentContext;
        if (screen != null) {
          AppSnackbar.showInfo(screen, title,
          action: SnackBarAction(label: 'View', onPressed: () => FcmService.onOpen?.call(data)));
        }
      };
      FcmService.routePending();
    });
  }
  @override
  void dispose() {
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    FcmService.onOpen = null;
    FcmService.onForeground = null;
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => widget.child;
}
