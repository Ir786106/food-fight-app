import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Utility class for storage operations
class StorageUtils {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _storagePrefix = 'ff_';

  // Shared Preferences helpers
  static Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString('$_storagePrefix$key', value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_storagePrefix$key');
  }

  static Future<bool> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt('$_storagePrefix$key', value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_storagePrefix$key');
  }

  static Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool('$_storagePrefix$key', value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_storagePrefix$key');
  }

  static Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove('$_storagePrefix$key');
  }

  // Secure storage helpers (for sensitive data)
  static Future<void> saveSecret(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecret(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecret(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> deleteAllSecrets() async {
    await _secureStorage.deleteAll();
  }

  // Clear all storage
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await deleteAllSecrets();
  }
}
