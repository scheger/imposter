import 'package:flutter/material.dart';
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
    'Tiere',
    'Essen',
    'Städte',
  ];

  final Map<String, List<String>> _categoryWords = {
    'Tiere': ['Hund', 'Katze', 'Elefant'],
    'Essen': ['Pizza', 'Burger', 'Salat'],
    'Städte': ['Berlin', 'Paris', 'New York'],
  };

  String? _expandedCategory; // aktuell aufgeklappte Kategorie
  String? _selectedWord; // ausgewähltes Wort

  void _toggleCategory(String category) {
    setState(() {
      _expandedCategory = _expandedCategory == category ? null : category;
    });
  }

  void _selectWord(String word) {
    setState(() {
      _selectedWord = word;
    });

    // Direkt im Service speichern
    final service = context.read<GameProvider>().service;
    service.settings = service.settings.copyWith(
      category: _expandedCategory!,
      word: word,
    );
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
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Text(category, style: const TextStyle(fontSize: 18)),
              ),
              Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              const SizedBox(width: 16),
            ],
          ),
        ),
        if (isExpanded)
          ..._categoryWords[category]!.map((word) {
            final bool isSelected = _selectedWord == word;
            return Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: ElevatedButton(
                onPressed: () => _selectWord(word),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isSelected ? Colors.blueAccent : null,
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
      ],
    );
  }

  void _continue() {
    if (_selectedWord == null || _expandedCategory == null) return;

    final service = context.read<GameProvider>().service;
    service.settings = service.settings.copyWith(
      category: _expandedCategory!,
      word: _selectedWord!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Themenauswahl')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: _categories.map(_buildCategoryButton).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _selectedWord == null ? null : _continue,
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
