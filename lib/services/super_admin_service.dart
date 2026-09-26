import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/models/admin/audit_log_model.dart';
import 'package:food_fight/models/admin/system_settings_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Super Admin Service for platform-wide management, admin accounts, settings & audit logs
class SuperAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final CollectionReference _usersCollection =
      _firestore.collection(FirestoreCollections.users);

  static final CollectionReference _settingsCollection =
      _firestore.collection(FirestoreCollections.settings);

  static final CollectionReference _auditCollection =
      _firestore.collection(FirestoreCollections.auditLogs);

  static final CollectionReference _ordersCollection =
      _firestore.collection(FirestoreCollections.orders);

  // -------------------------------------------------------------
  // ADMIN ACCOUNT MANAGEMENT
  // -------------------------------------------------------------

  /// Watch all admin and staff accounts
  static Stream<List<AdminAccountModel>> watchAdminAccounts() {
    return _usersCollection
        .where('role', whereIn: ['admin', 'staff', 'super_admin'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AdminAccountModel.fromJson(data);
      }).toList();
    });
  }

  /// Create a new Admin or Staff account
  static Future<String> createAdminAccount(AdminAccountModel admin, {String? createdBy}) async {
    final docRef = _usersCollection.doc();
    final data = admin.toJson();
    data['id'] = docRef.id;
    await docRef.set(data);

    // Write audit log
    await recordAuditLog(AuditLogModel(
      id: '',
      action: 'admin_created',
      actorName: createdBy ?? 'Super Admin',
      actorEmail: '',
      actorRole: 'super_admin',
      targetEntity: 'admin_account',
      targetId: docRef.id,
      description: 'Created new ${admin.role} account for ${admin.name} (${admin.email})',
    ));

    AppLogger.info('Created admin account: ${admin.email}', tag: 'SuperAdminService');
    return docRef.id;
  }

  /// Update admin account (status, permissions, phone, name)
  static Future<void> updateAdminAccount(AdminAccountModel admin, {String? updatedBy}) async {
    await _usersCollection.doc(admin.id).update(admin.toJson());

    await recordAuditLog(AuditLogModel(
      id: '',
      action: 'admin_updated',
      actorName: updatedBy ?? 'Super Admin',
      actorEmail: '',
      actorRole: 'super_admin',
      targetEntity: 'admin_account',
      targetId: admin.id,
      description: 'Updated ${admin.name}\'s profile and permissions',
    ));

    AppLogger.info('Updated admin account: ${admin.id}', tag: 'SuperAdminService');
  }

  /// Change status: 'active', 'suspended', 'deactivated'
  static Future<void> setAdminStatus(String adminId, String newStatus, {String? changedBy}) async {
    await _usersCollection.doc(adminId).update({
      'status': newStatus,
      'isActive': newStatus == 'active' ? 1 : 0,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await recordAuditLog(AuditLogModel(
      id: '',
      action: 'admin_status_changed',
      actorName: changedBy ?? 'Super Admin',
      actorEmail: '',
      actorRole: 'super_admin',
      targetEntity: 'admin_account',
      targetId: adminId,
      description: 'Changed admin account status to "$newStatus"',
    ));

    AppLogger.info('Changed admin status $adminId -> $newStatus', tag: 'SuperAdminService');
  }

  // -------------------------------------------------------------
  // SYSTEM SETTINGS
  // -------------------------------------------------------------

  /// Fetch global platform settings
  static Future<SystemSettingsModel> getSystemSettings() async {
    try {
      final doc = await _settingsCollection.doc('global_settings').get();
      if (!doc.exists || doc.data() == null) {
        final defaultSettings = SystemSettingsModel();
        await _settingsCollection.doc('global_settings').set(defaultSettings.toJson());
        return defaultSettings;
      }
      return SystemSettingsModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Error fetching system settings: $e', tag: 'SuperAdminService');
      return SystemSettingsModel();
    }
  }

  /// Watch global settings in real-time
  static Stream<SystemSettingsModel> watchSystemSettings() {
    return _settingsCollection.doc('global_settings').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return SystemSettingsModel();
      }
      return SystemSettingsModel.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  /// Save system settings
  static Future<void> saveSystemSettings(SystemSettingsModel settings, {String? savedBy}) async {
    await _settingsCollection.doc('global_settings').set(settings.toJson());

    await recordAuditLog(AuditLogModel(
      id: '',
      action: 'settings_updated',
      actorName: savedBy ?? 'Super Admin',
      actorEmail: '',
      actorRole: 'super_admin',
      targetEntity: 'system',
      targetId: 'global_settings',
      description: 'Modified platform configuration and notification policies',
    ));

    AppLogger.info('Saved system settings', tag: 'SuperAdminService');
  }

  // -------------------------------------------------------------
  // AUDIT LOGS
  // -------------------------------------------------------------

  /// Record an audit log entry
  static Future<void> recordAuditLog(AuditLogModel log) async {
    try {
      final docRef = _auditCollection.doc();
      final data = log.toJson();
      data['id'] = docRef.id;
      await docRef.set(data);
    } catch (e) {
      AppLogger.error('Failed to write audit log: $e', tag: 'SuperAdminService');
    }
  }

  /// Watch audit logs ordered by timestamp
  static Stream<List<AuditLogModel>> watchAuditLogs({String? entityFilter, String? search}) {
    Query query = _auditCollection.orderBy('timestamp', descending: true).limit(100);

    if (entityFilter != null && entityFilter.isNotEmpty && entityFilter != 'all') {
      query = query.where('targetEntity', isEqualTo: entityFilter);
    }

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AuditLogModel.fromJson(data);
      }).toList();

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list.where((l) =>
            l.description.toLowerCase().contains(q) ||
            l.action.toLowerCase().contains(q) ||
            l.actorName.toLowerCase().contains(q)).toList();
      }

      return list;
    });
  }

  // -------------------------------------------------------------
  // PLATFORM-WIDE KPI METRICS
  // -------------------------------------------------------------

  /// Load platform-wide aggregate counts
  static Future<Map<String, dynamic>> getPlatformMetrics() async {
    try {
      final usersSnap = await _usersCollection.get();
      final ordersSnap = await _ordersCollection.get();

      int customers = 0;
      int admins = 0;
      int staff = 0;

      for (var doc in usersSnap.docs) {
        final role = ((doc.data() as Map<String, dynamic>)['role'] ?? '').toString().toLowerCase();
        if (role == 'customer') {
          customers++;
        } else if (role == 'admin') {
          admins++;
        } else if (role == 'staff') {
          staff++;
        }
      }

      int totalOrders = ordersSnap.docs.length;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalPlatformRevenue = 0.0;

      for (var doc in ordersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString().toLowerCase();
        final total = (data['total'] ?? 0).toDouble();

        if (status == 'delivered') {
          completedOrders++;
          totalPlatformRevenue += total;
        } else if (status == 'cancelled') {
          cancelledOrders++;
        } else {
          totalPlatformRevenue += total;
        }
      }

      return {
        'totalRestaurants': 1,
        'totalCustomers': customers,
        'totalAdmins': admins,
        'totalStaff': staff,
        'totalRiders': 8,
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'platformRevenue': totalPlatformRevenue,
      };
    } catch (e) {
      AppLogger.error('Error fetching platform metrics: $e', tag: 'SuperAdminService');
      return {
        'totalRestaurants': 1,
        'totalCustomers': 0,
        'totalAdmins': 0,
        'totalStaff': 0,
        'totalRiders': 0,
        'totalOrders': 0,
        'completedOrders': 0,
        'cancelledOrders': 0,
        'platformRevenue': 0.0,
      };
    }
  }
}
