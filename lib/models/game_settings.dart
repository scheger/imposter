class GameSettings {
  String category;
  String word; 
  String hint;
  String mode; 
  int imposters;

  GameSettings({
    this.category = '',
    this.word = '',
    this.hint = '',
    this.mode = 'classic',
    this.imposters = 1,
  });

  GameSettings copyWith({
    String? category,
    String? word,
    String? hint,
    String? mode,
    int? imposters,
  }) {
    return GameSettings(
      category: category ?? this.category,
      word: word ?? this.word,
      hint: hint ?? this.hint,
      mode: mode ?? this.mode,
      imposters: imposters ?? this.imposters,
    );
  }
}
