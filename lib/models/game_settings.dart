class GameSettings {
  final String category;
  final String word;
  final int imposters;

  GameSettings({
    this.category = '',
    this.word = '',
    this.imposters = 1,
  });

  GameSettings copyWith({
    String? category,
    String? word,
    int? imposters,
  }) {
    return GameSettings(
      category: category ?? this.category,
      word: word ?? this.word,
      imposters: imposters ?? this.imposters,
    );
  }
}
