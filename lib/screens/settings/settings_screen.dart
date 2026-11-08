import '../../providers/auth_provider.dart';
import '../../core/localization/app_language.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:geolocator/geolocator.dart';
import '../../services/fcm_service.dart';
import 'policy_screen.dart';
import 'package:food_fight/core/utils/app_snackbar.dart';
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
  bool _autoDownloadUpdates = false;
  bool _changingLanguage = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoDownloadUpdates = prefs.getBool(autoDownloadUpdatesPreference) ?? false;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailOffers = prefs.getBool('email_offers') ?? true;
      _locationAccess = prefs.getBool('location_access') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (key == 'push_notifications') await FcmService.setPushEnabled(value, user?.uid);
      if (key == 'email_offers') await FcmService.setOffersEnabled(value);
      if (key == 'location_access' && value) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw StateError('Enable location permission in your device settings.');
        }
      }
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
        .set({'preferences': {key: value}}, SetOptions(merge: true));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      await _loadPreferences();
    } catch (error) {
      if (mounted) AppSnackbar.showError(context, error.toString().replaceFirst('Bad state: ', ''));
    }
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
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);
    if (prov.hasUpdate) {
      await AppUpdateBottomSheet.show(context);
    } else {
      AppSnackbar.showSnackBar(context,
        SnackBar(content: Text(prov.errorMessage ?? 'Food Fight is up to date.')),
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
    final language = context.watch<AppLanguage?>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('Settings')),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.tr('PREFERENCES'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              context.tr('Push Notifications'),
              context.tr('Get notified about order updates'),
              _pushNotifications,
              (v) => _savePreference('push_notifications', v),
            ),
            _buildSwitchTile(
              context.tr('Email Offers'),
              context.tr('Receive deals and promotions via email'),
              _emailOffers,
              (v) => _savePreference('email_offers', v),
            ),
            if (language != null)
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.tr('Language')),
                trailing: DropdownButton<Locale>(
                  value: language.locale,
                  onChanged: _changingLanguage ? null : (locale) async {
                    if (locale == null) return;
                    setState(() => _changingLanguage = true);
                    try {
                      await language.select(locale);
                    } catch (_) {
                      if (context.mounted) {
                        AppSnackbar.showError(
                          context, context.tr('Could not save language preference.'),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _changingLanguage = false);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: AppLanguage.english, child: Text('English')),
                    DropdownMenuItem(value: AppLanguage.urdu, child: Text('اردو')),
                  ],
                ),
              ),
            _buildThemeTile(themeProvider),
            _buildSwitchTile(
              context.tr('Location Access'),
              context.tr('Allow app to access your location'),
              _locationAccess,
              (v) => _savePreference('location_access', v),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('ABOUT & UPDATES'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile('App Version', _appVersion.isNotEmpty ? _appVersion : '…'),
            if (AppUpdateProvider.supported)
              _buildSwitchTile(
                'Automatically download updates',
                'Download when Food Fight is open. Android may ask you to confirm installation.',
                _autoDownloadUpdates,
                (enabled) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(autoDownloadUpdatesPreference, enabled);
                  if (mounted) setState(() => _autoDownloadUpdates = enabled);
                },
              ),
            if (AppUpdateProvider.supported)
              _buildActionTile(
              icon: Icons.system_update_rounded,
              title: context.tr('Check for Updates'),
              subtitle: context.tr('See if a newer version is available'),
              trailing: _isCheckingUpdate
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _isCheckingUpdate ? null : _checkForUpdates,
            ),
            if (context.watch<AuthProvider?>()?.edition.allowsCustomerRegistration ?? true)
              _buildActionTile(
              icon: Icons.play_circle_outline_rounded,
              title: context.tr('Replay App Intro'),
              subtitle: context.tr('See the onboarding screens again'),
              onTap: _replayOnboarding,
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('LEGAL'),
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
      ThemeMode.light: context.tr('Light'),
      ThemeMode.dark: context.tr('Dark'),
      ThemeMode.system: context.tr('System'),
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
            context.tr('Theme'),
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
            context.tr(title),
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
              _showDocumentSheet('Terms of Service', 'termsOfService');
            } else if (title == 'Privacy Policy') {
              _showDocumentSheet('Privacy Policy', 'privacyPolicy');
            } else if (title == 'App Version') {
              AppSnackbar.showSnackBar(context,
                SnackBar(content: Text('Food Fight ${_appVersion.isNotEmpty ? "v$_appVersion" : ""} is running the latest build')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showDocumentSheet(String title, String field) {
    final localizedTitle = context.tr(title);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PolicyScreen(title: localizedTitle, field: field),
    ));
  }
}
