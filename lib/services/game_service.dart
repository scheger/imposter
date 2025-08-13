import 'dart:math';
import '../models/player.dart';
import '../models/game_settings.dart';

class GameService {
  GameSettings settings = GameSettings();
  List<Player> players = [];

  void setupPlayers(List<String> names) {
    players = names.map((name) => Player(name: name)).toList();
  }

  void assignRoles() {
    final impostersCount = settings.imposters;

    // Alle Spieler kennen erst mal das Wort
    for (var player in players) {
      player.knowsWord = true;
    }

    // Zufällige Indizes der Imposter auswählen
    final random = Random();
    final imposterIndices = <int>{};

    while (imposterIndices.length < impostersCount && imposterIndices.length < players.length) {
      imposterIndices.add(random.nextInt(players.length));
    }

    // Rollen zuweisen
    for (var index in imposterIndices) {
      players[index].knowsWord = false; // Imposter
    }
  }


  void resetGame() {
    settings = GameSettings();
    players = [];
  }
}
