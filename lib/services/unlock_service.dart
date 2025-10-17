import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

class UnlockService extends ChangeNotifier {
  static const _prefsKey = 'unlocked_categories';
  static const _prefsDailyCountKey = 'daily_unlock_count';
  static const _prefsLastDateKey = 'last_unlock_date';

  final GameSettings settings;

  final List<String> _unlockedCategories = [];
  bool _initialized = false;

  UnlockService(this.settings);

  bool get initialized => _initialized;
  List<String> get unlockedCategories => List.unmodifiable(_unlockedCategories);

  int _dailyUnlockCount = 0;
  DateTime? _lastUnlockDate;

  static const int dailyLimit = 3;

  // Standardmäßig freigeschaltete Kategorien
  final List<String> _defaultUnlocked = [
    'Tiere',
    'Essen',
    'Sport',
    'Berufe',
  ];

  /// Lädt freigeschaltete Kategorien und Daily Count aus SharedPreferences
  Future<void> loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Kategorien laden
    final saved = prefs.getStringList(_prefsKey);
    if (saved == null || saved.isEmpty) {
      _unlockedCategories.addAll(_defaultUnlocked);
      await prefs.setStringList(_prefsKey, _unlockedCategories);
    } else {
      _unlockedCategories.addAll(saved);
    }

    // Daily Count & Datum laden
    _dailyUnlockCount = prefs.getInt(_prefsDailyCountKey) ?? 0;
    final lastDateString = prefs.getString(_prefsLastDateKey);
    if (lastDateString != null) {
      _lastUnlockDate = DateTime.tryParse(lastDateString);
    }

    // Wenn es ein neuer Tag ist, Count zurücksetzen
    if (_lastUnlockDate == null || !_isSameDay(_lastUnlockDate!, DateTime.now())) {
      _dailyUnlockCount = 0;
      _lastUnlockDate = DateTime.now();
      await prefs.setInt(_prefsDailyCountKey, _dailyUnlockCount);
      await prefs.setString(_prefsLastDateKey, _lastUnlockDate!.toIso8601String());
    }

    _initialized = true;
    notifyListeners();
  }

  /// Prüfen, ob eine Kategorie freigeschaltet ist
  bool isUnlocked(String categoryName) {
    return _unlockedCategories.contains(categoryName);
  }

  /// Neue Kategorie freischalten und speichern
  /// Gibt zurück, ob erfolgreich freigeschaltet wurde
  Future<bool> unlockCategory(String categoryName) async {
    if (_dailyUnlockCount >= dailyLimit) {
      // Limit erreicht
      return false;
    }

    if (!_unlockedCategories.contains(categoryName)) {
      _unlockedCategories.add(categoryName);
      _dailyUnlockCount++;
      _lastUnlockDate = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _unlockedCategories);
      await prefs.setInt(_prefsDailyCountKey, _dailyUnlockCount);
      await prefs.setString(_prefsLastDateKey, _lastUnlockDate!.toIso8601String());

      notifyListeners();
      return true; // erfolgreich freigeschaltet
    }

    return true; // schon freigeschaltet
  }

  /// Zurücksetzen auf Standard
  Future<void> resetUnlocked() async {
    _unlockedCategories
      ..clear()
      ..addAll(_defaultUnlocked);
    _dailyUnlockCount = 0;
    _lastUnlockDate = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _unlockedCategories);
    await prefs.setInt(_prefsDailyCountKey, _dailyUnlockCount);
    await prefs.setString(_prefsLastDateKey, _lastUnlockDate!.toIso8601String());

    notifyListeners();
  }

  /// Anzahl der verbleibenden Freischaltungen für heute
  int remainingDailyUnlocks() {
    if (_lastUnlockDate == null || !_isSameDay(_lastUnlockDate!, DateTime.now())) {
      return dailyLimit;
    }
    return dailyLimit - _dailyUnlockCount;
  }

  /// Hilfsfunktion: Prüfen, ob zwei Daten am selben Tag sind
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
