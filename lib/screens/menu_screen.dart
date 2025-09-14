import 'package:flutter/material.dart';
import 'mode_selection_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imposter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), // Zahnrad-Icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), 
                textStyle: const TextStyle(fontSize: 22), 
              ),
              child: const Text('Spiel starten'),        
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameModeSelectionScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
