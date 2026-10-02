import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/deal_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/deal_provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../core/constants/app_colors.dart';

class AddEditDealDialog extends StatefulWidget {
  final DealModel? deal;

  const AddEditDealDialog({super.key, this.deal});

  @override
  State<AddEditDealDialog> createState() => _AddEditDealDialogState();
}

class _AddEditDealDialogState extends State<AddEditDealDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _dealPriceCtrl;
  late TextEditingController _origPriceCtrl;

  late bool _isActive;
  DateTime? _startDate;
  DateTime? _endDate;
  late List<int> _activeDays;
  List<DealBundleItem> _bundleItems = [];
  bool _isSaving = false;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final d = widget.deal;
    _titleCtrl = TextEditingController(text: d?.title ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _dealPriceCtrl = TextEditingController(text: d != null ? d.dealPrice.toStringAsFixed(0) : '');
    _origPriceCtrl = TextEditingController(
        text: d != null && d.originalPrice > 0 ? d.originalPrice.toStringAsFixed(0) : '');

    _isActive = d?.isActive ?? true;
    _startDate = d?.startDate;
    _endDate = d?.endDate;
    _activeDays = d?.activeDays != null ? List.from(d!.activeDays) : [1, 2, 3, 4, 5, 6, 7];
    _bundleItems = d?.bundleItems != null ? List.from(d!.bundleItems) : [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dealPriceCtrl.dispose();
    _origPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.deal != null;
    final menuItems = context.watch<MenuProvider>().menuItems;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_offer_rounded, color: AppColors.brandYellow),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Branch Deal' : 'Create New Deal',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Configured promotions update customer home and menus instantly.',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),

                // Scrollable Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Deal Title *',
                            hintText: 'e.g. Twin Pizza Feast Deal',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.title_rounded),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            hintText: 'e.g. 2 Large Pizzas + 1.5L Soft Drink + Dip Sauces',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.description_rounded),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                        ),
                        const SizedBox(height: 14),

                        // Price Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dealPriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Deal Price (Rs.) *',
                                  hintText: '1999',
                                  border:
                                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.attach_money_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter deal price';
                                  final num = double.tryParse(v);
                                  if (num == null || num <= 0) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _origPriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Original Price (Rs.)',
                                  hintText: '2600',
                                  border:
                                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.money_off_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Bundle Items Selection
                        const Text(
                          'Bundle Items (What is included)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),

                        if (_bundleItems.isNotEmpty)
                          ..._bundleItems.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.fastfood_rounded, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.name}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        if (item.quantity > 1) {
                                          _bundleItems[idx] = DealBundleItem(
                                            menuItemId: item.menuItemId,
                                            name: item.name,
                                            quantity: item.quantity - 1,
                                            size: item.size,
                                          );
                                        } else {
                                          _bundleItems.removeAt(idx);
                                        }
                                      });
                                    },
                                  ),
                                  Text('${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _bundleItems[idx] = DealBundleItem(
                                          menuItemId: item.menuItemId,
                                          name: item.name,
                                          quantity: item.quantity + 1,
                                          size: item.size,
                                        );
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: AppColors.error),
                                    onPressed: () => setState(() => _bundleItems.removeAt(idx)),
                                  ),
                                ],
                              ),
                            );
                          }),

                        // Add item dropdown
                        if (menuItems.isNotEmpty)
                          PopupMenuButton<String>(
                            tooltip: 'Add item from menu',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.brandYellow, width: 1.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 18, color: AppColors.brandYellow),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add Menu Item to Bundle',
                                    style: TextStyle(
                                      color: AppColors.brandYellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (ctx) {
                              return menuItems.map((item) {
                                return PopupMenuItem(
                                  value: item.id,
                                  child: Text(item.name),
                                );
                              }).toList();
                            },
                            onSelected: (itemId) {
                              final match = menuItems.firstWhere((m) => m.id == itemId);
                              final existingIdx =
                                  _bundleItems.indexWhere((b) => b.menuItemId == itemId);
                              setState(() {
                                if (existingIdx >= 0) {
                                  final old = _bundleItems[existingIdx];
                                  _bundleItems[existingIdx] = DealBundleItem(
                                    menuItemId: old.menuItemId,
                                    name: old.name,
                                    quantity: old.quantity + 1,
                                    size: old.size,
                                  );
                                } else {
                                  _bundleItems.add(DealBundleItem(
                                    menuItemId: match.id,
                                    name: match.name,
                                    quantity: 1,
                                  ));
                                }
                              });
                            },
                          ),

                        const SizedBox(height: 20),

                        // Active Days of the week
                        const Text(
                          'Active Days',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(7, (i) {
                            final dayNum = i + 1;
                            final isSelected = _activeDays.contains(dayNum);
                            return FilterChip(
                              label: Text(_dayNames[i]),
                              selected: isSelected,
                              selectedColor: AppColors.brandYellow,
                              checkmarkColor: AppColors.onYellow,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.onYellow : colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _activeDays.add(dayNum);
                                  } else {
                                    if (_activeDays.length > 1) {
                                      _activeDays.remove(dayNum);
                                    }
                                  }
                                });
                              },
                            );
                          }),
                        ),

                        const SizedBox(height: 16),

                        // Active status toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active Immediately',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Deal will appear live to customers',
                              style: TextStyle(fontSize: 12)),
                          value: _isActive,
                          activeThumbColor: AppColors.brandYellow,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandYellow,
                        foregroundColor: AppColors.onYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSaving ? null : _saveDeal,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEdit ? 'Save Changes' : 'Create Deal',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveDeal() async {
    if (!_formKey.currentState!.validate()) return;

    final dealProvider = context.read<DealProvider>();
    final auth = context.read<AuthProvider>();
    final branchId = auth.currentUser?.branchId;

    setState(() => _isSaving = true);

    final dealPrice = double.parse(_dealPriceCtrl.text.trim());
    final origPrice = double.tryParse(_origPriceCtrl.text.trim()) ?? dealPrice;

    final dealToSave = DealModel(
      id: widget.deal?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      dealPrice: dealPrice,
      originalPrice: origPrice,
      discountType: 'fixed_price',
      bundleItems: _bundleItems,
      linkedItemIds: _bundleItems.map((b) => b.menuItemId).toList(),
      branchId: widget.deal?.branchId ?? branchId,
      activeDays: _activeDays,
      isActive: _isActive,
      startDate: _startDate,
      endDate: _endDate,
      createdAt: widget.deal?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool ok = false;
    if (widget.deal == null) {
      ok = await dealProvider.createDeal(dealToSave);
    } else {
      ok = await dealProvider.updateDeal(dealToSave);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.deal == null ? 'Deal created successfully!' : 'Deal updated successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dealProvider.error ?? 'Failed to save deal'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
