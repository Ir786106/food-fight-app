/// Canonical User Roles supported by Food Fight platform
/// Matches security policies defined in firestore.rules
enum UserRole {
  superAdmin,
  admin,
  subAdmin,
  staff,
  rider,
  customer,
  unknown;

  /// Parses any representation of user role string into a canonical [UserRole]
  /// Normalizes case, spaces, hyphens, underscores and aliases.
  static UserRole fromString(dynamic value) {
    if (value == null) return UserRole.customer;
    final raw = value.toString().trim();
    if (raw.isEmpty) return UserRole.customer;

    final normalized = raw
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      case 'superadmin':
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
      case 'branch_admin':
      case 'owner':
        return UserRole.admin;
      case 'subadmin':
      case 'sub_admin':
        return UserRole.subAdmin;
      case 'staff':
        return UserRole.staff;
      case 'delivery_rider':
      case 'rider':
        return UserRole.rider;
      case 'customer':
      case 'user':
        return UserRole.customer;
      default:
        return UserRole.unknown;
    }
  }

  /// Canonical string value for persistence in Firestore and SharedPreferences
  String get firestoreValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.subAdmin:
        return 'sub_admin';
      case UserRole.staff:
        return 'staff';
      case UserRole.rider:
        return 'delivery_rider';
      case UserRole.customer:
      case UserRole.unknown:
        return 'customer';
    }
  }

  /// True if role is Super Administrator
  bool get isSuperAdmin => this == UserRole.superAdmin;

  /// True if role has branch admin clearance (Super Admin, Branch Admin, Sub-Admin, or Staff)
  bool get isAdminLevel =>
      this == UserRole.admin ||
      this == UserRole.subAdmin ||
      this == UserRole.staff ||
      isSuperAdmin;

  /// True if role is delivery rider
  bool get isRider => this == UserRole.rider;

  /// True if role is customer
  bool get isCustomer => this == UserRole.customer;

  /// True if role is staff / sub-admin
  bool get isStaff => this == UserRole.staff || this == UserRole.subAdmin;
}
