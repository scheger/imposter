import 'dart:math';
import '../models/player.dart';
import '../models/game_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameService {
  GameSettings settings = GameSettings();
  List<Player> players = [];
  int? startPlayerIndex;

  // 🔹 Einstellungen laden
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('game_settings');
    if (jsonString != null) {
      settings = GameSettings.fromRawJson(jsonString);
    }
  }

  // 🔹 Einstellungen speichern
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game_settings', settings.toRawJson());
  }

  // 🔹 Settings updaten + speichern
  void updateSettings(GameSettings newSettings) async {
    settings = newSettings;
    await saveSettings();
  }

  void setupPlayers(List<String> names) {
    players = names.map((name) => Player(name: name)).toList();
  }

  void assignRoles() {
    final impostersCount = settings.imposters;
    final random = Random();

    // Rollen zurücksetzen
    for (var p in players) {
      p.role = PlayerRole.wordKnower;
    }

    // Imposter zufällig bestimmen
    final pool = List<int>.generate(players.length, (i) => i);
    for (var i = 0; i < impostersCount && pool.isNotEmpty; i++) {
      final idx = pool.removeAt(random.nextInt(pool.length));
      players[idx].role = PlayerRole.imposter;
    }

    // Startspieler festlegen
    startPlayerIndex = Random().nextInt(players.length);
  }

  /// Muss NACH dem Setzen von `crewWordQuestion`/`imposterWordQuestion`/`relatedWords`
  /// aus der ThemeSelection aufgerufen werden (z.B. im PlayerSetupScreen beim Start).
  void prepareWordsForMode() {
    switch (settings.mode) {
      case 'classic':
        // crewWordQuestion/imposterWordQuestion wurden in der Auswahl gesetzt.
        // Nichts weiter zu tun.
        break;

      case 'similar':
        // Crew behält das Wort, Imposter bekommen ALLE dasselbe zufällige related-Wort.
        String chosen = settings.imposterWordQuestion; // Fallback falls schon gesetzt
        if (settings.relatedWords.isNotEmpty) {
          chosen = settings.relatedWords[Random().nextInt(settings.relatedWords.length)];
        }
        settings = settings.copyWith(
          // crewWordQuestion bleibt wie gewählt
          imposterWordQuestion: chosen,
        );
        break;

      case 'undercover':
        // Fragen wurden bereits in der Auswahl gesetzt (crew/imposter Frage).
        // Nichts weiter zu tun.
        break;

      default:
        // Fallback wie classic – nichts zusätzlich.
        break;
    }
  }

  void resetGame() async {
    settings = GameSettings();
    players = [];
    startPlayerIndex = null;
    await saveSettings();
  }
}
