import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/category_service.dart';
import '../main.dart';
import 'player_setup_screen.dart';
import '../models/words.dart';
import '../services/game_service.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final Mode mode; // Wörter oder Fragen

  const ThemeSelectionScreen({super.key, required this.mode});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String? _expandedCategory;
  final Set<String> _selectedSubcategories = {};
  final Map<String, double> _dragOffsets = {};
  final double _maxDrag = 40.0;
  final double _toggleThresholdFraction = 0.6;

  bool _dragMode = false;
  List<WordCategory> _dragList = []; // veränderbare Kopie für Reorder

  // --- Interaktionen (nur aktiv, wenn !_dragMode) ---
  void _toggleCategory(String categoryName) {
    if (_dragMode) return;
    setState(() {
      _expandedCategory =
          _expandedCategory == categoryName ? null : categoryName;
    });
  }

  void _toggleSubcategory(String categoryName, String subName) {
    if (_dragMode) return;
    final key = "$categoryName::$subName";
    setState(() {
      if (_selectedSubcategories.contains(key)) {
        _selectedSubcategories.remove(key);
      } else {
        _selectedSubcategories.add(key);
      }
    });
  }

  void _selectRandomFromAll(CategoryService service) {
    if (_dragMode) return;

    // Alle Subkategorien sammeln
    final allSubcategories = <WordSubcategory>[];
    for (var cat in service.getWordCategories(widget.mode)) {
      allSubcategories.addAll(cat.subcategories);
    }

    // Alle Items aus allen Subkategorien sammeln
    final allItems = allSubcategories.expand((s) => s.items).toList();
    if (allItems.isEmpty) return;

    // Zufälliges Item auswählen
    final randomItem = (allItems..shuffle()).first;

    // Kategorie-Namen bestimmen, nur wenn showCategoryOnRandom aktiviert
    String chosenCategory = "Zufall";
    final gameService = context.read<GameProvider>().service;
    if (gameService.settings.showCategoryOnRandom) {
      outerLoop:
      for (var cat in service.getWordCategories(widget.mode)) {
        for (var sub in cat.subcategories) {
          if (sub.items.contains(randomItem)) {
            chosenCategory = sub.name;
            break outerLoop;
          }
        }
      }
    }

    gameService.settings = gameService.settings.copyWith(
      category: chosenCategory,
      crewWordQuestion: randomItem.main,
      imposterWordQuestion: randomItem.hint,
      relatedWords: randomItem.related,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
    );
  }

  void _continue(CategoryService service) {
    if (_dragMode) return;

    final selectedItems = <WordItem>[];
    for (var key in _selectedSubcategories) {
      final parts = key.split("::");
      final category = service.findByName(widget.mode, parts[0]);
      final sub = category?.subcategories.firstWhere(
        (s) => s.name == parts[1],
        orElse: () => WordSubcategory(name: "", items: []),
      );
      selectedItems.addAll(sub?.items ?? []);
    }

    if (selectedItems.isEmpty) return;

    final randomItem = (selectedItems..shuffle()).first;

    // Kategorie-Namen nur setzen, wenn showCategoryOnRandom aktiv
    String chosenCategory = "Auswahl";
    final gameService = context.read<GameProvider>().service;
    if (gameService.settings.showCategoryOnRandom) {
      outerLoop:
      for (var cat in service.getWordCategories(widget.mode)) {
        for (var sub in cat.subcategories) {
          if (sub.items.contains(randomItem)) {
            chosenCategory = sub.name;
            break outerLoop;
          }
        }
      }
    }

    gameService.settings = gameService.settings.copyWith(
      category: chosenCategory,
      crewWordQuestion: randomItem.main,
      imposterWordQuestion: randomItem.hint,
      relatedWords: randomItem.related,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
    );
  }

  bool isCategorySelected(String categoryName) {
    return _selectedSubcategories.any((k) => k.startsWith("$categoryName::"));
  }

  // Button-Ansicht wie vorher (für normalen Modus)
  Widget _buildCategoryButton(WordCategory category) {
    final bool isExpanded = _expandedCategory == category.name;
    final bool isSelected = isCategorySelected(category.name);
    final int selectedCount = _selectedSubcategories
        .where((key) => key.startsWith("${category.name}::"))
        .length;
    final double offset = _dragOffsets[category.name] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: _dragMode
              ? null
              : (details) {
                  if (details.delta.dx <= 0) return;
                  setState(() {
                    _dragOffsets[category.name] =
                        ((_dragOffsets[category.name] ?? 0) + details.delta.dx)
                            .clamp(0.0, _maxDrag);
                  });
                },
          onHorizontalDragEnd: _dragMode
              ? null
              : (details) {
                  final current = _dragOffsets[category.name] ?? 0.0;
                  if (current >= _maxDrag * _toggleThresholdFraction) {
                    final keys = category.subcategories
                        .map((s) => "${category.name}::${s.name}");
                    final allSelected = keys.every(_selectedSubcategories.contains);
                    setState(() {
                      if (allSelected) {
                        _selectedSubcategories.removeAll(keys);
                      } else {
                        _selectedSubcategories.addAll(keys);
                      }
                    });
                  }
                  setState(() => _dragOffsets[category.name] = 0.0);
                },
          onTap: _dragMode ? null : () => _toggleCategory(category.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(offset, 0, 0),
            child: ElevatedButton(
              onPressed:
                  _dragMode ? null : () => _toggleCategory(category.name),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    (isSelected || isExpanded) ? Colors.blueAccent : null,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 18,
                        color:
                            (isSelected || isExpanded) ? Colors.white : null,
                      ),
                    ),
                  ),
                  if (!_dragMode && selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        "$selectedCount",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  Icon(
                    _dragMode
                        ? Icons.drag_handle
                        : (isExpanded ? Icons.expand_less : Icons.expand_more),
                    color: (isSelected || isExpanded) ? Colors.white : null,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
        if (!_dragMode && isExpanded)
          ...category.subcategories.map((sub) {
            final key = "${category.name}::${sub.name}";
            final bool selected = _selectedSubcategories.contains(key);

            return Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: ElevatedButton(
                onPressed: () => _toggleSubcategory(category.name, sub.name),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: selected ? Colors.blueAccent : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                        child: Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 16,
                        color: selected ? Colors.white : null,
                      ),
                    )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          '${sub.items.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: selected ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
      ],
    );
  }

  // --- Wechsel Drag-Mode: lokale Kopie anlegen / löschen ---
  void _enterDragMode(List<WordCategory> serviceCategories) {
    _dragList = List<WordCategory>.from(serviceCategories);
    setState(() => _dragMode = true);
  }

  void _exitDragMode(CategoryService service, GameService gameService) {
    // Speichere finale Reihenfolge
    service.updateOrder(widget.mode, _dragList, gameService);

    setState(() {
      _dragMode = false;
      _expandedCategory = null;
      _selectedSubcategories.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    final categoryService = Provider.of<CategoryService>(context);
    final serviceCategories = categoryService.getWordCategories(widget.mode);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == Mode.words ? 'Wörter auswählen' : 'Fragen auswählen'),
        actions: [
          IconButton(
            icon: Icon(_dragMode ? Icons.check : Icons.swap_vert),
            onPressed: () {
              final gameService = context.read<GameProvider>().service;
              if (_dragMode) {
                _exitDragMode(categoryService, gameService);
              } else {
                _enterDragMode(serviceCategories);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: serviceCategories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (!_dragMode)
                    ElevatedButton(
                      onPressed: () => _selectRandomFromAll(categoryService),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.orangeAccent,
                      ),
                      child: Text(
                        widget.mode == Mode.words ? 'Zufall aus allen Themen' : 'Zufallsfrage aus allen Kategorien',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _dragMode
                        ? ReorderableListView(
                            buildDefaultDragHandles: false, // wir verwenden eigene handles
                            children: [
                              for (int i = 0; i < _dragList.length; i++)
                                ListTile(
                                  key: ValueKey(_dragList[i].name),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dragList[i].name,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ReorderableDragStartListener(
                                        index: i,
                                        child: const Icon(Icons.drag_handle),
                                      ),
                                    ],
                                  ),
                                )
                            ],
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = _dragList.removeAt(oldIndex);
                                _dragList.insert(newIndex, item);
                              });

                              final gameService = context.read<GameProvider>().service;
                              categoryService.updateOrder(widget.mode, _dragList, gameService);
                            },
                          )
                        : ListView(
                            children: serviceCategories.map(_buildCategoryButton).toList(),
                          ),
                  ),

                  if (!_dragMode) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _selectedSubcategories.isEmpty
                          ? null
                          : () => _continue(categoryService),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Weiter'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
