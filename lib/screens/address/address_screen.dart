import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<AddressProvider>().watchAddresses(userId);
      }
    });
  }

  IconData _getIconForType(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'work':
      case 'office':
        return Icons.work_outline_rounded;
      case 'other':
      case 'place':
        return Icons.place_outlined;
      case 'home':
      default:
        return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;
    final isLoading = addressProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121217),
        elevation: 0,
        title: const Text('Delivery Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await Navigator.of(context).pushNamed('/add-address');
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: isLoading && addresses.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : addresses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_off_outlined, size: 52, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No Addresses Saved',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your home or office address for fast, 1-tap checkout.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D1D26),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: address.isDefault
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.07),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _getIconForType(address.iconType),
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        address.label,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white),
                                      ),
                                      if (address.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                                          ),
                                          child: const Text(
                                            'DEFAULT',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.details,
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (!address.isDefault && userId.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.star_outline_rounded, color: Colors.white38, size: 20),
                                tooltip: 'Set as Default',
                                onPressed: () async {
                                  await addressProvider.setDefaultAddress(userId, address.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('"${address.label}" set as default address'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              tooltip: 'Delete Address',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1D1D26),
                                    title: const Text('Delete Address?', style: TextStyle(color: Colors.white)),
                                    content: Text('Are you sure you want to remove "${address.label}"?',
                                        style: const TextStyle(color: AppColors.textSecondary)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && userId.isNotEmpty) {
                                  await addressProvider.deleteAddress(userId, address.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Address removed'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
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
