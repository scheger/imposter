class GameSettings {
  String category;
  String word; // aktuell: nur ein zufällig gewähltes Wort aus der Kategorie
  String mode; // z.B. 'classic', 'undercover'
  int imposters;

  GameSettings({
    this.category = '',
    this.word = '',
    this.mode = 'classic',
    this.imposters = 1,
  });

  GameSettings copyWith({
    String? category,
    String? word,
    String? mode,
    int? imposters,
  }) {
    return GameSettings(
      category: category ?? this.category,
      word: word ?? this.word,
      mode: mode ?? this.mode,
      imposters: imposters ?? this.imposters,
    );
  }
}
