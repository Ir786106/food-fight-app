import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/google_sign_in_button.dart';
import '../../core/utils/validator_utils.dart';

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

  void _handleBackPress(bool didPop) {
    if (didPop) return;

    if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    Navigator.of(context).pop();
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

                      // Form Card floating over hero
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
                                    key: const ValueKey('name_input_field'),
                                    fieldKey: const ValueKey('name_field'),
                                    semanticsLabel: 'Full Name Field',
                                    controller: _nameController,
                                    label: 'Full Name',
                                    hint: 'John Doe',
                                    icon: Icons.person_outline_rounded,
                                    validator: (v) => ValidatorUtils.validateRequired(v, fieldName: 'Full Name'),
                                  ),
                                  const SizedBox(height: 14),

                                  // Email
                                  CustomTextField(
                                    key: const ValueKey('signup_email_input_field'),
                                    fieldKey: const ValueKey('email_field'),
                                    semanticsLabel: 'Email Address Field',
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hint: 'you@example.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: ValidatorUtils.validateEmail,
                                  ),
                                  const SizedBox(height: 14),

                                  // Phone
                                  CustomTextField(
                                    key: const ValueKey('phone_input_field'),
                                    fieldKey: const ValueKey('phone_field'),
                                    semanticsLabel: 'Pakistan Mobile Phone Field',
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    hint: '0300 1234567',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: ValidatorUtils.validatePhone,
                                  ),
                                  const SizedBox(height: 14),

                                  // Password
                                  CustomTextField(
                                    key: const ValueKey('signup_password_input_field'),
                                    fieldKey: const ValueKey('signup_password_field'),
                                    toggleKey: const ValueKey('signup_password_visibility_toggle'),
                                    semanticsLabel: 'Password Field',
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Min 6 characters',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    validator: (v) => ValidatorUtils.validatePassword(v, minLength: 6),
                                  ),
                                  const SizedBox(height: 14),

                                  // Confirm Password
                                  CustomTextField(
                                    key: const ValueKey('confirm_password_input_field'),
                                    fieldKey: const ValueKey('confirm_password_field'),
                                    toggleKey: const ValueKey('confirm_password_visibility_toggle'),
                                    semanticsLabel: 'Confirm Password Field',
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter your password',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Please confirm your password';
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Terms & Conditions Checkbox
                                  InkWell(
                                    key: const ValueKey('terms_checkbox'),
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
                                    key: const ValueKey('create_account_button'),
                                    semanticsLabel: 'Create Account Button',
                                    text: 'Create Account',
                                    isLoading: _isLoading,
                                    onPressed: _handleSignup,
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

                                  // Google Sign-Up Button
                                  GoogleSignInButton(
                                    key: const ValueKey('google_signup_button'),
                                    semanticsLabel: 'Sign up with Google Button',
                                    text: 'Sign up with Google',
                                    isLoading: _isGoogleLoading,
                                    onPressed: _handleGoogleSignIn,
                                  ),
                                  const SizedBox(height: 20),

                                  // Log in prompt
                                  Center(
                                    child: Wrap(
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
                                          key: const ValueKey('login_link'),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => Navigator.of(context).pop(),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 4),
                                            child: Text(
                                              'Log In',
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
    final headerHeight = (size.height * 0.24).clamp(160.0, 210.0);

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
          // Back button
          Positioned(
            top: 10,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brandMaroon),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
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
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join Food Fight',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandMaroon,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Create an account to start ordering',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brandMaroon),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: Image.asset(
              AppConstants.logoPath,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Join Food Fight',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandMaroon,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'Create an account to start ordering',
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
