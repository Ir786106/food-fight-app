import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Quick navigation modal bottom sheet for the customer storefront
class HomeNavigationSheet extends StatelessWidget {
  const HomeNavigationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const HomeNavigationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Navigation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.restaurant_menu_rounded, color: AppColors.brandYellow),
                title: const Text('Full Menu'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/menu');
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_offer_rounded, color: AppColors.brandYellow),
                title: const Text('Exclusive Deals & Combos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/deals');
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rounded, color: AppColors.brandYellow),
                title: const Text('Food Fight Loyalty Rewards'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/loyalty');
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: AppColors.brandYellow),
                title: const Text('Order History & Receipts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/orders');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
