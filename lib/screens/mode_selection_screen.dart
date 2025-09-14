import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/category_service.dart';
import 'theme_selection_screen.dart';

class GameModeSelectionScreen extends StatelessWidget {
  GameModeSelectionScreen({super.key});

  final List<Map<String, String>> modes = [
    {
      'key': 'classic',
      'title': 'Klassisch',
      'description': 'Standardmodus – Imposter kennt das Wort nicht, muss es erraten.'
    },
    {
      'key': 'undercover',
      'title': 'Undercover Question',
      'description': 'Imposter erhält eine andere Frage, ohne es zu wissen.'
    },
    {
      'key': 'similar',
      'title': 'Fast gleich',
      'description': 'Imposter bekommt ein ähnliches Wort und weiß nicht, dass es anders ist.'
    },
    {
      'key': 'wordwar',
      'title': 'Wortkrieg',
      'description': 'Zwei Teams mit unterschiedlichen Wörtern spielen gegeneinander.'
    },
  ];

  void _selectMode(BuildContext context, String modeKey) {
    final service = context.read<GameProvider>().service;
    service.settings = service.settings.copyWith(mode: modeKey);

    Mode selectedMode;
    if (modeKey == 'classic' || modeKey == 'similar' || modeKey == 'wordwar') {
      selectedMode = Mode.words;
    } else {
      selectedMode = Mode.questions;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThemeSelectionScreen(mode: selectedMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spielmodus wählen')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.separated(
          itemCount: modes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final mode = modes[index];
            return GestureDetector(
              onTap: () => _selectMode(context, mode['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode['title']!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mode['description']!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
