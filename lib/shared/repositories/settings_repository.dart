import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class SettingsRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Stream<Map<String, dynamic>> watchPublicSettings() => _db
      .collection('settings')
      .doc('global_settings')
      .snapshots()
      .map((snapshot) => snapshot.data() ?? const {});

  static Future<void> savePreference(String userId, String key, bool value) =>
      _db.collection('users').doc(userId).set({
        'preferences': {key: value},
      }, SetOptions(merge: true));
}
