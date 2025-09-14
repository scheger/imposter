import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/words.dart';
import '../models/game_settings.dart';
import 'game_service.dart'; // 🔹 wichtig für persistentes Speichern

enum Mode { words, questions }

class CategoryService extends ChangeNotifier {
  final Map<Mode, List<WordCategory>> _categories = {
    Mode.words: [],
    Mode.questions: [],
  };

  bool _initialized = false;
  bool get initialized => _initialized;

  GameSettings settings;

  CategoryService(this.settings);

  Future<void> init() async {
    await _loadAllAssets();
    _applySavedOrder(Mode.words);
    _applySavedOrder(Mode.questions);
    _initialized = true;
    notifyListeners();
  }

  List<WordCategory> getWordCategories(Mode mode) =>
      List.unmodifiable(_categories[mode]!);

  Future<void> _loadAllAssets() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifest);

    final wordPaths = manifestMap.keys
        .where((k) => k.startsWith('lib/assets/words/') && k.endsWith('.json'))
        .toList()
      ..sort();
    final questionPaths = manifestMap.keys
        .where((k) => k.startsWith('lib/assets/questions/') && k.endsWith('.json'))
        .toList()
      ..sort();

    final loadedWords =
        await Future.wait(wordPaths.map(_loadCategoryFromAsset));
    final loadedQuestions =
        await Future.wait(questionPaths.map(_loadCategoryFromAsset));

    _categories[Mode.words] =
        loadedWords.whereType<WordCategory>().toList();
    _categories[Mode.questions] =
        loadedQuestions.whereType<WordCategory>().toList();
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
          name: categoryName, assetPath: path, subcategories: subs);
    } catch (e) {
      debugPrint('Error loading $path: $e');
      return null;
    }
  }

  void _applySavedOrder(Mode mode) {
    final saved = mode == Mode.words
        ? settings.categoryOrderWords
        : settings.categoryOrderQuestions;

    if (saved.isEmpty) return;

    final current = _categories[mode]!;
    final byName = {for (var c in current) c.name: c};
    final List<WordCategory> reordered = [];

    for (final name in saved) {
      final cat = byName.remove(name);
      if (cat != null) reordered.add(cat);
    }

    reordered.addAll(byName.values);
    _categories[mode] = reordered;
  }

  /// Reihenfolge überschreiben und **persistieren**
  void updateOrder(Mode mode, List<WordCategory> newOrder, GameService gameService) {
    _categories[mode] = List<WordCategory>.from(newOrder);

    // Speichern in Settings
    final names = _categories[mode]!.map((c) => c.name).toList();
    if (mode == Mode.words) {
      settings = settings.copyWith(categoryOrderWords: names);
    } else {
      settings = settings.copyWith(categoryOrderQuestions: names);
    }

    // ⚡ Persistenz über GameService
    gameService.updateSettings(settings);

    notifyListeners();
  }

  WordCategory? findByName(Mode mode, String name) {
    try {
      return _categories[mode]!.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}
