import '../models/user_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/branch_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/models/admin/audit_log_model.dart';
import 'package:food_fight/models/admin/system_settings_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';

/// Super Admin Service for platform-wide management, admin accounts, settings & audit logs
class SuperAdminService {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static CollectionReference get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  static CollectionReference get _settingsCollection =>
      _firestore.collection(FirestoreCollections.settings);

  static CollectionReference get _auditCollection =>
      _firestore.collection(FirestoreCollections.auditLogs);

  static Future<({List<UserModel> users, bool hasMore})> fetchUserPage({
    required List<String> roles,
    String? after,
  }) async {
    const pageSize = 30;
    Query query = _usersCollection.orderBy(FieldPath.documentId);
    if (roles.isNotEmpty) query = query.where('role', whereIn: roles);
    if (after != null) query = query.startAfter([after]);
    final result = await query.limit(pageSize + 1).get();
    return (
      users: [
        for (final doc in result.docs.take(pageSize))
          UserModel.fromJson(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}),
      ],
      hasMore: result.docs.length > pageSize,
    );
  }

  /// Watch all admin and staff accounts
  static Stream<List<AdminAccountModel>> watchAdminAccounts() {
    return _usersCollection
        .where('role', whereIn: ['admin', 'staff', 'sub_admin', 'super_admin'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return AdminAccountModel.fromJson(data);
          }).toList();
        });
  }

  static Future<HttpsCallableResult<dynamic>> _mutate(
          Map<String, dynamic> input) =>
      FirebaseFunctions.instance.httpsCallable('mutatePlatform').call(input);

  static Future<String> createAdminAccount(AdminAccountModel admin,
      {String? createdBy, BranchModel? newBranch}) async {
    final result = await _mutate({
      'action': 'createAccount',
      ...admin.toJson(),
      if (newBranch != null) 'newBranch': newBranch.toJson(),
    });
    return result.data['userId'] as String;
  }

  static Future<void> updateAdminAccount(AdminAccountModel admin,
      {String? updatedBy}) async {
    await _mutate(
        {'action': 'updateAccount', 'targetId': admin.id, ...admin.toJson()});
  }

  static Future<void> setAdminStatus(String adminId, String newStatus,
      {String? changedBy}) async {
    await _mutate({
      'action': 'setAccountStatus',
      'targetId': adminId,
      'status': newStatus
    });
  }

  static Future<void> setBranchStatus(String branchId,
      {required bool active}) async {
    await _mutate({
      'action': 'setBranchStatus',
      'branchId': branchId,
      'status': active ? 'active' : 'inactive'
    });
  }

  static Future<SystemSettingsModel> getSystemSettings() async {
    final doc = await _settingsCollection.doc('global_settings').get();
    final data = doc.data();
    return data == null
        ? SystemSettingsModel()
        : SystemSettingsModel.fromJson(data as Map<String, dynamic>);
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

  static Future<void> saveSystemSettings(SystemSettingsModel settings,
      {String? savedBy}) async {
    await _mutate({'action': 'saveSettings', 'settings': settings.toJson()});
  }

  /// Watch audit logs ordered by timestamp
  static Stream<List<AuditLogModel>> watchAuditLogs(
      {String? entityFilter, String? search}) {
    Query query =
        _auditCollection.orderBy('timestamp', descending: true).limit(100);

    if (entityFilter != null &&
        entityFilter.isNotEmpty &&
        entityFilter != 'all') {
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
        list = list
            .where((l) =>
                l.description.toLowerCase().contains(q) ||
                l.action.toLowerCase().contains(q) ||
                l.actorName.toLowerCase().contains(q))
            .toList();
      }

      return list;
    });
  }

  // -------------------------------------------------------------
  // PLATFORM-WIDE KPI METRICS
  // -------------------------------------------------------------

  static Future<Map<String, dynamic>> getPlatformMetrics() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getPlatformMetrics')
        .call();
    return Map<String, dynamic>.from(result.data as Map);
  }
}
