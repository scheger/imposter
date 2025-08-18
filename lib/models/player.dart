enum PlayerRole {
  imposter,
  wordKnower,
  detective,
  spy,
}

class Player {
  final String name;
  PlayerRole role;

  Player({
    required this.name,
    this.role = PlayerRole.wordKnower,
  });
}

