import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/words.dart';
import '../services/category_service.dart';

class CustomCategoryEditorScreen extends StatefulWidget {
  final WordCategory? category;

  const CustomCategoryEditorScreen({super.key, this.category});

  @override
  State<CustomCategoryEditorScreen> createState() => _CustomCategoryEditorScreenState();
}

class _CustomCategoryEditorScreenState extends State<CustomCategoryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  // Wir merken uns den ursprünglichen Namen, um beim Speichern das Original zu ersetzen
  String? _originalName;
  
  List<_MutableSubcategory> _subcategories = [];

  @override
  void initState() {
    super.initState();
    _originalName = widget.category?.name;
    _nameController = TextEditingController(text: _originalName ?? '');

    if (widget.category != null) {
      for (var sub in widget.category!.subcategories) {
        _subcategories.add(_MutableSubcategory.fromModel(sub));
      }
    } else {
      _subcategories.add(_MutableSubcategory(name: 'Allgemein'));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    bool hasWords = _subcategories.any((sub) => sub.items.isNotEmpty);
    if (!hasWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte füge mindestens ein Wort hinzu.')),
      );
      return;
    }

    final newCategory = WordCategory(
      name: _nameController.text.trim(),
      subcategories: _subcategories.map((ms) => ms.toModel()).toList(),
      isCustom: true,
    );

    // Hier geben wir den alten Namen mit, damit der Service weiß, wen er ersetzen muss
    context.read<CategoryService>().saveCustomCategory(
      newCategory, 
      oldName: _originalName
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Kategorie erstellen' : 'Bearbeiten'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Kategorie Name
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Kategoriename',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Name fehlt' : null,
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _subcategories.length,
                itemBuilder: (ctx, i) {
                  return _buildSubcategoryCard(_subcategories[i], i);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => 
          _subcategories.add(_MutableSubcategory(name: 'Neue Gruppe'))
        ),
        label: const Text('Neue Unterkategorie'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubcategoryCard(_MutableSubcategory sub, int index) {
    // Frische Farben für die Cards (heller, cleaner)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final headerColor = isDark ? Colors.grey[800] : Colors.grey[100];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
           if (!isDark)
             BoxShadow(
               color: Colors.black.withOpacity(0.03),
               blurRadius: 5,
               offset: const Offset(0, 2),
             )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Name der Unterkategorie & Löschen
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: sub.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Name der Unterkategorie',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) => sub.name = val,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[300],
                  onPressed: () => setState(() => _subcategories.removeAt(index)),
                ),
              ],
            ),
          ),
          
          if (sub.items.isEmpty)
             Padding(
               padding: const EdgeInsets.all(20),
               child: Text(
                 'Keine Wörter vorhanden.',
                 style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                 textAlign: TextAlign.center,
               ),
             ),
             
          ...sub.items.asMap().entries.map((entry) {
            final itemIndex = entry.key;
            final item = entry.value;
            // Zeige Trennlinie außer beim letzten Element
            final showDivider = itemIndex < sub.items.length - 1;
            return Column(
              children: [
                _buildCompactWordItem(sub, item, itemIndex),
                if (showDivider)
                  Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
              ],
            );
          }),

          // Button "Wort hinzufügen" unten
          InkWell(
            onTap: () => setState(() => sub.items.add(_MutableWordItem())),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.blueAccent),
                  SizedBox(width: 4),
                  Text('Wort hinzufügen', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWordItem(
    _MutableSubcategory sub, 
    _MutableWordItem item, 
    int itemIndex, 
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Indikator
          Padding(
            padding: const EdgeInsets.only(top: 12, right: 12),
            child: Icon(Icons.text_fields, size: 16, color: Colors.grey[400]),
          ),
          
          // Eingabefelder
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  initialValue: item.crew.isNotEmpty ? item.crew.first : '',
                  decoration: const InputDecoration(
                    labelText: 'Gesuchtes Wort (Crew)',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    floatingLabelStyle: TextStyle(color: Colors.blueAccent),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  onChanged: (val) => item.crew = [val],
                ),
                TextFormField(
                  initialValue: item.imposter.join(', '),
                  decoration: const InputDecoration(
                    labelText: 'Hinweise (kommagetrennt)',
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 4),
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  onChanged: (val) {
                    item.imposter = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  },
                ),
              ],
            ),
          ),
          
          // Löschen Button
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey[400],
            onPressed: () => setState(() => sub.items.removeAt(itemIndex)),
          ),
        ],
      ),
    );
  }
}

// ... (Mutable Klassen bleiben gleich wie vorher)
class _MutableSubcategory {
  String name;
  List<_MutableWordItem> items;

  _MutableSubcategory({required this.name, List<_MutableWordItem>? items})
      : items = items ?? [];

  factory _MutableSubcategory.fromModel(WordSubcategory model) {
    return _MutableSubcategory(
      name: model.name,
      items: model.items.map((i) => _MutableWordItem.fromModel(i)).toList(),
    );
  }

  WordSubcategory toModel() {
    return WordSubcategory(
      name: name,
      items: items.map((i) => i.toModel()).toList(),
    );
  }
}

class _MutableWordItem {
  List<String> crew;
  List<String> imposter;

  _MutableWordItem({List<String>? crew, List<String>? imposter})
      : crew = crew ?? [],
        imposter = imposter ?? [];

  factory _MutableWordItem.fromModel(WordItem model) {
    return _MutableWordItem(
      crew: List.from(model.crew), 
      imposter: List.from(model.imposter)
    );
  }

  WordItem toModel() {
    return WordItem(
      crew: crew.where((s) => s.isNotEmpty).toList(),
      imposter: imposter.where((s) => s.isNotEmpty).toList(),
    );
  }
}