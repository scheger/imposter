import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player.dart';
import '../models/game_settings.dart';
import 'game_summary_screen.dart';
import 'game_play_screen.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  int _currentIndex = 0;
  bool _revealed = false;
  bool _showStartPlayer = false;

  String _roleText(Player player, GameSettings settings, bool isStartPlayer) {
    if (settings.mode == 'classic') {
      if (player.isImposter) {
        final showHint = switch (settings.imposterHintsMode) {
          'always' => true,
          'never' => false,
          'firstOnly' => isStartPlayer,
          _ => false,
        };
        if (showHint) {
          return 'Du bist der Imposter!\n\nHinweis: ${settings.imposterWordQuestion}';
        } else {
          return 'Du bist der Imposter!';
        }
      } else {
        return 'Dein Wort: ${settings.crewWordQuestion}';
      }
    }

    if (settings.mode == 'undercover') {
      return player.isImposter
          ? 'Deine Frage: ${settings.imposterWordQuestion}'
          : 'Deine Frage: ${settings.crewWordQuestion}';
    }

    if (settings.mode == 'similar') {
      return player.isImposter
          ? 'Dein Wort: ${settings.imposterWordQuestion}'
          : 'Dein Wort: ${settings.crewWordQuestion}';
    }

    return 'Unbekannter Modus!';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<GameProvider>().service;
    final players = service.players;
    final settings = service.settings;
    final player = players[_currentIndex];
    final bool isStartPlayer = service.startPlayerIndex == _currentIndex;
    final startPlayer = players[service.startPlayerIndex!];

    return Scaffold(
      appBar: AppBar(title: const Text('Rollenanzeige')),
      body: Center(
        child: _showStartPlayer
            // 🔹 Startspieler-Anzeige
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${startPlayer.name} beginnt die Runde!",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 22),
                    ),
                    child: Text(
                      (settings.enableTimer && settings.mode != 'undercover') 
                          ? 'Runde starten' 
                          : 'Auflösen',
                    ),
                    onPressed: () {
                      if (settings.enableTimer && settings.mode != 'undercover') {
                        // Timer aktiviert → GamePlayScreen starten
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GamePlayScreen(),
                          ),
                        );
                      } else {
                        // Kein Timer → direkt GameSummaryScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GameSummaryScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              )
            // 🔹 Rollenanzeige
            : _revealed
                ? Column(
                    children: [
                      const Spacer(flex: 2),
                      Text(
                        "Kategorie: ${settings.category}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(flex: 1),
                      Text(
                        _roleText(player, settings, isStartPlayer),
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(flex: 3),
                      Text(
                        "Imposter: ${settings.imposters}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            textStyle: const TextStyle(fontSize: 22),
                          ),
                          child: const Text('Weiter'),
                          onPressed: () {
                            if (_currentIndex < players.length - 1) {
                              setState(() {
                                _currentIndex++;
                                _revealed = false;
                              });
                            } else {
                              // 🔹 Startspieler-Anzeige immer zeigen
                              setState(() {
                                _showStartPlayer = true;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  )
                // 🔹 Button „Spieler anzeigen“
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 22),
                    ),
                    child: Text('${player.name} anzeigen'),
                    onPressed: () => setState(() => _revealed = true),
                  ),
      ),
    );
  }
}
