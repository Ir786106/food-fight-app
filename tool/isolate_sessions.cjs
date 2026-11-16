const fs=require('node:fs');
function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
edit('lib/main.dart',s=>{
  s="import 'widgets/common/session_bindings.dart';\n"+s;
  s=s.replace('    return MultiProvider(',`    return ChangeNotifierProvider(create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(builder: (context, auth, _) => MultiProvider(
      key: ValueKey(auth.currentUser?.id ?? 'guest'),`);
  s=s.replace('        ChangeNotifierProvider(create: (_) => AuthProvider()),\n','');
  s=s.replace('            title: AppConstants.appName,','            navigatorKey: appNavigatorKey,\n            title: AppConstants.appName,');
  s=s.replace('child: child ?? const SizedBox.shrink(),','child: SessionBindings(child: child ?? const SizedBox.shrink()),');
  const end=s.lastIndexOf('    );');
  s=s.slice(0,end)+'    )));'+s.slice(end+6);
  return s;
});
edit('lib/providers/auth_provider.dart',s=>{
  s="import 'package:shared_preferences/shared_preferences.dart';\n"+s;
  return s.replace('      await _authService.signOut();', `      await FcmService.unregisterUserToken();
      final prefs = await SharedPreferences.getInstance();
      for (final key in ['food_fight_cart_v1','food_fight_cart_branch_v1','food_fight_favorites_v1','pending_checkout_v1']) {
        await prefs.remove(key);
      }
      await _authService.signOut();`);
});
edit('lib/screens/home/main_navigation_screen.dart',s=>{
  s="import '../../providers/chat_provider.dart';\n"+s;
  s=s.replace('  int _currentIndex = 0;', '  int _currentIndex = 0;\n  final Set<int> _visitedTabs = {0};');
  s=s.replace('  void _onTabTapped(int index) {', '  void _onTabTapped(int index) {\n    context.read<ChatProvider>().setConversationVisible(index == 2);\n    _visitedTabs.add(index);');
  s=s.replace('    return ScaffoldMessenger(child: Navigator(', '    if (!_visitedTabs.contains(index)) return const SizedBox.shrink();\n    return ScaffoldMessenger(child: Navigator(');
  return s;
});
edit('lib/providers/notification_provider.dart',s=>s.replace('    if (userId.isEmpty) {','    if (userId.isEmpty) {\n      _sub?.cancel();\n      _sub = null;\n      _currentUserId = null;'));
edit('lib/screens/notifications/notifications_screen.dart',s=>s.replace("pushNamed('/chat', arguments: notif.referenceId)", "pushNamed('/chat', arguments: {'chatId': notif.referenceId})"));
