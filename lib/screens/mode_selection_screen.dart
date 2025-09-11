import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ThemeSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width / 2 - 24; 

    return Scaffold(
      appBar: AppBar(title: const Text('Spielmodus wählen')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: modes.map((mode) {
            return InkWell(
              onTap: () => _selectMode(context, mode['key']!), // 🔑 key statt title
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mode['title']!, // 🎨 Anzeige bleibt deutsch
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mode['description']!,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


