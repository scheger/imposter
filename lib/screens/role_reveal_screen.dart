import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player.dart';
import '../models/game_settings.dart';
import 'game_summary_screen.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  int _currentIndex = 0;
  bool _revealed = false;
  bool _showStartPlayer = false; // Flag to show start player announcement

    String _roleText(
      Player player,
      GameSettings settings,
      bool isStartPlayer,
    ) {
      if (settings.mode == 'classic') {
        // Classic Mode (Crew kennt Wort, Imposter nicht)
        if (player.isImposter) {
          final showHint = switch (settings.imposterHintsMode) {
            'always' => true,
            'never' => false,
            'firstOnly' => isStartPlayer,
            _ => false,
          };

          if (showHint) {
            return 'Du bist der Imposter!\n\nDein Wort: ${settings.imposterWordQuestion}';
          } else {
            return 'Du bist der Imposter!';
          }
        } else {
          return 'Dein Wort: ${settings.crewWordQuestion}';
        }
      }

      if (settings.mode == 'undercover') {
        // Undercover Mode (Crew & Imposter kriegen unterschiedliche Fragen)
        if (player.isImposter) {
          return 'Deine Frage: ${settings.imposterWordQuestion}';
        } else {
          return 'Deine Frage: ${settings.crewWordQuestion}';
        }
      }

      if (settings.mode == 'similar') {
        // Similar Mode (Imposter kriegt ähnliches Wort)
        if (player.isImposter) {
          return 'Dein Wort: ${settings.imposterWordQuestion}';
        } else {
          return 'Dein Wort: ${settings.crewWordQuestion}';
        }
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

    return Scaffold(
      appBar: AppBar(title: const Text('Rollenanzeige')),
      body: Center(
        child: _showStartPlayer
            // 🔹 Startspieler-Anzeige
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${players[service.startPlayerIndex!].name} beginnt die Runde!",
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
                      textStyle: const TextStyle(fontSize: 22), // Schrift größer
                    ),
                    child: const Text('Auflösen'),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GameSummaryScreen(),
                        ),
                      );
                    },
                  )
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
                            textStyle: const TextStyle(fontSize: 22), // Schrift größer
                          ),
                          child: const Text('Weiter'),
                          onPressed: () {
                            if (_currentIndex < players.length - 1) {
                              setState(() {
                                _currentIndex++;
                                _revealed = false;
                              });
                            } else {
                              // 🔹 Startspieler-Anzeige statt direkt GameSummaryScreen
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
                      textStyle: const TextStyle(fontSize: 22), // Schrift größer
                    ),
                    child: Text('${player.name} anzeigen'),
                    onPressed: () => setState(() => _revealed = true),
                  ),
      ),
    );
  }
}
