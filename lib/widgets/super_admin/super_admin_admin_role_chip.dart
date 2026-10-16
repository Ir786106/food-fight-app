import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Role Badge Chip distinguishing Super Admin, Branch Admin, and Sub-Admin
class SuperAdminAdminRoleChip extends StatelessWidget {
  final String role;
  final String? branchName;

  const SuperAdminAdminRoleChip({
    super.key,
    required this.role,
    this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    final cleanRole = role.toLowerCase().trim();
    Color bg;
    Color fg;
    String label;

    if (cleanRole == 'super_admin' || cleanRole == 'superadmin') {
      bg = AppColors.brandMaroon;
      fg = AppColors.brandYellow;
      label = 'SUPER ADMIN (HQ)';
    } else if (cleanRole == 'sub_admin' || cleanRole == 'subadmin') {
      bg = AppColors.infoSoft;
      fg = AppColors.info;
      label = branchName != null ? 'SUB-ADMIN ($branchName)' : 'SUB-ADMIN';
    } else {
      bg = AppColors.yellowSoft;
      fg = AppColors.brandMaroon;
      label = branchName != null ? 'BRANCH ADMIN ($branchName)' : 'BRANCH ADMIN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
