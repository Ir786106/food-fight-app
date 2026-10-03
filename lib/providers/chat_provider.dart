import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/logger.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import '../models/notification_model.dart';
import '../models/admin/audit_log_model.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/super_admin_service.dart';
import '../core/utils/safe_change_notifier.dart';

/// State management provider for Customer and Admin real-time chats.
class ChatProvider extends ChangeNotifier with SafeChangeNotifier {
  final ChatService _chatService;
  final NotificationService _notificationService;

  ChatProvider({
    ChatService? chatService,
    NotificationService? notificationService,
  })  : _chatService = chatService ?? ChatService(),
        _notificationService = notificationService ?? NotificationService();

  // Current active chat
  ChatModel? _activeChat;
  ChatModel? get activeChat => _activeChat;

  // Messages in active thread
  List<ChatMessageModel> _activeMessages = [];
  List<ChatMessageModel> get activeMessages => List.unmodifiable(_activeMessages);

  // Admin chat list
  List<ChatModel> _adminChats = [];
  List<ChatModel> get adminChats => List.unmodifiable(_adminChats);

  // Customer chat list
  List<ChatModel> _customerChats = [];
  List<ChatModel> get customerChats => List.unmodifiable(_customerChats);

  // Loading and sending states
  bool _isLoadingChats = false;
  bool get isLoadingChats => _isLoadingChats;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _sendErrorMessage;
  String? get sendErrorMessage => _sendErrorMessage;

  // Subscriptions
  StreamSubscription<List<ChatModel>>? _chatsSubscription;
  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;

  // Unread totals
  int get totalAdminUnread =>
      _adminChats.fold(0, (sum, chat) => sum + chat.unreadForAdmin);

  int get totalCustomerUnread =>
      _customerChats.fold(0, (sum, chat) => sum + chat.unreadForCustomer);

  int get totalUnreadForCustomer => totalCustomerUnread;
  int get totalUnreadCount => totalCustomerUnread;

  /// Initialize real-time stream of chats for customer
  void streamCustomerChats(String customerId) {
    if (customerId.isEmpty) return;
    _chatsSubscription?.cancel();
    _isLoadingChats = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _chatsSubscription = _chatService.streamCustomerChats(customerId).listen(
      (chats) {
        _customerChats = chats;
        _isLoadingChats = false;
        notifyListeners();
      },
      onError: (e) {
        if (e.toString().contains('permission-denied')) {
          _chatsSubscription?.cancel();
          _chatsSubscription = null;
          return;
        }
        _isLoadingChats = false;
        _errorMessage = 'Failed to load chats: $e';
        AppLogger.error('Customer chats stream error: $e', tag: 'ChatProvider');
        notifyListeners();
      },
    );
  }

  /// Initialize real-time stream of chats for admin / branch
  void streamAdminChats(
    String branchId, {
    String? statusFilter,
    bool isSuperAdmin = false,
  }) {
    _chatsSubscription?.cancel();
    _isLoadingChats = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _chatsSubscription = _chatService
        .streamBranchChats(
          branchId,
          statusFilter: statusFilter,
          isSuperAdmin: isSuperAdmin,
        )
        .listen(
          (chats) {
            _adminChats = chats;
            _isLoadingChats = false;
            notifyListeners();
          },
          onError: (e) {
            if (e.toString().contains('permission-denied')) {
              _chatsSubscription?.cancel();
              _chatsSubscription = null;
              return;
            }
            _isLoadingChats = false;
            _errorMessage = 'Failed to load admin chats: $e';
            AppLogger.error('Admin chats stream error: $e', tag: 'ChatProvider');
            notifyListeners();
          },
        );
  }

  /// Select or create chat channel and subscribe to message updates
  Future<void> openChatChannel({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String branchId,
    String? orderId,
    String? orderNumber,
    String userRole = 'customer',
  }) async {
    try {
      _isLoadingMessages = true;
      _errorMessage = null;
      _sendErrorMessage = null;
      notifyListeners();

      final chat = await _chatService.getOrCreateChat(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        branchId: branchId,
        orderId: orderId,
        orderNumber: orderNumber,
      );

      _activeChat = chat;
      _subscribeToActiveMessages(chat.id, customerId, userRole);
    } catch (e) {
      _isLoadingMessages = false;
      _errorMessage = 'Could not open support chat: $e';
      AppLogger.error('Error opening chat channel: $e', tag: 'ChatProvider');
      notifyListeners();
    }
  }

  /// Open an existing chat directly (e.g. from Admin thread selection)
  void openExistingChat(ChatModel chat, String userId, String userRole) {
    _activeChat = chat;
    _sendErrorMessage = null;
    _subscribeToActiveMessages(chat.id, userId, userRole);
  }

  void _subscribeToActiveMessages(String chatId, String userId, String userRole) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService.streamMessages(chatId).listen(
      (messages) {
        _activeMessages = messages;
        _isLoadingMessages = false;
        notifyListeners();

        // Mark as read automatically when new messages arrive while viewing
        _chatService.markAsRead(chatId, userId, userRole);
      },
      onError: (e) {
        if (e.toString().contains('permission-denied')) {
          _messagesSubscription?.cancel();
          _messagesSubscription = null;
          return;
        }
        _isLoadingMessages = false;
        _errorMessage = 'Failed to load conversation: $e';
        AppLogger.error('Messages stream error: $e', tag: 'ChatProvider');
        notifyListeners();
      },
    );
  }

  /// Send message
  Future<bool> sendMessage({
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
    String type = 'text',
    String? imageUrl,
  }) async {
    final chat = _activeChat;
    if (chat == null) {
      _sendErrorMessage = 'No active chat session.';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _sendErrorMessage = null;
    notifyListeners();

    try {
      await _chatService.sendMessage(
        chatId: chat.id,
        senderId: senderId,
        senderRole: senderRole,
        senderName: senderName,
        text: text,
        type: type,
        imageUrl: imageUrl,
      );

      _isSending = false;

      // In-app notifications
      try {
        final isCustomer = senderRole == 'customer';
        if (isCustomer) {
          // Notify admin of that branch
          await _notificationService.createNotification(NotificationModel(
            id: '',
            userId: 'branch_${chat.branchId}',
            title: 'New message from $senderName',
            message: text.isNotEmpty ? text : 'Sent a photo attachment',
            type: 'chat',
            referenceId: chat.id,
            createdAt: DateTime.now(),
          ));
        } else {
          // Notify customer
          await _notificationService.createNotification(NotificationModel(
            id: '',
            userId: chat.customerId,
            title: 'Food Fight Support',
            message: text.isNotEmpty ? text : 'Support sent an attachment',
            type: 'chat',
            referenceId: chat.id,
            createdAt: DateTime.now(),
          ));
        }
      } catch (notifyErr) {
        AppLogger.warning('Could not create in-app notification: $notifyErr', tag: 'ChatProvider');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _isSending = false;
      _sendErrorMessage = 'Failed to send. Tap to retry.';
      AppLogger.error('Error sending message: $e', tag: 'ChatProvider');
      notifyListeners();
      return false;
    }
  }

  /// Send image attachment
  Future<bool> sendImage({
    required XFile image,
    required String senderId,
    required String senderRole,
    required String senderName,
  }) async {
    final chat = _activeChat;
    if (chat == null) return false;

    _isSending = true;
    _sendErrorMessage = null;
    notifyListeners();

    try {
      final imageUrl = await _chatService.uploadChatImage(
        imageFileOrBytes: image,
        fileName: image.name,
      );

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Failed to upload image');
      }

      return await sendMessage(
        senderId: senderId,
        senderRole: senderRole,
        senderName: senderName,
        text: '',
        type: 'image',
        imageUrl: imageUrl,
      );
    } catch (e) {
      _isSending = false;
      _sendErrorMessage = 'Image upload failed: $e';
      AppLogger.error('Error uploading chat image: $e', tag: 'ChatProvider');
      notifyListeners();
      return false;
    }
  }

  /// Mark chat status (open, pending, resolved)
  Future<void> updateStatus(
    String newStatus, {
    required String actorName,
    required String actorEmail,
    required String actorRole,
  }) async {
    final chat = _activeChat;
    if (chat == null) return;

    try {
      await _chatService.updateStatus(chat.id, newStatus);
      _activeChat = chat.copyWith(status: newStatus);

      // Audit Log
      await SuperAdminService.recordAuditLog(AuditLogModel(
        id: '',
        action: newStatus == 'resolved' ? 'RESOLVE_CHAT' : 'REOPEN_CHAT',
        actorName: actorName,
        actorEmail: actorEmail,
        actorRole: actorRole,
        targetEntity: 'chat',
        targetId: chat.id,
        description: '$actorName ($actorRole) changed chat status to $newStatus',
        metadata: {
          'customerId': chat.customerId,
          'branchId': chat.branchId,
          'orderId': chat.orderId,
        },
      ));

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating chat status: $e', tag: 'ChatProvider');
    }
  }

  /// Assign chat to an admin
  Future<void> assignAdmin(String? adminId) async {
    final chat = _activeChat;
    if (chat == null) return;

    try {
      await _chatService.assignAdmin(chat.id, adminId);
      _activeChat = chat.copyWith(assignedAdminId: adminId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error assigning admin: $e', tag: 'ChatProvider');
    }
  }

  /// Close current active thread
  void closeActiveChat() {
    _messagesSubscription?.cancel();
    _activeChat = null;
    _activeMessages = [];
    _sendErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
