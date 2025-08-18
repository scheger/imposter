import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player.dart';

class GameSummaryScreen extends StatelessWidget {
  const GameSummaryScreen({super.key});

  String _roleDescription(Player player, String word) {
    switch (player.role) {
      case PlayerRole.wordKnower:
        return 'Wort: $word';
      case PlayerRole.imposter:
        return 'Imposter ';
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
      body: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return ListTile(
            title: Text(player.name),
            subtitle: Text(_roleDescription(player, service.settings.word)),
          );
        },
      ),
    );
  }
}

