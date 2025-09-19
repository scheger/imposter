import 'dart:convert';

class GameSettings {
  String category;
  String mode; // 'classic' | 'similar' | 'undercover' | ...
  String crewWordQuestion;       // Was die Crew sieht
  String imposterWordQuestion;   // Was der Imposter sieht
  List<String> relatedWords;     // für 'similar'-Modus
  int imposters;                 // Anzahl der Imposter

  // Einstellungen
  bool showCategoryOnRandom;     // 1: Kategorie bei Zufall trotzdem anzeigen
  bool enableTimer;              // 2: Timer an/aus
  int timerSeconds;              // Zeit pro Spieler
  int prepareSeconds;            // Zeit Überlegephase
  int bufferSeconds;             // Zeit Pufferphase
  String imposterHintsMode;      // 3: "always" | "never" | "firstOnly"
  bool soundOn;                  // 4: Sound ein/aus
  String themeMode;              // 5: "system" | "dark" | "light"

  List<String> categoryOrderWords;      // Reihenfolge der Kategorien (für CategoryService)
  List<String> categoryOrderQuestions;  // Reihenfolge der Fragen-Kategorien

  bool showSwipeHint;            // nur temporär, um den Hinweis zu zeigen

  GameSettings({
    this.category = '',
    this.mode = 'classic',
    this.crewWordQuestion = '',
    this.imposterWordQuestion = '',
    this.relatedWords = const [],
    this.imposters = 1,

    // Default-Werte
    this.showCategoryOnRandom = true,
    this.enableTimer = false,
    this.timerSeconds = 30,
    this.prepareSeconds = 15,
    this.bufferSeconds = 5,
    this.imposterHintsMode = 'firstOnly',
    this.soundOn = true,
    this.themeMode = 'system',

    this.categoryOrderWords = const [],
    this.categoryOrderQuestions = const [],

    this.showSwipeHint = true,
  });

  GameSettings copyWith({
    String? category,
    String? mode,
    String? crewWordQuestion,
    String? imposterWordQuestion,
    List<String>? relatedWords,
    int? imposters,

    // neue Felder
    bool? showCategoryOnRandom,
    bool? enableTimer,
    int? timerSeconds,
    int? prepareSeconds,
    int? bufferSeconds,
    String? imposterHintsMode,
    bool? soundOn,
    String? themeMode,

    List<String>? categoryOrderWords,
    List<String>? categoryOrderQuestions,

    bool? showSwipeHint,
  }) {
    return GameSettings(
      category: category ?? this.category,
      mode: mode ?? this.mode,
      crewWordQuestion: crewWordQuestion ?? this.crewWordQuestion,
      imposterWordQuestion: imposterWordQuestion ?? this.imposterWordQuestion,
      relatedWords: relatedWords ?? this.relatedWords,
      imposters: imposters ?? this.imposters,

      // Einstellungen
      showCategoryOnRandom: showCategoryOnRandom ?? this.showCategoryOnRandom,
      enableTimer: enableTimer ?? this.enableTimer,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      prepareSeconds: prepareSeconds ?? this.prepareSeconds,
      bufferSeconds: bufferSeconds ?? this.bufferSeconds,
      imposterHintsMode: imposterHintsMode ?? this.imposterHintsMode,
      soundOn: soundOn ?? this.soundOn,
      themeMode: themeMode ?? this.themeMode,

      // Reihenfolge der Kategorien
      categoryOrderWords: categoryOrderWords ?? this.categoryOrderWords,
      categoryOrderQuestions: categoryOrderQuestions ?? this.categoryOrderQuestions,

      showSwipeHint: showSwipeHint ?? this.showSwipeHint,
    );
  }

  /// Praktisch, um beim Rundenwechsel die Wort-/Fragen-Daten zu leeren
  void clearRoundData() {
    crewWordQuestion = '';
    imposterWordQuestion = '';
    relatedWords = [];
  }

  // 🔹 Neu: JSON-Export
  Map<String, dynamic> toJson() {
    return {
      'showCategoryOnRandom': showCategoryOnRandom,
      'enableTimer': enableTimer,
      'timerSeconds': timerSeconds,
      'prepareSeconds': prepareSeconds,
      'bufferSeconds': bufferSeconds,
      'imposterHintsMode': imposterHintsMode,
      'soundOn': soundOn,
      'themeMode': themeMode,
      'categoryOrderWords': categoryOrderWords,
      'categoryOrderQuestions': categoryOrderQuestions,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      showCategoryOnRandom: json['showCategoryOnRandom'] ?? true,
      enableTimer: json['enableTimer'] ?? false,
      timerSeconds: json['timerSeconds'] ?? 30,
      prepareSeconds: json['prepareSeconds'] ?? 15,
      bufferSeconds: json['bufferSeconds'] ?? 5,
      imposterHintsMode: json['imposterHintsMode'] ?? 'firstOnly',
      soundOn: json['soundOn'] ?? true,
      themeMode: json['themeMode'] ?? 'system',
      categoryOrderWords: List<String>.from(json['categoryOrderWords'] ?? []),
      categoryOrderQuestions: List<String>.from(json['categoryOrderQuestions'] ?? []),
    );
  }

  String toRawJson() => jsonEncode(toJson());
  factory GameSettings.fromRawJson(String str) =>
      GameSettings.fromJson(jsonDecode(str));
}
