import 'package:flutter/material.dart';
import 'package:food_fight/models/cart_item_model.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/models/coupon_model.dart';
import 'package:food_fight/services/coupon_service.dart';
import 'package:food_fight/services/order_service.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';
import 'package:food_fight/models/deal_model.dart';

/// Provider for managing customer shopping cart, delivery area, coupons, and checkout
class CartProvider extends ChangeNotifier with SafeChangeNotifier {
  final List<CartItemModel> _items = [];
  final List<FoodModel> _favorites = [];
  DeliveryAreaModel? _selectedArea;
  CouponModel? _appliedCoupon;
  double _couponDiscount = 0.0;
  bool _isFreeDelivery = false;
  String? _couponError;
  String? _branchId;
  int _tokensToRedeem = 0;
  double _tokenValue = 1.0;

  List<CartItemModel> get items => List.unmodifiable(_items);
  List<FoodModel> get favorites => List.unmodifiable(_favorites);
  DeliveryAreaModel? get selectedArea => _selectedArea;
  CouponModel? get appliedCoupon => _appliedCoupon;
  double get couponDiscount => _couponDiscount;
  bool get isFreeDelivery => _isFreeDelivery;
  String? get couponError => _couponError;
  String? get branchId => _branchId ?? (_items.isNotEmpty ? _items.first.food.branchId : null);
  int get tokensToRedeem => _tokensToRedeem;
  double get tokenValue => _tokenValue;
  double get loyaltyDiscount => (_tokensToRedeem * _tokenValue).clamp(0.0, subtotal);

  void setBranchId(String? id) {
    _branchId = id;
    notifyListeners();
  }

  bool isDifferentBranch(String? incomingBranchId) {
    if (_items.isEmpty || incomingBranchId == null || incomingBranchId.isEmpty) return false;
    final current = branchId;
    return current != null && current.isNotEmpty && current != incomingBranchId;
  }

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

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee {
    if (_items.isEmpty) return 0.0;
    if (_isFreeDelivery) return 0.0;
    return _selectedArea?.deliveryCharge ?? 150.0;
  }

  double get total {
    final discount = loyaltyDiscount > 0 ? loyaltyDiscount : _couponDiscount;
    final t = subtotal + deliveryFee - discount;
    return t > 0 ? t : 0.0;
  }

  double get totalPrice => total;

  /// Apply loyalty tokens for discount at checkout
  void applyTokens(int tokens, {double tokenValue = 1.0}) {
    _tokensToRedeem = tokens;
    _tokenValue = tokenValue;
    notifyListeners();
  }

  /// Remove tokens
  void clearTokens() {
    _tokensToRedeem = 0;
    notifyListeners();
  }

  /// Add a pre-configured deal / bundle directly to cart with deal price applied
  void addDealToCart(DealModel deal) {
    final bundleDesc = deal.bundleItems.isNotEmpty
        ? deal.bundleItems.map((b) => '${b.quantity}x ${b.name}').join(', ')
        : deal.description;

    final dealFood = FoodModel(
      id: 'deal_${deal.id}',
      name: deal.title,
      description: bundleDesc,
      price: deal.dealPrice,
      imageEmoji: '🎁',
      imageUrl: deal.imageUrl,
      category: 'Deals',
      branchId: deal.branchId,
      rating: 5.0,
      prepTimeMinutes: 25,
      restaurantId: 'rest-1',
    );

    addToCart(
      dealFood,
      quantity: 1,
      selectedSize: 'Bundle Deal',
    );
  }

  bool isInCart(String foodId) => _items.any((i) => i.food.id == foodId);

  int getQuantity(String foodId) {
    final item = _items.firstWhere(
      (i) => i.food.id == foodId,
      orElse: () => CartItemModel(food: FoodModel(id: '', name: '', description: '', price: 0, category: '', rating: 0, prepTimeMinutes: 0, restaurantId: ''), quantity: 0),
    );
    return item.quantity;
  }

  void addToCart(
    FoodModel food, {
    int quantity = 1,
    String? note,
    String? selectedSize,
    MenuVariant? selectedVariant,
    List<MenuAddon>? selectedAddons,
    bool clearIfDifferentBranch = false,
  }) {
    if (food.branchId != null && food.branchId!.isNotEmpty) {
      if (isDifferentBranch(food.branchId)) {
        if (clearIfDifferentBranch) {
          clearCart();
        }
      }
      _branchId ??= food.branchId;
    }

    // Resolve variant if not explicitly provided
    final variant = selectedVariant ??
        (selectedSize != null && food.variants != null && food.variants!.isNotEmpty
            ? food.variants!.firstWhere(
                (v) => v.label.toLowerCase() == selectedSize.toLowerCase(),
                orElse: () => food.variants!.first,
              )
            : null);

    final candidate = CartItemModel(
      food: food,
      quantity: quantity,
      note: note,
      selectedSize: selectedSize ?? variant?.label,
      selectedVariant: variant,
      selectedAddons: selectedAddons != null ? List<MenuAddon>.from(selectedAddons) : [],
    );

    final existingIndex = _items.indexWhere((i) => i.lineKey == candidate.lineKey);

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(candidate);
    }
    _recalculateCoupon();
    notifyListeners();
  }

  /// Increment quantity of a specific cart line by lineKey
  void incrementLine(String lineKey) {
    final index = _items.indexWhere((i) => i.lineKey == lineKey);
    if (index != -1) {
      _items[index].quantity++;
      _recalculateCoupon();
      notifyListeners();
    }
  }

  /// Decrement quantity or remove a specific cart line by lineKey
  void decrementLine(String lineKey) {
    final index = _items.indexWhere((i) => i.lineKey == lineKey);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _recalculateCoupon();
      notifyListeners();
    }
  }

  /// Remove a specific cart line by lineKey
  void removeLine(String lineKey) {
    _items.removeWhere((i) => i.lineKey == lineKey);
    _recalculateCoupon();
    notifyListeners();
  }

  void incrementQuantity(String foodId, {String? selectedSize, String? lineKey}) {
    if (lineKey != null) {
      incrementLine(lineKey);
      return;
    }
    final index = _items.indexWhere(
      (i) => i.food.id == foodId && (selectedSize == null || i.selectedSize == selectedSize),
    );
    if (index != -1) {
      _items[index].quantity++;
      _recalculateCoupon();
      notifyListeners();
    }
  }

  void decrementQuantity(String foodId, {String? selectedSize, String? lineKey}) {
    if (lineKey != null) {
      decrementLine(lineKey);
      return;
    }
    final index = _items.indexWhere(
      (i) => i.food.id == foodId && (selectedSize == null || i.selectedSize == selectedSize),
    );
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _recalculateCoupon();
      notifyListeners();
    }
  }

  void removeFromCart(String foodId, {String? selectedSize, String? lineKey}) {
    if (lineKey != null) {
      removeLine(lineKey);
      return;
    }
    _items.removeWhere(
      (i) => i.food.id == foodId && (selectedSize == null || i.selectedSize == selectedSize),
    );
    _recalculateCoupon();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _couponDiscount = 0.0;
    _isFreeDelivery = false;
    _couponError = null;
    _branchId = null;
    _tokensToRedeem = 0;
    notifyListeners();
  }

  void setDeliveryArea(DeliveryAreaModel? area) {
    _selectedArea = area;
    notifyListeners();
  }

  /// Apply Coupon code
  Future<bool> applyCoupon(String code) async {
    _couponError = null;
    if (_items.isEmpty) {
      _couponError = 'Cart is empty';
      notifyListeners();
      return false;
    }

    final result = await CouponService.validateCoupon(code, subtotal);
    if (!result.isValid) {
      _couponError = result.errorMessage ?? 'Invalid coupon code';
      _appliedCoupon = null;
      _couponDiscount = 0.0;
      _isFreeDelivery = false;
      notifyListeners();
      return false;
    }

    _appliedCoupon = result.coupon;
    _couponDiscount = result.discountAmount;
    _isFreeDelivery = result.isFreeDelivery;
    _couponError = null;
    notifyListeners();
    return true;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponDiscount = 0.0;
    _isFreeDelivery = false;
    _couponError = null;
    notifyListeners();
  }

  void _recalculateCoupon() {
    if (_appliedCoupon != null) {
      if (subtotal < _appliedCoupon!.minimumOrder) {
        removeCoupon();
        _couponError = 'Order subtotal is below coupon minimum requirement';
      } else {
        if (_appliedCoupon!.type == 'percentage') {
          double disc = (subtotal * _appliedCoupon!.value) / 100.0;
          if (_appliedCoupon!.maximumDiscount != null && _appliedCoupon!.maximumDiscount! > 0) {
            if (disc > _appliedCoupon!.maximumDiscount!) {
              disc = _appliedCoupon!.maximumDiscount!;
            }
          }
          _couponDiscount = disc;
        } else if (_appliedCoupon!.type == 'free_delivery') {
          _isFreeDelivery = true;
          _couponDiscount = 0.0;
        } else {
          _couponDiscount = _appliedCoupon!.value > subtotal ? subtotal : _appliedCoupon!.value;
        }
      }
    }
  }

  /// Place order to Cloud Firestore
  Future<OrderModel> placeOrder({
    required String customerId,
    required String deliveryAddress,
    required String paymentMethod,
    String customerName = 'Guest Customer',
    String customerPhone = '',
    String paymentStatus = 'pending',
    String restaurantName = 'Food Fight HQ',
    String? branchId,
  }) async {
    final effectiveBranchId = branchId ?? this.branchId;
    final effectiveDiscount = loyaltyDiscount > 0 ? loyaltyDiscount : _couponDiscount;

    final order = OrderModel(
      id: '',
      orderNumber: OrderService.generateOrderNumber(),
      branchId: effectiveBranchId,
      items: List.from(_items),
      subtotal: subtotal,
      discount: effectiveDiscount,
      deliveryCharge: deliveryFee,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      status: OrderStatus.pending,
      deliveryAddress: deliveryAddress,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      restaurantName: restaurantName,
      tokensUsed: _tokensToRedeem,
      tokensDiscount: loyaltyDiscount,
    );

    final generatedId = await OrderService.placeOrder(order);

    final savedOrder = order.copyWith(id: generatedId);

    clearCart();
    return savedOrder;
  }
}
