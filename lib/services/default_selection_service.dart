import 'package:cloud_firestore/cloud_firestore.dart';

/// Serializes default selections through the owner document. Reading the pointer
/// again on transaction retries prevents two devices from selecting two defaults.
class DefaultSelectionService {
  static Future<void> write({
    required String userId,
    required CollectionReference collection,
    required String pointer,
    required String id,
    Map<String, dynamic>? data,
    bool select = false,
    bool delete = false,
  }) async {
    final db = FirebaseFirestore.instance;
    final owner = db.collection('users').doc(userId);
    final legacy = await collection
        .where('userId', isEqualTo: userId)
        .where('isDefault', whereIn: [1, true])
        .get();
    await db.runTransaction((tx) async {
      final user = await tx.get(owner);
      final target = collection.doc(id);
      final current = await tx.get(target);
      if (current.exists && (current.data() as Map)['userId'] != userId) {
        throw StateError('This entry belongs to another account.');
      }
      if (data == null && !current.exists) throw StateError('Entry no longer exists.');
      final oldId = user.data()?[pointer] as String?;
      final oldRef = oldId == null || oldId.isEmpty ? null : collection.doc(oldId);
      final old = oldRef == null ? null : await tx.get(oldRef);
      final shouldSelect = select || (oldId == id && !delete);
      // Read every legacy default before any write. Clean up old installations.
      final oldDefaults = <DocumentSnapshot>[];
      if (shouldSelect) {
        for (final entry in legacy.docs) {
          if (entry.id != id && entry.id != oldId) {
            oldDefaults.add(await tx.get(entry.reference));
          }
        }
      }
      if (shouldSelect) {
        if (old?.exists == true && oldId != id) tx.update(oldRef!, {'isDefault': 0});
        for (final entry in oldDefaults) {
          if (entry.exists && (entry.data() as Map)['userId'] == userId) {
            tx.update(entry.reference, {'isDefault': 0});
          }
        }
        tx.update(owner, {pointer: id});
      } else if (delete && oldId == id) {
        tx.update(owner, {pointer: FieldValue.delete()});
      }
      if (delete) {
        tx.delete(target);
      } else if (data != null) {
        tx.set(target, {...data, 'isDefault': shouldSelect ? 1 : 0});
      } else {
        tx.update(target, {'isDefault': 1});
      }
    });
  }
}
