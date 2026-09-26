import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import 'address_screen.dart';

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

  final Map<String, IconData> _typeIcons = {
    'Home': Icons.home_outlined,
    'Work': Icons.work_outline,
    'Other': Icons.place_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Address')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Address Type',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: _typeIcons.keys.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(_typeIcons[type],
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary),
                              const SizedBox(width: 6),
                              Text(type,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _labelController,
                  label: 'Label',
                  hint: 'e.g. Home, Office',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter a label' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _detailsController,
                  label: 'Full Address',
                  hint: 'House no, street, area, city',
                  icon: Icons.location_on_outlined,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your address' : null,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Save Address',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop(
                        SimpleAddress(
                          _labelController.text.trim(),
                          _detailsController.text.trim(),
                          _typeIcons[_selectedType]!,
                        ),
                      );
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
}
