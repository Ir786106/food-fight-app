import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/logger.dart';

/// Banner & notify-me modal when customer is outside all active delivery radii.
class OutOfDeliveryAreaBanner extends StatelessWidget {
  final String? nearestBranchName;
  final double? distanceKm;
  final VoidCallback? onSwitchCity;

  const OutOfDeliveryAreaBanner({
    super.key,
    this.nearestBranchName,
    this.distanceKm,
    this.onSwitchCity,
  });

  void _showNotifyMeDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: AppColors.brandMaroon),
                SizedBox(width: 8),
                Text('Get Notified! 🥊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We are rapidly expanding! Leave your contact number and we will notify you the moment Food Fight starts delivering in your zone.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number or Email',
                    hintText: '0300 1234567',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.brandMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final val = phoneCtrl.text.trim();
                        if (val.isEmpty) return;
                        setDialogState(() => isSubmitting = true);
                        try {
                          await FirebaseFirestore.instance.collection('branch_waitlist').add({
                            'contact': val,
                            'createdAt': FieldValue.serverTimestamp(),
                            'nearestBranch': nearestBranchName ?? '',
                            'distanceKm': distanceKm ?? 0.0,
                          });
                        } catch (e) {
                          AppLogger.warn('Waitlist submission notice: $e', tag: 'Waitlist');
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you! You are on our VIP launch list! 🎉'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                child: const Text('Notify Me', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km away' : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Warm amber tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEA580C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We don\'t deliver to your area yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nearestBranchName != null
                      ? 'Nearest kitchen ($nearestBranchName) is $distanceText. You can still browse our menu.'
                      : 'You are currently outside our delivery coverage zones.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFC2410C),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showNotifyMeDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Notify Me When Available',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (onSwitchCity != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onSwitchCity,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            'Change City',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9A3412),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
