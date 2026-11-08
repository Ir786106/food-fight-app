import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_dimens.dart';
import '../../models/order_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';

class OrderReviewDialog extends StatefulWidget {
  final OrderModel order;
  const OrderReviewDialog({super.key, required this.order});
  @override
  State<OrderReviewDialog> createState() => _OrderReviewDialogState();
}
class _OrderReviewDialogState extends State<OrderReviewDialog> {
  final _comment = TextEditingController();
  int _rating = 5;
  String? _target;
  bool _saving = false;
  String? _error;
  @override
  void dispose() { _comment.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final targets = <String,String>{for (final item in widget.order.items) 'item:${item.food.id}': item.food.name,
      if (widget.order.riderId != null) 'rider:${widget.order.riderId}': 'Delivery rider'};
    _target ??= targets.keys.firstOrNull;
    return AlertDialog(title: const Text('Review your order'), content: SingleChildScrollView(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: _target, isExpanded: true,
          items: targets.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _saving ? null : (value) => setState(() => _target = value)),
        const SizedBox(height: AppDimens.space16),
        Wrap(children: List.generate(5, (index) => IconButton(tooltip: '${index+1} stars',
          onPressed: _saving ? null : () => setState(() => _rating = index+1),
          icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Theme.of(context).colorScheme.primary)))),
        TextField(controller: _comment, maxLines: 4, maxLength: 2000, decoration: const InputDecoration(labelText: 'Your feedback (optional)')),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ])), actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving || _target == null ? null : () async {
          final user = context.read<AuthProvider>().currentUser;
          if (user == null) return;
          setState(() { _saving = true; _error = null; });
          final split = _target!.indexOf(':');
          final ok = await context.read<ReviewProvider>().submitReview(ReviewModel(id: '', userId: user.id,
            orderId: widget.order.id, itemId: _target!.substring(split+1), targetType: _target!.substring(0,split),
            branchId: widget.order.branchId, rating: _rating.toDouble(), reviewText: _comment.text.trim(),
            createdAt: DateTime.now(), updatedAt: DateTime.now()));
          if (!context.mounted) return;
          if (ok) { Navigator.pop(context, true); }
          else { setState(() { _saving = false; _error = 'Could not save your review. Check your connection and retry.'; }); }
        }, child: Text(_saving ? 'Saving...' : 'Save review')),
      ]);
  }
}
