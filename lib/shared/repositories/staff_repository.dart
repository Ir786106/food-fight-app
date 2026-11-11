import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/admin/admin_account_model.dart';

abstract final class StaffRepository {
  static Stream<List<AdminAccountModel>> watch({String? branchId}) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: ['admin', 'staff', 'sub_admin']);
    if (branchId != null) query = query.where('branchId', isEqualTo: branchId);
    return query.snapshots().map((snapshot) => [
      for (final doc in snapshot.docs)
        AdminAccountModel.fromJson({...doc.data(), 'id': doc.id}),
    ]);
  }

  static Future<void> setStatus(String userId, String status) async {
    await FirebaseFunctions.instance.httpsCallable('mutatePlatform').call({
      'action': 'setBranchStaffStatus',
      'targetId': userId,
      'status': status,
    });
  }
}
