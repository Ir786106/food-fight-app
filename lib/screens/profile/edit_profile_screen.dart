import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase/supabase_image_storage_service.dart';
import '../../core/config/supabase_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/network_image_view.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _profileImageUrl;
  XFile? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _profileImageUrl = user?.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final img = await SupabaseImageStorageService.pickImage();
    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalPhotoUrl = _profileImageUrl;

      if (_pickedImage != null) {
        final storage = SupabaseImageStorageService();
        finalPhotoUrl = await storage.uploadImage(
          image: _pickedImage!,
          path: SupabaseConfig.profilesFolder,
        );
      }

      final success = await auth.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImage: finalPhotoUrl,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final err = auth.errorMessage ?? 'Failed to update profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar with pick button
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _pickedImage != null
                            ? Image.file(
                                File(_pickedImage!.path),
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              )
                            : NetworkImageView(
                                imageUrl: _profileImageUrl,
                                width: 96,
                                height: 96,
                                fallbackIcon: Icons.person,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Your full name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '0300 1234567',
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
