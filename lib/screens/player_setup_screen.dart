import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'role_reveal_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final List<TextEditingController> _controllers = [];

  int _selectedImposters = 1;
  final List<int> _imposterOptions = List.generate(10, (i) => i + 1); // 1..10

  @override
  void initState() {
    super.initState();
    final service = context.read<GameProvider>().service;

    // Spieler laden
    _controllers.clear();
    for (var player in service.players) {
      _controllers.add(TextEditingController(text: player.name));
    }
    if (_controllers.isEmpty) {
      _addPlayerField();
    }

    // Imposter-Anzahl aus den aktuellen Settings übernehmen
    _selectedImposters = service.settings.imposters;
  }




  void _addPlayerField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removePlayerField(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startGame() async {
    final names = _controllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens 2 Spieler eingeben!')),
      );
      return;
    }

    final service = context.read<GameProvider>().service;

    // Einstellungen aktualisieren
    service.settings = service.settings.copyWith(
      imposters: _selectedImposters,
    );

    // Spieler neu setzen und Rollen neu vergeben
    service.setupPlayers(names);
    service.assignRoles(); // !!! Wichtig, damit Imposter neu verteilt werden

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleRevealScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spieler eingeben')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Zeile: Text links, Dropdown rechts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Anzahl der Imposter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: _selectedImposters,
                  items: _imposterOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedImposters = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Spieler-Textfelder
            for (int index = 0; index < _controllers.length; index++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[index],
                      // Hier: erlaubte Zeichen inklusive äöüÄÖÜß
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-ZäöüÄÖÜß0-9\s\-_.]"),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Spieler ${index + 1}',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: _controllers.length > 1
                        ? () => _removePlayerField(index)
                        : null,
                  ),
                ],
              ),
              if (index == _controllers.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: _addPlayerField,
                    icon: const Icon(Icons.add),
                    label: const Text('Spieler hinzufügen'),
                  ),
                ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Spiel starten'),
        ),
      ),
    );
  }
}
