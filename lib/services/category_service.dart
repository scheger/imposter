import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Wichtig!
import '../models/words.dart';
import '../models/game_settings.dart';
import 'game_service.dart';

enum Mode { classic, similar, undercover }

class CategoryService extends ChangeNotifier {
  final Map<Mode, List<WordCategory>> _categories = {
    Mode.classic: [],
    Mode.similar: [],
    Mode.undercover: [],
  };
  
  // Separate Liste für eigene Kategorien
  List<WordCategory> _customCategories = [];

  bool _initialized = false;
  bool get initialized => _initialized;

  GameSettings settings;

  CategoryService(this.settings);

  Future<void> init() async {
    await _loadAllAssets();
    await _loadCustomCategories(); // Custom laden
    
    _applySavedOrder(Mode.classic);
    _applySavedOrder(Mode.undercover);
    _applySavedOrder(Mode.similar);
    _initialized = true;
    notifyListeners();
  }

  // Gibt Asset-Kategorien + Custom Categories zurück
  List<WordCategory> getWordCategories(Mode mode) {
    final baseList = _categories[mode] ?? [];
    // Wir fügen Custom Categories nur im Classic Mode hinzu (oder wo du willst)
    if (mode == Mode.classic) {
      return [...baseList, ..._customCategories];
    }
    return List.unmodifiable(baseList);
  }

  // --- Custom Category Logic ---

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('custom_categories_data');
    
    _customCategories.clear();
    
    if (stored != null) {
      for (String jsonStr in stored) {
        try {
          final Map<String, dynamic> data = json.decode(jsonStr);
          final categoryName = data['category'] as String? ?? 'Unbekannt';
          final subMap = data['subcategories'] as Map<String, dynamic>? ?? {};

          final subs = subMap.entries
            .map((e) => WordSubcategory.fromJson(e.key, e.value))
            .toList();
            
          _customCategories.add(WordCategory(
            name: categoryName, 
            subcategories: subs,
            isCustom: true, // Markieren als editierbar
          ));
        } catch (e) {
          debugPrint("Fehler beim Laden einer Custom Category: $e");
        }
      }
    }
  }

  Future<void> saveCustomCategory(WordCategory category, {String? oldName}) async {
    if (oldName != null) {
      // Wir bearbeiten eine existierende Kategorie
      final index = _customCategories.indexWhere((c) => c.name == oldName);
      if (index != -1) {
        _customCategories[index] = category;
      } else {
        // Fallback: Sollte eigentlich nicht passieren, aber falls oldName nicht gefunden wird
        _customCategories.add(category);
      }
    } else {
      // Neue Kategorie: Prüfen, ob Name schon existiert, um Duplikate zu vermeiden
      final index = _customCategories.indexWhere((c) => c.name == category.name);
      if (index != -1) {
        _customCategories[index] = category;
      } else {
        _customCategories.add(category);
      }
    }
    
    await _persistCustomCategories();
    notifyListeners();
  }

  Future<void> deleteCustomCategory(String name) async {
    _customCategories.removeWhere((c) => c.name == name);
    await _persistCustomCategories();
    notifyListeners();
  }

  Future<void> _persistCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> dataList = _customCategories
        .map((c) => json.encode(c.toJson()))
        .toList();
    await prefs.setStringList('custom_categories_data', dataList);
  }

  // --- Bestehende Methoden ---
  
  Future<void> _loadAllAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    final wordPaths = assets
        .where((k) => k.startsWith('lib/assets/words/classic/') && k.endsWith('.json'))
        .toList()..sort();
    
    final questionPaths = assets
        .where((k) => k.startsWith('lib/assets/questions/') && k.endsWith('.json'))
        .toList()..sort();
    
    final similarPaths = assets
        .where((k) => k.startsWith('lib/assets/words/similar/') && k.endsWith('.json'))
        .toList()..sort();

    final loadedWords = await Future.wait(wordPaths.map(_loadCategoryFromAsset));
    final loadedQuestions = await Future.wait(questionPaths.map(_loadCategoryFromAsset));
    final loadedSimilar = await Future.wait(similarPaths.map(_loadCategoryFromAsset));

    _categories[Mode.classic] = loadedWords.whereType<WordCategory>().toList();
    _categories[Mode.undercover] = loadedQuestions.whereType<WordCategory>().toList();
    _categories[Mode.similar] = loadedSimilar.whereType<WordCategory>().toList();
  }

  Future<WordCategory?> _loadCategoryFromAsset(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> data = json.decode(jsonString);

      final categoryName = data['category'] as String? ?? '';
      final subMap = data['subcategories'] as Map<String, dynamic>? ?? {};

      final subs = subMap.entries
        .map((e) => WordSubcategory.fromJson(e.key, e.value))
        .toList();

      if (categoryName.isEmpty) return null;

      return WordCategory(
          name: categoryName, 
          assetPath: path, 
          subcategories: subs,
          isCustom: false // Standard
      );
    } catch (e) {
      debugPrint('Error loading $path: $e');
      return null;
    }
  }

  void _applySavedOrder(Mode mode) {
    List<String> saved;
    switch (mode) {
      case Mode.classic: saved = settings.categoryOrderClassic; break;
      case Mode.similar: saved = settings.categoryOrderSimilar; break;
      case Mode.undercover: saved = settings.categoryOrderUndercover; break;
    }

    if (saved.isEmpty) return;

    final current = _categories[mode]!;
    final byName = {for (var c in current) c.name: c};
    final List<WordCategory> reordered = [];

    // Erst die gespeicherten Assets
    for (final name in saved) {
      final cat = byName.remove(name);
      if (cat != null) reordered.add(cat);
    }
    // Dann Rest-Assets
    reordered.addAll(byName.values);
    
    _categories[mode] = reordered;
  }

  void updateOrder(Mode mode, List<WordCategory> newOrder, GameService gameService) {
    // Hier trennen wir Custom und Asset wieder für die Sortier-Speicherung
    // Wir speichern nur die Namen.
    // Aber Achtung: Custom Categories werden separat gespeichert.
    // Die Sortierung mixen wir hier.
    
    // Für die UI aktualisieren wir die interne Liste:
    // Wenn es Classic Mode ist, müssen wir aufpassen, dass wir _categories[classic]
    // nicht mit Custom Categories überschreiben, da diese dynamisch dazugeholt werden via getWordCategories.
    // Aber für Drag&Drop im UI ist das OK, solange wir getWordCategories nutzen.
    
    // Einfache Lösung: Wir speichern die Reihenfolge ALLER Namen in den Settings.
    final names = newOrder.map((c) => c.name).toList();

    switch (mode) {
      case Mode.classic:
        settings = settings.copyWith(categoryOrderClassic: names);
        break;
      case Mode.similar:
        settings = settings.copyWith(categoryOrderSimilar: names);
        break;
      case Mode.undercover:
        settings = settings.copyWith(categoryOrderUndercover: names);
        break;
    }
    gameService.updateSettings(settings);
    notifyListeners();
  }

  void notifyCategoryChanged() {
    notifyListeners();
  }
  
  WordCategory? findByName(Mode mode, String name) {
    // Erst in der Map suchen
    try {
      return _categories[mode]!.firstWhere((c) => c.name == name);
    } catch (_) {
      // Wenn nicht gefunden, in Custom suchen
      try {
        return _customCategories.firstWhere((c) => c.name == name);
      } catch (_) {
        return null;
      }
    }
  }
}