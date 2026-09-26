import 'package:food_fight/models/category_model.dart';

/// Interface for category service
abstract class ICategoryService {
  /// Get all categories
  Future<List<CategoryModel>> getAllCategories();

  /// Get category by ID
  Future<CategoryModel?> getCategoryById(String categoryId);

  /// Get categories by restaurant
  Future<List<CategoryModel>> getCategoriesByRestaurant(String restaurantId);

  /// Create category
  Future<CategoryModel?> createCategory(CategoryModel category);

  /// Update category
  Future<void> updateCategory(CategoryModel category);

  /// Delete category
  Future<void> deleteCategory(String categoryId);

  /// Activate/deactivate category
  Future<void> setCategoryStatus(String categoryId, bool isActive);

  /// Get featured categories
  Future<List<CategoryModel>> getFeaturedCategories();
}
