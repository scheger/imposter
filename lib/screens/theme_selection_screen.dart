import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/category_service.dart';
import '../main.dart';
import 'player_setup_screen.dart';
import '../models/words.dart';
import '../services/game_service.dart';
import '../services/unlock_service.dart';
import '../services/ad_service.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final Mode mode; // Wörter oder Fragen

  const ThemeSelectionScreen({super.key, required this.mode});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _expandedCategory;
  final Set<String> _selectedSubcategories = {};
  final Map<String, double> _dragOffsets = {};
  final double _maxDrag = 40.0;
  final double _toggleThresholdFraction = 0.6;

  bool _dragMode = false;
  List<WordCategory> _dragList = []; // veränderbare Kopie für Reorder

  // Animation für den Swipe-Hinweis
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  @override
  void initState() {
    super.initState();

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _hintAnimation = Tween<double>(begin: 0.0, end: _maxDrag * 0.8).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );

    _hintController.addListener(() {
      final firstCategoryName = _getFirstCategoryName();
      if (firstCategoryName != null) {
        setState(() {
          _dragOffsets[firstCategoryName] = _hintAnimation.value;
        });
      }
    });

    _hintController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hintController.reverse();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameService = context.read<GameProvider>().service;
      if (!_dragMode && gameService.settings.showSwipeHint) {
        _hintController.forward(from: 0.0);

        // nach Abspielen für diese App-Sitzung deaktivieren
        gameService.settings =
            gameService.settings.copyWith(showSwipeHint: false);
      }
    });
  }


  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  String? _getFirstCategoryName() {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final categories = categoryService.getWordCategories(widget.mode);
    return categories.isNotEmpty ? categories.first.name : null;
  }

  // --- Interaktionen ---
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

    final allSubcategories = <WordSubcategory>[];
    for (var cat in service.getWordCategories(widget.mode)) {
      allSubcategories.addAll(cat.subcategories);
    }

    final allItems = allSubcategories.expand((s) => s.items).toList();
    if (allItems.isEmpty) return;

    final randomItem = (allItems..shuffle()).first;

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

    // --- Auswahl aus den Listen (neu: crew / imposter als List<String>)
    final crewList = randomItem.crew;
    final imposterList = randomItem.imposter;

    final crew = (crewList.isNotEmpty ? (crewList..shuffle()).first : '');
    final imposter = (imposterList.isNotEmpty ? (imposterList..shuffle()).first : '');

    gameService.settings = gameService.settings.copyWith(
      category: chosenCategory,
      crewContent: crew,
      imposterContent: imposter,
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

    // --- Auswahl aus den Listen (neu: crew / imposter als List<String>)
    final crewList = randomItem.crew;
    final imposterList = randomItem.imposter;

    final crew = (crewList.isNotEmpty ? (crewList..shuffle()).first : '');
    final imposter = (imposterList.isNotEmpty ? (imposterList..shuffle()).first : '');

    gameService.settings = gameService.settings.copyWith(
      category: chosenCategory,
      crewContent: crew,
      imposterContent: imposter,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
    );
  }

  bool isCategorySelected(String categoryName) {
    return _selectedSubcategories.any((k) => k.startsWith("$categoryName::"));
  }

  void _showUnlockDialog(
    WordCategory category,
    UnlockService unlockService,
    AdService adService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;

        Future<void> startAdFlow() async {
          if (!mounted) return;
          Navigator.pop(dialogContext);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anzeige wird geladen...')),
          );

          await adService.loadRewardAd(
            onLoaded: () async {
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              await adService.showRewardAd(
                onUserEarnedReward: () async {
                  await unlockService.unlockCategory(category.name);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${category.name} wurde freigeschaltet! 🎉'),
                    ),
                  );
                },
                onAdClosed: () {},
              );
            },
            onFailed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Werbung konnte nicht geladen werden.'),
                ),
              );
            },
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${category.name} ist gesperrt'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diese Kategorie ist gesperrt. '
                      'Möchtest du sie durch das Ansehen einer Werbung freischalten?\n',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inhalt dieser Kategorie:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    // Unterkategorien und Wortanzahl auflisten
                    ...category.subcategories.map((sub) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sub.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${sub.items.length} Wörter',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          await startAdFlow();
                          if (mounted) setState(() => isLoading = false);
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Freischalten'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // Button-Ansicht für Kategorie
  Widget _buildCategoryButton(WordCategory category) {
    final unlockService = Provider.of<UnlockService>(context, listen: false);
    final adService = context.read<AdService>();
    final bool unlocked = unlockService.isUnlocked(category.name);

    final bool isExpanded = _expandedCategory == category.name;
    final bool isSelected = isCategorySelected(category.name);
    final int selectedCount = _selectedSubcategories
        .where((key) => key.startsWith("${category.name}::"))
        .length;
    final double offset = _dragOffsets[category.name] ?? 0.0;

    return Opacity(
      opacity: unlocked ? 1.0 : 0.4, // halbtransparent, wenn gesperrt
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _dragMode
                ? null
                : () {
                    if (!unlocked) {
                      _showUnlockDialog(category, unlockService, adService);
                      return;
                    }
                    _toggleCategory(category.name);
                  },
            onHorizontalDragUpdate: _dragMode || !unlocked
                ? null
                : (details) {
                    if (details.delta.dx <= 0) return;
                    setState(() {
                      _dragOffsets[category.name] =
                          ((_dragOffsets[category.name] ?? 0) + details.delta.dx)
                              .clamp(0.0, _maxDrag);
                    });
                  },
            onHorizontalDragEnd: _dragMode || !unlocked
                ? null
                : (details) {
                    final current = _dragOffsets[category.name] ?? 0.0;
                    if (current >= _maxDrag * _toggleThresholdFraction) {
                      final keys = category.subcategories
                          .map((s) => "${category.name}::${s.name}");
                      final allSelected =
                          keys.every(_selectedSubcategories.contains);
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              transform: Matrix4.translationValues(offset, 0, 0),
              child: ElevatedButton(
                onPressed: _dragMode
                    ? null
                    : () {
                        if (!unlocked) {
                          _showUnlockDialog(category, unlockService, adService);
                          return;
                        }
                        _toggleCategory(category.name);
                      },
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
                          color: (isSelected || isExpanded)
                              ? Colors.white
                              : (unlocked ? null : Colors.grey[600]),
                        ),
                      ),
                    ),
                    if (!unlocked)
                      const Icon(Icons.lock, color: Colors.white70), // rechts
                    if (unlocked && !_dragMode && selectedCount > 0)
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
                      color: (isSelected || isExpanded)
                          ? Colors.white
                          : (unlocked ? null : Colors.grey[500]),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
          if (!_dragMode && isExpanded && unlocked)
            ...category.subcategories.map((sub) {
              final key = "${category.name}::${sub.name}";
              final selected = _selectedSubcategories.contains(key);

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
                        ),
                      ),
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
      ),
    );
  }

  void _enterDragMode(List<WordCategory> serviceCategories) {
    final unlockService = context.read<UnlockService>();

    // freigeschaltete zuerst, gesperrte danach
    _dragList = [
      ...serviceCategories.where((c) => unlockService.isUnlocked(c.name)),
      ...serviceCategories.where((c) => !unlockService.isUnlocked(c.name)),
    ];
    setState(() => _dragMode = true);
  }

  void _exitDragMode(CategoryService service, GameService gameService) {
    service.updateOrder(widget.mode, _dragList, gameService);
    setState(() {
      _dragMode = false;
      _expandedCategory = null;
      _selectedSubcategories.clear();
    });
  }

  String _getModeTitle(Mode mode) {
    switch (mode) {
      case Mode.classic:
        return 'Wörterkategorie auswählen';
      case Mode.similar:
        return 'Wörterkategorie auswählen';
      case Mode.undercover:
        return 'Fragenkategorie auswählen';
      default:
        return 'Themen auswählen';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryService = Provider.of<CategoryService>(context);
    final unlockService = context.watch<UnlockService>(); // 🔹 watch für automatische UI-Aktualisierung
    final serviceCategories = categoryService.getWordCategories(widget.mode);

    // Sortierte Kategorien: freigeschaltet zuerst
    final sortedCategories = [
      ...serviceCategories.where((c) => unlockService.isUnlocked(c.name)),
      ...serviceCategories.where((c) => !unlockService.isUnlocked(c.name)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getModeTitle(widget.mode)),
        actions: [
          IconButton(
            icon: Icon(_dragMode ? Icons.check : Icons.swap_vert),
            onPressed: () {
              final gameService = context.read<GameProvider>().service;
              if (_dragMode) {
                _exitDragMode(categoryService, gameService);
              } else {
                _enterDragMode(sortedCategories); // 🔹 Drag-Liste ebenfalls sortiert
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: sortedCategories.isEmpty
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
                        widget.mode == Mode.undercover
                            ? 'Zufallsfrage aus allen Kategorien'
                            : 'Zufall aus allen Themen',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _dragMode
                        ? ReorderableListView(
                            buildDefaultDragHandles: false,
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
                                      if (unlockService.isUnlocked(_dragList[i].name))
                                        ReorderableDragStartListener(
                                          index: i,
                                          child: const Icon(Icons.drag_handle),
                                        ),
                                    ],
                                  ),
                                )
                            ],
                            onReorder: (oldIndex, newIndex) {
                              // Nur freigeschaltete Kategorien verschieben
                              if (!_dragList[oldIndex].name.isNotEmpty &&
                                  !unlockService.isUnlocked(_dragList[oldIndex].name)) {
                                return;
                              }

                              // Gesperrte dürfen nicht vor die freigeschalteten kommen
                              final lastUnlockedIndex =
                                  _dragList.lastIndexWhere((c) => unlockService.isUnlocked(c.name));
                              if (newIndex > lastUnlockedIndex + 1) newIndex = lastUnlockedIndex + 1;

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
                            children: sortedCategories.map(_buildCategoryButton).toList(),
                          ),
                  ),
                  if (!_dragMode) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _selectedSubcategories.isEmpty ? null : () => _continue(categoryService),
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
