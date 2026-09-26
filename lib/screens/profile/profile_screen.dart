import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/common/network_image_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile 🥊'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Center(
              child: Column(
                children: [
                  user?.profileImage != null && user!.profileImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(44),
                          child: NetworkImageView(
                            imageUrl: user.profileImage,
                            width: 88,
                            height: 88,
                            fallbackIcon: Icons.person,
                          ),
                        )
                      : CircleAvatar(
                          radius: 44,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                          child: Text(
                            (user?.name.isNotEmpty == true)
                                ? user!.name[0].toUpperCase()
                                : 'F',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Guest Fighter',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13.5,
                    ),
                  ),
                  if (auth.isAdmin) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ADMINISTRATOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // In-app Theme Mode Selector
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_outlined, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildThemeOption(
                            context,
                            title: 'Light',
                            icon: Icons.light_mode_outlined,
                            isSelected: themeProvider.themeMode == ThemeMode.light,
                            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOption(
                            context,
                            title: 'Dark',
                            icon: Icons.dark_mode_outlined,
                            isSelected: themeProvider.themeMode == ThemeMode.dark,
                            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOption(
                            context,
                            title: 'System',
                            icon: Icons.settings_suggest_outlined,
                            isSelected: themeProvider.themeMode == ThemeMode.system,
                            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Admin Portal Shortcut for Admins
            if (auth.isAdmin)
              _ProfileTile(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Open Admin Management Portal',
                iconColor: Colors.blue.shade600,
                onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
              ),

            _ProfileTile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile & Photo',
              onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
            ),
            _ProfileTile(
              icon: Icons.receipt_long_outlined,
              label: 'Order History',
              onTap: () => Navigator.of(context).pushNamed('/order-history'),
            ),
            _ProfileTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => Navigator.of(context).pushNamed('/notifications'),
            ),
            _ProfileTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.of(context).pushNamed('/settings'),
            ),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              textColor: AppColors.error,
              iconColor: AppColors.error,
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? colorScheme.primary, size: 22),
          title: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor ?? colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
