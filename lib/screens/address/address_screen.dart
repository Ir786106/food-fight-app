import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import 'add_address_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});
  @override
  State<AddressScreen> createState() => _AddressScreenState();
}
class _AddressScreenState extends State<AddressScreen> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AddressProvider>().watchAddresses(context.read<AuthProvider>().currentUser?.id ?? '');
    });
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final uid = context.watch<AuthProvider>().currentUser?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery addresses')),
      bottomNavigationBar: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(AppDimens.space16),
        child: FilledButton.icon(onPressed: () => Navigator.pushNamed(context, '/add-address'),
          icon: const Icon(Icons.add), label: const Text('Add address')))),
      body: provider.isLoading ? const Center(child: CircularProgressIndicator())
        : provider.errorMessage != null ? Center(child: TextButton(onPressed: () => provider.watchAddresses(uid), child: const Text('Could not load addresses. Retry')))
        : provider.addresses.isEmpty ? const Center(child: Text('Add an address for faster checkout.'))
        : ListView.separated(padding: const EdgeInsets.all(AppDimens.space16), itemCount: provider.addresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space8), itemBuilder: (context, index) {
            final address = provider.addresses[index];
            return Card(child: Padding(padding: const EdgeInsets.all(AppDimens.space16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: AppDimens.space8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(address.label, style: Theme.of(context).textTheme.titleMedium),
                  if (address.isDefault) const Chip(label: Text('Default')),
                ]),
                Text(address.details),
                Wrap(spacing: AppDimens.space8, children: [
                  TextButton.icon(onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddAddressScreen(address: address))),
                    icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                  if (!address.isDefault) TextButton(onPressed: _busy ? null : () async {
                    setState(() => _busy = true);
                    final ok = await provider.setDefaultAddress(uid, address.id);
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (!ok) AppSnackbar.showError(context, 'Could not update the default address. Retry.');
                  }, child: const Text('Set default')),
                  TextButton.icon(onPressed: _busy ? null : () async {
                    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                      title: const Text('Delete address?'), content: Text(address.label), actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ]));
                    if (confirm != true || !context.mounted) return;
                    setState(() => _busy = true);
                    final ok = await provider.deleteAddress(uid, address.id);
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (!ok) AppSnackbar.showError(context, 'Could not delete the address. Retry.');
                  }, icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
                ]),
              ])));
          }),
    );
  }
}
