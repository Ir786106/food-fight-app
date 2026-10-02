import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _detailsController = TextEditingController();
  String _selectedType = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;

  final Map<String, IconData> _typeIcons = {
    'Home': Icons.home_outlined,
    'Work': Icons.work_outline,
    'Other': Icons.place_outlined,
  };

  @override
  void dispose() {
    _labelController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final addressProvider = context.read<AddressProvider>();
    final userId = authProvider.currentUser?.id ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your address')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final newAddress = AddressModel(
        id: '',
        userId: userId,
        label: _labelController.text.trim(),
        details: _detailsController.text.trim(),
        iconType: _selectedType.toLowerCase(),
        isDefault: _isDefault,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await addressProvider.addAddress(newAddress);

      if (mounted) {
        setState(() => _isSaving = false);
        if (saved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully!')),
          );
          Navigator.of(context).pop(saved);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(addressProvider.errorMessage ?? 'Failed to save address'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _typeIcons.keys.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            if (_labelController.text.isEmpty ||
                                _typeIcons.containsKey(_labelController.text)) {
                              _labelController.text = type;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandYellow
                                : (isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.brandYellow : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _typeIcons[type],
                                size: 16,
                                color: isSelected ? AppColors.onYellow : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type,
                                style: TextStyle(
                                  color: isSelected ? AppColors.onYellow : colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _labelController,
                  label: 'Label',
                  hint: 'e.g. Home, Office, Gym',
                  icon: Icons.label_outline,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter a label' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _detailsController,
                  label: 'Full Address',
                  hint: 'House / Flat no., street, area, city',
                  icon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your address' : null,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Set as default address',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'Use this address automatically for future orders',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    value: _isDefault,
                    activeTrackColor: AppColors.brandYellow,
                    activeThumbColor: AppColors.onYellow,
                    inactiveTrackColor: isDark ? AppColors.darkBorder : AppColors.border,
                    inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    onChanged: (val) => setState(() => _isDefault = val),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: _isSaving ? 'Saving Address...' : 'Save Address',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
