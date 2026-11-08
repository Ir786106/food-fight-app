import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/chat_message_model.dart';
import 'package:food_fight/services/chat_service.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Orders cannot skip pickup, move backwards or leave terminal states', () {
    for (final status in OrderStatus.values) {
      for (final next in OrderStatus.values) {
        final expected = !status.isTerminal && (next == status.nextStatus || next == OrderStatus.cancelled);
        expect(status.canTransitionTo(next), expected, reason: '${status.name} -> ${next.name}');
      }
    }
    expect(OrderStatus.ready.canTransitionTo(OrderStatus.outForDelivery), isFalse);
    expect(OrderStatus.assigned.isBroadcasting, isFalse);
    expect(OrderStatus.pickedUp.isBroadcasting, isTrue);
    expect(OrderStatus.cancelled.isBroadcasting, isFalse);
  });
  test('Pagination retains older messages and applies updated receipts without duplicates', () {
    ChatMessageModel message(String id, int time, [List<String>? readBy]) => ChatMessageModel(
      id:id, senderId:'customer', senderRole:'customer', senderName:'Customer', text:id,
      createdAt:DateTime.fromMillisecondsSinceEpoch(time), readBy:readBy);
    final merged = ChatService.mergeMessages([message('old', 1),message('recent',2)],
      [message('recent',2,['customer','admin']),message('new',3)]);
    expect(merged.map((m)=>m.id), ['old','recent','new']);
    expect(merged[1].isReadBy('admin'), isTrue);
  });
  test('Non-unit token value is capped at subtotal and does not discount delivery', () async {
    SharedPreferences.setMockInitialValues({});
    final cart = CartProvider();
    await Future<void>.delayed(Duration.zero);
    cart.addToCart(FoodModel(id:'meal',name:'Meal',description:'',price:101,category:'Meals'));
    cart.applyTokens(1000,tokenValue:2.5);
    expect(cart.tokensToRedeem,40);
    expect(cart.loyaltyDiscount,100);
    expect(cart.total,cart.deliveryFee+1);
    cart.clearCart();
    expect(cart.total,0);
    cart.dispose();
  });
}
