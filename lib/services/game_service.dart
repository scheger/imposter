import 'dart:math';
import '../models/player.dart';
import '../models/game_settings.dart';

class GameService {
  GameSettings settings = GameSettings();
  List<Player> players = [];
  int? startPlayerIndex; // wer beginnt?

  void setupPlayers(List<String> names) {
    players = names.map((name) => Player(name: name)).toList();
  }

  void assignRoles() {
    final impostersCount = settings.imposters;
    final random = Random();

    // Alle Rollen zurücksetzen
    for (var player in players) {
      player.role = PlayerRole.wordKnower;
    }

    // Imposter zufällig auswählen
    final availableIndexes = List<int>.generate(players.length, (i) => i);
    for (var i = 0; i < impostersCount && availableIndexes.isNotEmpty; i++) {
      final randomIndex = availableIndexes.removeAt(random.nextInt(availableIndexes.length));
      players[randomIndex].role = PlayerRole.imposter;
    }

    // 🎲 Startspieler zufällig bestimmen
    startPlayerIndex = Random().nextInt(players.length);
  }

  void resetGame() {
    settings = GameSettings();
    players = [];
    startPlayerIndex = null;
  }
}
