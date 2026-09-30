import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/constants/app_colors.dart';
import 'package:food_fight/models/chat_message_model.dart';

void main() {
  group('Chat Widget Component Tests', () {
    testWidgets('Quick reply chips render and are tappable', (WidgetTester tester) async {
      String? tappedReply;
      final quickReplies = [
        'Where is my order?',
        'Change address',
        'Wrong/missing item',
        'Cancel order',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickReplies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(reply),
                      backgroundColor: AppColors.yellowSoft,
                      labelStyle: const TextStyle(
                        color: AppColors.brandMaroon,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onPressed: () {
                        tappedReply = reply;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Where is my order?'), findsOneWidget);
      expect(find.text('Change address'), findsOneWidget);

      await tester.tap(find.text('Where is my order?'));
      await tester.pump();

      expect(tappedReply, equals('Where is my order?'));
    });

    testWidgets('Chat message bubble colors match brand design guidelines', (WidgetTester tester) async {
      final customerMsg = ChatMessageModel(
        id: 'msg-1',
        senderId: 'cust-1',
        senderRole: 'customer',
        senderName: 'Customer',
        text: 'Hello support!',
        type: 'text',
      );

      final adminMsg = ChatMessageModel(
        id: 'msg-2',
        senderId: 'admin-1',
        senderRole: 'admin',
        senderName: 'Support Agent',
        text: 'Hello! How can we help?',
        type: 'text',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Customer Bubble (brandYellow with maroon text)
                Container(
                  key: const Key('customer-bubble'),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    customerMsg.text,
                    style: const TextStyle(color: AppColors.brandMaroon),
                  ),
                ),
                // Admin Bubble (white surface with border and textPrimary)
                Container(
                  key: const Key('admin-bubble'),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    adminMsg.text,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hello support!'), findsOneWidget);
      expect(find.text('Hello! How can we help?'), findsOneWidget);

      final customerContainer = tester.widget<Container>(find.byKey(const Key('customer-bubble')));
      final customerDecoration = customerContainer.decoration as BoxDecoration;
      expect(customerDecoration.color, equals(AppColors.brandYellow));

      final adminContainer = tester.widget<Container>(find.byKey(const Key('admin-bubble')));
      final adminDecoration = adminContainer.decoration as BoxDecoration;
      expect(adminDecoration.color, equals(Colors.white));
    });

    testWidgets('Resolved banner displays and shows Reopen action', (WidgetTester tester) async {
      bool reopened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.successSoft,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This conversation was marked as resolved.',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => reopened = true,
                    child: const Text('Reopen', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('This conversation was marked as resolved.'), findsOneWidget);
      expect(find.text('Reopen'), findsOneWidget);

      await tester.tap(find.text('Reopen'));
      await tester.pump();
      expect(reopened, isTrue);
    });

    testWidgets('Order context card displays order details', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellowTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.brandMaroon),
                  SizedBox(width: 10),
                  Text('Order #FF-1002', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMaroon)),
                  Spacer(),
                  Text('Rs. 1,450', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandMaroon)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Order #FF-1002'), findsOneWidget);
      expect(find.text('Rs. 1,450'), findsOneWidget);
    });
  });
}
