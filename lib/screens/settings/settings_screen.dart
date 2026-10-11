import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_update_provider.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/app_update_bottom_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailOffers = true;
  bool _locationAccess = true;
  String _appVersion = '';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {}
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    final prov = context.read<AppUpdateProvider>();
    await prov.checkForUpdateNow();
    setState(() => _isCheckingUpdate = false);
    if (!mounted) return;
    if (prov.hasUpdate) {
      await AppUpdateBottomSheet.show(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food Fight is up to date.')),
      );
    }
  }

  Future<void> _replayOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.storageOnboardingCompleted, false);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          value: value,
          activeTrackColor: AppColors.brandYellow,
          activeThumbColor: AppColors.onYellow,
          inactiveTrackColor: isDark ? AppColors.darkBorder : AppColors.border,
          inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'PREFERENCES',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              'Push Notifications',
              'Get notified about order updates',
              _pushNotifications,
              (v) => setState(() => _pushNotifications = v),
            ),
            _buildSwitchTile(
              'Email Offers',
              'Receive deals and promotions via email',
              _emailOffers,
              (v) => setState(() => _emailOffers = v),
            ),
            _buildThemeTile(themeProvider),
            _buildSwitchTile(
              'Location Access',
              'Allow app to access your location',
              _locationAccess,
              (v) => setState(() => _locationAccess = v),
            ),
            const SizedBox(height: 20),
            Text(
              'ABOUT & UPDATES',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile('App Version', _appVersion.isNotEmpty ? _appVersion : '…'),
            _buildActionTile(
              icon: Icons.system_update_rounded,
              title: 'Check for Updates',
              subtitle: 'See if a newer version is available',
              trailing: _isCheckingUpdate
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _isCheckingUpdate ? null : _checkForUpdates,
            ),
            _buildActionTile(
              icon: Icons.play_circle_outline_rounded,
              title: 'Replay App Intro',
              subtitle: 'See the onboarding screens again',
              onTap: _replayOnboarding,
            ),
            const SizedBox(height: 20),
            Text(
              'LEGAL',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile('Terms of Service', ''),
            _buildInfoTile('Privacy Policy', ''),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final modes = <ThemeMode, String>{
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
      ThemeMode.system: 'System',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modes.entries.map((entry) {
              final mode = entry.key;
              final isSelected = themeProvider.themeMode == mode;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                avatar: Icon(
                  _themeIconFor(mode),
                  size: 18,
                  color: isSelected ? AppColors.onYellow : colorScheme.onSurfaceVariant,
                ),
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.yellowPressed
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
                selectedColor: AppColors.brandYellow,
                backgroundColor: colorScheme.surface,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.onYellow : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
                onSelected: (_) => themeProvider.setThemeMode(mode),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _themeIconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_suggest;
    }
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: AppColors.brandMaroon, size: 22),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)) : null,
          trailing: trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String trailingText, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailingText.isNotEmpty
              ? Text(
                  trailingText,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Icon(Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant, size: 20),
          onTap: onTap ?? () {
            if (title == 'Terms of Service') {
              _showDocumentSheet('Terms of Service', _termsOfServiceContent);
            } else if (title == 'Privacy Policy') {
              _showDocumentSheet('Privacy Policy', _privacyPolicyContent);
            } else if (title == 'App Version') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Food Fight v1.2.0 is running the latest build')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showDocumentSheet(String title, String content) {
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
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    content,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13.5, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _termsOfServiceContent = '''
Welcome to Food Fight! By using our platform and ordering delicious meals, you agree to our Terms of Service.

1. Ordering & Fulfillment
All orders placed via Food Fight are dispatched from our verified local partner kitchens. Estimated delivery times are approximations influenced by real-time traffic and kitchen volume.

2. Pricing & Payments
Prices listed reflect current kitchen menu rates. Payment may be executed via Cash on Delivery or approved card/e-wallet methods.

3. Cancellations & Refunds
Cancellations are accepted within 10 minutes of order placement prior to kitchen preparation commencement.

4. Account Security
You are responsible for maintaining the confidentiality of your credentials and linked communication channels.
''';

  static const String _privacyPolicyContent = '''
At Food Fight, your privacy and data security are paramount.

1. Data Collection
We collect account information (name, contact number, delivery address) necessary to fulfill your orders safely.

2. Location Data
Location access is utilized exclusively while using the app to identify nearby partner kitchens and estimate precise arrival times. You may manage location permissions via your device settings at any time.

3. Security
All transactions and communication channels are encrypted with industry-standard protocols.
''';
}
