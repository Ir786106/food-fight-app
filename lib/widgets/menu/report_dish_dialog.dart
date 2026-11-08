import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import '../../models/food_model.dart';

class ReportDishDialog extends StatefulWidget {
  final FoodModel food;
  const ReportDishDialog({super.key, required this.food});
  @override
  State<ReportDishDialog> createState() => _ReportDishDialogState();
}

class _ReportDishDialogState extends State<ReportDishDialog> {
  final _message = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;
  @override
  void dispose() { _message.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in before sending a report.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await FirebaseFirestore.instance.collection('menuReports').add({
        'userId': user.uid, 'menuItemId': widget.food.id, 'menuItemName': widget.food.name,
        'branchId': widget.food.branchId, 'message': _message.text.trim(),
        'status': 'open', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send your report. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Report a menu issue'),
    content: SingleChildScrollView(child: Form(key: _form, child: Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(widget.food.name), const SizedBox(height: AppDimens.space16),
        TextFormField(controller: _message, minLines: 3, maxLines: 6, maxLength: 2000,
          decoration: const InputDecoration(labelText: 'What needs correcting?'),
          validator: (value) => (value?.trim().length ?? 0) < 10 ? 'Please include at least 10 characters.' : null),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    ))),
    actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'Sending…' : 'Send report'))],
  );
}
