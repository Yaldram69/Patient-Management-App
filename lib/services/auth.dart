// lib/services/auth.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AuthService extends ChangeNotifier {
  static const String _settingsBox = 'app_settings';
  static const String _usersBox = 'users_box';
  static const String _currentUserKey = 'current_user_email';
  static const String _rememberKey = 'remember_me';

  bool _loading = false;
  String? _userEmail;

  bool get loading => _loading;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _userEmail != null;

  AuthService();

  Future<Box> _openSettingsBoxIfNeeded() async {
    if (!Hive.isBoxOpen(_settingsBox)) {
      return await Hive.openBox(_settingsBox);
    }
    return Hive.box(_settingsBox);
  }

  Future<Box> _openUsersBoxIfNeeded() async {
    if (!Hive.isBoxOpen(_usersBox)) {
      return await Hive.openBox(_usersBox);
    }
    return Hive.box(_usersBox);
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  /// Try auto-login using saved email in settings **only** if remember_me is true.
  /// Returns true if auto-login succeeded.
  Future<bool> tryAutoLogin() async {
    final settings = await _openSettingsBoxIfNeeded();
    final remember = settings.get(_rememberKey) as bool? ?? false;
    if (!remember) return false;

    final savedEmail = settings.get(_currentUserKey) as String?;
    if (savedEmail == null || savedEmail.isEmpty) return false;

    // Ensure the user still exists in users box (safer for mock implementation)
    final users = await _openUsersBoxIfNeeded();
    if (!users.containsKey(savedEmail)) {
      // saved email not found — clear saved values
      await settings.delete(_currentUserKey);
      await settings.put(_rememberKey, false);
      return false;
    }

    _userEmail = savedEmail;
    notifyListeners();
    return true;
  }

  /// Sign up/register a new account. Returns true on success, false if the
  /// email already exists. (Mock implementation)
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    try {
      final users = await _openUsersBoxIfNeeded();

      // If email exists, fail
      if (users.containsKey(email)) {
        _setLoading(false);
        return false;
      }

      // NOTE: This stores password in plain text (mock). For real apps:
      // - Hash passwords with a secure algorithm (bcrypt, argon2).
      // - Use a secure backend or platform auth provider.
      await users.put(email, password);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Login using persisted users (mock).
  ///
  /// If [rememberMe] is true, the user's email will be saved to the settings box
  /// and used for auto-login on next app start. If false, the login is session-only
  /// and nothing persistent is stored.
  ///
  /// Returns true on success.
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    try {
      final users = await _openUsersBoxIfNeeded();
      final stored = users.get(email) as String?;
      final success = stored != null && stored == password;

      if (success) {
        // Set in-memory user for this session
        _userEmail = email;

        // Persist only if requested
        final settings = await _openSettingsBoxIfNeeded();
        if (rememberMe) {
          await settings.put(_currentUserKey, email);
          await settings.put(_rememberKey, true);
        } else {
          // Remove persisted values so next app start requires login
          await settings.delete(_currentUserKey);
          await settings.put(_rememberKey, false);
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Logout / clear saved user and remember flag
  Future<void> logout() async {
    final settings = await _openSettingsBoxIfNeeded();
    await settings.delete(_currentUserKey);
    await settings.put(_rememberKey, false);
    _userEmail = null;
    notifyListeners();
  }

  /// Optional: allow toggling remember flag without changing current session.
  Future<void> setRememberMe(bool remember) async {
    final settings = await _openSettingsBoxIfNeeded();
    await settings.put(_rememberKey, remember);
    // If turning off remember while someone is saved, remove current_user_key
    if (!remember) {
      await settings.delete(_currentUserKey);
    } else {
      // if enabling remember and a user is logged in, persist that user
      if (_userEmail != null) {
        await settings.put(_currentUserKey, _userEmail);
      }
    }
    notifyListeners();
  }

  /// Helpful helper to read persisted remember flag (if needed).
  Future<bool> persistedRememberMe() async {
    final settings = await _openSettingsBoxIfNeeded();
    return settings.get(_rememberKey) as bool? ?? false;
  }
}
