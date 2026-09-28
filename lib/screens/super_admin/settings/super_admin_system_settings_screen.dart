import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/admin/system_settings_model.dart';
import 'package:food_fight/providers/super_admin_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:food_fight/widgets/super_admin/super_admin_drawer.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/core/utils/validator_utils.dart';

class SuperAdminSystemSettingsScreen extends StatefulWidget {
  const SuperAdminSystemSettingsScreen({super.key});

  @override
  State<SuperAdminSystemSettingsScreen> createState() => _SuperAdminSystemSettingsScreenState();
}

class _SuperAdminSystemSettingsScreenState extends State<SuperAdminSystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _appNameCtrl;
  late TextEditingController _restaurantNameCtrl;
  late TextEditingController _contactEmailCtrl;
  late TextEditingController _contactPhoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _deliveryChargeCtrl;
  late TextEditingController _freeDeliveryThresholdCtrl;
  late TextEditingController _cancellationWindowCtrl;

  bool _isStoreOpen = true;
  bool _maintenanceMode = false;
  bool _allowCod = true;
  bool _allowOnlinePay = true;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = true;

  bool _initialized = false;
  bool _isSaving = false;

  void _populateForm(SystemSettingsModel settings) {
    _appNameCtrl = TextEditingController(text: settings.appName);
    _restaurantNameCtrl = TextEditingController(text: settings.restaurantName);
    _contactEmailCtrl = TextEditingController(text: settings.contactEmail);
    _contactPhoneCtrl = TextEditingController(text: settings.contactPhone);
    _whatsappCtrl = TextEditingController(text: settings.supportWhatsApp);
    _deliveryChargeCtrl = TextEditingController(text: settings.defaultDeliveryCharge.toStringAsFixed(0));
    _freeDeliveryThresholdCtrl = TextEditingController(text: settings.freeDeliveryThreshold.toStringAsFixed(0));
    _cancellationWindowCtrl = TextEditingController(text: settings.orderCancellationWindowMinutes.toString());

    _isStoreOpen = settings.isStoreOpen;
    _maintenanceMode = settings.maintenanceMode;
    _allowCod = settings.allowCashOnDelivery;
    _allowOnlinePay = settings.allowOnlinePayment;
    _pushNotifications = settings.pushNotificationsEnabled;
    _emailNotifications = settings.emailNotificationsEnabled;
    _smsNotifications = settings.smsNotificationsEnabled;
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _restaurantNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _deliveryChargeCtrl.dispose();
    _freeDeliveryThresholdCtrl.dispose();
    _cancellationWindowCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<SuperAdminProvider>();
    final currentUserName = context.read<AuthProvider>().currentUser?.name;

    final updated = provider.settings.copyWith(
      appName: _appNameCtrl.text.trim(),
      restaurantName: _restaurantNameCtrl.text.trim(),
      contactEmail: _contactEmailCtrl.text.trim(),
      contactPhone: _contactPhoneCtrl.text.trim(),
      supportWhatsApp: _whatsappCtrl.text.trim(),
      defaultDeliveryCharge: double.tryParse(_deliveryChargeCtrl.text.trim()) ?? 150.0,
      freeDeliveryThreshold: double.tryParse(_freeDeliveryThresholdCtrl.text.trim()) ?? 2500.0,
      orderCancellationWindowMinutes: int.tryParse(_cancellationWindowCtrl.text.trim()) ?? 10,
      isStoreOpen: _isStoreOpen,
      maintenanceMode: _maintenanceMode,
      allowCashOnDelivery: _allowCod,
      allowOnlinePayment: _allowOnlinePay,
      pushNotificationsEnabled: _pushNotifications,
      emailNotificationsEnabled: _emailNotifications,
      smsNotificationsEnabled: _smsNotifications,
      updatedAt: DateTime.now(),
    );

    final success = await provider.saveSettings(updated, savedBy: currentUserName);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Global system settings updated and synchronized! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update settings'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = SuperAdminTheme.getCardBg(context);
    final textDark = SuperAdminTheme.getTextDark(context);

    final provider = context.watch<SuperAdminProvider>();

    if (!_initialized) {
      _populateForm(provider.settings);
      _initialized = true;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/super-admin/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: SuperAdminTheme.getBackground(context),
        drawer: const SuperAdminDrawer(currentRoute: '/super-admin/settings'),
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Platform & System Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          backgroundColor: SuperAdminTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Save Settings',
              onPressed: _isSaving ? null : _handleSave,
            ),
          ],
        ),
        body: ResponsiveContainer.content(
          maxWidth: 900,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform Operating Status
                  Text(
                    'Operational State Master Switches',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    title: 'Restaurant Kitchen Status (Store Open)',
                    subtitle: _isStoreOpen
                        ? 'Store is OPEN: Accepting incoming customer food orders'
                        : 'Store is CLOSED: Orders paused across customer app',
                    value: _isStoreOpen,
                    activeColor: AppColors.success,
                    cardBg: cardBg,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _isStoreOpen = val),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchCard(
                    title: 'Platform Maintenance Mode',
                    subtitle: _maintenanceMode
                        ? 'MAINTENANCE ACTIVE: Only Super Admins can access services'
                        : 'NORMAL MODE: All users and customers have standard access',
                    value: _maintenanceMode,
                    activeColor: AppColors.warning,
                    cardBg: cardBg,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _maintenanceMode = val),
                  ),

                  const SizedBox(height: 24),

                  // General Branding & App Info
                  Text(
                    'Brand & Contact Details',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _appNameCtrl,
                          validator: (v) => ValidatorUtils.validateRequired(v, fieldName: 'App Name'),
                          decoration: const InputDecoration(
                            labelText: 'Application Name *',
                            prefixIcon: Icon(Icons.app_registration_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _restaurantNameCtrl,
                          validator: (v) => ValidatorUtils.validateRequired(v, fieldName: 'Restaurant Brand'),
                          decoration: const InputDecoration(
                            labelText: 'Restaurant Brand *',
                            prefixIcon: Icon(Icons.storefront_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _contactEmailCtrl,
                          validator: ValidatorUtils.validateEmail,
                          decoration: const InputDecoration(
                            labelText: 'Support Email Address *',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _contactPhoneCtrl,
                          validator: (v) => ValidatorUtils.validateRequired(v, fieldName: 'Contact Phone'),
                          decoration: const InputDecoration(
                            labelText: 'Support Hotline Phone *',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _whatsappCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Customer Support WhatsApp Number',
                            prefixIcon: Icon(Icons.chat_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery Fee Rules & Order Policies
                  Text(
                    'Delivery & Order Cancellation Policies',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _deliveryChargeCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => ValidatorUtils.validateRequired(v, fieldName: 'Default delivery charge'),
                          decoration: const InputDecoration(
                            labelText: 'Default Delivery Fee (Rs.) *',
                            prefixIcon: Icon(Icons.delivery_dining_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _freeDeliveryThresholdCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => ValidatorUtils.validateRequired(v, fieldName: 'Free delivery threshold'),
                          decoration: const InputDecoration(
                            labelText: 'Free Delivery Order Threshold (Rs.) *',
                            helperText: 'Orders above this amount automatically receive free delivery',
                            prefixIcon: Icon(Icons.local_shipping_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cancellationWindowCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Cancellation window is required';
                            final val = int.tryParse(v);
                            if (val == null || val < 1 || val > 60) {
                              return 'Please enter a valid window between 1 and 60 minutes';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Order Cancellation Window (minutes) *',
                            helperText: 'Window within which customers are permitted to self-cancel an order (1–60 min)',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Gateways & Notification Rules
                  Text(
                    'Payment & Notification Rules',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    title: 'Cash on Delivery (COD)',
                    subtitle: 'Enable customers to pay in cash upon meal arrival',
                    value: _allowCod,
                    activeColor: SuperAdminTheme.primary,
                    cardBg: cardBg,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _allowCod = val),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchCard(
                    title: 'Online Card / Mobile Payments',
                    subtitle: 'Enable credit cards and digital wallets checkout',
                    value: _allowOnlinePay,
                    activeColor: SuperAdminTheme.primary,
                    cardBg: cardBg,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _allowOnlinePay = val),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchCard(
                    title: 'Push Notifications System',
                    subtitle: 'Send real-time order status notifications to users',
                    value: _pushNotifications,
                    activeColor: AppColors.primaryYellow,
                    cardBg: cardBg,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchCard(
                    title: 'Automated Email Receipts & Alerts',
                    subtitle: 'Dispatch email order confirmations and admin alerts',
                    value: _emailNotifications,
                    activeColor: AppColors.primaryYellow,
                    cardBg: cardBg,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _emailNotifications = val),
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchCard(
                    title: 'SMS Alerts & Order Updates',
                    subtitle: 'Send automated SMS notifications to customers on order progress',
                    value: _smsNotifications,
                    activeColor: AppColors.primaryYellow,
                    cardBg: cardBg,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _smsNotifications = val),
                  ),

                  const SizedBox(height: 32),

                  // Save Changes CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SuperAdminTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSaving ? 'Synchronizing System Configuration...' : 'Save Global Settings',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required Color cardBg,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: SuperAdminTheme.getTextMuted(context))),
        value: value,
        activeThumbColor: activeColor,
        activeTrackColor: activeColor.withValues(alpha: 0.3),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}
