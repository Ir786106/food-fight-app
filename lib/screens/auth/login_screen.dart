import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  DateTime? _lastBackPressTime;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleBackPress(bool didPop) {
    if (didPop) return;

    // 1. If keyboard has focus, dismiss keyboard first
    if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    // 2. Double-back to exit on root login screen
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exit_to_app_rounded, color: AppColors.brandMaroon, size: 20),
              SizedBox(width: 10),
              Text(
                'Press back again to exit Food Fight',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandMaroon),
              ),
            ],
          ),
          backgroundColor: AppColors.brandYellow,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (auth.isSuperAdmin) {
        Navigator.of(context).pushNamedAndRemoveUntil('/super-admin/dashboard', (r) => false);
      } else if (auth.isAdmin) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false);
      } else if (auth.isRider) {
        Navigator.of(context).pushNamedAndRemoveUntil('/rider/dashboard', (r) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } else {
      final error = auth.errorMessage ?? 'Login failed. Please check your credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      if (auth.isSuperAdmin) {
        Navigator.of(context).pushNamedAndRemoveUntil('/super-admin/dashboard', (r) => false);
      } else if (auth.isAdmin) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false);
      } else if (auth.isRider) {
        Navigator.of(context).pushNamedAndRemoveUntil('/rider/dashboard', (r) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isLandscape && size.height < 540;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBackPress(didPop),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      // Responsive Branded Header
                      if (isCompactLandscape)
                        _buildCompactHeader()
                      else
                        _buildStandardHeader(size),

                      // Form Container with reliable gesture hit testing
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isCompactLandscape ? 16 : 20,
                              vertical: isCompactLandscape ? 8 : 12,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.7 : 0.8),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : AppColors.darkBrown.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Log in to your account to order delicious meals',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Email
                                  CustomTextField(
                                    key: const ValueKey('email_input_field'),
                                    fieldKey: const ValueKey('email_field'),
                                    semanticsLabel: 'Email Address Field',
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hint: 'name@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    icon: Icons.email_outlined,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) return 'Enter your email';
                                      if (!value.contains('@') || !value.contains('.')) return 'Enter a valid email address';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Password
                                  CustomTextField(
                                    key: const ValueKey('password_input_field'),
                                    fieldKey: const ValueKey('password_field'),
                                    toggleKey: const ValueKey('password_visibility_toggle'),
                                    semanticsLabel: 'Password Field',
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: '••••••••',
                                    isPassword: true,
                                    icon: Icons.lock_outline_rounded,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Enter your password';
                                      if (value.length < 6) return 'Password must be at least 6 characters';
                                      return null;
                                    },
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      key: const ValueKey('forgot_password_button'),
                                      onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Primary Log In Button
                                  CustomButton(
                                    key: const ValueKey('login_button'),
                                    semanticsLabel: 'Log In Button',
                                    text: 'Log In',
                                    isLoading: _isLoading,
                                    onPressed: _handleLogin,
                                  ),
                                  const SizedBox(height: 18),

                                  // Horizontal "OR" Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Google Sign-In Button
                                  GoogleSignInButton(
                                    key: const ValueKey('google_signin_button'),
                                    semanticsLabel: 'Continue with Google Button',
                                    isLoading: _isGoogleLoading,
                                    onPressed: _handleGoogleSignIn,
                                  ),
                                  const SizedBox(height: 20),

                                  // Sign up prompt
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        GestureDetector(
                                          key: const ValueKey('signup_button'),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => Navigator.of(context).pushNamed('/signup'),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 4),
                                            child: Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStandardHeader(Size size) {
    final headerHeight = (size.height * 0.26).clamp(170.0, 230.0);

    return Container(
      width: double.infinity,
      height: headerHeight,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Decorative glow circles
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellowSoft.withValues(alpha: 0.45),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppConstants.logoPath,
                        width: 76,
                        height: 76,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FOOD FIGHT',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandMaroon,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Flavors that punch above the rest',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.maroonDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              AppConstants.logoPath,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FOOD FIGHT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandMaroon,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'Flavors that punch above the rest',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.maroonDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
