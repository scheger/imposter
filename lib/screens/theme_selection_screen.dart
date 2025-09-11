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
  final List<String> _wordCategories = [
    'Sport',
    'Tiere',
    'Essen',
    'Geography',
    'Fantasy und Mythologie',
    'Filme und Serien',
    'Mode und Marken',
    'Berufe',
    'Objekte',
    'Gefühle',
    'Superhelden',
    'Videospiele'
  ];

  final List<String> _questionCategories = [
    'Everyday',
    //'Job',
    'Everyday 2',
    'Fun',
    'Fun 2',
  ];

  final Map<String, Map<String, List<Map<String, dynamic>>>> _data = {};
  String? _expandedCategory;
  final Set<String> _selectedSubcategories = {}; // Mehrfachauswahl speichern

  final Map<String, double> _dragOffsets = {};
  final double _maxDrag = 40.0; // maximale visuelle Verschiebung in px
  final double _toggleThresholdFraction =
      0.6; // Schwellwert anteilig von _maxDrag (0..1)

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    final service = context.read<GameProvider>().service;
    final isQuestionMode = service.settings.mode == "undercover";

    final categories = isQuestionMode ? _questionCategories : _wordCategories;

    for (final category in categories) {
      try {
        final path = isQuestionMode
            ? 'lib/assets/questions/${category.toLowerCase()}.json'
            : 'lib/assets/words/${category.toLowerCase()}.json';

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
      } else {
        _expandedCategory = category;
      }
    });
  }

  void _toggleSubcategory(String category, String subcategory) {
    final key = "$category::$subcategory";
    setState(() {
      if (_selectedSubcategories.contains(key)) {
        _selectedSubcategories.remove(key);
      } else {
        _selectedSubcategories.add(key);
      }
    });
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
      final related = List<String>.from(randomObj['related'] ?? []);

      final service = context.read<GameProvider>().service;

      String chosenCategory = "Zufall";
      if (service.settings.showCategoryOnRandom) {
        outerLoop:
        for (final cat in _data.entries) {
          for (final sub in cat.value.entries) {
            if (sub.value.contains(randomObj)) {
              chosenCategory = sub.key;
              break outerLoop;
            }
          }
        }
      }

      service.settings = service.settings.copyWith(
        category: chosenCategory,
        crewWordQuestion: randomWord,
        imposterWordQuestion: hint,
        relatedWords: related,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
      );
    }
  }

  void _continue() {
    final service = context.read<GameProvider>().service;
    final allWords = <Map<String, dynamic>>[];
    String? chosenCategory;

    // Nur wenn Subkategorien explizit ausgewählt wurden
    for (final key in _selectedSubcategories) {
      final parts = key.split("::");
      final category = parts[0];
      final subcategory = parts[1];
      allWords.addAll(_data[category]?[subcategory] ?? []);
    }

    if (allWords.isNotEmpty) {
      final randomObj = allWords[Random().nextInt(allWords.length)];
      final randomWord = randomObj['main'];
      final hint = randomObj['hint'] ?? "";
      final related = List<String>.from(randomObj['related'] ?? []);

      if (service.settings.showCategoryOnRandom) {
        outerLoop:
        for (final cat in _data.entries) {
          for (final sub in cat.value.entries) {
            if (sub.value.contains(randomObj)) {
              chosenCategory = sub.key;
              break outerLoop;
            }
          }
        }
      }

      service.settings = service.settings.copyWith(
        category: service.settings.showCategoryOnRandom
            ? (chosenCategory ?? "Zufall")
            : "Zufall",
        crewWordQuestion: randomWord,
        imposterWordQuestion: hint,
        relatedWords: related,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
      );
    }
  }

  bool isCategorySelected(String category) {
    return _selectedSubcategories.any((key) => key.startsWith("$category::"));
  }

  Widget _buildCategoryButton(String category) {
    final bool isExpanded = _expandedCategory == category;
    final bool isSelected = isCategorySelected(category);

    final int selectedCount = _selectedSubcategories
        .where((key) => key.startsWith("$category::"))
        .length;

    final double offset = _dragOffsets[category] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            // Nur nach rechts zählen (positive dx)
            if (details.delta.dx <= 0) return;
            setState(() {
              final newVal = ( (_dragOffsets[category] ?? 0.0) + details.delta.dx )
                  .clamp(0.0, _maxDrag);
              _dragOffsets[category] = newVal;
            });
          },
          onHorizontalDragEnd: (details) {
            final current = _dragOffsets[category] ?? 0.0;
            final threshold = _maxDrag * _toggleThresholdFraction;

            if (current >= threshold) {
              // Toggle: alle Unterkategorien auswählen/abwählen
              final subs = _data[category]?.keys ?? [];
              final keys = subs.map((s) => "$category::$s");
              final allSelected = keys.every(_selectedSubcategories.contains);

              setState(() {
                if (allSelected) {
                  _selectedSubcategories.removeAll(keys);
                } else {
                  _selectedSubcategories.addAll(keys);
                }
              });
            }

            // Zurück animieren
            setState(() {
              _dragOffsets[category] = 0.0;
            });
          },
          onTap: () => _toggleCategory(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            // transform verschiebt nur die Ansicht, verändert nicht das Layout
            transform: Matrix4.translationValues(offset, 0, 0),
            child: ElevatedButton(
              onPressed: () => _toggleCategory(category),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    isSelected || isExpanded ? Colors.blueAccent : null,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 18,
                        color: (isSelected || isExpanded) ? Colors.white : null,
                      ),
                    ),
                  ),
                  if (selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        "$selectedCount",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: (isSelected || isExpanded) ? Colors.white : null),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),

        if (isExpanded)
          ..._data[category]?.entries.map((entry) {
                final subcategory = entry.key;
                final words = entry.value;
                final key = "$category::$subcategory";
                final bool isSelected = _selectedSubcategories.contains(key);
                final int count = words.length;

                return Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: ElevatedButton(
                    onPressed: () => _toggleSubcategory(category, subcategory),
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
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList() ??
          [],
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (dein bestehender build-Inhalt bleibt gleich)
    final service = context.read<GameProvider>().service;
    final isQuestionMode = service.settings.mode == "undercover";

    final categories = isQuestionMode ? _questionCategories : _wordCategories;
    final bool isLoading = _data.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isQuestionMode ? 'Fragen auswählen' : 'Themenauswahl'),
      ),
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
                    child: Text(
                      isQuestionMode
                          ? 'Zufallsfrage aus allen Kategorien'
                          : 'Zufall aus allen Themen',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: categories.map(_buildCategoryButton).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:
                        _selectedSubcategories.isEmpty ? null : _continue,
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
