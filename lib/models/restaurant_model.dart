import '../core/utils/safe_convert.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String imageEmoji;
  final String cuisine;
  final double rating;
  final int deliveryTimeMinutes;
  final double deliveryFee;
  final String address;
  final bool isFeatured;
  final bool isOpen;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.imageEmoji,
    required this.cuisine,
    required this.rating,
    required this.deliveryTimeMinutes,
    required this.deliveryFee,
    required this.address,
    this.isFeatured = false,
    this.isOpen = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageEmoji': imageEmoji,
      'cuisine': cuisine,
      'rating': rating,
      'deliveryTimeMinutes': deliveryTimeMinutes,
      'deliveryFee': deliveryFee,
      'address': address,
      'isFeatured': isFeatured ? 1 : 0,
      'isOpen': isOpen ? 1 : 0,
    };
  }

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Partner Kitchen',
      imageEmoji: json['imageEmoji']?.toString() ?? '🍽️',
      cuisine: json['cuisine']?.toString() ?? 'Multi-Cuisine & Fast Food',
      rating: SafeConvert.toDouble(json['rating'], 4.8),
      deliveryTimeMinutes: SafeConvert.toInt(json['deliveryTimeMinutes'], 25),
      deliveryFee: SafeConvert.toDouble(json['deliveryFee'], 0.0),
      address: json['address']?.toString() ?? 'Central Market, Sector B',
      isFeatured: json['isFeatured'] == 1 || json['isFeatured'] == true,
      isOpen: json['isOpen'] == 1 || json['isOpen'] == true || json['isOpen'] == null,
    );
  }

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? imageEmoji,
    String? cuisine,
    double? rating,
    int? deliveryTimeMinutes,
    double? deliveryFee,
    String? address,
    bool? isFeatured,
    bool? isOpen,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      cuisine: cuisine ?? this.cuisine,
      rating: rating ?? this.rating,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      address: address ?? this.address,
      isFeatured: isFeatured ?? this.isFeatured,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

