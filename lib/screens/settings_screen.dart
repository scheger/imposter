import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'player_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  String? _expandedCategory; // Welche Kategorie ist aufgeklappt
  String? _selectedSubcategory; // Welche Unterkategorie ist ausgewählt

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategory == category) {
        _expandedCategory = null;
      } else {
        _expandedCategory = category;
      }
    });
  }

  void _selectSubcategory(String subcat) {
    setState(() {
      _selectedSubcategory = subcat;
    });

    // Direkt im Service speichern, damit es aktuell bleibt
    final service = context.read<GameProvider>().service;
    service.settings = service.settings.copyWith(
      category: _expandedCategory!,
      word: subcat,
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
              borderRadius: BorderRadius.circular(30), // runde Ecken
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 16), // Abstand links
              Expanded(
                child: Text(category, style: const TextStyle(fontSize: 18)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16), // Abstand rechts
                child: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ],
          ),

        ),
        if (isExpanded)
          ..._categoryWords[category]!.map((subcat) {
            final bool isSelected = _selectedSubcategory == subcat;
            return Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: ElevatedButton(
                onPressed: () => _selectSubcategory(subcat),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isSelected ? Colors.blueAccent : null,
                ),
                child: Text(
                  subcat,
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
    if (_selectedSubcategory == null || _expandedCategory == null) return;

    final service = context.read<GameProvider>().service;
    // Hier setzen wir das neue Wort und die Kategorie
    service.settings = service.settings.copyWith(
      category: _expandedCategory!,
      word: _selectedSubcategory!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
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
              onPressed: _selectedSubcategory == null ? null : _continue,
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
