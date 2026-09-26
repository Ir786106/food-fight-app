import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _otpVerified = false;

  void _verifyOtp() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 4) {
      setState(() => _otpVerified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleReset(String email) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final error = await auth.resetPassword(
      email: email,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: const Text(
              'Your password has been reset. You can now log in.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (r) => false),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otpVerified ? 'Set New Password' : 'Verify Code',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otpVerified
                        ? 'Create a new password for $email'
                        : 'Enter the 4-digit code sent to $email (offline demo: use any 4 digits)',
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  if (!_otpVerified) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 64,
                          height: 64,
                          child: TextField(
                            controller: _otpControllers[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              counterText: '',
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 3) {
                                FocusScope.of(context).nextFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    CustomButton(text: 'Verify Code', onPressed: _verifyOtp),
                  ] else ...[
                    CustomTextField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      hint: 'Enter new password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password';
                        if (v.length < 4) return 'Minimum 4 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      hint: 'Re-enter new password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) {
                        if (v != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Reset Password',
                      isLoading: _isLoading,
                      onPressed: () => _handleReset(email),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
