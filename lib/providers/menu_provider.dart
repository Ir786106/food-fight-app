import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/services/menu_service.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Provider for managing Menu Items across Customer and Admin panels
class MenuProvider extends ChangeNotifier {
  List<MenuItemModel> _menuItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  StreamSubscription<List<MenuItemModel>>? _subscription;

  List<MenuItemModel> get menuItems => List.unmodifiable(_menuItems);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  /// Filtered items for Admin/Customer screens
  List<MenuItemModel> get filteredItems {
    return _menuItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' ||
          item.categoryId == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Active menu items only (for customer menu/home screens)
  List<MenuItemModel> get activeItems {
    return _menuItems.where((item) => item.isActive).toList();
  }

  /// Popular items (for home screen & dashboard)
  List<MenuItemModel> get popularItems {
    final list = _menuItems.where((item) => item.isActive && item.isPopular).toList();
    if (list.isNotEmpty) return list;
    return _menuItems.where((item) => item.isActive).take(6).toList();
  }

  /// List of items mapped to FoodModel for customer components
  List<FoodModel> get foodList {
    return activeItems.map((item) => FoodModel.fromMenuItem(item)).toList();
  }

  /// Get FoodModels for specific category
  List<FoodModel> getFoodByCategory(String categoryId) {
    final items = categoryId == 'All'
        ? activeItems
        : activeItems.where((i) => i.categoryId == categoryId).toList();
    return items.map((item) => FoodModel.fromMenuItem(item)).toList();
  }

  MenuProvider() {
    init();
  }

  void init() {
    watchMenuItems();
  }

  String? _currentBranchId;

  String? get currentBranchId => _currentBranchId;

  /// Real-time listener for Firestore menu collection
  void watchMenuItems({
    String? categoryId,
    bool activeOnly = false,
    String? branchId,
  }) {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = MenuService.watchMenuItems(
      categoryId: categoryId,
      activeOnly: activeOnly,
      branchId: branchId,
    ).listen(
      (data) {
        _menuItems = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load menu items: $e';
        AppLogger.error('MenuProvider watch error: $e', tag: 'MenuProvider');
        notifyListeners();
      },
    );
  }

  /// Manual fetch
  Future<void> fetchMenuItems({String? categoryId, String? branchId}) async {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _menuItems = await MenuService.getMenuItems(
        categoryId: categoryId,
        branchId: branchId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch menu items: $e';
      notifyListeners();
    }
  }

  /// Set category filter
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Create new menu item
  Future<String?> createMenuItem(MenuItemModel item) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await MenuService.createMenuItem(item);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create menu item: $e';
      AppLogger.error('Create menu item error: $e', tag: 'MenuProvider');
      notifyListeners();
      return null;
    }
  }

  /// Update existing menu item
  Future<bool> updateMenuItem(MenuItemModel item) async {
    _isLoading = true;
    notifyListeners();
    try {
      await MenuService.updateMenuItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update menu item: $e';
      AppLogger.error('Update menu item error: $e', tag: 'MenuProvider');
      notifyListeners();
      return false;
    }
  }

  /// Delete menu item
  Future<bool> deleteMenuItem(String id, {String? imageUrl}) async {
    try {
      await MenuService.deleteMenuItem(id, imageUrl: imageUrl);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete menu item: $e';
      AppLogger.error('Delete menu item error: $e', tag: 'MenuProvider');
      notifyListeners();
      return false;
    }
  }

  /// Toggle active status
  Future<bool> toggleActive(String id, bool currentStatus) async {
    try {
      await MenuService.toggleActive(id, currentStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to toggle active status: $e';
      AppLogger.error('Toggle active error: $e', tag: 'MenuProvider');
      notifyListeners();
      return false;
    }
  }

  /// Find item by ID
  MenuItemModel? findById(String id) {
    try {
      return _menuItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
