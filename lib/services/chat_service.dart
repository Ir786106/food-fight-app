import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import 'interfaces/chat_service_interface.dart';
import 'supabase/supabase_image_storage_service.dart';

class ChatService implements IChatService {
  final FirebaseFirestore _firestore;
  final SupabaseImageStorageService _storageService;

  ChatService({
    FirebaseFirestore? firestore,
    SupabaseImageStorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? SupabaseImageStorageService();

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection(FirestoreCollections.chats);

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _chatsRef.doc(chatId).collection(FirestoreCollections.messages);

  /// Deterministically derives chatId
  static String deriveChatId({
    required String customerId,
    required String branchId,
    String? orderId,
  }) {
    if (orderId != null && orderId.trim().isNotEmpty) {
      return 'order_${orderId.trim()}';
    }
    final cleanCustomer = customerId.trim();
    final cleanBranch = branchId.trim().isEmpty ? 'default' : branchId.trim();
    return 'support_${cleanCustomer}_$cleanBranch';
  }

  /// Static helper for testing and external callers
  static String generateChatId({
    required String type,
    required String customerId,
    required String branchId,
    String? orderId,
  }) {
    if (type == 'order' && orderId != null && orderId.trim().isNotEmpty) {
      return 'order_${orderId.trim()}';
    }
    return deriveChatId(customerId: customerId, branchId: branchId);
  }

  @override
  Stream<List<ChatModel>> streamCustomerChats(String customerId) {
    return _chatsRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<ChatModel>> streamBranchChats(
    String branchId, {
    String? statusFilter,
    bool isSuperAdmin = false,
  }) {
    Query<Map<String, dynamic>> query = _chatsRef;

    if (!isSuperAdmin || branchId.isNotEmpty) {
      query = query.where('branchId', isEqualTo: branchId);
    }

    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<ChatMessageModel>> streamMessages(String chatId, {int limit = 50}) {
    return _messagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<ChatModel> getOrCreateChat({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String branchId,
    String? orderId,
    String? orderNumber,
    String type = 'support',
  }) async {
    final chatId = deriveChatId(
      customerId: customerId,
      branchId: branchId,
      orderId: orderId,
    );

    final chatDocRef = _chatsRef.doc(chatId);
    final now = DateTime.now();

    final fallbackChat = ChatModel(
      id: chatId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      branchId: branchId,
      orderId: orderId,
      orderNumber: orderNumber,
      type: (orderId != null && orderId.isNotEmpty) ? 'order' : type,
      status: 'open',
      lastMessage: '',
      lastMessageAt: now,
      lastSenderRole: 'customer',
      unreadForAdmin: 0,
      unreadForCustomer: 0,
      createdAt: now,
      updatedAt: now,
    );

    try {
      // Set with merge ensures the document exists and creation does not depend on a prior read
      await chatDocRef.set({
        'id': chatId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'branchId': branchId,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'type': (orderId != null && orderId.isNotEmpty) ? 'order' : type,
        'status': 'open',
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderRole': 'customer',
        'unreadForAdmin': 0,
        'unreadForCustomer': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final docSnapshot = await chatDocRef.get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ChatModel.fromJson(docSnapshot.data()!, docSnapshot.id);
      }
    } catch (e) {
      AppLogger.warn('getOrCreateChat: $e', tag: 'ChatService');
    }

    return fallbackChat;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
    String type = 'text',
    String? imageUrl,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      throw ArgumentError('Message text or image URL must be provided');
    }

    final messageRef = _messagesRef(chatId).doc();
    final chatRef = _chatsRef.doc(chatId);

    final summary = cleanText.isNotEmpty
        ? cleanText
        : (type == 'image' ? '📷 Image attachment' : '');

    final isCustomer = senderRole == 'customer';

    final batch = _firestore.batch();

    // 1. Write message doc
    batch.set(messageRef, {
      'id': messageRef.id,
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': cleanText,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });

    // 2. Atomically update parent chat
    final chatUpdates = <String, dynamic>{
      'lastMessage': summary,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderRole': senderRole,
      'status': 'open', // Reopens if it was resolved
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isCustomer) {
      chatUpdates['unreadForAdmin'] = FieldValue.increment(1);
    } else {
      chatUpdates['unreadForCustomer'] = FieldValue.increment(1);
    }

    batch.set(chatRef, chatUpdates, SetOptions(merge: true));

    await batch.commit();
    AppLogger.info('Sent message ${messageRef.id} in chat $chatId', tag: 'ChatService');
  }

  @override
  Future<void> markAsRead(String chatId, String userId, String userRole) async {
    try {
      final chatRef = _chatsRef.doc(chatId);
      final isCustomer = userRole == 'customer';

      await chatRef.update({
        if (isCustomer) 'unreadForCustomer': 0 else 'unreadForAdmin': 0,
      });

      // Mark recent unread messages
      final unreadSnap = await _messagesRef(chatId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final batch = _firestore.batch();
      bool hasUpdates = false;

      for (final doc in unreadSnap.docs) {
        final data = doc.data();
        final readBy = List<String>.from(data['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      AppLogger.error('Failed to mark chat as read: $e', tag: 'ChatService');
    }
  }

  @override
  Future<void> updateStatus(String chatId, String status) async {
    await _chatsRef.doc(chatId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.info('Updated chat $chatId status to $status', tag: 'ChatService');
  }

  @override
  Future<void> assignAdmin(String chatId, String? adminId) async {
    await _chatsRef.doc(chatId).update({
      'assignedAdminId': adminId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.info('Assigned chat $chatId to admin: $adminId', tag: 'ChatService');
  }

  @override
  Future<String?> uploadChatImage({
    required dynamic imageFileOrBytes,
    required String fileName,
  }) async {
    try {
      if (imageFileOrBytes is XFile) {
        return await _storageService.uploadImage(
          image: imageFileOrBytes,
          path: 'chat_attachments',
        );
      }
      return null;
    } catch (e) {
      AppLogger.error('Chat image upload error: $e', tag: 'ChatService');
      rethrow;
    }
  }
}
