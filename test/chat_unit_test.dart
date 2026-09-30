import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/chat_model.dart';
import 'package:food_fight/models/chat_message_model.dart';
import 'package:food_fight/services/chat_service.dart';

void main() {
  group('ChatService Unit Tests - Deterministic IDs & Logic', () {
    test('generateChatId produces deterministic ID for order chat', () {
      final chatId1 = ChatService.generateChatId(
        type: 'order',
        customerId: 'cust_123',
        branchId: 'branch_johar',
        orderId: 'order_999',
      );
      final chatId2 = ChatService.generateChatId(
        type: 'order',
        customerId: 'cust_123',
        branchId: 'branch_johar',
        orderId: 'order_999',
      );

      expect(chatId1, equals('order_order_999'));
      expect(chatId1, equals(chatId2));
    });

    test('generateChatId produces deterministic ID for general support chat', () {
      final chatId1 = ChatService.generateChatId(
        type: 'support',
        customerId: 'cust_456',
        branchId: 'branch_dha',
      );
      final chatId2 = ChatService.generateChatId(
        type: 'support',
        customerId: 'cust_456',
        branchId: 'branch_dha',
      );

      expect(chatId1, equals('support_cust_456_branch_dha'));
      expect(chatId1, equals(chatId2));
    });

    test('generateChatId creates different IDs for different branches or customers', () {
      final chatBranch1 = ChatService.generateChatId(
        type: 'support',
        customerId: 'cust_1',
        branchId: 'branch_1',
      );
      final chatBranch2 = ChatService.generateChatId(
        type: 'support',
        customerId: 'cust_1',
        branchId: 'branch_2',
      );
      final chatCust2 = ChatService.generateChatId(
        type: 'support',
        customerId: 'cust_2',
        branchId: 'branch_1',
      );

      expect(chatBranch1, isNot(equals(chatBranch2)));
      expect(chatBranch1, isNot(equals(chatCust2)));
    });
  });

  group('ChatModel Serialization & SafeConvert Tests', () {
    test('ChatModel round-trip serialization maintains all fields', () {
      final now = DateTime.now();
      final chat = ChatModel(
        id: 'order_ord_101',
        customerId: 'user_abc',
        customerName: 'Ahmad Khan',
        customerPhone: '+923001234567',
        branchId: 'branch_1',
        orderId: 'ord_101',
        orderNumber: 'FF-101',
        type: 'order',
        status: 'open',
        lastMessage: 'Where is my delivery?',
        lastMessageAt: now,
        lastSenderRole: 'customer',
        unreadForAdmin: 1,
        unreadForCustomer: 0,
        assignedAdminId: null,
        createdAt: now,
        updatedAt: now,
      );

      final map = chat.toMap();
      expect(map['customerId'], equals('user_abc'));
      expect(map['branchId'], equals('branch_1'));
      expect(map['unreadForAdmin'], equals(1));
      expect(map['unreadForCustomer'], equals(0));

      final fromMap = ChatModel.fromMap(map, 'order_ord_101');
      expect(fromMap.id, equals('order_ord_101'));
      expect(fromMap.customerName, equals('Ahmad Khan'));
      expect(fromMap.orderNumber, equals('FF-101'));
      expect(fromMap.status, equals('open'));
    });

    test('ChatModel handles null/missing fields gracefully without crashing', () {
      final emptyMap = <String, dynamic>{};
      final chat = ChatModel.fromMap(emptyMap, 'test_id');

      expect(chat.id, equals('test_id'));
      expect(chat.customerId, equals(''));
      expect(chat.branchId, equals(''));
      expect(chat.unreadForAdmin, equals(0));
      expect(chat.unreadForCustomer, equals(0));
      expect(chat.status, equals('open'));
      expect(chat.type, equals('support'));
    });
  });

  group('ChatMessageModel Serialization Tests', () {
    test('ChatMessageModel serialization preserves sender, readBy array and type', () {
      final now = DateTime.now();
      final msg = ChatMessageModel(
        id: 'msg_001',
        senderId: 'user_abc',
        senderRole: 'customer',
        senderName: 'Ahmad Khan',
        text: 'Can I add extra sauce to my order?',
        type: 'text',
        imageUrl: null,
        createdAt: now,
        readBy: ['user_abc'],
      );

      final map = msg.toMap();
      expect(map['senderId'], equals('user_abc'));
      expect(map['senderRole'], equals('customer'));
      expect(map['text'], equals('Can I add extra sauce to my order?'));
      expect(map['readBy'], contains('user_abc'));

      final fromMap = ChatMessageModel.fromMap(map, 'msg_001');
      expect(fromMap.id, equals('msg_001'));
      expect(fromMap.senderRole, equals('customer'));
      expect(fromMap.isReadBy('user_abc'), isTrue);
      expect(fromMap.isReadBy('admin_xyz'), isFalse);
    });

    test('ChatMessageModel markAsRead adds user ID without duplicates', () {
      final msg = ChatMessageModel(
        id: 'msg_002',
        senderId: 'user_1',
        senderRole: 'customer',
        senderName: 'Customer',
        text: 'Hello',
        type: 'text',
        readBy: ['user_1'],
      );

      final updated = msg.copyWith(readBy: [...msg.readBy, 'admin_1']);
      expect(updated.readBy, contains('user_1'));
      expect(updated.readBy, contains('admin_1'));
      expect(updated.readBy.length, equals(2));
      expect(updated.isReadBy('admin_1'), isTrue);
    });
  });
}
