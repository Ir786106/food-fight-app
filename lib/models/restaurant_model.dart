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
}
