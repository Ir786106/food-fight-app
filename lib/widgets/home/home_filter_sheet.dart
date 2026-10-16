import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Modal bottom sheet for filtering and sorting menu dishes on the customer Home Screen
class HomeFilterSheet extends StatefulWidget {
  final bool initialVeg;
  final bool initialSpicy;
  final String initialSortBy;
  final Function(bool isVeg, bool isSpicy, String sortBy) onApply;

  const HomeFilterSheet({
    super.key,
    required this.initialVeg,
    required this.initialSpicy,
    required this.initialSortBy,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isVeg,
    required bool isSpicy,
    required String sortBy,
    required Function(bool isVeg, bool isSpicy, String sortBy) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => HomeFilterSheet(
        initialVeg: isVeg,
        initialSpicy: isSpicy,
        initialSortBy: sortBy,
        onApply: onApply,
      ),
    );
  }

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late bool _filterOnlyVeg;
  late bool _filterOnlySpicy;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _filterOnlyVeg = widget.initialVeg;
    _filterOnlySpicy = widget.initialSpicy;
    _sortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Sort Dishes',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Vegetarian only (🌱)'),
              value: _filterOnlyVeg,
              activeTrackColor: AppColors.lettuce,
              onChanged: (val) => setState(() => _filterOnlyVeg = val),
            ),
            SwitchListTile(
              title: const Text('Spicy only (🌶️)'),
              value: _filterOnlySpicy,
              activeTrackColor: AppColors.tomato,
              onChanged: (val) => setState(() => _filterOnlySpicy = val),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort by',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Popular'),
                  selected: _sortBy == 'popular',
                  onSelected: (s) => setState(() => _sortBy = 'popular'),
                ),
                ChoiceChip(
                  label: const Text('Rating'),
                  selected: _sortBy == 'rating',
                  onSelected: (s) => setState(() => _sortBy = 'rating'),
                ),
                ChoiceChip(
                  label: const Text('Price: Low to High'),
                  selected: _sortBy == 'price_low',
                  onSelected: (s) => setState(() => _sortBy = 'price_low'),
                ),
                ChoiceChip(
                  label: const Text('Price: High to Low'),
                  selected: _sortBy == 'price_high',
                  onSelected: (s) => setState(() => _sortBy = 'price_high'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.brandMaroon,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                widget.onApply(_filterOnlyVeg, _filterOnlySpicy, _sortBy);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
