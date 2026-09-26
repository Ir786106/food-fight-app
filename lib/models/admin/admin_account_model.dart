/// Admin Account Model for Super Admin management
class AdminAccountModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'admin', 'staff', 'super_admin'
  final String status; // 'active', 'suspended', 'deactivated'
  final List<String> permissions; // e.g., 'manage_menu', 'manage_orders', 'view_reports', 'manage_coupons'
  final String? restaurantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  AdminAccountModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'admin',
    this.status = 'active',
    List<String>? permissions,
    this.restaurantId = 'food_fight_hq',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
  })  : permissions = permissions ?? const ['manage_menu', 'manage_orders', 'manage_coupons', 'view_reports'],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isDeactivated => status == 'deactivated';

  AdminAccountModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    List<String>? permissions,
    String? restaurantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return AdminAccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      restaurantId: restaurantId ?? this.restaurantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'permissions': permissions,
      'restaurantId': restaurantId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.millisecondsSinceEpoch,
    };
  }

  factory AdminAccountModel.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    if (json['permissions'] is List) {
      perms = List<String>.from(json['permissions']);
    }

    return AdminAccountModel(
      id: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'admin',
      status: json['status'] ?? (json['isActive'] == 1 || json['isActive'] == true ? 'active' : 'suspended'),
      permissions: perms,
      restaurantId: json['restaurantId'] ?? 'food_fight_hq',
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'] as int)
          : null,
    );
  }

  factory AdminAccountModel.fromMap(Map<String, dynamic> map) =>
      AdminAccountModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
