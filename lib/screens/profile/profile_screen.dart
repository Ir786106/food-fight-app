import '../../core/localization/app_language.dart';
import '../../widgets/common/account_dialogs.dart';
import 'package:food_fight/core/utils/app_insets.dart';
import 'package:food_fight/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../providers/address_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/branch_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _watchedUserId;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
      }
    } catch (_) {}
  }

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

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final changed = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
    if (context.mounted && changed == true) AppSnackbar.showSuccess(context, 'Password updated.');
  }

  void _showHelpCenterDialog(BuildContext context) {
    final phone = context.read<BranchProvider>().selectedBranch?.phone;
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (_) => HelpCenterSheet(branchPhone: phone));
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
        title: Text(context.tr('Profile'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
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
                  subtitle: 'JazzCash & Easypaisa wallet references',
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
                  title: context.tr('Settings'),
                  subtitle: 'App preferences, theme & about',
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
              ]),

              // Privileged Portals (if Admin, Super Admin, or Rider)
              if (auth.isAdmin || auth.isSuperAdmin || user?.isRider == true) ...[
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
                  if (user?.isRider == true || auth.isAdmin || auth.isSuperAdmin) ...[
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
                        title: Text(context.tr('Sign Out'), style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        content: Text(
                          'Are you sure you want to sign out from Food Fight?',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(context.tr('Cancel'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(context.tr('Sign Out')),
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
                  'Food Fight ${_appVersion.isNotEmpty ? _appVersion : "v1.7.3+11"} • Premium Fast-Food Experience',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              SizedBox(height: AppInsets.bottomBarClearance(context)),
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
