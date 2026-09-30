import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Delivery Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandYellow,
        foregroundColor: AppColors.brandMaroon,
        onPressed: () async {
          await Navigator.of(context).pushNamed('/add-address');
        },
        icon: const Icon(Icons.add_rounded, color: AppColors.brandMaroon),
        label: const Text('Add New', style: TextStyle(color: AppColors.brandMaroon, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: isLoading && addresses.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.brandMaroon))
            : addresses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: const BoxDecoration(
                              color: AppColors.yellowSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_off_outlined, size: 52, color: AppColors.brandMaroon),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No Addresses Saved',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your home or office address for fast, 1-tap checkout.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
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
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: address.isDefault
                                ? AppColors.brandYellow
                                : (isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
                                color: AppColors.yellowSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _getIconForType(address.iconType),
                                color: AppColors.brandMaroon,
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
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: colorScheme.onSurface),
                                      ),
                                      if (address.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.yellowSoft,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.brandYellow),
                                          ),
                                          child: const Text(
                                            'DEFAULT',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.brandMaroon,
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
                                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            if (!address.isDefault && userId.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.star_outline_rounded, color: colorScheme.onSurfaceVariant, size: 20),
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
                                    backgroundColor: colorScheme.surface,
                                    title: Text('Delete Address?', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    content: Text('Are you sure you want to remove "${address.label}"?',
                                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
