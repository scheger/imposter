import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player.dart';
import '../models/game_settings.dart';

class GameSummaryScreen extends StatelessWidget {
  const GameSummaryScreen({super.key});

  String _roleDescription(Player player, String word, GameSettings settings) {
    switch (player.role) {
      case PlayerRole.wordKnower:
        return 'Wort: $word';
      case PlayerRole.imposter:
        if (settings.mode == 'classic') {
          return 'Imposter';
        } else if (settings.mode == 'undercover') {
          return 'Imposter: ${settings.imposterWordQuestion}';
        } else if (settings.mode == 'similar') {
          return 'Imposter: ${settings.imposterWordQuestion}';
        } else if (settings.mode == 'wordwar') {
          return 'Imposter spielt gegen Crew mit unterschiedlichen Wörtern.';
        } else {
          return 'Imposter';
        }
      default:
        return player.role.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<GameProvider>().service;
    final players = service.players;

    return Scaffold(
      appBar: AppBar(title: const Text('Spielerübersicht')),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // auch leere Flächen anklickbar
        onTap: () => Navigator.pop(context),
        child: ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            return ListTile(
              title: Text(player.name),
              subtitle: Text(
                _roleDescription(
                  player,
                  service.settings.crewWordQuestion,
                  service.settings,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
