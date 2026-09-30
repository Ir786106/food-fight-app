import '../../models/chat_model.dart';
import '../../models/chat_message_model.dart';

/// Contract interface for real-time customer <-> admin chat service
abstract class IChatService {
  /// Stream chats belonging to a customer
  Stream<List<ChatModel>> streamCustomerChats(String customerId);

  /// Stream chats routed to a specific branch (or all branches for Super Admin)
  Stream<List<ChatModel>> streamBranchChats(
    String branchId, {
    String? statusFilter,
    bool isSuperAdmin = false,
  });

  /// Stream messages in a specific chat
  Stream<List<ChatMessageModel>> streamMessages(String chatId, {int limit = 50});

  /// Get existing chat or create a new one deterministically
  Future<ChatModel> getOrCreateChat({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String branchId,
    String? orderId,
    String? orderNumber,
    String type = 'support',
  });

  /// Send message and atomically update chat metadata & unread counters
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
    String type = 'text',
    String? imageUrl,
  });

  /// Mark chat as read for a participant
  Future<void> markAsRead(String chatId, String userId, String userRole);

  /// Update chat status (open, pending, resolved)
  Future<void> updateStatus(String chatId, String status);

  /// Assign branch admin to a chat
  Future<void> assignAdmin(String chatId, String? adminId);

  /// Upload chat image to storage and return its public URL
  Future<String?> uploadChatImage({
    required dynamic imageFileOrBytes,
    required String fileName,
  });
}
