import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant_model.dart';
import '../../models/food_model.dart';
import '../../providers/menu_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/cart/floating_cart_mini_pill.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  final List<Map<String, dynamic>> _customReviews = [
    {
      'name': 'Hamza Tariq',
      'rating': 5.0,
      'date': 'Yesterday',
      'comment': 'Best smash burger in town! Crispy edges, juicy patty and lightning fast delivery.',
      'item': 'Smash Fighter Double',
    },
    {
      'name': 'Ayesha Khan',
      'rating': 5.0,
      'date': '3 days ago',
      'comment': 'Pizza crust is authentic wood-fire style. Sauce was bursting with flavour.',
      'item': 'Artisan Pepperoni',
    },
    {
      'name': 'Bilal Ahmed',
      'rating': 4.0,
      'date': 'Last week',
      'comment': 'Good portion size, food was piping hot when it arrived at my doorstep.',
      'item': 'Loaded Garlic Fries',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant =
        ModalRoute.of(context)?.settings.arguments as RestaurantModel? ??
            RestaurantModel(
              id: 'food_fight_hq',
              name: 'Food Fight Restaurant',
              cuisine: 'Fast Food • Burgers • Pizza',
              rating: 4.8,
              deliveryTimeMinutes: 25,
              deliveryFee: 150,
              imageEmoji: '🥊',
              address: 'Food Fight HQ, Main Boulevard',
            );

    final menuProvider = context.watch<MenuProvider>();
    final activeItems = menuProvider.activeItems;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveContainer.content(
        maxWidth: 860,
        child: CustomScrollView(
          slivers: [
            // Hero AppBar with favorite & share overlays
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: colorScheme.surface,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colorScheme.onSurface,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              actions: [
                // Share
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.share_outlined, color: colorScheme.onSurface, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sharing "${restaurant.name}" with friends! 🥊'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                // Favorite
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavorite ? AppColors.primary : colorScheme.onSurface,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isFavorite
                                ? 'Added "${restaurant.name}" to favorites ❤️'
                                : 'Removed from favorites',
                          ),
                          duration: const Duration(milliseconds: 900),
                        ),
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.25),
                            colorScheme.surfaceContainerHighest,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(restaurant.imageEmoji, style: const TextStyle(fontSize: 88)),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Restaurant Info Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.cuisine,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Badges: Rating, Delivery time, Delivery fee
                    Row(
                      children: [
                        _infoChip(Icons.star_rounded, '${restaurant.rating}', AppColors.accent),
                        const SizedBox(width: 10),
                        _infoChip(
                          Icons.access_time_rounded,
                          '${restaurant.deliveryTimeMinutes} min',
                          colorScheme.onSurface,
                        ),
                        const SizedBox(width: 10),
                        _infoChip(
                          Icons.delivery_dining_rounded,
                          restaurant.deliveryFee == 0
                              ? 'Free Delivery'
                              : 'Rs. ${restaurant.deliveryFee.toStringAsFixed(0)}',
                          AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Address
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            restaurant.address,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tabbed Navigation (Menu / Reviews / Info)
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        tabs: const [
                          Tab(text: 'Menu'),
                          Tab(text: 'Reviews'),
                          Tab(text: 'Info'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            // Tab Content: Menu list (index 0)
            if (_tabController.index == 0) ...[
              if (menuProvider.isLoading && activeItems.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: LoadingIndicator(message: 'Loading delicious menu...'),
                  ),
                )
              else if (menuProvider.errorMessage != null && activeItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: ErrorView(
                      message: menuProvider.errorMessage!,
                      onRetry: () => menuProvider.fetchMenuItems(),
                    ),
                  ),
                )
              else if (activeItems.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: EmptyStateView(
                      icon: Icons.fastfood_rounded,
                      title: 'No Dishes Available',
                      description: 'Please check back soon for delicious new additions!',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = activeItems[index];
                        final food = FoodModel.fromMenuItem(item);
                        return FoodCard(
                          food: food,
                          onTap: () => Navigator.of(context).pushNamed(
                            '/food-detail',
                            arguments: food,
                          ),
                        );
                      },
                      childCount: activeItems.length,
                    ),
                  ),
                ),
            ] else if (_tabController.index == 1) ...[
              // Tab Content: Reviews (index 1)
              _buildReviewsSliver(context, restaurant, colorScheme, isDark),
            ] else ...[
              // Tab Content: Info (index 2)
              _buildInfoSliver(context, restaurant, colorScheme, isDark),
            ],
          ],
        ),
      ),

      // Sticky Floating Mini Cart Pill (Ref A)
      bottomNavigationBar: const FloatingCartMiniPill(),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSliver(
    BuildContext context,
    RestaurantModel restaurant,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Rating Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${restaurant.rating}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_customReviews.length + 42} Verified Reviews',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _showWriteReviewDialog(context, restaurant),
                  icon: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 18),
                  label: const Text(
                    'Write Review',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Customer Experiences',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ..._customReviews.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r['name'],
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        r['date'],
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          (r['rating'] as double).toInt(),
                          (i) => const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r['item'],
                          style: const TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r['comment'],
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildInfoSliver(
    BuildContext context,
    RestaurantModel restaurant,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Address & Location
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kitchen Location',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.address,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
                  tooltip: 'Copy Address',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: restaurant.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kitchen address copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Operational Hours
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operating Hours',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Monday – Sunday • 11:00 AM – 11:30 PM',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OPEN NOW',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Kitchen Hotline
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.brandMaroon, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kitchen Hotline',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '+92 300 8765432',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                  tooltip: 'Call Kitchen',
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: '+923008765432');
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        await Clipboard.setData(const ClipboardData(text: '+923008765432'));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hotline phone copied to clipboard')),
                          );
                        }
                      }
                    } catch (_) {
                      await Clipboard.setData(const ClipboardData(text: '+923008765432'));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Hygiene & Quality Badge
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppColors.warning, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Hygiene & Safety Verified',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '100% Halal Certified • Grade A Kitchen Safety Protocol',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context, RestaurantModel restaurant) {
    double selectedRating = 5.0;
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Review ${restaurant.name}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: colorScheme.onSurface),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) {
                        final star = idx + 1;
                        return IconButton(
                          icon: Icon(
                            star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppColors.mustard,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() => selectedRating = star.toDouble());
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: commentCtrl,
                      maxLines: 3,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Your Experience',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please share your review' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.brandMaroon,
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      _customReviews.insert(0, {
                        'name': nameCtrl.text.trim(),
                        'rating': selectedRating,
                        'date': 'Just now',
                        'comment': commentCtrl.text.trim(),
                        'item': 'Verified Customer',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you! Your review for ${restaurant.name} has been published ⭐️'),
                        backgroundColor: AppColors.brandMaroon,
                      ),
                    );
                  }
                },
                child: const Text('Submit Review', style: TextStyle(color: AppColors.brandMaroon, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}

