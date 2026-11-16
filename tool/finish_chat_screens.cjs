const fs=require('node:fs');
for(const p of ['lib/screens/chat/customer_chat_screen.dart','lib/screens/admin/chats/admin_chats_screen.dart']) {
  let s=fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n');
  s=s.replace(/import '[^']*widgets\/common\/network_image_view.dart';/, "import 'package:food_fight/widgets/common/chat_image_view.dart';");
  s=s.replaceAll('NetworkImageView(', 'ChatImageView(');
  s=s.replace("import 'package:image_picker/image_picker.dart';\n",'');
  s=s.replace(/    final picker = ImagePicker\(\);\n    final image = await picker.pickImage\([\s\S]*?    \);/, '    final image = await pickChatImage(context);');
  s=s.replace('  bool _isComposing = false;', '  bool _isComposing = false;\n  ChatProvider? _roomProvider;');
  if(!s.includes('ChatProvider? _roomProvider;')) s=s.replace('  final TextEditingController', '  ChatProvider? _roomProvider;\n  final TextEditingController');
  s=s.replace('    super.initState();', `    super.initState();
    _roomProvider = context.read<ChatProvider>();
    _scrollController.addListener(() async {
      final provider = _roomProvider!;
      if (!_scrollController.hasClients || _scrollController.offset > 48 ||
          !provider.hasMoreMessages || provider.isLoadingOlderMessages) return;
      final before = _scrollController.position.maxScrollExtent;
      final offset = _scrollController.offset;
      await provider.loadOlderMessages();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(
          (offset + _scrollController.position.maxScrollExtent - before).clamp(0.0, _scrollController.position.maxScrollExtent));
      });
    });`);
  s=s.replace('  void dispose() {', '  void dispose() {\n    _roomProvider?.closeActiveChat();');
  s=s.replace("'Online • Replies in minutes'", "'Support team'");
  s=s.replace('onPressed: () => _handleSendMessage(customText: _lastFailedText),', 'onPressed: chatProv.isSending ? null : () {\n                        if (chatProv.hasFailedImage) { chatProv.retryFailedImage(); }\n                        else { _handleSendMessage(customText: _lastFailedText); }\n                      },');
  s=s.replace('onPressed: _handleAttachImage,', 'onPressed: context.watch<ChatProvider>().isSending ? null : _handleAttachImage,');
  const marker = p.includes('customer_chat') ? '            // 4. Message List or Silent Skeleton Loader' : '            // Messages';
  const progress=`            if (chatProv.uploadProgress != null) LinearProgressIndicator(value: chatProv.uploadProgress),
            if (chatProv.isLoadingOlderMessages) const LinearProgressIndicator(),
`;
  if(s.includes(marker)) s=s.replace(marker,progress+marker);
  if(p.includes('customer_chat')) {
    s=s.replace('    // Determine target orderId', `    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map && routeArgs['chatId'] != null) {
      await chatProv.openChatById(routeArgs['chatId'].toString(), user.id, 'customer');
      return;
    }
    // Determine target orderId`);
    s=s.replace('final foundOrder = orderProv.getOrderById(orderId);', 'final foundOrder = orderProv.getOrderById(orderId) ?? await orderProv.fetchOrderById(orderId);\n      if (!mounted) return;');
  }
  fs.writeFileSync(p,s);
}
