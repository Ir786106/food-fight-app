import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/design_system.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _visible = false;
  bool _saving = false;
  String? _error;
  @override
  void dispose() { _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) throw StateError('Sign in again to change your password.');
      if (!user!.providerData.any((provider) => provider.providerId == 'password')) {
        throw StateError('Manage your password with your Google account provider.');
      }
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(
        email: user.email!, password: _current.text));
      await user.updatePassword(_next.text);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.code == 'invalid-credential' || error.code == 'wrong-password'
        ? 'The current password is incorrect.' : error.message ?? 'Unable to update your password.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change password'),
    content: SingleChildScrollView(child: Form(key: _form, child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _current, obscureText: !_visible,
          decoration: const InputDecoration(labelText: 'Current password'),
          validator: (v) => v == null || v.isEmpty ? 'Enter your current password' : null),
        const SizedBox(height: AppDimens.space16),
        TextFormField(controller: _next, obscureText: !_visible,
          decoration: const InputDecoration(labelText: 'New password'),
          validator: (v) => (v?.length ?? 0) < 8 ? 'Use at least 8 characters' : null),
        const SizedBox(height: AppDimens.space16),
        TextFormField(controller: _confirm, obscureText: !_visible,
          decoration: const InputDecoration(labelText: 'Confirm password'),
          validator: (v) => v != _next.text ? 'Passwords do not match' : null),
        CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Show passwords'),
          value: _visible, onChanged: (v) => setState(() => _visible = v ?? false)),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    ))),
    actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save password'))],
  );
}

class HelpCenterSheet extends StatelessWidget {
  final String? branchPhone;
  const HelpCenterSheet({super.key, this.branchPhone});

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No application can open this link.');
      }
    } catch (_) {
      if (context.mounted) AppSnackbar.showError(context, 'Unable to open this contact on your device.');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(
    padding: DesignSystem.screenPadding,
    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('settings').doc('global_settings').snapshots(),
      builder: (context, snapshot) {
        final settings = snapshot.data?.data() ?? {};
        final phone = (settings['contactPhone'] ?? branchPhone ?? '').toString().trim();
        final email = (settings['contactEmail'] ?? '').toString().trim();
        final whatsapp = (settings['supportWhatsApp'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Help center', style: Theme.of(context).textTheme.titleLarge),
          if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator(),
          if (phone.isNotEmpty) ListTile(leading: const Icon(Icons.phone_outlined), title: Text(phone),
            onTap: () => _open(context, Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')))),
          if (email.isNotEmpty) ListTile(leading: const Icon(Icons.email_outlined), title: Text(email),
            onTap: () => _open(context, Uri(scheme: 'mailto', path: email))),
          if (whatsapp.isNotEmpty) ListTile(leading: const Icon(Icons.chat_outlined), title: const Text('WhatsApp'),
            onTap: () => _open(context, Uri.https('wa.me', '/$whatsapp'))),
          ListTile(leading: const Icon(Icons.support_agent), title: const Text('Support chat'),
            onTap: () { Navigator.pop(context); Navigator.of(context, rootNavigator: true).pushNamed('/chat'); }),
          if (snapshot.hasError) const Text('Contact details could not be loaded. Please try support chat.'),
        ]);
      },
    ),
  ));
}
