import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import 'interfaces/chat_service_interface.dart';

import 'package:food_fight/services/interfaces/image_storage_service_interface.dart';
import 'package:food_fight/services/app_image_storage_service.dart';

class ChatMessagePage {
  final List<ChatMessageModel> messages;
  final bool hasMore;

  const ChatMessagePage({required this.messages, required this.hasMore});
}

class ChatService implements IChatService {
  final FirebaseFirestore _firestore;
  final IImageStorageService _storageService;

  ChatService({
    FirebaseFirestore? firestore,
    IImageStorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? AppImageStorageService();

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

  static List<ChatMessageModel> sortMessagesOldestFirst(
    Iterable<ChatMessageModel> messages,
  ) {
    return messages.toList()
      ..sort((a, b) {
        final time = a.createdAt.compareTo(b.createdAt);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
  }

  /// Pages and live snapshots can overlap. Keep the newest representation of
  /// each message, including changes to its read receipts.
  static List<ChatMessageModel> mergeMessages(
    Iterable<ChatMessageModel> existing,
    Iterable<ChatMessageModel> incoming,
  ) => sortMessagesOldestFirst({
    for (final message in existing) message.id: message,
    for (final message in incoming) message.id: message,
  }.values);

  String createMessageId(String chatId) => _messagesRef(chatId).doc().id;

  Stream<ChatModel?> watchChat(String chatId) =>
      _chatsRef.doc(chatId).snapshots().map((doc) =>
          doc.exists ? ChatModel.fromJson(doc.data()!, doc.id) : null);

  Future<ChatModel?> getChat(String chatId) async {
    final doc = await _chatsRef.doc(chatId).get();
    return doc.exists ? ChatModel.fromJson(doc.data()!, doc.id) : null;
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
  Stream<List<ChatModel>> streamCustomerChats(String customerId,
      {int limit = 50}) {
    return _chatsRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  @override
  Stream<List<ChatModel>> streamBranchChats(
    String branchId, {
    String? statusFilter,
    bool isSuperAdmin = false,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _chatsRef;

    // Only filter by branch if non-empty, not 'all', and not Super Admin viewing all branches
    if (branchId.isNotEmpty && branchId != 'all' && !isSuperAdmin) {
      query = query.where('branchId', isEqualTo: branchId);
    }

    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.orderBy('lastMessageAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  @override
  Stream<List<ChatMessageModel>> streamMessages(String chatId,
      {int limit = 50}) {
    return _messagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => sortMessagesOldestFirst(
        snapshot.docs.map(
          (doc) => ChatMessageModel.fromJson(doc.data(), doc.id),
        ),
      ));
  }

  Future<ChatMessagePage> getMessagesBefore(
    String chatId, {
    required String beforeMessageId,
    int limit = 50,
  }) async {
    final cursor = await _messagesRef(chatId).doc(beforeMessageId).get();
    if (!cursor.exists) {
      throw StateError('The message used to load earlier messages was removed.');
    }
    final snapshot = await _messagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .startAfterDocument(cursor)
        .limit(limit + 1)
        .get();
    return ChatMessagePage(
      messages: sortMessagesOldestFirst(snapshot.docs.take(limit).map(
        (doc) => ChatMessageModel.fromJson(doc.data(), doc.id),
      )),
      hasMore: snapshot.docs.length > limit,
    );
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

    final newChat = ChatModel(
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

    return _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(chatDocRef);
      if (existing.exists) {
        return ChatModel.fromJson(existing.data()!, existing.id);
      }
      transaction.set(chatDocRef, {
        ...newChat.toJson(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return newChat;
    });
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
    String? messageId,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      throw ArgumentError('Message text or image URL must be provided');
    }

    final messageRef = _messagesRef(chatId).doc(messageId);
    final chatRef = _chatsRef.doc(chatId);

    final summary = cleanText.isNotEmpty
        ? cleanText
        : (type == 'image' ? 'Image attachment' : '');

    final isCustomer = senderRole == 'customer';

    await _firestore.runTransaction((transaction) async {
      // A retry after an uncertain network result must not send twice.
      final existing = await transaction.get(messageRef);
      if (existing.exists) return;
      final chat = await transaction.get(chatRef);
      if (!chat.exists) throw StateError('This conversation is unavailable.');
      transaction.set(messageRef, {
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

      transaction.update(chatRef, chatUpdates);
    });
    AppLogger.info('Sent message ${messageRef.id} in chat $chatId',
        tag: 'ChatService');
  }

  @override
  Future<void> markAsRead(String chatId, String userId, String userRole,
      {Iterable<String>? messageIds}) async {
    final ids = messageIds?.toSet().toList() ??
        (await _messagesRef(chatId)
          .orderBy('createdAt', descending: true).limit(50).get())
          .docs.map((doc) => doc.id).toList();
    final chatRef = _chatsRef.doc(chatId);
    final isCustomer = userRole == 'customer';
    final counter = isCustomer ? 'unreadForCustomer' : 'unreadForAdmin';

    // Read the counter and receipts together: concurrent arrivals and another
    // staff member reading the same message cannot lose or double-decrement it.
    for (var offset = 0; offset < ids.length; offset += 100) {
      final chunk = ids.skip(offset).take(100).toList();
      await _firestore.runTransaction((transaction) async {
        final chat = await transaction.get(chatRef);
        if (!chat.exists) return;
        final messages = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final id in chunk) {
          messages.add(await transaction.get(_messagesRef(chatId).doc(id)));
        }
        var newlyRead = 0;
        for (final doc in messages) {
          final data = doc.data();
          if (data == null ||
              (data['senderRole'] == 'customer') == isCustomer) {
            continue;
          }
          final readBy = List<String>.from(data['readBy'] ?? []);
          if (readBy.contains(userId)) continue;
          if (!readBy.any((reader) => reader != data['senderId'])) {
            newlyRead++;
          }
          transaction.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
        if (newlyRead > 0) {
          final current = (chat.data()?[counter] as num?)?.toInt() ?? 0;
          transaction.update(chatRef, {
            counter: (current - newlyRead).clamp(0, current),
          });
        }
      });
    }
  }

  @override
  Future<void> updateStatus(String chatId, String status) async {
    if (!const ['open', 'pending', 'resolved'].contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unknown chat status');
    }
    await _chatsRef.doc(chatId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.info('Updated chat $chatId status to $status',
        tag: 'ChatService');
  }

  @override
  Future<void> assignAdmin(String chatId, String? adminId) async {
    await _chatsRef.doc(chatId).update({
      'assignedAdminId': adminId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.info('Assigned chat $chatId to admin: $adminId',
        tag: 'ChatService');
  }

  @override
  Future<String?> uploadChatImage({
    required dynamic imageFileOrBytes,
    required String fileName,
    String? chatId,
    void Function(double)? onProgress,
  }) async {
    if (chatId == null || chatId.isEmpty || chatId.contains('/')) {
      throw ArgumentError('A conversation is required to upload an attachment.');
    }
    if (imageFileOrBytes is! XFile) {
      throw ArgumentError('Select an image from your camera or gallery.');
    }
    return _storageService.uploadImage(
      image: imageFileOrBytes,
      path: 'chat_attachments/$chatId',
      onProgress: onProgress,
    );
  }
}
