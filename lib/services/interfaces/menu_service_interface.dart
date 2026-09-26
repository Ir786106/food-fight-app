import 'package:food_fight/models/menu_item_model.dart';

/// Interface for menu service
abstract class IMenuService {
  /// Get all menu items
  Future<List<MenuItemModel>> getAllMenuItems();

  /// Get menu items by category
  Future<List<MenuItemModel>> getMenuItemsByCategory(String categoryId);

  /// Get menu items by restaurant
  Future<List<MenuItemModel>> getMenuItemsByRestaurant(String restaurantId);

  /// Get featured menu items
  Future<List<MenuItemModel>> getFeaturedMenuItems();

  /// Get popular menu items
  Future<List<MenuItemModel>> getPopularMenuItems();

  /// Get menu item by ID
  Future<MenuItemModel?> getMenuItemById(String itemId);

  /// Create menu item
  Future<MenuItemModel?> createMenuItem(MenuItemModel item);

  /// Update menu item
  Future<void> updateMenuItem(MenuItemModel item);

  /// Delete menu item
  Future<void> deleteMenuItem(String itemId);

  /// Activate/deactivate menu item
  Future<void> setMenuItemStatus(String itemId, bool isActive);

  /// Search menu items
  Future<List<MenuItemModel>> searchMenuItems(String query);

  /// Get menu items by category and search
  Future<List<MenuItemModel>> getItemsByCategoryAndSearch(
    String categoryId,
    String query,
  );
}
