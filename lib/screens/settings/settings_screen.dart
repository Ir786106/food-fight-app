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
            _buildInfoTile('App Version', '1.2.0'),
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

  Widget _buildInfoTile(String title, String trailingText, {VoidCallback? onTap}) {
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
1. Acceptance of Terms
By downloading, accessing, or using Food Fight, you agree to comply with and be bound by these Terms of Service. If you do not agree, please refrain from using our application.

2. Ordering & Payment
- All orders placed via Food Fight are subject to kitchen acceptance and stock availability.
- Prices displayed include applicable taxes. Delivery fees may vary depending on destination zone and surge conditions.
- We support Cash on Delivery (COD) and tokenized online payment methods. Payment details are encrypted and never stored in plain text.

3. Delivery & Fulfillment
- Estimated delivery times are provided as approximations and may fluctuate due to traffic, adverse weather, or peak order volumes.
- Customers must provide an accurate delivery address and active phone number for the delivery rider.

4. Cancellation & Refund Policy
- Orders may be cancelled within the initial preparation grace window.
- Once food preparation has begun, cancellations may be restricted or subject to a partial fee.
- Refunds for cancelled prepaid orders are processed back to the original funding source within 3–5 business days.

5. Code of Conduct
Users agree not to misuse promotional codes, harass delivery personnel or restaurant staff, or attempt unauthorized platform access. Food Fight reserves the right to suspend accounts violating these standards.
''';

  static const String _privacyPolicyContent = '''
1. Information We Collect
We collect personal information necessary to fulfill your food delivery orders:
- Account Information: Name, email address, phone number.
- Location Data: Delivery address and geographic coordinates to route delivery riders.
- Order History: Items purchased, coupon applications, and kitchen ratings.

2. How We Use Information
Your data is strictly utilized to:
- Process, dispatch, and track your food deliveries.
- Provide order status alerts and system notifications.
- Optimize kitchen recommendations and prevent fraudulent transactions.

3. Payment Data Security
Credit card and mobile wallet transactions are processed via secure, PCI-DSS compliant payment gateways. Food Fight never retains sensitive card verification numbers (CVV) on our servers.

4. Location Permissions
Location access is utilized exclusively while using the app to identify nearby partner kitchens and estimate precise arrival times. You may manage location permissions via your device settings at any time.

5. Data Retention & Deletion
You retain the right to request deletion of your account and associated personal information by contacting support@foodfight.pk or through the in-app Help Center.
''';
}
