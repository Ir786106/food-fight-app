import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';
import '../core/utils/logger.dart';

class RestaurantService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'restaurants';

  static CollectionReference _col() => _firestore.collection(_collectionName);

  static final List<RestaurantModel> _defaultPartners = [
    RestaurantModel(
      id: 'food_fight_hq',
      name: 'Food Fight Kitchen',
      imageEmoji: '🥊',
      cuisine: 'Fast Food • Burgers • Pizza • Wings',
      rating: 4.9,
      deliveryTimeMinutes: 20,
      deliveryFee: 0,
      address: 'Main Boulevard, Model Town',
      isFeatured: true,
      isOpen: true,
    ),
    RestaurantModel(
      id: 'fight_burger_joint',
      name: 'Fight Burger Joint',
      imageEmoji: '🍔',
      cuisine: 'Gourmet Smash Burgers • Fries',
      rating: 4.8,
      deliveryTimeMinutes: 25,
      deliveryFee: 120,
      address: 'Food Fight Boulevard, Block 4',
      isFeatured: true,
      isOpen: true,
    ),
    RestaurantModel(
      id: 'fire_crust_pizza',
      name: 'Fire & Crust Pizza Bar',
      imageEmoji: '🍕',
      cuisine: 'Stuffed Crust • Artisan Pizza',
      rating: 4.9,
      deliveryTimeMinutes: 35,
      deliveryFee: 0,
      address: 'Food Street, Sector B',
      isFeatured: true,
      isOpen: true,
    ),
    RestaurantModel(
      id: 'shawarma_battle_club',
      name: 'Shawarma Battle Club',
      imageEmoji: '🥙',
      cuisine: 'Arabic Shawarma • Platters',
      rating: 4.7,
      deliveryTimeMinutes: 20,
      deliveryFee: 80,
      address: 'Central Market, Shop 14',
      isFeatured: false,
      isOpen: true,
    ),
  ];

  /// Ensure initial restaurants exist in Firestore collection
  static Future<void> ensureSeeded() async {
    try {
      final snap = await _col().limit(1).get();
      if (snap.docs.isEmpty) {
        AppLogger.info('Seeding initial restaurants to Firestore...', tag: 'RestaurantService');
        final batch = _firestore.batch();
        for (var r in _defaultPartners) {
          batch.set(_col().doc(r.id), r.toJson());
        }
        await batch.commit();
        AppLogger.info('Restaurants seeded successfully!', tag: 'RestaurantService');
      }
    } catch (e) {
      AppLogger.warn('Could not check/seed restaurants: $e', tag: 'RestaurantService');
    }
  }

  /// Watch live restaurants from Firestore
  static Stream<List<RestaurantModel>> watchRestaurants() {
    return _col().snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Return default fallback if Firestore is still propagating
        return _defaultPartners;
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RestaurantModel.fromJson(data);
      }).toList();
    });
  }

  /// Get restaurant by ID
  static Future<RestaurantModel?> getRestaurantById(String id) async {
    try {
      final doc = await _col().doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RestaurantModel.fromJson(data);
      }
      final fallback = _defaultPartners.where((r) => r.id == id);
      return fallback.isNotEmpty ? fallback.first : null;
    } catch (e) {
      AppLogger.error('Failed to get restaurant by id: $e', tag: 'RestaurantService');
      final fallback = _defaultPartners.where((r) => r.id == id);
      return fallback.isNotEmpty ? fallback.first : null;
    }
  }
}
