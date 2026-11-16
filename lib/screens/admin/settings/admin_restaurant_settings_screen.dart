import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../../../models/branch_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/branch_service.dart';
import '../../../widgets/admin/admin_scaffold.dart';

class AdminRestaurantSettingsScreen extends StatelessWidget {
  const AdminRestaurantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final branchId =
        context.watch<AuthProvider>().currentUser?.branchId?.trim();
    return AdminScaffold(
      currentRoute: '/admin/settings',
      appBar: AppBar(title: const Text('Restaurant settings')),
      body: branchId == null ||
              branchId.isEmpty ||
              branchId.toLowerCase() == 'all'
          ? const ErrorView(
              message: 'Choose a branch account to edit restaurant settings.')
          : _BranchSettings(key: ValueKey(branchId), branchId: branchId),
    );
  }
}

class _BranchSettings extends StatefulWidget {
  const _BranchSettings({super.key, required this.branchId});

  final String branchId;

  @override
  State<_BranchSettings> createState() => _BranchSettingsState();
}

class _BranchSettingsState extends State<_BranchSettings> {
  final _formKey = GlobalKey<FormState>();
  late Future<BranchModel?> _branch;
  bool _saving = false;
  String _name = '';
  String _address = '';
  String _phone = '';
  String _hours = '';

  @override
  void initState() {
    super.initState();
    _branch = BranchService.getBranch(widget.branchId);
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (_saving || form == null || !form.validate()) return;
    form.save();
    setState(() => _saving = true);
    try {
      await BranchService.updateBranchContactSettings(
        widget.branchId,
        name: _name,
        address: _address,
        phone: _phone,
        openingHours: _hours,
      );
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Restaurant settings saved.');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Unable to save restaurant settings.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<BranchModel?>(
        future: _branch,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: DesignSystem.screenPadding,
              child: ShimmerLoader(height: 200),
            );
          }
          final branch = snapshot.data;
          if (branch == null || snapshot.hasError) {
            return ErrorView(
              message: 'Unable to load this branch.',
              onRetry: () => setState(
                  () => _branch = BranchService.getBranch(widget.branchId)),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: DesignSystem.screenPadding,
                children: [
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(title: 'Branch details'),
                          const SizedBox(height: DesignSystem.space16),
                          _field('Restaurant name', branch.name,
                              (value) => _name = value),
                          _field('Address', branch.address,
                              (value) => _address = value),
                          _field(
                              'Phone', branch.phone, (value) => _phone = value,
                              keyboard: TextInputType.phone),
                          _field('Opening hours', branch.openingHours,
                              (value) => _hours = value),
                          AppButton(
                            label: 'Save settings',
                            loadingLabel: _saving ? 'Saving…' : null,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _field(String label, String initial, ValueChanged<String> save,
          {TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: DesignSystem.space16),
        child: TextFormField(
          enabled: !_saving,
          initialValue: initial,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter $label' : null,
          onSaved: (value) => save(value!.trim()),
        ),
      );
}
