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
  Future<void> updateSettings(GameSettings newSettings) async {
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

  /// Muss NACH dem Setzen von `crewContent` / `imposterContent`
  /// in der Theme-Auswahl aufgerufen werden (z.B. im PlayerSetupScreen beim Start).
  /// 
  /// Aufgabe: kleine, sichere Fallback-Logik je Modus (falls etwas nicht gesetzt wurde).
  void prepareWordsForMode() {
    switch (settings.mode) {
      case 'classic':
        // classic erwartet, dass crewContent und imposterContent bereits gesetzt sind.
        // Keine zusätzliche Logik erforderlich.
        break;

      case 'similar':
        // Bei 'similar' sollte imposterContent ein alternatives/ähnliches Wort enthalten.
        // Falls es leer ist (z. B. weil ThemeSelection das nicht gesetzt hat),
        // setzen wir einen sicheren Fallback (crewContent), damit das Spiel nicht mit
        // einem leeren Imposter-Text startet.
        if ((settings.imposterContent).trim().isEmpty) {
          settings = settings.copyWith(
            imposterContent: settings.crewContent,
          );
        }
        break;

      case 'undercover':
        // undercover kann so gestaltet sein, dass crewContent und imposterContent
        // bereits korrekt gesetzt sind (z.B. unterschiedliche Fragen).
        // Falls imposterContent leer ist, belassen wir es leer — das bedeutet:
        // Imposter sieht ggf. dieselbe Frage (je nach Spiel-UI).
        // Falls du möchtest, dass Imposter immer etwas anderes sieht, 
        // setze hier einen Fallback analog zu 'similar'.
        break;

      default:
        // Unbekannter Modus -> minimaler Fallback: ensure crewContent ist nicht null.
        if ((settings.crewContent).trim().isEmpty) {
          settings = settings.copyWith(crewContent: '');
        }
        if ((settings.imposterContent).trim().isEmpty) {
          settings = settings.copyWith(imposterContent: '');
        }
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
