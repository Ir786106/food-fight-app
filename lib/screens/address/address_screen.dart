import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SimpleAddress {
  final String label;
  final String details;
  final IconData icon;
  SimpleAddress(this.label, this.details, this.icon);
}

/// In-memory list shared for the session (offline demo).
class AddressStore {
  static final List<SimpleAddress> addresses = [
    SimpleAddress('Home', 'House 12, Model Town, DG Khan', Icons.home_outlined),
    SimpleAddress('Work', 'Office 4B, Circular Road, DG Khan', Icons.work_outline),
  ];
}

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/add-address');
          if (result != null && result is SimpleAddress) {
            setState(() => AddressStore.addresses.add(result));
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: AddressStore.addresses.length,
          itemBuilder: (context, index) {
            final address = AddressStore.addresses[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(address.icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(address.details,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: () {
                      setState(() => AddressStore.addresses.removeAt(index));
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
