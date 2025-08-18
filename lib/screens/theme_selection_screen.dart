import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../main.dart';
import 'player_setup_screen.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  final List<String> _categories = [
    'Sport',
    'Tiere',
    'Essen',
    'Geography',
  ];

  final Map<String, Map<String, List<Map<String, dynamic>>>> _data = {};
  String? _expandedCategory;
  String? _selectedSubcategory;
  String? _selectedWord;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    for (final category in _categories) {
      try {
        final path = 'lib/assets/words/${category.toLowerCase()}.json';
        final jsonString = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonData = json.decode(jsonString);

        _data[category] = jsonData.map((sub, list) {
          return MapEntry(sub, List<Map<String, dynamic>>.from(list));
        });
      } catch (e) {
        debugPrint('Fehler beim Laden von $category: $e');
        _data[category] = {};
      }
    }
    setState(() {});
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategory == category) {
        _expandedCategory = null;
        _selectedSubcategory = null;
        _selectedWord = null;
      } else {
        _expandedCategory = category;
        _selectedSubcategory = null;
        _selectedWord = null;
      }
    });
  }

void _selectSubcategory(String subcategory) {
  setState(() {
    _selectedSubcategory = subcategory;

    final words = _data[_expandedCategory]?[subcategory] ?? [];
    if (words.isNotEmpty) {
      final randomIndex = Random().nextInt(words.length);
      final wordObj = words[randomIndex];
      _selectedWord = wordObj['main'];
      final hint = wordObj['hint'] ?? "";

      final service = context.read<GameProvider>().service;
      service.settings = service.settings.copyWith(
        category: _expandedCategory!,
        word: _selectedWord!,
        hint: hint, // 🔹 neu: Hint speichern
      );
    } else {
      _selectedWord = null;
    }
  });
}

void _selectRandomFromCategory(String category) {
  final allWords = <Map<String, dynamic>>[];
  _data[category]?.forEach((_, list) {
    allWords.addAll(list);
  });

  if (allWords.isNotEmpty) {
    final randomObj = allWords[Random().nextInt(allWords.length)];
    final randomWord = randomObj['main'];
    final hint = randomObj['hint'] ?? "";

    _selectedWord = randomWord;

    final service = context.read<GameProvider>().service;
    service.settings = service.settings.copyWith(
      category: category,
      word: randomWord,
      hint: hint, // 🔹 neu
    );
  }
}

void _selectRandomFromAll() {
  final allWords = <Map<String, dynamic>>[];
  _data.forEach((_, subMap) {
    subMap.forEach((_, list) {
      allWords.addAll(list);
    });
  });

  if (allWords.isNotEmpty) {
    final randomObj = allWords[Random().nextInt(allWords.length)];
    final randomWord = randomObj['main'];
    final hint = randomObj['hint'] ?? "";

    final service = context.read<GameProvider>().service;
    service.settings = service.settings.copyWith(
      category: 'Zufall',
      word: randomWord,
      hint: hint, // 🔹 neu
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
    );
  }
}


  Widget _buildCategoryButton(String category) {
    final bool isExpanded = _expandedCategory == category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => _toggleCategory(category),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: isExpanded ? Colors.blueAccent : null, // 🔹 blau markieren
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 18,
                    color: isExpanded ? Colors.white : null,
                  ),
                ),
              ),
              Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isExpanded ? Colors.white : null),
              const SizedBox(width: 16),
            ],
          ),
        ),
        if (isExpanded)
          ..._data[category]?.entries.map((entry) {
            final subcategory = entry.key;
            final words = entry.value;
            final bool isSelected = _selectedSubcategory == subcategory;
            final int count = words.length;

            return Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: ElevatedButton(
                onPressed: () => _selectSubcategory(subcategory),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isSelected ? Colors.blueAccent : null,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          subcategory,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList() ?? [],

        const SizedBox(height: 12),
      ],
    );
  }

  void _continue() {
    if (_expandedCategory == null) return;

    // 🔹 Falls keine Subkategorie gewählt → aus ganzer Kategorie wählen
    if (_selectedSubcategory == null || _selectedWord == null) {
      _selectRandomFromCategory(_expandedCategory!);
    }

    if (_selectedWord != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _data.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Themenauswahl')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  ElevatedButton(
                    onPressed: _selectRandomFromAll,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.orangeAccent,
                    ),
                    child: const Text(
                      'Zufall aus allen Kategorien',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: _categories.map(_buildCategoryButton).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _expandedCategory == null ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Weiter'),
                  ),
                ],
              ),
      ),
    );
  }
}
