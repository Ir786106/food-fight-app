import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/services/category_service.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Provider managing Category state for Admin & Customer panels
class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<CategoryModel>>? _subscription;

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<CategoryModel> get activeCategories =>
      List.unmodifiable(_categories.where((c) => c.isActive).toList());
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CategoryProvider() {
    init();
  }

  void init() {
    watchCategories();
  }

  /// Watch real-time categories from Firestore
  void watchCategories({bool activeOnly = false}) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = CategoryService.watchCategories(activeOnly: activeOnly).listen(
      (data) {
        _categories = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load categories: $e';
        AppLogger.error('CategoryProvider watch error: $e', tag: 'CategoryProvider');
        notifyListeners();
      },
    );
  }

  /// Manual fetch
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await CategoryService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch categories: $e';
      notifyListeners();
    }
  }

  /// Create new category
  Future<bool> createCategory(CategoryModel category) async {
    try {
      await CategoryService.createCategory(category);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create category: $e';
      AppLogger.error('Create category error: $e', tag: 'CategoryProvider');
      notifyListeners();
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await CategoryService.updateCategory(category);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update category: $e';
      AppLogger.error('Update category error: $e', tag: 'CategoryProvider');
      notifyListeners();
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await CategoryService.deleteCategory(categoryId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete category: $e';
      AppLogger.error('Delete category error: $e', tag: 'CategoryProvider');
      notifyListeners();
      return false;
    }
  }

  /// Toggle active status
  Future<bool> toggleActive(String categoryId, bool currentStatus) async {
    try {
      await CategoryService.toggleActive(categoryId, currentStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to toggle category: $e';
      AppLogger.error('Toggle category error: $e', tag: 'CategoryProvider');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
