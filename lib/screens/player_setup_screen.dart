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
  bool _dragMode = false; // Umschalten zwischen Löschen und Verschieben

  @override
  void initState() {
    super.initState();
    final service = context.read<GameProvider>().service;

    // Spieler aus der aktuellen Session laden
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

  /// 🔹 Spieler in Provider speichern (ohne Rollen zu verteilen)
  void _savePlayersToProvider() {
    final names = _controllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final service = context.read<GameProvider>().service;
    service.settings = service.settings.copyWith(imposters: _selectedImposters);

    // Spieler setzen, aber Rollen & Wörter erst beim Start
    service.setupPlayers(names);
  }

  Future<void> _startGame() async {
    final names =
        _controllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();

    if (names.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens 2 Spieler eingeben!')),
      );
      return;
    }

    final service = context.read<GameProvider>().service;

    // Spieler erst hier übernehmen (Rollenvergabe folgt)
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
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Speichern')),
        ],
      ),
    );

    if (ok != true) return;
    final groupName = groupNameController.text.trim();
    if (groupName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final players =
        _controllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    if (players.isEmpty) return;

    await prefs.setStringList('group_${groupName}_players', players);
    await prefs.setInt('group_${groupName}_imposters', _selectedImposters);

    // Zeitstempel speichern (Millisekunden seit 1970)
    await prefs.setInt(
        'group_${groupName}_timestamp', DateTime.now().millisecondsSinceEpoch);

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

    // Nach Timestamp sortieren (älteste zuerst)
    initialKeys.sort((a, b) {
      final groupA = a.replaceFirst('group_', '').replaceFirst('_players', '');
      final groupB = b.replaceFirst('group_', '').replaceFirst('_players', '');
      final tsA = prefs.getInt('group_${groupA}_timestamp') ?? 0;
      final tsB = prefs.getInt('group_${groupB}_timestamp') ?? 0;
      return tsA.compareTo(tsB);
    });

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
                        await prefs.remove('group_${groupName}_timestamp');
                        setStateDialog(() {
                          dialogKeys.remove(playerKey);
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
    final playerCount =
        _controllers.where((c) => c.text.trim().isNotEmpty).length;
    final impostersTooMany = _selectedImposters >= playerCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spieler eingeben'),
        // ⬅ Back-Button überschreiben
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _savePlayersToProvider(); // Spieler beim Zurückgehen speichern
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.folder_open), onPressed: _loadGroup),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveGroup),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Anzahl der Imposter',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: _selectedImposters,
                  borderRadius: BorderRadius.circular(12),
                  items: _imposterOptions
                      .map((v) =>
                          DropdownMenuItem<int>(value: v, child: Text(v.toString())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedImposters = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Scrollbarer Bereich: Spieler-Liste
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > _controllers.length) {
                            newIndex = _controllers.length;
                          }
                          if (newIndex > oldIndex) newIndex -= 1;

                          final item = _controllers.removeAt(oldIndex);
                          _controllers.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int index = 0; index < _controllers.length; index++)
                          Row(
                            key: ValueKey('player_$index'),
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controllers[index],
                                  onChanged: (_) => setState(() {}),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r"[a-zA-ZäöüÄÖÜß0-9\s\-_.]"))
                                  ],
                                  decoration: InputDecoration(
                                      labelText: 'Spieler ${index + 1}'),
                                ),
                              ),
                              _dragMode
                                  ? ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Icon(Icons.drag_handle),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: _controllers.length > 1
                                          ? () => _removePlayerField(index)
                                          : null,
                                    ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// Spieler hinzufügen Button direkt unter den Spielern
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addPlayerField,
                            icon: const Icon(Icons.add),
                            label: const Text('Spieler hinzufügen'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                              _dragMode ? Icons.remove_circle : Icons.swap_vert),
                          onPressed: () {
                            setState(() {
                              _dragMode = !_dragMode;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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