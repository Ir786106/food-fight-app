import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tall Branded Hero Header with Gradient
            Container(
              width: double.infinity,
              height: size.height * 0.34 > 240 ? size.height * 0.34 : 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary,
                    Color(0xFF2E1A11),
                    Color(0xFF230F0A),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Decorative glow circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Centered branding header
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppConstants.logoPath,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'FOOD FIGHT',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Flavors that punch above the rest',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form container floating over background
            Transform.translate(
              offset: const Offset(0, -28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.7 : 0.8),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : AppColors.darkBrown.withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 22),

                          // Email
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'name@example.com',
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter your email';
                              if (!value.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          CustomTextField(
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
                          const SizedBox(height: 12),

                          // Primary Log In Button
                          CustomButton(
                            text: 'Log In',
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 22),

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
                          const SizedBox(height: 20),

                          // Google Sign-In Button
                          GoogleSignInButton(
                            isLoading: _isGoogleLoading,
                            onPressed: _handleGoogleSignIn,
                          ),
                          const SizedBox(height: 24),

                          // Sign up prompt
                          Wrap(
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
                                onTap: () => Navigator.of(context).pushNamed('/signup'),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
