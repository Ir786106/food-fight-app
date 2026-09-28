import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/google_sign_in_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions to proceed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } else {
      final error = auth.errorMessage ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
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
      if (auth.isAdmin) {
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
              height: size.height * 0.30 > 220 ? size.height * 0.30 : 220,
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
                    // Back button
                    Positioned(
                      top: 10,
                      left: 12,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    // Decorative glow circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
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
                              width: 86,
                              height: 86,
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
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Join Food Fight',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create an account to start ordering',
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

            // Form Card floating over hero
            Transform.translate(
              offset: const Offset(0, -24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quick and easy setup — join our food arena',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Full Name
                          CustomTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'John Doe',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter your email';
                              final normalized = v.trim().toLowerCase();
                              if (!normalized.contains('@') || !normalized.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Phone
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: '0300 1234567',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Min 6 characters',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter a password';
                              if (v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Terms & Conditions Checkbox (Cleanly constrained to prevent horizontal overflow)
                          InkWell(
                            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'I agree to the Terms & Conditions and Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Primary Sign Up Button
                          CustomButton(
                            text: 'Create Account',
                            isLoading: _isLoading,
                            onPressed: _handleSignup,
                          ),
                          const SizedBox(height: 20),

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
                          const SizedBox(height: 18),

                          // Google Sign-Up Button
                          GoogleSignInButton(
                            text: 'Sign up with Google',
                            isLoading: _isGoogleLoading,
                            onPressed: _handleGoogleSignIn,
                          ),
                          const SizedBox(height: 22),

                          // Log in prompt
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Log In',
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
