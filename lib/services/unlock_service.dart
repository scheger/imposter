import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

class UnlockService extends ChangeNotifier {
  // -----------------------------------------------------------
  // 🔹 HIER DIE VARIABLE ZUM UMSCHALTEN:
  // Setze dies auf 'true', wenn du eine APK für Freunde baust.
  // Setze dies auf 'false' für den normalen Store-Release.
  static const bool bypassLock = bool.fromEnvironment('UNLOCK_ALL', defaultValue: false); 
  // -----------------------------------------------------------

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
    'Bosch Werkstatt',
  ];

  /// Lädt freigeschaltete Kategorien und Daily Count aus SharedPreferences
  Future<void> loadUnlocked() async {
    // Wenn der Bypass aktiv ist, müssen wir eigentlich nichts laden, 
    // tun es aber trotzdem, damit keine Fehler entstehen.
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
    // 🔹 MODIFIKATION: Wenn Bypass an ist, ist ALLES immer freigeschaltet
    if (bypassLock) {
      return true;
    }

    return _unlockedCategories.contains(categoryName);
  }

  /// Neue Kategorie freischalten und speichern
  Future<bool> unlockCategory(String categoryName) async {
    // Wenn Bypass an ist, tun wir so, als ob es erfolgreich war, speichern aber nichts
    if (bypassLock) return true;

    if (_dailyUnlockCount >= dailyLimit) {
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
      return true; 
    }

    return true; 
  }

  // ... (Rest der Datei bleibt gleich: resetUnlocked, remainingDailyUnlocks, _isSameDay)
  
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

  int remainingDailyUnlocks() {
    if (_lastUnlockDate == null || !_isSameDay(_lastUnlockDate!, DateTime.now())) {
      return dailyLimit;
    }
    return dailyLimit - _dailyUnlockCount;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}