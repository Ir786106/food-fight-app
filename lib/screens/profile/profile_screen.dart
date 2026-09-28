import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../providers/address_provider.dart';
import '../../providers/coupon_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _watchedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponProvider>().fetchCoupons();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.id != _watchedUserId) {
      _watchedUserId = user.id;
      context.read<AddressProvider>().watchAddresses(user.id);
      context.read<OrderProvider>().watchCustomerOrders(user.id);
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final colorScheme = Theme.of(dialogCtx).colorScheme;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: colorScheme.surface,
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPassCtrl,
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                    decoration: const InputDecoration(labelText: 'Current Password *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
                    decoration: const InputDecoration(labelText: 'New Password *'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    validator: (v) {
                      if (v != newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                    decoration: const InputDecoration(labelText: 'Confirm New Password *'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        final email = context.read<AuthProvider>().currentUser?.email;
                        if (email != null && email.isNotEmpty) {
                          await context.read<AuthProvider>().sendPasswordResetEmail(email);
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password security confirmation sent to your email!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPromoCodesDialog(BuildContext context) {
    final couponProvider = context.read<CouponProvider>();
    final activeCoupons = couponProvider.activeCoupons;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Available Promo Codes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (activeCoupons.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.local_offer_outlined, color: Colors.white.withValues(alpha: 0.25), size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active Promo Codes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Check back soon or tune in during fight events for exclusive discounts!',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...activeCoupons.map((coupon) {
                  final discountText = coupon.type == 'percentage'
                      ? '${coupon.value.toInt()}% OFF'
                      : 'Rs. ${coupon.value.toInt()} OFF';
                  final descText = coupon.description ??
                      (coupon.minimumOrder > 0
                          ? 'Min. order Rs. ${coupon.minimumOrder.toInt()}'
                          : 'Valid on all orders');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF272734),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    coupon.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.primary,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      discountText,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descText,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                          tooltip: 'Copy Code',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: coupon.code));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Promo "${coupon.code}" copied to clipboard!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferAndEarnDialog(BuildContext context) {
    const referralCode = 'FIGHT-WIN200';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Invite Friends, Get Rs. 200!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share your code with friends. When they place their first order, you both get Rs. 200 off your next feast!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF272734),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    referralCode,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: referralCode));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied! Share with friends.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                    label: const Text('COPY', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

  void _showHelpCenterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.headset_mic_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Food Fight Help Center',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call_outlined, color: AppColors.success, size: 20),
              ),
              title: const Text('24/7 Support Hotline', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              subtitle: const Text('0800-FOODFIGHT (Toll-Free)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dialing Support Helpline: 0800-3663344...')),
                );
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryYellow, size: 20),
              ),
              title: const Text('Live Support Chat', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              subtitle: const Text('Instant answers from our delivery team', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to Food Fight live support representative...')),
                );
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mail_outline_rounded, color: AppColors.primaryYellow, size: 20),
              ),
              title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              subtitle: const Text('support@foodfight.pk', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening mail to support@foodfight.pk')),
                );
              },
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final cartProvider = context.watch<CartProvider>();
    final user = auth.currentUser;

    final ordersCount = orderProvider.customerOrders.length;
    final favoritesCount = cartProvider.favorites.length;
    final addressesCount = context.watch<AddressProvider>().addresses.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121217),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            tooltip: 'Edit Profile Info',
            onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // User Header Card with Avatar & Edit affordance
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D26),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with Camera Edit Affordance
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                          ),
                          child: ClipOval(
                            child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                                ? NetworkImageView(
                                    imageUrl: user.profileImage,
                                    width: 72,
                                    height: 72,
                                    fallbackIcon: Icons.person,
                                  )
                                : Container(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '🥊',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name.isNotEmpty == true ? user!.name : 'Foodie Fighter',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No email linked',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (user?.phone.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.phone,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (user?.isAdmin == true || user?.isRider == true)
                                      ? AppColors.darkBrown
                                      : AppColors.primaryYellow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user?.isSuperAdmin == true
                                      ? 'SUPER ADMIN'
                                      : (user?.isAdmin == true
                                          ? 'RESTAURANT ADMIN'
                                          : (user?.isRider == true ? 'RIDER' : 'FOODIE CHAMPION')),
                                  style: TextStyle(
                                    color: (user?.isAdmin == true || user?.isRider == true)
                                        ? Colors.white
                                        : AppColors.darkBrown,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Small Stats Row (Orders / Favorites / Addresses counts)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      count: ordersCount.toString(),
                      label: 'Orders',
                      icon: Icons.receipt_long_outlined,
                      accentColor: AppColors.primary,
                      onTap: () => Navigator.of(context).pushNamed('/order-history'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      count: favoritesCount.toString(),
                      label: 'Favorites',
                      icon: Icons.favorite_outline_rounded,
                      accentColor: AppColors.error,
                      onTap: () => Navigator.of(context).pushNamed('/favorites'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      count: addressesCount.toString(),
                      label: 'Addresses',
                      icon: Icons.location_on_outlined,
                      accentColor: AppColors.warning,
                      onTap: () => Navigator.of(context).pushNamed('/addresses'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Group 1: Account & Delivery Preferences
              _buildSectionHeader('ACCOUNT & ADDRESSES'),
              _buildCardGroup([
                _buildMenuItem(
                  icon: Icons.badge_outlined,
                  title: 'Edit Profile Information',
                  subtitle: 'Change name, phone and profile photo',
                  onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                ),
                const Divider(height: 1, color: Colors.white10, indent: 56),
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Delivery Addresses',
                  subtitle: '$addressesCount saved addresses (Home, Work)',
                  onTap: () => Navigator.of(context).pushNamed('/addresses'),
                ),
                const Divider(height: 1, color: Colors.white10, indent: 56),
                _buildMenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  subtitle: 'Saved debit cards, JazzCash & Easypaisa',
                  onTap: () => Navigator.of(context).pushNamed('/payment-methods'),
                ),
              ]),

              const SizedBox(height: 18),

              // Group 2: Promotions & Perks
              _buildSectionHeader('REWARDS & DISCOUNTS'),
              _buildCardGroup([
                _buildMenuItem(
                  icon: Icons.local_offer_outlined,
                  title: 'Promo Codes & Vouchers',
                  subtitle: 'View discounts & special coupon codes',
                  trailingBadge: '3 ACTIVE',
                  onTap: () => _showPromoCodesDialog(context),
                ),
                const Divider(height: 1, color: Colors.white10, indent: 56),
                _buildMenuItem(
                  icon: Icons.card_giftcard_outlined,
                  title: 'Refer & Earn',
                  subtitle: 'Give Rs. 200, Get Rs. 200 off',
                  trailingBadge: 'REWARD',
                  onTap: () => _showReferAndEarnDialog(context),
                ),
              ]),

              const SizedBox(height: 18),

              // Group 3: App Settings & Help
              _buildSectionHeader('PREFERENCES & SUPPORT'),
              _buildCardGroup([
                _buildMenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Push notifications & order alerts',
                  onTap: () => Navigator.of(context).pushNamed('/notifications'),
                ),
                const Divider(height: 1, color: Colors.white10, indent: 56),
                _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Help Center',
                  subtitle: 'FAQs, contact support & live helpline',
                  onTap: () => _showHelpCenterDialog(context),
                ),
                const Divider(height: 1, color: Colors.white10, indent: 56),
                _buildMenuItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Send password security update link',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1, color: Colors.white10, indent: 56),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App preferences, theme & about',
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
              ]),

              // Privileged Portals (if Admin or Rider)
              if (auth.isAdmin || user?.isRider == true) ...[
                const SizedBox(height: 18),
                _buildSectionHeader('ROLE PORTALS'),
                _buildCardGroup([
                  if (auth.isAdmin)
                    _buildMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Restaurant Admin Portal',
                      subtitle: 'Orders, menu, categories & kitchen console',
                      iconColor: AppColors.primaryYellow,
                      onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                    ),
                  if (auth.isSuperAdmin) ...[
                    const Divider(height: 1, color: Colors.white10, indent: 56),
                    _buildMenuItem(
                      icon: Icons.shield_rounded,
                      title: 'Super Admin HQ Console',
                      subtitle: 'Platform analytics, staff & system audit logs',
                      iconColor: AppColors.primaryYellow,
                      onTap: () => Navigator.of(context).pushNamed('/super-admin/dashboard'),
                    ),
                  ],
                  if (user?.isRider == true || auth.isAdmin) ...[
                    const Divider(height: 1, color: Colors.white10, indent: 56),
                    _buildMenuItem(
                      icon: Icons.moped_rounded,
                      title: 'Rider Delivery Mode',
                      subtitle: 'Active deliveries, pickup & dispatch map',
                      iconColor: AppColors.primaryYellow,
                      onTap: () => Navigator.of(context).pushNamed('/rider/dashboard'),
                    ),
                  ],
                ]),
              ],

              const SizedBox(height: 24),

              // Log Out CTA Button
              Material(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1D1D26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: const Text(
                          'Are you sure you want to sign out from Food Fight?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Food Fight v1.0.1 • Near-black Dark Edition',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white30,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String count,
    required String label,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1D1D26),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(height: 6),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFF1D1D26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    String? trailingBadge,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trailingBadge,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white38),
        ],
      ),
    );
  }
}
