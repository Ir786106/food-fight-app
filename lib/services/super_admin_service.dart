import '../models/user_model.dart';
import 'trusted_operations.dart';
import '../models/branch_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  static Future<dynamic> _mutate(Map<String, dynamic> input) =>
      TrustedOperations.call('mutatePlatform', input);

  static Future<String> createAdminAccount(AdminAccountModel admin,
      {String? createdBy, BranchModel? newBranch}) async {
    final result = await _mutate({
      'action': 'createAccount',
      ...admin.toJson(),
      if (newBranch != null) 'newBranch': newBranch.toJson(),
    });
    return result['userId'] as String;
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
    final users = _firestore.collection(FirestoreCollections.users);
    final orders = _firestore.collection(FirestoreCollections.orders);
    final delivered = orders.where('status', isEqualTo: 'delivered');
    final queries = {
      'totalRestaurants':
          _firestore.collection(FirestoreCollections.restaurants),
      'totalBranches': _firestore.collection(FirestoreCollections.branches),
      'totalCustomers': users.where('role', isEqualTo: 'customer'),
      'totalAdmins': users.where('role', isEqualTo: 'admin'),
      'totalStaff': users.where('role', whereIn: ['staff', 'sub_admin']),
      'totalRiders': users.where('role', whereIn: ['rider', 'delivery_rider']),
      'activeRiders': _firestore
          .collection(FirestoreCollections.riders)
          .where('isOnline', whereIn: [true, 1]),
      'totalOrders': orders,
      'completedOrders': delivered,
      'cancelledOrders': orders.where('status', isEqualTo: 'cancelled'),
    };
    final totals = await Future.wait(queries.entries.map((entry) async =>
        MapEntry(entry.key, (await entry.value.count().get()).count ?? 0)));
    final metrics = <String, dynamic>{...Map.fromEntries(totals)};

    // The native Windows Firestore plugin supports count, but omits sum.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return metrics;
    }

    final today = DateTime.now().toUtc();
    final startOfToday = DateTime.utc(today.year, today.month, today.day);
    final deliveredGmv = delivered.aggregate(sum('total')).get();
    final dailySales = Future.wait(List.generate(7, (index) async {
      final start = startOfToday.subtract(Duration(days: 6 - index));
      final end = start.add(const Duration(days: 1));
      final day = await delivered
          .where('createdAt',
              isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
          .where('createdAt', isLessThan: end.millisecondsSinceEpoch)
          .orderBy('createdAt', descending: true)
          .aggregate(sum('total'), count())
          .get();
      return {
        'date': start.millisecondsSinceEpoch,
        'revenue': day.getSum('total') ?? 0,
        'ordersCount': day.count ?? 0,
      };
    }));
    final results = await Future.wait<Object>([deliveredGmv, dailySales]);
    metrics['deliveredGmv'] =
        (results[0] as AggregateQuerySnapshot).getSum('total') ?? 0;
    metrics['dailySales'] = results[1];
    return metrics;
  }
}
