import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/safe_convert.dart';
import '../../models/food_model.dart';

class MenuReport {
  const MenuReport({
    required this.id,
    required this.itemName,
    required this.message,
    required this.resolved,
    required this.createdAt,
  });

  final String id;
  final String itemName;
  final String message;
  final bool resolved;
  final DateTime createdAt;

  factory MenuReport.fromJson(String id, Map<String, dynamic> data) =>
      MenuReport(
        id: id,
        itemName: data['menuItemName']?.toString() ??
            'Item ${data['menuItemId'] ?? ''}',
        message: data['message']?.toString() ?? '',
        resolved: data['status'] == 'resolved',
        createdAt: SafeConvert.toDateTime(
            data['createdAt'], DateTime.fromMillisecondsSinceEpoch(0)),
      );
}

abstract final class MenuReportRepository {
  static CollectionReference<Map<String, dynamic>> get _reports =>
      FirebaseFirestore.instance.collection('menuReports');

  static Stream<List<MenuReport>> watch({String? branchId}) {
    final query = branchId == null
        ? _reports
        : _reports.where('branchId', isEqualTo: branchId);
    return query
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              MenuReport.fromJson(doc.id, doc.data()),
          ],
        );
  }

  static Future<void> submit({
    required String userId,
    required FoodModel food,
    required String message,
  }) async {
    await _reports.add({
      'userId': userId,
      'menuItemId': food.id,
      'menuItemName': food.name,
      'branchId': food.branchId,
      'message': message.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setResolved(
    MenuReport report, {
    required String updatedBy,
    required bool resolved,
  }) =>
      _reports.doc(report.id).update({
        'status': resolved ? 'resolved' : 'open',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      });
}
