import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<NotificationProvider>().watchNotifications(userId);
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.delivery_dining_rounded;
      case 'promo':
      case 'coupon':
        return Icons.local_fire_department_rounded;
      case 'review':
        return Icons.star_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return AppColors.success;
      case 'promo':
      case 'coupon':
        return AppColors.primary;
      case 'review':
        return AppColors.accent;
      default:
        return AppColors.primaryYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;
    final isLoading = notifProvider.isLoading;
    final userId = auth.currentUser?.id ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (notifications.isNotEmpty && notifProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: AppColors.brandMaroon),
              tooltip: 'Mark All as Read',
              onPressed: () async {
                if (userId.isNotEmpty) {
                  await notifProvider.markAllAsRead(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications marked as read')),
                    );
                  }
                }
              },
            ),
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
              color: colorScheme.surface,
              onSelected: (val) async {
                if (val == 'clear_all' && userId.isNotEmpty) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: colorScheme.surface,
                      title: Text('Clear All Notifications?', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                      content: Text('Are you sure you want to remove all notifications?',
                          style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await notifProvider.clearAll(userId);
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Clear All', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_off_outlined, size: 52, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No Notifications Yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You will receive updates here about your orders, exclusive battle discounts, and delivery alerts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final color = _getColor(n.type);
                      final icon = _getIcon(n.type);

                      return Dismissible(
                        key: Key('notif-${n.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          notifProvider.deleteNotification(n.id);
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (!n.isRead) {
                              notifProvider.markAsRead(n.id);
                            }
                            final refId = n.referenceId;
                            if (n.type == 'chat' ||
                                refId?.startsWith('chat_') == true ||
                                refId?.startsWith('order_') == true) {
                              Navigator.pushNamed(context, '/chat', arguments: refId);
                            } else if (refId != null && refId.isNotEmpty) {
                              Navigator.pushNamed(context, '/order-tracking', arguments: refId);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: !n.isRead
                                    ? AppColors.brandYellow
                                    : (isDark ? AppColors.darkBorder : AppColors.border),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: n.isRead ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.brandYellow,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.message,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: n.isRead
                                              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                                              : colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTime(n.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
