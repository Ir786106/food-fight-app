import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingItem {
  final String title;
  final String subtitle;
  final String imagePath;
  final String badge;
  final bool isPermissionPrimer;

  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.badge,
    this.isPermissionPrimer = false,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isRequestingPermissions = false;

  static const List<_OnboardingItem> _pages = [
    _OnboardingItem(
      title: 'Knockout Fast Delivery',
      subtitle:
          'Freshly grilled and delivered piping hot across all 5 branches in record time. Select your nearest kitchen and savor the punch.',
      imagePath: 'assets/images/onboarding/fast_delivery.jpg',
      badge: '5 BRANCHES • RAPID DISPATCH',
    ),
    _OnboardingItem(
      title: 'Epic Food Battles & Combos',
      subtitle:
          'Customize double smash patties, loaded cheese pizzas, signature crusts, and secret dip sauces. Build your ultimate champion meal.',
      imagePath: 'assets/images/onboarding/menu_combos.jpg',
      badge: 'CUSTOM PORTIONS & DEALS',
    ),
    _OnboardingItem(
      title: 'Live GPS Round-by-Round Tracking',
      subtitle:
          'Watch your food journey in real time — from the kitchen grill to your front doorstep with live rider telemetry and instant status.',
      imagePath: 'assets/images/onboarding/live_tracking.jpg',
      badge: 'REAL-TIME SATELLITE MAPS',
    ),
    _OnboardingItem(
      title: 'Stay in the Fight',
      subtitle:
          'Allow notifications for hot order alerts and exclusive discounts, and share your location to automatically pinpoint your nearest branch.',
      imagePath: 'assets/images/onboarding/permissions.jpg',
      badge: 'INSTANT ALERTS & EASY PINNING',
      isPermissionPrimer: true,
    ),
  ];

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.storageOnboardingCompleted, true);
    } catch (e) {
      debugPrint('Error saving onboarding state: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _handlePermissionRequest() async {
    setState(() => _isRequestingPermissions = true);
    try {
      // 1. Notifications permission
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('Notification permission error: $e');
      }

      // 2. Location permission
      try {
        final current = await Geolocator.checkPermission();
        if (current == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
      } catch (e) {
        debugPrint('Location permission error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermissions = false);
        await _completeOnboarding();
      }
    }
  }

  void _onNextPressed() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    final bgColor = isDark ? const Color(0xFF140C0B) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF1E1211) : Colors.white;
    final primaryTextColor = isDark ? const Color(0xFFF7EFE6) : const Color(0xFF2A1415);
    final secondaryTextColor = isDark ? const Color(0xFFBCA9A3) : const Color(0xFF6B5B58);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top Header: Logo + Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.brandYellow,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandYellow.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Image.asset(
                                  AppConstants.logoIconPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppConstants.appName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.brandMaroon,
                            ),
                          ),
                        ],
                      ),
                      if (_currentIndex < _pages.length - 1)
                        Semantics(
                          button: true,
                          label: 'Skip onboarding',
                          child: TextButton(
                            key: const ValueKey('onboarding_skip_button'),
                            onPressed: _completeOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: secondaryTextColor,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // PageView with Illustration + Text Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      final isPermissionPage = item.isPermissionPrimer;

                      // Image sizing that stays responsive across orientations
                      final maxImgHeight = isLandscape
                          ? (constraints.maxHeight * 0.42).clamp(120.0, 220.0)
                          : (constraints.maxHeight * 0.44).clamp(180.0, 340.0);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.brandYellow.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.brandYellow.withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                item.badge,
                                style: const TextStyle(
                                  color: AppColors.brandMaroon,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Hero Illustration
                            Container(
                              height: maxImgHeight,
                              constraints: const BoxConstraints(maxWidth: 380),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  item.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: cardBg,
                                    child: const Center(
                                      child: Icon(
                                        Icons.fastfood_rounded,
                                        size: 72,
                                        color: AppColors.brandYellow,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Title
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isLandscape ? 20 : 25,
                                fontWeight: FontWeight.w900,
                                color: primaryTextColor,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Text(
                                item.subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: secondaryTextColor,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            // Permission cards preview if page 4
                            if (isPermissionPage) ...[
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPermissionChip(
                                    icon: Icons.notifications_active_rounded,
                                    label: 'Hot Order Alerts',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildPermissionChip(
                                    icon: Icons.location_on_rounded,
                                    label: 'Nearest Branch',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Bar: Dots Indicator + Action Buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth Page Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (index) {
                          final isSelected = index == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 7,
                            width: isSelected ? 26 : 7,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandYellow
                                  : (isDark ? Colors.white24 : AppColors.brandMaroon.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Navigation Actions
                      if (_currentIndex == _pages.length - 1) ...[
                        // Permission Primer Options
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: const ValueKey('onboarding_not_now_button'),
                                onPressed: _isRequestingPermissions ? null : _completeOnboarding,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: secondaryTextColor,
                                  side: BorderSide(
                                    color: isDark ? Colors.white24 : AppColors.brandMaroon.withValues(alpha: 0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Not Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                key: const ValueKey('onboarding_get_started_button'),
                                onPressed: _isRequestingPermissions ? null : _handlePermissionRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandYellow,
                                  foregroundColor: AppColors.brandMaroon,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isRequestingPermissions
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandMaroon),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Enable & Get Started',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(Icons.arrow_forward_rounded, size: 18),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Next Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const ValueKey('onboarding_next_button'),
                            onPressed: _onNextPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandYellow,
                              foregroundColor: AppColors.brandMaroon,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261817) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.brandMaroon.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.brandMaroon),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.brandMaroon,
            ),
          ),
        ],
      ),
    );
  }
}
