const fs=require('node:fs');
const p='lib/providers/chat_provider.dart';
let s=fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n');
s=s.replace('  // Unread totals', `  StreamSubscription<ChatModel?>? _activeChatSubscription;
  bool _conversationVisible = false;
  bool _loadingOlder = false;
  bool _hasMore = true;
  double? _uploadProgress;
  XFile? _failedImage;
  String? _failedSenderId, _failedSenderRole, _failedSenderName;
  int _session = 0;
  bool get isLoadingOlderMessages => _loadingOlder;
  bool get hasMoreMessages => _hasMore;
  double? get uploadProgress => _uploadProgress;
  bool get hasFailedImage => _failedImage != null;

  void setConversationVisible(bool visible) { _conversationVisible = visible; }

  Future<void> openChatById(String id, String userId, String role) async {
    final chat = await _chatService.getChat(id);
    if (chat == null) throw StateError('Conversation not found');
    openExistingChat(chat, userId, role);
  }

  Future<void> loadOlderMessages() async {
    final chat = _activeChat;
    if (_loadingOlder || !_hasMore || chat == null || _activeMessages.isEmpty) return;
    _loadingOlder = true;
    notifyListeners();
    try {
      final page = await _chatService.getMessagesBefore(chat.id, beforeMessageId: _activeMessages.first.id);
      if (_activeChat?.id != chat.id) return;
      _activeMessages = ChatService.mergeMessages(page.messages, _activeMessages);
      _hasMore = page.hasMore;
    } catch (_) {
      _errorMessage = 'Could not load earlier messages. Please retry.';
    } finally {
      _loadingOlder = false;
      notifyListeners();
    }
  }

  Future<bool> retryFailedImage() async {
    final image = _failedImage;
    if (image == null) return false;
    return sendImage(image: image, senderId: _failedSenderId!,
      senderRole: _failedSenderRole!, senderName: _failedSenderName!);
  }

  // Unread totals`);
s=s.replace('    try {\n      _isLoadingMessages = true;', '    final session = ++_session;\n    try {\n      _isLoadingMessages = true;');
s=s.replace('      _activeChat = chat;\n      _subscribeToActiveMessages', '      if (session != _session) return;\n      _activeChat = chat;\n      _subscribeToActiveMessages');
s=s.replace('    _messagesSubscription?.cancel();\n    _messagesSubscription =', `    _messagesSubscription?.cancel();
    _activeChatSubscription?.cancel();
    _activeMessages = [];
    _hasMore = true;
    _conversationVisible = true;
    _activeChatSubscription = _chatService.watchChat(chatId).listen((chat) {
      if (_activeChat?.id != chatId) return;
      _activeChat = chat;
      notifyListeners();
    }, onError: (_) { _errorMessage = 'Could not refresh conversation status.'; notifyListeners(); });
    _messagesSubscription =`);
s=s.replace('        _activeMessages = messages;', '        if (_activeChat?.id != chatId) return;\n        _activeMessages = ChatService.mergeMessages(_activeMessages, messages);\n        if (messages.length < 50) _hasMore = false;');
s=s.replace('        _chatService.markAsRead(chatId, userId, userRole);', `        if (_conversationVisible && messages.any((message) =>
            message.senderId != userId && !message.readBy.contains(userId))) {
          _chatService.markAsRead(chatId, userId, userRole,
            messageIds: messages.map((message) => message.id).toList())
            .catchError((Object error) { AppLogger.warn('Could not update read receipts', tag: 'ChatProvider'); });
        }`);
s=s.replaceAll('          _messagesSubscription = null;\n          return;', '          _messagesSubscription = null;\n          _isLoadingMessages = false;\n          _errorMessage = "You no longer have access to this conversation.";\n          notifyListeners();\n          return;');
const start=s.indexOf('  /// Send image attachment'), end=s.indexOf('  /// Mark chat status',start);
s=s.slice(0,start)+`  /// Upload and send to the captured conversation, even if another room opens.
  Future<bool> sendImage({required XFile image, required String senderId,
    required String senderRole, required String senderName}) async {
    final chat = _activeChat;
    if (chat == null || _isSending) return false;
    _isSending = true;
    _uploadProgress = 0;
    _sendErrorMessage = null;
    _failedImage = image;
    _failedSenderId = senderId; _failedSenderRole = senderRole; _failedSenderName = senderName;
    notifyListeners();
    try {
      final url = await _chatService.uploadChatImage(imageFileOrBytes: image,
        fileName: image.name, chatId: chat.id, onProgress: (value) {
          _uploadProgress = value; notifyListeners();
        });
      if (url == null) throw StateError('Upload did not complete');
      await _chatService.sendMessage(chatId: chat.id, senderId: senderId,
        senderRole: senderRole, senderName: senderName, text: '', type: 'image', imageUrl: url);
      _failedImage = null;
      return true;
    } catch (_) {
      _sendErrorMessage = 'Photo could not be sent. Retry when connected.';
      return false;
    } finally {
      _uploadProgress = null; _isSending = false; notifyListeners();
    }
  }

`+s.slice(end);
s=s.replace('  void closeActiveChat() {', '  void closeActiveChat() {\n    _session++;\n    _conversationVisible = false;\n    _failedImage = null;\n    _activeChatSubscription?.cancel();');
s=s.replace('  void dispose() {', '  void dispose() {\n    _session++;\n    _activeChatSubscription?.cancel();');
fs.writeFileSync(p,s);
