import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../core/constants/app_dimens.dart';
import '../../providers/address_provider.dart';
import '../../providers/loyalty_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _watchedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.id != _watchedUserId) {
      _watchedUserId = user.id;
      final userId = user.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AddressProvider>().watchAddresses(userId);
        context.read<OrderProvider>().watchCustomerOrders(userId);
        context.read<LoyaltyProvider>().watchAccount(userId);
      });
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final colorScheme = Theme.of(dialogCtx).colorScheme;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: colorScheme.surface,
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: AppColors.brandMaroon),
                const SizedBox(width: 8),
                Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: colorScheme.onSurface)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPassCtrl,
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                    decoration: const InputDecoration(labelText: 'Current Password *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
                    decoration: const InputDecoration(labelText: 'New Password *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    validator: (v) {
                      if (v != newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                    decoration: const InputDecoration(labelText: 'Confirm New Password *'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.brandMaroon,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        final email = context.read<AuthProvider>().currentUser?.email;
                        if (email != null && email.isNotEmpty) {
                          await context.read<AuthProvider>().sendPasswordResetEmail(email);
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password security confirmation sent to your email!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.brandMaroon, strokeWidth: 2))
                    : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.headset_mic_outlined, color: AppColors.brandMaroon, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Food Fight Help Center',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call_outlined, color: AppColors.success, size: 20),
              ),
              title: Text('24/7 Support Hotline', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              subtitle: Text('0800-FOODFIGHT (Toll-Free)', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri(scheme: 'tel', path: '08003663344');
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    await Clipboard.setData(const ClipboardData(text: '08003663344'));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hotline phone copied to clipboard!')),
                      );
                    }
                  }
                } catch (_) {
                  await Clipboard.setData(const ClipboardData(text: '08003663344'));
                }
              },
            ),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandMaroon, size: 20),
              ),
              title: Text('Live Support Chat', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              subtitle: Text('Real-time chat with restaurant support', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/chat');
              },
            ),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mail_outline_rounded, color: AppColors.info, size: 20),
              ),
              title: Text('Email Support', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              subtitle: Text('support@foodfight.pk', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@foodfight.pk',
                  queryParameters: {'subject': 'Food Fight Customer Support Inquiry'},
                );
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    await Clipboard.setData(const ClipboardData(text: 'support@foodfight.pk'));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support email copied to clipboard!')),
                      );
                    }
                  }
                } catch (_) {
                  await Clipboard.setData(const ClipboardData(text: 'support@foodfight.pk'));
                }
              },
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final cartProvider = context.watch<CartProvider>();
    final user = auth.currentUser;

    final ordersCount = orderProvider.customerOrders.length;
    final favoritesCount = cartProvider.favorites.length;
    final addressProv = context.watch<AddressProvider>();
    final addressesCount = addressProv.addresses.length;
    final loyalty = context.watch<LoyaltyProvider>();
    final totalEarned = loyalty.account?.totalEarned ?? loyalty.balance;

    String customerTierBadge = 'BRONZE BITE';
    if (totalEarned >= 2000) {
      customerTierBadge = 'FOODIE CHAMPION';
    } else if (totalEarned >= 1000) {
      customerTierBadge = 'GOLD GOURMET';
    } else if (totalEarned >= 400) {
      customerTierBadge = 'SILVER SNACKER';
    }

    final addressLabels = addressProv.addresses.map((a) => a.label).where((l) => l.isNotEmpty).take(3).join(', ');
    final addressSubtitle = addressesCount == 0
        ? 'No saved addresses yet'
        : '$addressesCount ${addressesCount == 1 ? "saved address" : "saved addresses"}${addressLabels.isNotEmpty ? " ($addressLabels)" : ""}';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.brandMaroon),
            tooltip: 'Edit Profile Info',
            onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // User Header Card with Avatar & Edit affordance
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with Camera Edit Affordance
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.brandYellow, width: 2),
                          ),
                          child: ClipOval(
                            child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                                ? NetworkImageView(
                                    imageUrl: user.profileImage,
                                    width: 72,
                                    height: 72,
                                    fallbackIcon: Icons.person,
                                  )
                                : Container(
                                    color: AppColors.yellowSoft,
                                    alignment: Alignment.center,
                                    child: Text(
                                      (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'F',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.brandYellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: AppColors.onYellow, size: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name.isNotEmpty == true ? user!.name : 'Foodie Fighter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No email linked',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          if (user?.phone.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.phone,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.yellowSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user?.isSuperAdmin == true
                                      ? 'SUPER ADMIN'
                                      : (user?.isAdmin == true
                                          ? 'RESTAURANT ADMIN'
                                          : (user?.isRider == true ? 'RIDER' : customerTierBadge)),
                                  style: const TextStyle(
                                    color: AppColors.maroonDeep,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Small Stats Row (Orders / Favorites / Addresses counts)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      count: ordersCount.toString(),
                      label: 'Orders',
                      icon: Icons.receipt_long_outlined,
                      accentColor: AppColors.brandMaroon,
                      onTap: () => Navigator.of(context).pushNamed('/order-history'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      count: favoritesCount.toString(),
                      label: 'Favorites',
                      icon: Icons.favorite_outline_rounded,
                      accentColor: AppColors.tomato,
                      onTap: () => Navigator.of(context).pushNamed('/favorites'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      count: addressesCount.toString(),
                      label: 'Addresses',
                      icon: Icons.location_on_outlined,
                      accentColor: AppColors.warning,
                      onTap: () => Navigator.of(context).pushNamed('/addresses'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Group 1: Account & Delivery Preferences
              _buildSectionHeader('ACCOUNT & ADDRESSES'),
              _buildCardGroup([
                _buildMenuItem(
                  icon: Icons.badge_outlined,
                  title: 'Edit Profile Information',
                  subtitle: 'Change name, phone and profile photo',
                  onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Delivery Addresses',
                  subtitle: addressSubtitle,
                  onTap: () => Navigator.of(context).pushNamed('/addresses'),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                _buildMenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  subtitle: 'Saved debit cards, JazzCash & Easypaisa',
                  onTap: () => Navigator.of(context).pushNamed('/payment-methods'),
                ),
              ]),

              const SizedBox(height: 18),

              // Group 2: Loyalty Rewards
              _buildSectionHeader('LOYALTY & REWARDS'),
              _buildCardGroup([
                _buildMenuItem(
                  icon: Icons.stars_rounded,
                  title: 'Food Fight Loyalty Tokens',
                  subtitle: '${loyalty.balance} Tokens (Rs. ${(loyalty.balance * loyalty.tokenValueInCurrency).toStringAsFixed(0)} value • $customerTierBadge)',
                  trailingBadge: '${loyalty.balance} PTS',
                  iconColor: AppColors.brandMaroon,
                  onTap: () => Navigator.of(context).pushNamed('/loyalty'),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                _buildMenuItem(
                  icon: Icons.history_rounded,
                  title: 'Token Activity History',
                  subtitle: 'Earned and redeemed token statements',
                  trailingBadge: 'HISTORY',
                  onTap: () => Navigator.of(context).pushNamed('/loyalty'),
                ),
              ]),

              const SizedBox(height: 18),

              // Group 3: App Settings & Help
              _buildSectionHeader('PREFERENCES & SUPPORT'),
              _buildCardGroup([
                _buildMenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Push notifications & order alerts',
                  onTap: () => Navigator.of(context).pushNamed('/notifications'),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Help Center',
                  subtitle: 'Real-time chat, FAQs & helpline',
                  onTap: () => _showHelpCenterDialog(context),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                _buildMenuItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Send password security update link',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App preferences, theme & about',
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
              ]),

              // Privileged Portals (if Admin or Rider)
              if (auth.isAdmin || user?.isRider == true) ...[
                const SizedBox(height: 18),
                _buildSectionHeader('ROLE PORTALS'),
                _buildCardGroup([
                  if (auth.isAdmin)
                    _buildMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Restaurant Admin Portal',
                      subtitle: 'Orders, menu, categories & kitchen console',
                      iconColor: AppColors.brandMaroon,
                      onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                    ),
                  if (auth.isSuperAdmin) ...[
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                    _buildMenuItem(
                      icon: Icons.shield_rounded,
                      title: 'Super Admin HQ Console',
                      subtitle: 'Platform analytics, staff & system audit logs',
                      iconColor: AppColors.brandMaroon,
                      onTap: () => Navigator.of(context).pushNamed('/super-admin/dashboard'),
                    ),
                  ],
                  if (user?.isRider == true || auth.isAdmin) ...[
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider, indent: 56),
                    _buildMenuItem(
                      icon: Icons.moped_rounded,
                      title: 'Rider Delivery Mode',
                      subtitle: 'Active deliveries, pickup & dispatch map',
                      iconColor: AppColors.brandMaroon,
                      onTap: () => Navigator.of(context).pushNamed('/rider/dashboard'),
                    ),
                  ],
                ]),
              ],

              const SizedBox(height: 24),

              // Log Out CTA Button
              Material(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Sign Out', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        content: Text(
                          'Are you sure you want to sign out from Food Fight?',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      context.read<CartProvider>().clearCart();
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (r) => false);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Food Fight v1.2.0 • Premium Fast-Food Experience',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.navBarScrollPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String count,
    required String label,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(height: 6),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    String? trailingBadge,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.brandMaroon).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.brandMaroon, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5)),
              ),
              child: Text(
                trailingBadge,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.brandYellow : AppColors.onYellow,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
