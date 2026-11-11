const fs=require('node:fs');
function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
edit('lib/screens/food/food_detail_screen.dart',s=>{
  s="import '../../widgets/menu/report_dish_dialog.dart';\n"+s;
  const a=s.indexOf('  void _reportDish('), b=s.indexOf('  void _handleAddToCart(',a);
  s=s.slice(0,a)+`  Future<void> _reportDish(FoodModel food) async {
    final sent = await showDialog<bool>(context: context,
      builder: (_) => ReportDishDialog(food: food));
    if (mounted && sent == true) AppSnackbar.showSuccess(context, 'Report sent to the restaurant.');
  }

`+s.slice(b);
  const n=s.indexOf('                    // Nutritional Highlights');
  const end=s.indexOf('                  ] else if (_tabController.index == 1)',n);
  s=s.slice(0,n)+s.slice(end);
  const chip=s.indexOf('  Widget _buildNutritionChip('), reviews=s.indexOf('  Widget _buildDishReviews(',chip);
  s=s.slice(0,chip)+s.slice(reviews);
  s=s.replace('    HapticFeedback.lightImpact();\n\n    final spiceStr',`    if (!food.isAvailable) {
      AppSnackbar.showError(context, 'This dish is currently unavailable.');
      return;
    }
    if (food.hasVariants && _selectedVariant == null) {
      AppSnackbar.showError(context, 'Choose a size before adding this dish.');
      return;
    }
    HapticFeedback.lightImpact();

    final spiceStr`);
  s=s.replace('onTap: () => _handleAddToCart(foodItem, cart, totalPrice),','onTap: foodItem.isAvailable ? () => _handleAddToCart(foodItem, cart, totalPrice) : null,');
  s=s.replace("'Live price'", "'Price'");
  return s;
});
edit('lib/screens/orders/order_history_screen.dart',s=>s.replace("import '../../widgets/orders/order_speed_dial_fab.dart';\n",'').replace('      floatingActionButton: const OrderSpeedDialFab(),\n',''));
edit('lib/screens/orders/order_tracking_screen.dart',s=>{
  s=s.replace('final stepTime = baseTime.add(Duration(minutes: stepIndex * 6));','final stepTime = baseTime;');
  s=s.replace("      case OrderStatus.assigned:\n      case OrderStatus.pickedUp:\n      case OrderStatus.outForDelivery:\n        return 'Your order is on the way!';", "      case OrderStatus.assigned:\n        return 'Rider assigned';\n      case OrderStatus.pickedUp:\n        return 'Order picked up';\n      case OrderStatus.outForDelivery:\n        return 'Your order is on the way!';");
  s=s.replace("      case OrderStatus.assigned:\n      case OrderStatus.pickedUp:\n      case OrderStatus.outForDelivery:\n        return 'Our express rider is en route to you';", "      case OrderStatus.assigned:\n        return 'Your rider is preparing to collect the order';\n      case OrderStatus.pickedUp:\n        return 'Your rider has collected your meal';\n      case OrderStatus.outForDelivery:\n        return 'Your rider is on the way to your address';");
  s=s.replace('if (hasRider)\n                      Stack(', 'if (hasRider && order.status.isBroadcasting)\n                      Stack(');
  s=s.replace(/isDelivered \? 'Delivered' : 'ETA:[^']*'/g, "order.status.displayName");
  return s;
});
