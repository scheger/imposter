import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class GameSummaryScreen extends StatelessWidget {
  const GameSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final players = context.read<GameProvider>().service.players;
    final service = context.read<GameProvider>().service;

    return Scaffold(
      appBar: AppBar(title: const Text('Spielerübersicht')),
      body: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return ListTile(
            title: Text(player.name),
            subtitle: Text(player.knowsWord ? 'Wort: ${service.settings.word}' : 'Imposter'),
          );
        },
      ),
    );
  }
}
