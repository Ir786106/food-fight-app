import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/food_model.dart';
import '../models/order_model.dart';

class CartService extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  final List<OrderModel> _orders = [];
  final List<FoodModel> _favorites = [];

  List<CartItemModel> get items => _items;
  List<OrderModel> get orders => _orders;
  List<FoodModel> get favorites => _favorites;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => _items.isEmpty ? 0 : 249;

  double get total => subtotal + deliveryFee;

  void addToCart(FoodModel food, {int quantity = 1, String? note, String? selectedSize}) {
    final existingIndex = _items.indexWhere((i) => i.food.id == food.id && i.selectedSize == selectedSize);
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemModel(food: food, quantity: quantity, note: note, selectedSize: selectedSize));
    }
    notifyListeners();
  }

  void incrementQuantity(String foodId) {
    final index = _items.indexWhere((i) => i.food.id == foodId);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String foodId) {
    final index = _items.indexWhere((i) => i.food.id == foodId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String foodId) {
    _items.removeWhere((i) => i.food.id == foodId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String foodId) => _items.any((i) => i.food.id == foodId);

  // Favorites
  void toggleFavorite(FoodModel food) {
    final exists = _favorites.any((f) => f.id == food.id);
    if (exists) {
      _favorites.removeWhere((f) => f.id == food.id);
    } else {
      _favorites.add(food);
    }
    notifyListeners();
  }

  bool isFavorite(String foodId) => _favorites.any((f) => f.id == foodId);

  OrderModel placeOrder({
    required String address,
    required String paymentMethod,
    required String restaurantName,
  }) {
    final now = DateTime.now();
    final order = OrderModel(
      id: 'FF${now.millisecondsSinceEpoch}',
      orderNumber: 'FF${now.millisecondsSinceEpoch}',
      items: List.from(_items),
      subtotal: subtotal,
      deliveryCharge: deliveryFee,
      total: total,
      paymentMethod: paymentMethod,
      deliveryAddress: address,
      restaurantName: restaurantName,
      createdAt: now,
      updatedAt: now,
      customerId: 'local_user',
    );
    _orders.insert(0, order);
    clearCart();
    notifyListeners();
    return order;
  }
}
