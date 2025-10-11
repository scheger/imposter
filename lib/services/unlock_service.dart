import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

class UnlockService extends ChangeNotifier {
  static const _prefsKey = 'unlocked_categories';

  final GameSettings settings;

  final List<String> _unlockedCategories = [];
  bool _initialized = false;

  UnlockService(this.settings);

  bool get initialized => _initialized;
  List<String> get unlockedCategories => List.unmodifiable(_unlockedCategories);

  // Standardmäßig freigeschaltete Kategorien
  final List<String> _defaultUnlocked = [
    'Tiere',
    'Essen',
    'Sport',
    'Berufe',
  ];

  /// Lädt freigeschaltete Kategorien aus SharedPreferences
  Future<void> loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);

    if (saved == null || saved.isEmpty) {
      _unlockedCategories.addAll(_defaultUnlocked);
      await prefs.setStringList(_prefsKey, _unlockedCategories);
    } else {
      _unlockedCategories.addAll(saved);
    }

    _initialized = true;
    notifyListeners();
  }

  /// Prüfen, ob eine Kategorie freigeschaltet ist
  bool isUnlocked(String categoryName) {
    return _unlockedCategories.contains(categoryName);
  }

  /// Neue Kategorie freischalten und speichern
  Future<void> unlockCategory(String categoryName) async {
    if (!_unlockedCategories.contains(categoryName)) {
      _unlockedCategories.add(categoryName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _unlockedCategories);
      notifyListeners();
    }
  }

  /// Zurücksetzen auf Standard
  Future<void> resetUnlocked() async {
    _unlockedCategories
      ..clear()
      ..addAll(_defaultUnlocked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _unlockedCategories);
    notifyListeners();
  }
}