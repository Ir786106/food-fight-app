import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../../services/branch_service.dart';
import '../../services/option_template_service.dart';

/// Database Seed & Migration Script for Food Fight Platform
/// Initializes global settings, 5 branches, option templates, and migrates
/// existing admin & rider user records so permissions and branch isolation work properly.
class DatabaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> runMigrationAndSeed() async {
    final results = <String, dynamic>{
      'globalSettingsCreated': false,
      'branchesSeeded': false,
      'templatesSeeded': false,
      'usersUpdated': 0,
    };

    try {
      AppLogger.info('Starting Food Fight database migration and seed...', tag: 'DatabaseSeeder');

      // 1. Ensure settings/global_settings exists
      final settingsRef = _firestore.collection('settings').doc('global_settings');
      final settingsDoc = await settingsRef.get();
      if (!settingsDoc.exists) {
        await settingsRef.set({
          'orderCancellationWindowMinutes': 10,
          'defaultDeliveryCharge': 150.0,
          'isStoreOpen': true,
          'isMaintenanceMode': false,
          'allowCashOnDelivery': true,
          'allowOnlinePayment': true,
          'welcomeTokens': 50,
          'loyaltyEarnRate': 100,
          'loyaltyRedeemRate': 1.0,
          'minTokensToRedeem': 10,
          'emailNotificationsEnabled': true,
          'smsNotificationsEnabled': true,
          'pushNotificationsEnabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        results['globalSettingsCreated'] = true;
        AppLogger.info('global_settings seeded successfully', tag: 'DatabaseSeeder');
      } else {
        // Ensure new loyalty fields are present
        await settingsRef.set({
          'welcomeTokens': settingsDoc.data()?['welcomeTokens'] ?? 50,
          'loyaltyEarnRate': settingsDoc.data()?['loyaltyEarnRate'] ?? 100,
          'loyaltyRedeemRate': settingsDoc.data()?['loyaltyRedeemRate'] ?? 1.0,
          'minTokensToRedeem': settingsDoc.data()?['minTokensToRedeem'] ?? 10,
          'orderCancellationWindowMinutes': settingsDoc.data()?['orderCancellationWindowMinutes'] ?? 10,
          'defaultDeliveryCharge': settingsDoc.data()?['defaultDeliveryCharge'] ?? 150.0,
          'isStoreOpen': settingsDoc.data()?['isStoreOpen'] ?? true,
          'isMaintenanceMode': settingsDoc.data()?['isMaintenanceMode'] ?? false,
          'allowCashOnDelivery': settingsDoc.data()?['allowCashOnDelivery'] ?? true,
          'allowOnlinePayment': settingsDoc.data()?['allowOnlinePayment'] ?? true,
        }, SetOptions(merge: true));
      }

      // 2. Seed 5 physical branches if empty
      await BranchService.seedInitialBranchesIfEmpty();
      results['branchesSeeded'] = true;

      // 3. Seed Option Templates (Size sets, Dips, Toppings)
      final templateService = OptionTemplateService();
      await templateService.seedDefaultTemplatesIfEmpty();
      results['templatesSeeded'] = true;

      // 4. Migrate User Documents: ensure branchId, role, and permissions are valid
      final usersSnap = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      int updatedCount = 0;

      final branchesSnap = await _firestore.collection('branches').get();
      final defaultBranchId = branchesSnap.docs.isNotEmpty ? branchesSnap.docs.first.id : 'branch_1';

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final role = data['role']?.toString().toLowerCase() ?? 'customer';
        final updates = <String, dynamic>{};

        if (role == 'admin') {
          if (data['branchId'] == null || data['branchId'].toString().isEmpty) {
            updates['branchId'] = defaultBranchId;
          }
          if (data['permissions'] == null) {
            updates['permissions'] = [
              'orders',
              'menu',
              'categories',
              'customers',
              'delivery_areas',
              'riders',
              'coupons',
              'deals',
              'reviews',
              'reports',
              'chats',
            ];
          }
        } else if (role == 'sub_admin') {
          if (data['branchId'] == null || data['branchId'].toString().isEmpty) {
            updates['branchId'] = defaultBranchId;
          }
          if (data['parentAdminId'] == null) {
            updates['parentAdminId'] = 'admin';
          }
        } else if (role == 'delivery_rider' || role == 'rider') {
          if (data['branchId'] == null || data['branchId'].toString().isEmpty) {
            updates['branchId'] = defaultBranchId;
          }
          if (data['status'] == null) {
            updates['status'] = 'active';
          }
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        AppLogger.info('Migrated $updatedCount user documents with branch & permissions', tag: 'DatabaseSeeder');
      }
      results['usersUpdated'] = updatedCount;

      return results;
    } catch (e, stack) {
      AppLogger.error('Database migration/seed error: $e\n$stack', tag: 'DatabaseSeeder');
      rethrow;
    }
  }
}
