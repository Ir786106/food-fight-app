import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  NotificationItem(this.title, this.message, this.time, this.icon, this.color);
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      NotificationItem(
        'Order Delivered! 🎉',
        'Your order from Burger Brawl has been delivered. Enjoy!',
        '2 min ago',
        Icons.check_circle,
        AppColors.success,
      ),
      NotificationItem(
        'Order On The Way 🚴',
        'Your rider is heading to your location.',
        '15 min ago',
        Icons.delivery_dining,
        Colors.blue,
      ),
      NotificationItem(
        '50% Off Combo Deal 🔥',
        'Grab your favorite burger combo at half price today only.',
        '1 hr ago',
        Icons.local_fire_department,
        AppColors.primary,
      ),
      NotificationItem(
        'Welcome to Food Fight! 🥊',
        'Explore top-rated restaurants near you and start ordering.',
        'Yesterday',
        Icons.celebration,
        AppColors.accent,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final n = notifications[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: n.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(n.icon, color: n.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13.5)),
                        const SizedBox(height: 4),
                        Text(n.message,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text(n.time,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
