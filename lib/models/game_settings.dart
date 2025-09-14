import 'dart:convert';

class GameSettings {
  String category;
  String mode; // 'classic' | 'similar' | 'undercover' | ...
  String crewWordQuestion;       // Was die Crew sieht
  String imposterWordQuestion;   // Was der Imposter sieht
  List<String> relatedWords;     // für 'similar'-Modus
  int imposters;

  // NEU: Einstellungen
  bool showCategoryOnRandom;     // 1: Kategorie bei Zufall trotzdem anzeigen
  bool enableTimer;              // 2: Timer an/aus
  int timerSeconds;              // Zeit pro Spieler
  String imposterHintsMode;      // 3: "always" | "never" | "firstOnly"
  bool soundOn;                  // 4: Sound ein/aus
  String themeMode;              // 5: "system" | "dark" | "light"

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
    this.imposterHintsMode = 'firstOnly',
    this.soundOn = true,
    this.themeMode = 'system',
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
    String? imposterHintsMode,
    bool? soundOn,
    String? themeMode,
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
      imposterHintsMode: imposterHintsMode ?? this.imposterHintsMode,
      soundOn: soundOn ?? this.soundOn,
      themeMode: themeMode ?? this.themeMode,
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
      'imposterHintsMode': imposterHintsMode,
      'soundOn': soundOn,
      'themeMode': themeMode,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      showCategoryOnRandom: json['showCategoryOnRandom'] ?? true,
      enableTimer: json['enableTimer'] ?? false,
      timerSeconds: json['timerSeconds'] ?? 30,
      imposterHintsMode: json['imposterHintsMode'] ?? 'firstOnly',
      soundOn: json['soundOn'] ?? true,
      themeMode: json['themeMode'] ?? 'system',
    );
  }

  String toRawJson() => jsonEncode(toJson());
  factory GameSettings.fromRawJson(String str) =>
      GameSettings.fromJson(jsonDecode(str));
}
