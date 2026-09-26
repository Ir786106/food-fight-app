class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer', 'admin', 'super_admin'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImage;
  final String? password;
  final List<String>? permissions;

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
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isSuperAdmin => role.toLowerCase() == 'super_admin';
  bool get isAdmin => role.toLowerCase() == 'admin' || isSuperAdmin;
  bool get isCustomer => role.toLowerCase() == 'customer';

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
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
      profileImage: json['profileImage'],
      password: json['password'],
      permissions: parsedPermissions,
    );
  }
}
