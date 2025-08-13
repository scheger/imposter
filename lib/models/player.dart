class Player {
  final String name;
  bool isImposter;
  bool knowsWord;

  Player({
    required this.name,
    this.isImposter = false,
    this.knowsWord = true,
  });
}
