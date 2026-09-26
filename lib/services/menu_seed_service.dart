import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/services/category_service.dart';

/// Service to migrate and seed the official Food Fight menu with multi-size variants and extras
class MenuSeedService {
  static final CollectionReference _menuCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.menuItems);
  static final CollectionReference _catCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.categories);

  /// Alias for seedRealMenu
  static Future<Map<String, int>> seedAll() => seedRealMenu();

  /// Seeds all categories and multi-size variant menu items into Firestore
  static Future<Map<String, int>> seedRealMenu() async {
    int categoriesCreated = 0;
    int itemsCreated = 0;

    try {
      // 1. Fetch or create categories
      final existingCategories = await CategoryService.getCategories();
      final Map<String, String> categoryNameToId = {
        for (var c in existingCategories) c.name.trim().toLowerCase(): c.id,
      };

      final List<Map<String, dynamic>> targetCategories = [
        {'name': 'Regular Pizza', 'icon': '🍕', 'order': 1},
        {'name': 'Most Recommended', 'icon': '⭐', 'order': 2},
        {'name': 'Stuffed Crust', 'icon': '🧀', 'order': 3},
        {'name': 'Burger with Fries', 'icon': '🍔', 'order': 4},
        {'name': 'Broast', 'icon': '🍗', 'order': 5},
        {'name': 'Crispy Fried Chicken', 'icon': '🍗', 'order': 6},
        {'name': 'Special Hot Wings', 'icon': '🔥', 'order': 7},
        {'name': 'Wraps & Pratha Roll', 'icon': '🌯', 'order': 8},
        {'name': 'Shawarma & Platter', 'icon': '🥙', 'order': 9},
        {'name': 'Pizza Stacker', 'icon': '🍕', 'order': 10},
        {'name': 'Pasta', 'icon': '🍝', 'order': 11},
        {'name': 'Fries', 'icon': '🍟', 'order': 12},
        {'name': 'Platters', 'icon': '🍱', 'order': 13},
        {'name': 'Beverages', 'icon': '🥤', 'order': 14},
        {'name': 'Deals & Combos', 'icon': '🎁', 'order': 15},
      ];

      for (var cat in targetCategories) {
        final catName = cat['name'] as String;
        final key = catName.trim().toLowerCase();
        if (!categoryNameToId.containsKey(key)) {
          final docRef = _catCollection.doc();
          final newCat = CategoryModel(
            id: docRef.id,
            name: catName,
            description: cat['icon'],
            order: cat['order'],
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await docRef.set(newCat.toJson());
          categoryNameToId[key] = docRef.id;
          categoriesCreated++;
        }
      }

      // Reusable Standard Pizza Variants & Add-ons
      final regularPizzaVariants = [
        const MenuVariant(label: 'Small', price: 399),
        const MenuVariant(label: 'Medium', price: 799),
        const MenuVariant(label: 'Large', price: 1199),
        const MenuVariant(label: 'Extra Large', price: 1599),
      ];

      final mostRecommendedVariants = [
        const MenuVariant(label: 'Medium', price: 999),
        const MenuVariant(label: 'Large', price: 1599),
        const MenuVariant(label: 'Extra Large', price: 1999),
      ];

      final stuffedCrustVariants = [
        const MenuVariant(label: 'Medium', price: 1199),
        const MenuVariant(label: 'Large', price: 1799),
        const MenuVariant(label: 'Extra Large', price: 2199),
      ];

      final pizzaAddons = [
        const MenuAddon(name: 'Extra Chicken Topping', price: 200),
        const MenuAddon(name: 'Extra Cheese Topping', price: 200),
        const MenuAddon(name: 'Spicy Dip Sauce', price: 70),
        const MenuAddon(name: 'Garlic Mayo Dip Sauce', price: 70),
      ];

      final burgerAddons = [
        const MenuAddon(name: 'Extra Cheese Slice', price: 60),
        const MenuAddon(name: 'Spicy Dip Sauce', price: 70),
        const MenuAddon(name: 'Extra Fries Portion', price: 120),
      ];

      final broastVariants = [
        const MenuVariant(
          label: 'Quarter',
          price: 399,
          description: '1 leg, 1 thigh, 1 bun + fries + 1 dip sauce',
        ),
        const MenuVariant(
          label: 'Half',
          price: 749,
          description: '2 legs, 2 thighs, 2 buns + fries + 2 dip sauces',
        ),
        const MenuVariant(
          label: 'Full',
          price: 1399,
          description: '4 legs, 4 thighs, 4 buns + fries + 4 dip sauces',
        ),
      ];

      final friedChickenVariants = [
        const MenuVariant(label: '3 Pcs', price: 399),
        const MenuVariant(label: '5 Pcs', price: 649),
        const MenuVariant(label: '10 Pcs', price: 1199),
      ];

      final wingsVariants = [
        const MenuVariant(label: '5 Pcs', price: 299),
        const MenuVariant(label: '10 Pcs', price: 549),
      ];

      final friesVariants = [
        const MenuVariant(label: 'Regular', price: 180),
        const MenuVariant(label: 'Large', price: 280),
        const MenuVariant(label: 'Family', price: 450),
      ];

      final drinkVariants = [
        const MenuVariant(label: 'Regular Can (250ml)', price: 90),
        const MenuVariant(label: '1.5 Litre Bottle', price: 220),
      ];

      // 2. Define real Food Fight menu items
      final List<MenuItemModel> seedItems = [
        // ================= Regular Pizza =================
        MenuItemModel(
          id: '',
          name: 'Chicken Tikka Pizza',
          description: 'Tikka Topping + Onion + Black Olives',
          price: 399,
          categoryId: categoryNameToId['regular pizza'] ?? '',
          variants: regularPizzaVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 20,
          isVeg: false,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Chicken Fajita Pizza',
          description: 'Mild Spicy Chicken + Onion + Bell Pepper + Jalapeno',
          price: 399,
          categoryId: categoryNameToId['regular pizza'] ?? '',
          variants: regularPizzaVariants,
          addons: pizzaAddons,
          isSpicy: true,
          prepTimeMinutes: 20,
          isVeg: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Chicken Supreme Pizza',
          description: 'Tikka Topping + Chicken Sausages + Black Olives',
          price: 399,
          categoryId: categoryNameToId['regular pizza'] ?? '',
          variants: regularPizzaVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 22,
          isVeg: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Cheese Lover Pizza',
          description: 'Loaded with rich creamy Mozzarella & Cheddar cheese',
          price: 399,
          categoryId: categoryNameToId['regular pizza'] ?? '',
          variants: regularPizzaVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 20,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Vegi Lovers Pizza',
          description: 'Onion + Bell Pepper + Tomato + Mushroom + Sweet Corn + Black Olives',
          price: 399,
          categoryId: categoryNameToId['regular pizza'] ?? '',
          variants: regularPizzaVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 20,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Most Recommended =================
        MenuItemModel(
          id: '',
          name: 'Real Taste Special Pizza',
          description: 'Chef Special Topping with Signature House Sauce',
          price: 999,
          categoryId: categoryNameToId['most recommended'] ?? '',
          variants: mostRecommendedVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 22,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Four Season Pizza',
          description: 'Four Different Types of Toppings with Signature Sauce',
          price: 999,
          categoryId: categoryNameToId['most recommended'] ?? '',
          variants: mostRecommendedVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 22,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Bone Fire Pizza',
          description: 'Creamy Base & Grilled Chicken + Mushroom + Jalapeno with Fiery Sauce',
          price: 999,
          categoryId: categoryNameToId['most recommended'] ?? '',
          variants: mostRecommendedVariants,
          addons: pizzaAddons,
          isSpicy: true,
          prepTimeMinutes: 24,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Malai Booti Chicken Pizza',
          description: 'Creamy Base + Creamy Chicken + Mushroom + Black Olive',
          price: 999,
          categoryId: categoryNameToId['most recommended'] ?? '',
          variants: mostRecommendedVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 24,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Chicken Seekh Kabab Pizza',
          description: 'Seekh Kabab Topping + Onion + Bell Pepper + Tomato',
          price: 999,
          categoryId: categoryNameToId['most recommended'] ?? '',
          variants: mostRecommendedVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 24,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Crown Crust Pizza',
          description: 'Lots of Cheese & Chicken + Onion + Black Olive + Sweet Corn in a Crown Crust',
          price: 999,
          categoryId: categoryNameToId['most recommended'] ?? '',
          variants: mostRecommendedVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Stuffed Crust =================
        MenuItemModel(
          id: '',
          name: 'Chicken Seekh Kabab Stuffed Crust',
          description: 'Seekh kabab chunks rolled inside a cheese stuffed crust',
          price: 1199,
          categoryId: categoryNameToId['stuffed crust'] ?? '',
          variants: stuffedCrustVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 24,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Cheese Stuff Crust Pizza',
          description: 'Creamy Mozzarella melted inside every bite of crust',
          price: 1199,
          categoryId: categoryNameToId['stuffed crust'] ?? '',
          variants: stuffedCrustVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 24,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Real Taste Special Stuffed Crust',
          description: 'Signature toppings with molten cheese stuffed crust',
          price: 1199,
          categoryId: categoryNameToId['stuffed crust'] ?? '',
          variants: stuffedCrustVariants,
          addons: pizzaAddons,
          prepTimeMinutes: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Broast =================
        MenuItemModel(
          id: '',
          name: 'Golden Crispy Broast',
          description: 'Deep-fried golden crunchy broast served with golden fries, fresh bun and dip',
          price: 399,
          categoryId: categoryNameToId['broast'] ?? '',
          variants: broastVariants,
          addons: [
            const MenuAddon(name: 'Extra Bun', price: 50),
            const MenuAddon(name: 'Extra Garlic Dip Sauce', price: 70),
            const MenuAddon(name: 'Extra Fries Portion', price: 120),
          ],
          prepTimeMinutes: 20,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Spicy Masala Broast',
          description: 'Spicy seasoned broast served with golden fries, fresh bun and fiery dip',
          price: 399,
          categoryId: categoryNameToId['broast'] ?? '',
          variants: broastVariants,
          addons: [
            const MenuAddon(name: 'Extra Bun', price: 50),
            const MenuAddon(name: 'Extra Spicy Dip Sauce', price: 70),
          ],
          isSpicy: true,
          prepTimeMinutes: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Crispy Fried Chicken =================
        MenuItemModel(
          id: '',
          name: 'Crispy Fried Chicken Pieces',
          description: 'Secret spice coated tender bone-in chicken fried to crunchy perfection',
          price: 399,
          categoryId: categoryNameToId['crispy fried chicken'] ?? '',
          variants: friedChickenVariants,
          addons: [
            const MenuAddon(name: 'Dip Sauce', price: 70),
            const MenuAddon(name: 'Coleslaw', price: 90),
          ],
          prepTimeMinutes: 18,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Special Hot Wings =================
        MenuItemModel(
          id: '',
          name: 'Crispy Hot Wings',
          description: 'Tender chicken wings fried crispy with zesty seasoning',
          price: 299,
          categoryId: categoryNameToId['special hot wings'] ?? '',
          variants: wingsVariants,
          addons: [const MenuAddon(name: 'Extra Dip Sauce', price: 70)],
          isSpicy: true,
          prepTimeMinutes: 12,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Oven Baked Hot Wings',
          description: 'Juicy oven baked chicken wings glazed in barbecue glaze',
          price: 299,
          categoryId: categoryNameToId['special hot wings'] ?? '',
          variants: wingsVariants,
          addons: [const MenuAddon(name: 'Extra Dip Sauce', price: 70)],
          prepTimeMinutes: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Honey Mustard Hot Wings',
          description: 'Crispy wings tossed in rich honey mustard glaze',
          price: 299,
          categoryId: categoryNameToId['special hot wings'] ?? '',
          variants: wingsVariants,
          addons: [const MenuAddon(name: 'Extra Dip Sauce', price: 70)],
          prepTimeMinutes: 14,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Peri Peri Hot Wings',
          description: 'Fiery peri-peri glazed hot wings for true spice lovers',
          price: 299,
          categoryId: categoryNameToId['special hot wings'] ?? '',
          variants: wingsVariants,
          addons: [const MenuAddon(name: 'Extra Dip Sauce', price: 70)],
          isSpicy: true,
          prepTimeMinutes: 14,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Burger with Fries =================
        MenuItemModel(
          id: '',
          name: 'Zinger Burger with Fries',
          description: 'Signature crispy whole breast zinger fillet with lettuce and mayo',
          price: 349,
          categoryId: categoryNameToId['burger with fries'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 15,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Patty Burger',
          description: 'Classic chicken patty with house sauce, onions and cucumber',
          price: 249,
          categoryId: categoryNameToId['burger with fries'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 12,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Grill Burger with Fries',
          description: 'Tender chargrilled chicken breast fillet with smoky sauce',
          price: 399,
          categoryId: categoryNameToId['burger with fries'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Mighty Burger with Fries',
          description: 'Double crunchy zinger fillet stacked with double cheese',
          price: 499,
          categoryId: categoryNameToId['burger with fries'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Double Decker Burger with Fries',
          description: 'Stacked multi-layer chicken patty & zinger burger',
          price: 599,
          categoryId: categoryNameToId['burger with fries'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 18,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Wraps & Pratha Roll =================
        MenuItemModel(
          id: '',
          name: 'Crispy Wrap',
          description: 'Crunchy chicken tenders wrapped in fresh tortilla with garlic sauce',
          price: 499,
          categoryId: categoryNameToId['wraps & pratha roll'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 14,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Grill Chicken Wrap',
          description: 'Chargrilled chicken strips wrapped with fresh salad and spicy mayo',
          price: 499,
          categoryId: categoryNameToId['wraps & pratha roll'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 14,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Crispy Pratha Roll',
          description: 'Crispy chicken roll wrapped in flaky layered paratha',
          price: 349,
          categoryId: categoryNameToId['wraps & pratha roll'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 12,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Shawarma & Platter =================
        MenuItemModel(
          id: '',
          name: 'Chicken Shawarma',
          description: 'Authentic spiced chicken shawarma with pickled cucumber and tahini mayo',
          price: 249,
          categoryId: categoryNameToId['shawarma & platter'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Cheese Chicken Shawarma',
          description: 'Chicken shawarma loaded with shredded melted cheese',
          price: 299,
          categoryId: categoryNameToId['shawarma & platter'] ?? '',
          addons: burgerAddons,
          prepTimeMinutes: 12,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Platter Shawarma',
          description: 'Open shawarma platter served with pita bread, fries and house salad',
          price: 449,
          categoryId: categoryNameToId['shawarma & platter'] ?? '',
          prepTimeMinutes: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Fries =================
        MenuItemModel(
          id: '',
          name: 'French Fries',
          description: 'Golden, crispy, lightly salted potatoes',
          price: 180,
          categoryId: categoryNameToId['fries'] ?? '',
          variants: friesVariants,
          addons: [const MenuAddon(name: 'Dip Sauce', price: 70)],
          prepTimeMinutes: 10,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Masala Fries',
          description: 'Crispy fries tossed in signature chatpata Food Fight masala',
          price: 180,
          categoryId: categoryNameToId['fries'] ?? '',
          variants: friesVariants,
          addons: [const MenuAddon(name: 'Dip Sauce', price: 70)],
          prepTimeMinutes: 10,
          isSpicy: true,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Loaded Cheese Fries',
          description: 'Fries smothered in hot melted cheese and jalapenos',
          price: 299,
          categoryId: categoryNameToId['fries'] ?? '',
          variants: [
            const MenuVariant(label: 'Regular', price: 299),
            const MenuVariant(label: 'Large', price: 499),
          ],
          prepTimeMinutes: 12,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Platters =================
        MenuItemModel(
          id: '',
          name: 'Regular Platter',
          description: '2 Pcs Bihari Roll + 6 Pcs Oven Baked Wings + Regular Fries + Spicy Dip',
          price: 449,
          categoryId: categoryNameToId['platters'] ?? '',
          prepTimeMinutes: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Large Platter',
          description: '4 Pcs Bihari Roll + 12 Pcs Oven Baked Wings + Large Fries + 2 Pcs Spicy Dip',
          price: 849,
          categoryId: categoryNameToId['platters'] ?? '',
          prepTimeMinutes: 25,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Beverages =================
        MenuItemModel(
          id: '',
          name: 'Pepsi',
          description: 'Chilled refreshing soda',
          price: 90,
          categoryId: categoryNameToId['beverages'] ?? '',
          variants: drinkVariants,
          prepTimeMinutes: 2,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: '7Up',
          description: 'Crisp lemon-lime refreshment',
          price: 90,
          categoryId: categoryNameToId['beverages'] ?? '',
          variants: drinkVariants,
          prepTimeMinutes: 2,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Mountain Dew',
          description: 'Exhilarating citrus kick',
          price: 90,
          categoryId: categoryNameToId['beverages'] ?? '',
          variants: drinkVariants,
          prepTimeMinutes: 2,
          isVeg: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // ================= Deals & Combos =================
        MenuItemModel(
          id: '',
          name: 'Deal 1: Zinger Combo',
          description: '1 Zinger Burger + 1 Regular Fries + 1 Regular Drink (250ml)',
          price: 499,
          discount: 10,
          finalPrice: 449,
          categoryId: categoryNameToId['deals & combos'] ?? '',
          prepTimeMinutes: 15,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Deal 2: Pizza & Wings Combo',
          description: '1 Small Pizza + 3 Pcs Hot Wings + 1 Regular Drink (250ml)',
          price: 599,
          categoryId: categoryNameToId['deals & combos'] ?? '',
          prepTimeMinutes: 18,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuItemModel(
          id: '',
          name: 'Family Feast Mega Deal',
          description: '1 Large Pizza + 2 Zinger Burgers + 6 Pcs Hot Wings + 1.5L Drink',
          price: 2199,
          discount: 15,
          finalPrice: 1869,
          categoryId: categoryNameToId['deals & combos'] ?? '',
          prepTimeMinutes: 28,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // 3. Check existing items by name to prevent duplicating if already seeded
      final existingItemsSnapshot = await _menuCollection.get();
      final Set<String> existingNames = existingItemsSnapshot.docs
          .map((d) => ((d.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase())
          .toSet();

      for (var item in seedItems) {
        if (!existingNames.contains(item.name.toLowerCase())) {
          final docRef = _menuCollection.doc();
          final data = item.toJson();
          data['id'] = docRef.id;
          await docRef.set(data);
          itemsCreated++;
        }
      }

      AppLogger.info(
        'Menu seeded successfully: $categoriesCreated categories created, $itemsCreated items created.',
        tag: 'MenuSeedService',
      );

      return {
        'categoriesCreated': categoriesCreated,
        'itemsCreated': itemsCreated,
      };
    } catch (e) {
      AppLogger.error('Failed to seed menu: $e', tag: 'MenuSeedService');
      rethrow;
    }
  }
}
