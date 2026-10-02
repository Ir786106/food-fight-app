import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Fully offline / local authentication.
/// No backend or internet required — user records are stored on-device
/// using SharedPreferences under the key "ff_users", and the currently
/// logged-in user under "ff_current_user".
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  static const String _usersKey = 'ff_users';
  static const String _currentUserKey = 'ff_current_user';

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Load current session (if any) — call on app start.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<List<UserModel>> _getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getStringList(_usersKey) ?? [];
    return usersString
        .map((u) => UserModel.fromJson(jsonDecode(u)))
        .toList();
  }

  Future<void> _saveAllUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(_usersKey, usersString);
  }

  /// Sign up a new user locally. Returns null on success, error message otherwise.
  Future<String?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 700)); // simulate work

    final users = await _getAllUsers();
    final exists = users.any((u) => normalizeEmail(u.email) == normalizedEmail);
    if (exists) {
      _setLoading(false);
      return 'An account with this email already exists.';
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: normalizedEmail,
      phone: phone,
      password: password,
    );
    users.add(newUser);
    await _saveAllUsers(users);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));
    _currentUser = newUser;

    _setLoading(false);
    notifyListeners();
    return null;
  }

  /// Log in with email/password against locally stored users.
  /// Returns null on success, error message otherwise.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 700));

    final users = await _getAllUsers();
    UserModel? matched;
    for (final u in users) {
      if (normalizeEmail(u.email) == normalizedEmail && u.password == password) {
        matched = u;
        break;
      }
    }

    if (matched == null) {
      _setLoading(false);
      return 'Email or password is incorrect.';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(matched.toJson()));
    _currentUser = matched;

    _setLoading(false);
    notifyListeners();
    return null;
  }

  /// Simulated "forgot password" reset — since app is offline, it directly
  /// updates the stored password for the matching local account.
  /// Returns null on success, error message otherwise.
  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 700));

    final users = await _getAllUsers();
    final index = users.indexWhere((u) => normalizeEmail(u.email) == normalizedEmail);
    if (index == -1) {
      _setLoading(false);
      return 'No account found with this email.';
    }

    final old = users[index];
    final updated = UserModel(
      id: old.id,
      name: old.name,
      email: normalizedEmail,
      phone: old.phone,
      password: newPassword,
      profileImage: old.profileImage,
    );
    users[index] = updated;
    await _saveAllUsers(users);

    _setLoading(false);
    notifyListeners();
    return null;
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    final users = await _getAllUsers();
    final index = users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      await _saveAllUsers(users);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
