import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/common/responsive_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _emailReceipts = true;
  bool _smsUpdates = true;

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
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        // Trigger secure password reset or update
                        final email = context.read<AuthProvider>().currentUser?.email;
                        if (email != null && email.isNotEmpty) {
                          await context.read<AuthProvider>().sendPasswordResetEmail(email);
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password security confirmation sent to your email!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Profile 🥊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile Info',
            onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1E26), const Color(0xFF282834)]
                        : [Colors.white, const Color(0xFFF9F9FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    user?.profileImage != null && user!.profileImage!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(38),
                            child: NetworkImageView(
                              imageUrl: user.profileImage,
                              width: 76,
                              height: 76,
                              fallbackIcon: Icons.person,
                            ),
                          )
                        : CircleAvatar(
                            radius: 38,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                            child: Text(
                              (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '🥊',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Guest Fighter',
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
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: user?.isAdmin == true
                                      ? Colors.blue.shade900
                                      : (user?.isRider == true
                                          ? Colors.green.shade800
                                          : AppColors.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user?.isSuperAdmin == true
                                      ? 'SUPER ADMIN'
                                      : (user?.isAdmin == true
                                          ? 'ADMINISTRATOR'
                                          : (user?.isRider == true ? 'DELIVERY RIDER' : 'FOODIE CHAMPION')),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
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

              const SizedBox(height: 24),

              // Quick Actions Bar (Orders & Favorites)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'My Orders',
                      subtitle: 'Active & History',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      onTap: () => Navigator.of(context).pushNamed('/order-history'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Favorites',
                      subtitle: 'Saved Dishes',
                      icon: Icons.favorite_rounded,
                      color: Colors.redAccent,
                      onTap: () => Navigator.of(context).pushNamed('/favorites'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section: Addresses & Payment Methods
              _buildSectionTitle('PREFERENCES & PAYMENTS', colorScheme),
              _buildCardGroup(
                context,
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Saved Delivery Addresses',
                    subtitle: 'Manage home, office, and other locations',
                    onTap: () => Navigator.of(context).pushNamed('/addresses'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(
                    context,
                    icon: Icons.credit_card_rounded,
                    title: 'Payment Methods',
                    subtitle: 'Debit/Credit Cards, JazzCash & Easypaisa',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => Navigator.of(context).pushNamed('/payment-methods'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section: Appearance Theme
              _buildSectionTitle('APPEARANCE & THEME', colorScheme),
              _buildCardGroup(
                context,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Application Theme',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildThemeChip(
                              context,
                              title: 'Light',
                              icon: Icons.wb_sunny_outlined,
                              isSelected: themeProvider.themeMode == ThemeMode.light,
                              onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 8),
                            _buildThemeChip(
                              context,
                              title: 'Dark',
                              icon: Icons.nightlight_outlined,
                              isSelected: themeProvider.themeMode == ThemeMode.dark,
                              onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                            ),
                            const SizedBox(width: 8),
                            _buildThemeChip(
                              context,
                              title: 'System',
                              icon: Icons.auto_mode_rounded,
                              isSelected: themeProvider.themeMode == ThemeMode.system,
                              onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section: Notification Preferences
              _buildSectionTitle('NOTIFICATIONS & ALERTS', colorScheme),
              _buildCardGroup(
                context,
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Live order status alerts on device', style: TextStyle(fontSize: 12)),
                    value: _pushNotifications,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    title: const Text('Email Receipts & Offers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Get order invoices sent to your email', style: TextStyle(fontSize: 12)),
                    value: _emailReceipts,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _emailReceipts = val),
                  ),
                  const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    title: const Text('SMS Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Critical order dispatch SMS texts', style: TextStyle(fontSize: 12)),
                    value: _smsUpdates,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _smsUpdates = val),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section: Security & Account
              _buildSectionTitle('SECURITY & ACCOUNT', colorScheme),
              _buildCardGroup(
                context,
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your login credentials',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(
                    context,
                    icon: Icons.badge_outlined,
                    title: 'Edit Full Name & Phone',
                    subtitle: 'Update profile details & avatar',
                    onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                  ),
                ],
              ),

              // Portals for privileged roles
              if (auth.isAdmin || user?.isRider == true) ...[
                const SizedBox(height: 20),
                _buildSectionTitle('ROLE PORTALS', colorScheme),
                _buildCardGroup(
                  context,
                  children: [
                    if (auth.isAdmin)
                      _buildListTile(
                        context,
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Restaurant Admin Portal',
                        subtitle: 'Orders, menu, categories & branch management',
                        iconColor: Colors.blue.shade700,
                        onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                      ),
                    if (auth.isSuperAdmin) ...[
                      const Divider(height: 1, indent: 56),
                      _buildListTile(
                        context,
                        icon: Icons.shield_rounded,
                        title: 'Super Admin HQ Console',
                        subtitle: 'Platform analytics, staff accounts & audit logs',
                        iconColor: const Color(0xFFD4AF37),
                        onTap: () => Navigator.of(context).pushNamed('/super-admin/dashboard'),
                      ),
                    ],
                    if (user?.isRider == true || auth.isAdmin) ...[
                      const Divider(height: 1, indent: 56),
                      _buildListTile(
                        context,
                        icon: Icons.moped_rounded,
                        title: 'Rider Delivery Mode',
                        subtitle: 'Active deliveries, pickup & live navigation',
                        iconColor: Colors.green.shade700,
                        onTap: () => Navigator.of(context).pushNamed('/rider/dashboard'),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Sign Out CTA
              Material(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out from Food Fight?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out from Food Fight',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Food Fight v1.0.1 (Build 2) • Secure Production',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildCardGroup(BuildContext context, {required List<Widget> children}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
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
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
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
  }

  Widget _buildThemeChip(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
