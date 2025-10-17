enum PlayerRole {
  imposter,
  crew,
  detective,
  spy,
}

class Player {
  final String name;
  PlayerRole role;

  Player({
    required this.name,
    this.role = PlayerRole.crew,
  });

  bool get isImposter => role == PlayerRole.imposter;
}

