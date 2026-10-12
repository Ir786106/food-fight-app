import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../services/firebase/firebase_auth_service.dart';
import '../../core/utils/logger.dart';
import '../../core/metrics/app_startup_metrics.dart';

/// Professional restaurant splash screen displaying the official FoodFight logo.
class SplashScreen extends StatefulWidget {
  final Stopwatch? startupStopwatch;

  const SplashScreen({super.key, this.startupStopwatch});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('[PERF] SplashScreen initState reached', tag: 'Splash');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.85, curve: Curves.easeIn),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Start route resolution immediately in parallel with the 1.4s animation
    _startParallelRouting();
  }

  void _startParallelRouting() {
    final minAnimationDelay = Future.delayed(const Duration(milliseconds: 1400));
    final routeResolution = _decideDestinationRoute();

    Future.wait([minAnimationDelay, routeResolution])
        .timeout(
          const Duration(milliseconds: 3800),
          onTimeout: () => [null, _fallbackOfflineRoute()],
        )
        .then((results) {
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;

      final destination = (results.length > 1 && results[1] != null)
          ? results[1] as String
          : _fallbackOfflineRoute();

      final elapsed = widget.startupStopwatch?.elapsedMilliseconds ?? AppStartupMetrics.elapsedMs;
      AppLogger.info(
        '[PERF] Cold start to routed screen: $destination at +${elapsed}ms',
        tag: 'Performance',
      );

      Navigator.of(context).pushReplacementNamed(destination);
    }).catchError((e) {
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      final fallback = _fallbackOfflineRoute();
      Navigator.of(context).pushReplacementNamed(fallback);
    });
  }

  Future<String> _decideDestinationRoute() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompleted =
            prefs.getBool(AppConstants.storageOnboardingCompleted) ?? false;
        return onboardingCompleted ? '/login' : '/onboarding';
      }

      // User has active session: load cached profile instantly
      final auth = context.read<AuthProvider>();
      await auth.init(preferCache: true).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          AppLogger.warn('Auth cache init exceeded 2s, using direct cached role', tag: 'Splash');
        },
      );

      if (auth.isLoggedIn && auth.currentUser != null) {
        return _resolveRoleRoute(auth.currentUser!.role);
      }

      // If network is slow or offline, use local cached role
      final cachedRole = await FirebaseAuthService.getCachedUserRole(firebaseUser.uid);
      return _resolveRoleRoute(cachedRole ?? 'customer');
    } catch (e) {
      AppLogger.warn('Route determination notice: $e', tag: 'Splash');
      return _fallbackOfflineRoute();
    }
  }

  String _resolveRoleRoute(String? role) {
    final normalized = (role ?? '').trim().toLowerCase();
    if (normalized == 'superadmin' || normalized == 'super_admin') {
      return '/super-admin/dashboard';
    } else if (normalized == 'admin') {
      return '/admin/dashboard';
    } else if (normalized == 'rider') {
      return '/rider/dashboard';
    } else {
      return '/home';
    }
  }

  String _fallbackOfflineRoute() {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      // Logged-in user is NEVER sent to /login just because network is offline or slow!
      if (firebaseUser != null) {
        return '/home';
      }
    } catch (_) {
      // In headless test environments where Firebase is not initialized
    }
    return '/login';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = (size.width * 0.52).clamp(160.0, 220.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryYellow,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient background glow circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              top: 140,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth entrance for official FoodFight logo
                      FadeTransition(
                        opacity: _logoFade,
                        child: SlideTransition(
                          position: _logoSlide,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppConstants.logoPath,
                                  width: logoSize,
                                  height: logoSize,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tagline & loading indicator
                      FadeTransition(
                        opacity: _taglineFade,
                        child: SlideTransition(
                          position: _taglineSlide,
                          child: const Column(
                            children: [
                              Text(
                                AppConstants.appTagline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.brandMaroon,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(height: 36),
                              SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.brandMaroon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
