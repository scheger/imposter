import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player.dart';
import 'game_summary_screen.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  int _currentIndex = 0;
  bool _revealed = false;

  String _roleText(Player player, String word) {
    switch (player.role) {
      case PlayerRole.wordKnower:
        return 'Dein Wort: $word';
      case PlayerRole.imposter:
        return 'Du bist der Imposter!';
      default:
        return 'Deine Rolle: ${player.role.toString().split('.').last}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<GameProvider>().service;
    final players = service.players;
    final settings = service.settings;
    final player = players[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Rollenanzeige')),
      body: Center(
        child: _revealed
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _roleText(player, settings.word),
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('Weiter'),
                    onPressed: () {
                      if (_currentIndex < players.length - 1) {
                        setState(() {
                          _currentIndex++;
                          _revealed = false;
                        });
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GameSummaryScreen()),
                        );
                      }
                    },
                  )
                ],
              )
            : ElevatedButton(
                child: Text('${player.name} anzeigen'),
                onPressed: () => setState(() => _revealed = true),
              ),
      ),
    );
  }
}
