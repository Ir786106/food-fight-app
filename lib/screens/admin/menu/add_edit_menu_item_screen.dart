import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/providers/menu_provider.dart';
import 'package:food_fight/providers/category_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_fight/services/supabase/supabase_image_storage_service.dart';
import 'package:food_fight/widgets/common/network_image_view.dart';

class VariantFormEntry {
  final TextEditingController labelCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discountCtrl;
  final TextEditingController descCtrl;

  VariantFormEntry({
    String label = '',
    String price = '',
    String discount = '0',
    String description = '',
  })  : labelCtrl = TextEditingController(text: label),
        priceCtrl = TextEditingController(text: price),
        discountCtrl = TextEditingController(text: discount),
        descCtrl = TextEditingController(text: description);

  void dispose() {
    labelCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    descCtrl.dispose();
  }
}

class AddonFormEntry {
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;

  AddonFormEntry({
    String name = '',
    String price = '',
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price);

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class AddEditMenuItemScreen extends StatefulWidget {
  final MenuItemModel? item;

  const AddEditMenuItemScreen({super.key, this.item});

  @override
  State<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _prepTimeCtrl;

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  String? _imageUrl;
  XFile? _pickedImage;

  bool _hasVariants = false;
  final List<VariantFormEntry> _variantEntries = [];
  final List<AddonFormEntry> _addonEntries = [];

  bool _isVeg = false;
  bool _isSpicy = false;
  bool _isFeatured = false;
  bool _isActive = true;

  bool _isLoadingCategories = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _priceCtrl = TextEditingController(
        text: item != null ? item.price.toStringAsFixed(0) : '');
    _discountCtrl = TextEditingController(
        text: item != null ? item.discount.toStringAsFixed(0) : '0');
    _prepTimeCtrl = TextEditingController(
        text: item != null ? item.prepTimeMinutes.toString() : '25');

    _imageUrl = item?.imageUrl;
    _selectedCategoryId = item?.categoryId;
    _isVeg = item?.isVeg ?? false;
    _isSpicy = item?.isSpicy ?? false;
    _isFeatured = item?.isFeatured ?? false;
    _isActive = item?.isActive ?? true;

    // Initialize variants if existing
    if (item != null && item.hasVariants) {
      _hasVariants = true;
      for (var v in item.variants!) {
        _variantEntries.add(VariantFormEntry(
          label: v.label,
          price: v.price.toStringAsFixed(0),
          discount: v.discount.toStringAsFixed(0),
          description: v.description ?? '',
        ));
      }
    } else {
      _hasVariants = false;
    }

    // Initialize addons if existing
    if (item != null && item.hasAddons) {
      for (var a in item.addons!) {
        _addonEntries.add(AddonFormEntry(
          name: a.name,
          price: a.price.toStringAsFixed(0),
        ));
      }
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _prepTimeCtrl.dispose();
    for (var v in _variantEntries) {
      v.dispose();
    }
    for (var a in _addonEntries) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = context.read<CategoryProvider>().categories;
    if (mounted) {
      setState(() {
        _categories = list;
        _isLoadingCategories = false;
        if (_selectedCategoryId == null && list.isNotEmpty) {
          _selectedCategoryId = list.first.id;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final img = await SupabaseImageStorageService.pickImage();
    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  double get _calculatedFinalPrice {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    if (discount <= 0) return price;
    final discounted = price - (price * discount / 100.0);
    return discounted > 0 ? discounted : 0.0;
  }

  void _addVariantEntry() {
    setState(() {
      _variantEntries.add(VariantFormEntry());
    });
  }

  void _removeVariantEntry(int index) {
    if (_variantEntries.length > 2) {
      setState(() {
        _variantEntries[index].dispose();
        _variantEntries.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items with multiple sizes must have at least 2 variants.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _addAddonEntry() {
    setState(() {
      _addonEntries.add(AddonFormEntry());
    });
  }

  void _removeAddonEntry(int index) {
    setState(() {
      _addonEntries[index].dispose();
      _addonEntries.removeAt(index);
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Validate photo selection for new item
    if (widget.item == null && _pickedImage == null && (_imageUrl == null || _imageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item photo before saving.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate variants if enabled
    List<MenuVariant>? variantsToSave;
    if (_hasVariants) {
      if (_variantEntries.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide at least 2 size/portion variants.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final Set<String> labelSet = {};
      final List<MenuVariant> parsedVariants = [];

      for (int i = 0; i < _variantEntries.length; i++) {
        final entry = _variantEntries[i];
        final label = entry.labelCtrl.text.trim();
        final price = double.tryParse(entry.priceCtrl.text.trim());
        final discount = double.tryParse(entry.discountCtrl.text.trim()) ?? 0.0;
        final desc = entry.descCtrl.text.trim();

        if (label.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variant #${i + 1} is missing a label (e.g. Small, Medium).'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (labelSet.contains(label.toLowerCase())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Duplicate variant label "$label". Labels must be unique.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        labelSet.add(label.toLowerCase());

        if (price == null || price < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variant "$label" has an invalid price.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        parsedVariants.add(MenuVariant(
          label: label,
          price: price,
          discount: discount,
          description: desc.isNotEmpty ? desc : null,
        ));
      }

      variantsToSave = parsedVariants;
    }

    // Parse addons
    List<MenuAddon>? addonsToSave;
    if (_addonEntries.isNotEmpty) {
      final List<MenuAddon> parsedAddons = [];
      for (int i = 0; i < _addonEntries.length; i++) {
        final entry = _addonEntries[i];
        final name = entry.nameCtrl.text.trim();
        final price = double.tryParse(entry.priceCtrl.text.trim());

        if (name.isNotEmpty) {
          if (price == null || price < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Add-on "$name" must have a valid non-negative price.'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
          parsedAddons.add(MenuAddon(name: name, price: price));
        }
      }
      if (parsedAddons.isNotEmpty) {
        addonsToSave = parsedAddons;
      }
    }

    final menuProvider = context.read<MenuProvider>();
    final currentAdminBranchId = context.read<AuthProvider>().currentUser?.branchId;

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = _imageUrl;

      // Upload image to Supabase Storage if a new one was picked
      if (_pickedImage != null) {
        try {
          final supabase = Supabase.instance.client;
          final imageBytes = await _pickedImage!.readAsBytes();

          // Determine extension and proper MIME type dynamically
          final rawExt = _pickedImage!.name.split('.').last.toLowerCase();
          final ext = (rawExt == 'png' || rawExt == 'webp' || rawExt == 'gif') ? rawExt : 'jpg';
          final mimeType = ext == 'png'
              ? 'image/png'
              : ext == 'webp'
                  ? 'image/webp'
                  : ext == 'gif'
                      ? 'image/gif'
                      : 'image/jpeg';

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = 'products/product_$timestamp.$ext';

          await supabase.storage
              .from('food-images')
              .uploadBinary(
                filePath,
                imageBytes,
                fileOptions: FileOptions(
                  contentType: mimeType,
                  upsert: false,
                ),
              );

          finalImageUrl = supabase.storage
              .from('food-images')
              .getPublicUrl(filePath);
        } catch (e, stackTrace) {
          debugPrint('SUPABASE STORAGE ERROR: $e');
          debugPrint('$stackTrace');
          rethrow;
        }
      }

      double basePrice;
      double baseDiscount;
      double baseFinalPrice;

      if (_hasVariants && variantsToSave != null && variantsToSave.isNotEmpty) {
        // Base price is lowest variant price
        final cheapest = variantsToSave.reduce((a, b) => a.finalPrice < b.finalPrice ? a : b);
        basePrice = cheapest.price;
        baseDiscount = cheapest.discount;
        baseFinalPrice = cheapest.finalPrice;
      } else {
        basePrice = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
        baseDiscount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
        baseFinalPrice = _calculatedFinalPrice;
      }

      final prepTime = int.tryParse(_prepTimeCtrl.text.trim()) ?? 25;
      final itemToSave = MenuItemModel(
        id: widget.item?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: basePrice,
        discount: baseDiscount,
        finalPrice: baseFinalPrice,
        imageUrl: finalImageUrl,
        categoryId: _selectedCategoryId!,
        isActive: _isActive,
        isFeatured: _isFeatured,
        isVeg: _isVeg,
        isSpicy: _isSpicy,
        prepTimeMinutes: prepTime,
        rating: widget.item?.rating ?? 4.8,
        variants: _hasVariants ? variantsToSave : null,
        addons: addonsToSave,
        branchId: widget.item?.branchId ?? currentAdminBranchId,
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.item == null) {
        await menuProvider.createMenuItem(itemToSave);
      } else {
        await menuProvider.updateMenuItem(itemToSave);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null
                ? 'Menu item created!'
                : 'Menu item updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final String errorMsg;
        if (e is StorageException) {
          final statusCode = e.statusCode != null ? '[Storage ${e.statusCode}] ' : '';
          final details = e.message.isNotEmpty ? e.message : (e.error?.toString() ?? 'Permission denied (RLS policy)');
          errorMsg = 'Image upload failed: $statusCode$details';
        } else {
          errorMsg = 'Error saving menu item: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker Section
                    const Text('Item Photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    Center(
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _pickedImage != null
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: AppColors.success, size: 48),
                                        SizedBox(height: 8),
                                        Text('New photo selected from device',
                                            style: TextStyle(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                : (_imageUrl != null && _imageUrl!.isNotEmpty
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          NetworkImageView(
                                              imageUrl: _imageUrl,
                                              fit: BoxFit.cover),
                                          Container(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            child: const Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.camera_alt,
                                                      color: Colors.white),
                                                  SizedBox(width: 8),
                                                  Text('Change Photo',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_rounded,
                                                size: 44,
                                                color: Colors.grey.shade400),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Upload Item Photo to Supabase',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              'JPG, PNG, or WebP',
                                              style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Dropdown
                    const Text('Category',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCategoryId,
                          hint: const Text('Select a Category'),
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategoryId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    const Text('Item Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g., Chicken Tikka, Broast Quarter',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Enter item name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text('Description',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Describe ingredients, flavor profile, or special details...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // Multi-Size / Variants Toggle & Templates (Phase 7)
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasVariants
                              ? AdminTheme.primaryBlue.withValues(alpha: 0.5)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Has multiple sizes / variants?',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            subtitle: Text(
                              _hasVariants
                                  ? 'Configuring per-size pricing (e.g. S/M/L, Quarter/Half/Full)'
                                  : 'Single flat price for this item',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            value: _hasVariants,
                            activeThumbColor: AdminTheme.primaryBlue,
                            onChanged: (val) {
                              setState(() {
                                _hasVariants = val;
                                if (_hasVariants && _variantEntries.isEmpty) {
                                  _variantEntries.add(VariantFormEntry(
                                      label: 'Small', price: '399'));
                                  _variantEntries.add(VariantFormEntry(
                                      label: 'Medium', price: '799'));
                                }
                              });
                            },
                          ),
                          if (_hasVariants) ...[
                            const Divider(height: 16),
                            const Text(
                              'Apply Size Set Template:',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.primaryBlue),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.style_outlined, size: 16, color: AdminTheme.primaryBlue),
                                  label: const Text('4 Sizes (S, M, L, XL)', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    setState(() {
                                      _variantEntries.clear();
                                      _variantEntries.add(VariantFormEntry(label: 'Small', price: '450'));
                                      _variantEntries.add(VariantFormEntry(label: 'Medium', price: '850'));
                                      _variantEntries.add(VariantFormEntry(label: 'Large', price: '1350'));
                                      _variantEntries.add(VariantFormEntry(label: 'XL', price: '1850'));
                                    });
                                  },
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.style_outlined, size: 16, color: AdminTheme.primaryBlue),
                                  label: const Text('3 Sizes (M, L, XL)', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    setState(() {
                                      _variantEntries.clear();
                                      _variantEntries.add(VariantFormEntry(label: 'Medium', price: '850'));
                                      _variantEntries.add(VariantFormEntry(label: 'Large', price: '1350'));
                                      _variantEntries.add(VariantFormEntry(label: 'XL', price: '1850'));
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // When Flat Price: Show standard price and discount
                    if (!_hasVariants) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Base Price (Rs.)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '599',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) {
                                    if (!_hasVariants &&
                                        (val == null || val.trim().isEmpty)) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Discount (%)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _discountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_calculatedFinalPrice > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Selling Price: Rs. ${_calculatedFinalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],

                    // When Multi-Size: Show repeatable Variants Editor
                    if (_hasVariants) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Item Sizes / Variants (Minimum 2)',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                          TextButton.icon(
                            onPressed: _addVariantEntry,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Size'),
                            style: TextButton.styleFrom(
                              foregroundColor: AdminTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._variantEntries.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final v = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AdminTheme.primaryBlue
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AdminTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Size / Variant #${idx + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                  const Spacer(),
                                  if (_variantEntries.length > 2)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.error, size: 20),
                                      onPressed: () => _removeVariantEntry(idx),
                                      tooltip: 'Remove variant',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: v.labelCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Size Label',
                                        hintText: 'e.g. Small, Quarter',
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: v.priceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Price (Rs.)',
                                        hintText: '399',
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: v.discountCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Disc %',
                                        hintText: '0',
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: v.descCtrl,
                                decoration: InputDecoration(
                                  labelText:
                                      'Portion Description / Notes (Optional)',
                                  hintText:
                                      'e.g. 1 leg, 1 thigh, 1 bun + fries + 1 dip',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    // ==========================================
                    // Repeatable Extras / Add-ons Editor
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Extras / Add-ons (Optional)',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                        TextButton.icon(
                          onPressed: _addAddonEntry,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Extra'),
                          style: TextButton.styleFrom(
                            foregroundColor: AdminTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.layers_outlined, size: 15, color: AdminTheme.primaryBlue),
                          label: const Text('+ Extra Toppings Set', style: TextStyle(fontSize: 11.5)),
                          onPressed: () {
                            setState(() {
                              _addonEntries.add(AddonFormEntry(name: 'Extra Mozzarella Cheese', price: '150'));
                              _addonEntries.add(AddonFormEntry(name: 'Smoked Chicken Chunks', price: '180'));
                              _addonEntries.add(AddonFormEntry(name: 'Jalapeno & Mushrooms', price: '100'));
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.soup_kitchen_outlined, size: 15, color: AdminTheme.primaryBlue),
                          label: const Text('+ Extra Dips Set', style: TextStyle(fontSize: 11.5)),
                          onPressed: () {
                            setState(() {
                              _addonEntries.add(AddonFormEntry(name: 'Garlic Mayo Dip', price: '70'));
                              _addonEntries.add(AddonFormEntry(name: 'Chipotle Ranch Dip', price: '80'));
                              _addonEntries.add(AddonFormEntry(name: 'Ghost Pepper Hot Sauce', price: '90'));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_addonEntries.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'No extras configured. Tap "+ Add Extra" to offer toppings, cheese, or dip sauces.',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12.5),
                        ),
                      ),
                    ..._addonEntries.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final a = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: a.nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Extra Name',
                                  hintText: 'e.g. Extra Cheese',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: a.priceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Price (Rs.)',
                                  hintText: '150',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.grey, size: 20),
                              onPressed: () => _removeAddonEntry(idx),
                              tooltip: 'Remove Extra',
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 18),

                    // Preparation Time
                    const Text('Preparation Time (minutes)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _prepTimeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '25',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Toggles
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Spicy Item 🌶️',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: const Text(
                                  'Shows hot/spicy badge to customers'),
                              value: _isSpicy,
                              activeThumbColor: AppColors.error,
                              onChanged: (val) =>
                                  setState(() => _isSpicy = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Vegetarian 🥗',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              subtitle:
                                  const Text('Shows green veg indicator'),
                              value: _isVeg,
                              activeThumbColor: AppColors.success,
                              onChanged: (val) => setState(() => _isVeg = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Featured on Home ⭐',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: const Text(
                                  'Highlighted in home deals & promotions'),
                              value: _isFeatured,
                              activeThumbColor: AppColors.warning,
                              onChanged: (val) =>
                                  setState(() => _isFeatured = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Active (Available to order)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              value: _isActive,
                              activeThumbColor: AdminTheme.primaryBlue,
                              onChanged: (val) =>
                                  setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSaving ? null : _saveItem,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              widget.item == null
                                  ? 'Create Menu Item'
                                  : 'Update Menu Item',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
