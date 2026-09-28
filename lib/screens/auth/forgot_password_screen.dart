import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Password Reset Sent'),
          content: Text('A password reset link has been sent to $email. Please check your inbox.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              child: const Text('Return to Login'),
            ),
          ],
        ),
      );
    } else {
      final err = auth.errorMessage ?? 'Failed to send password reset email';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lightCream, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.lock_reset,
                            color: AppColors.primary, size: 34),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your registered email and we\'ll help you reset your password.',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter your email';
                          final normalized = v.trim().toLowerCase();
                          if (!normalized.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Continue',
                        isLoading: _isLoading,
                        onPressed: _handleContinue,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
