import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailOffers = true;
  bool _locationAccess = true;

  Widget _buildSwitchTile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: SwitchListTile(
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface)),
          subtitle: Text(subtitle,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          value: value,
          activeThumbColor: colorScheme.primary,
          activeTrackColor: colorScheme.primary.withValues(alpha: 0.34),
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Preferences',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 14),
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
            const Text('About',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 14),
            _buildInfoTile('App Version', '1.0.0'),
            _buildInfoTile('Terms of Service', ''),
            _buildInfoTile('Privacy Policy', ''),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(ThemeProvider themeProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final modes = <ThemeMode, String>{
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
      ThemeMode.system: 'System',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: colorScheme.onSurface),
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
                avatar: Icon(_themeIconFor(mode), size: 18),
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
                selectedColor: colorScheme.primaryContainer,
                backgroundColor: colorScheme.surface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildInfoTile(String title, String trailingText) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
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
              ? Text(trailingText,
                  style: TextStyle(color: colorScheme.onSurfaceVariant))
              : Icon(Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant, size: 20),
          onTap: () {},
        ),
      ),
    );
  }
}
