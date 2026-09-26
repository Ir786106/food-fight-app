import '../models/restaurant_model.dart';
import '../models/food_model.dart';
import 'menu_data.dart';

class DummyData {
  static List<RestaurantModel> restaurants = [MenuData.foodFightRestaurant];
  static List<FoodModel> foods = MenuData.foods;
  static List<String> categories = ['All', ...MenuData.categories];

  static List<FoodModel> foodsByRestaurant(String restaurantId) {
    return foods.where((f) => f.restaurantId == restaurantId).toList();
  }
}
