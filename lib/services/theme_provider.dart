// lib/services/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _kAccent = 'accent';
  static const _kDark = 'dark';

  final Box _box;

  ThemeProvider._(this._box) {
    // initialize from box
    final accentVal = _box.get(_kAccent, defaultValue: Colors.blue.value) as int;
    final darkVal = _box.get(_kDark, defaultValue: false) as bool;
    _accentColor = Color(accentVal);
    _darkMode = darkVal;
  }

  /// Call this factory after Hive.initFlutter(); it opens (or reuses) the box.
  static Future<ThemeProvider> create() async {
    final box = await Hive.openBox(_boxName);
    return ThemeProvider._(box);
  }

  Color _accentColor = Colors.blue;
  bool _darkMode = false;

  Color get accentColor => _accentColor;
  bool get isDark => _darkMode;

  /// Update accent color and persist.
  Future<void> setAccent(Color c) async {
    _accentColor = c;
    await _box.put(_kAccent, c.value);
    notifyListeners();
  }

  /// Update dark mode and persist.
  Future<void> setDark(bool dark) async {
    _darkMode = dark;
    await _box.put(_kDark, dark);
    notifyListeners();
  }

  /// Toggle dark mode convenience.
  Future<void> toggleDark() async {
    await setDark(!isDark);
  }
}
