import 'dart:convert';

class GameSettings {
  String category;
  String mode; // 'classic' | 'similar' | 'undercover' | ...
  String crewContent;      // Was die Crew sieht
  String imposterContent;  // Was die Imposter sehen
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

  List<String> categoryOrderClassic;      // Reihenfolge der Kategorien (für CategoryService)
  List<String> categoryOrderSimilar;
  List<String> categoryOrderUndercover;  // Reihenfolge der Fragen-Kategorien

  bool showSwipeHint;            // nur temporär, um den Hinweis zu zeigen

  GameSettings({
    this.category = '',
    this.mode = 'classic',
    this.crewContent = '',
    this.imposterContent = '',
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

    this.categoryOrderClassic = const [],
    this.categoryOrderSimilar = const [],
    this.categoryOrderUndercover = const [],

    this.showSwipeHint = true,
  });

  GameSettings copyWith({
    String? category,
    String? mode,
    String? crewContent,
    String? imposterContent,
    int? imposters,

    bool? showCategoryOnRandom,
    bool? enableTimer,
    int? timerSeconds,
    int? prepareSeconds,
    int? bufferSeconds,
    String? imposterHintsMode,
    bool? soundOn,
    String? themeMode,

    List<String>? categoryOrderClassic,
    List<String>? categoryOrderSimilar,
    List<String>? categoryOrderUndercover,

    bool? showSwipeHint,
  }) {
    return GameSettings(
      category: category ?? this.category,
      mode: mode ?? this.mode,
      crewContent: crewContent ?? this.crewContent,
      imposterContent: imposterContent ?? this.imposterContent,
      imposters: imposters ?? this.imposters,

      showCategoryOnRandom: showCategoryOnRandom ?? this.showCategoryOnRandom,
      enableTimer: enableTimer ?? this.enableTimer,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      prepareSeconds: prepareSeconds ?? this.prepareSeconds,
      bufferSeconds: bufferSeconds ?? this.bufferSeconds,
      imposterHintsMode: imposterHintsMode ?? this.imposterHintsMode,
      soundOn: soundOn ?? this.soundOn,
      themeMode: themeMode ?? this.themeMode,

      categoryOrderClassic: categoryOrderClassic ?? this.categoryOrderClassic,
      categoryOrderSimilar: categoryOrderSimilar ?? this.categoryOrderSimilar,
      categoryOrderUndercover:
          categoryOrderUndercover ?? this.categoryOrderUndercover,

      showSwipeHint: showSwipeHint ?? this.showSwipeHint,
    );
  }

  /// Leert die Spielinhalte für eine neue Runde
  void clearRoundData() {
    crewContent = '';
    imposterContent = '';
  }

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
      'categoryOrderClassic': categoryOrderClassic,
      'categoryOrderSimilar': categoryOrderSimilar,
      'categoryOrderUndercover': categoryOrderUndercover,
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
      categoryOrderClassic:
          List<String>.from(json['categoryOrderClassic'] ?? []),
      categoryOrderSimilar:
          List<String>.from(json['categoryOrderSimilar'] ?? []),
      categoryOrderUndercover:
          List<String>.from(json['categoryOrderUndercover'] ?? []),
    );
  }

  String toRawJson() => jsonEncode(toJson());
  factory GameSettings.fromRawJson(String str) =>
      GameSettings.fromJson(jsonDecode(str));
}
