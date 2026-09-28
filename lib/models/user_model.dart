import '../core/utils/safe_convert.dart';

class UserModel {
  static const String roleCustomer = 'customer';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';
  static const String roleRider = 'delivery_rider';

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer', 'admin', 'super_admin', 'delivery_rider'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImage;
  final String? password;
  final List<String>? permissions;
  final String? branchId;
  final String? parentAdminId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'customer',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.profileImage,
    this.password,
    this.permissions,
    this.branchId,
    this.parentAdminId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isSuperAdmin => role.toLowerCase() == 'super_admin';
  bool get isAdmin => role.toLowerCase() == 'admin' || isSuperAdmin;
  bool get isCustomer => role.toLowerCase() == 'customer';
  bool get isRider =>
      role.toLowerCase() == 'delivery_rider' || role.toLowerCase() == 'rider';

  /// Whether this account is a Sub-Admin under a parent Branch Admin
  bool get isSubAdmin =>
      role.toLowerCase() == roleAdmin &&
      parentAdminId != null &&
      parentAdminId!.isNotEmpty;

  /// Check granular permission for Admin/Sub-Admin
  bool can(String permission) {
    if (isSuperAdmin) return true;
    if (!isAdmin) return false;
    // Primary Branch Admin has all permissions under their branch
    if (parentAdminId == null || parentAdminId!.isEmpty) return true;
    // Sub-Admin is checked against granted permission list
    if (permissions == null || permissions!.isEmpty) return false;
    return permissions!.contains(permission);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImage,
    String? password,
    List<String>? permissions,
    String? branchId,
    String? parentAdminId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImage: profileImage ?? this.profileImage,
      password: password ?? this.password,
      permissions: permissions ?? this.permissions,
      branchId: branchId ?? this.branchId,
      parentAdminId: parentAdminId ?? this.parentAdminId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'profileImage': profileImage,
      if (password != null) 'password': password,
      if (permissions != null) 'permissions': permissions,
      if (branchId != null) 'branchId': branchId,
      if (parentAdminId != null) 'parentAdminId': parentAdminId,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String>? parsedPermissions;
    if (json['permissions'] is List) {
      parsedPermissions = List<String>.from(json['permissions']);
    }

    return UserModel(
      id: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
      profileImage: json['profileImage'],
      password: json['password'],
      permissions: parsedPermissions,
      branchId: json['branchId']?.toString() ?? json['branch_id']?.toString(),
      parentAdminId: json['parentAdminId']?.toString() ?? json['parent_admin_id']?.toString(),
    );
  }
}
