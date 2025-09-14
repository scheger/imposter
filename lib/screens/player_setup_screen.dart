import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (_controllers.isEmpty) _addPlayerField();

    _selectedImposters = service.settings.imposters;
  }

  void _addPlayerField() {
    setState(() => _controllers.add(TextEditingController()));
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
    final names = _controllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    if (names.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens 2 Spieler eingeben!')),
      );
      return;
    }

    final service = context.read<GameProvider>().service;

    service.settings = service.settings.copyWith(imposters: _selectedImposters);
    service.setupPlayers(names);
    service.assignRoles();
    service.prepareWordsForMode();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleRevealScreen()),
    );
  }

  // 🔹 Spielergruppe speichern
  Future<void> _saveGroup() async {
    final groupNameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Spielergruppe speichern'),
        content: TextField(
          controller: groupNameController,
          decoration: const InputDecoration(labelText: 'Gruppenname'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Speichern')),
        ],
      ),
    );

    if (ok != true) return;
    final groupName = groupNameController.text.trim();
    if (groupName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final players = _controllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    if (players.isEmpty) return;

    await prefs.setStringList('group_${groupName}_players', players);
    await prefs.setInt('group_${groupName}_imposters', _selectedImposters);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spielergruppe gespeichert')),
    );
  }

  // 🔹 Spielergruppe laden
  Future<void> _loadGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final initialKeys = prefs.getKeys()
        .where((k) => k.startsWith('group_') && k.endsWith('_players'))
        .toList();

    if (initialKeys.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine gespeicherten Gruppen vorhanden')),
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (contextDialog) {
        // Kopie der Keys hier **einmalig** erstellen
        List<String> dialogKeys = List.from(initialKeys);

        return StatefulBuilder(
          builder: (contextDialog, setStateDialog) => AlertDialog(
            title: const Text('Spielergruppe laden'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: dialogKeys.map((playerKey) {
                  final groupName = playerKey
                      .replaceFirst('group_', '')
                      .replaceFirst('_players', '');
                  return ListTile(
                    title: Text(groupName),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await prefs.remove(playerKey);
                        await prefs.remove('group_${groupName}_imposters');
                        setStateDialog(() {
                          dialogKeys.remove(playerKey); // direkt aus der Liste entfernen
                        });
                      },
                    ),
                    onTap: () {
                      final players = prefs.getStringList(playerKey) ?? [];
                      final imposters =
                          prefs.getInt('group_${groupName}_imposters') ?? 1;

                      if (!mounted) return;
                      setState(() {
                        _controllers.clear();
                        for (var player in players) {
                          _controllers.add(TextEditingController(text: player));
                        }
                        _selectedImposters = imposters;
                      });

                      Navigator.pop(contextDialog);
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(contextDialog),
                child: const Text('Abbrechen'),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final playerCount = _controllers.where((c) => c.text.trim().isNotEmpty).length;
    final impostersTooMany = _selectedImposters >= playerCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spieler eingeben'),
        actions: [
          IconButton(icon: const Icon(Icons.folder_open), onPressed: _loadGroup),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveGroup),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Anzahl der Imposter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: _selectedImposters,
                  borderRadius: BorderRadius.circular(12),
                  items: _imposterOptions.map((v) => DropdownMenuItem<int>(value: v, child: Text(v.toString()))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedImposters = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (int index = 0; index < _controllers.length; index++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[index],
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZäöüÄÖÜß0-9\s\-_.]"))],
                      decoration: InputDecoration(labelText: 'Spieler ${index + 1}'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: _controllers.length > 1 ? () => _removePlayerField(index) : null,
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
          onPressed: impostersTooMany || playerCount < 2 ? null : _startGame,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Spiel starten'),
        ),
      ),
    );
  }
}
