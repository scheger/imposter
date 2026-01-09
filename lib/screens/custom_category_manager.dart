import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/words.dart';
import '../services/category_service.dart';
import 'custom_category_editor_screen.dart'; // 🔹 Import der neuen Datei

class CustomCategoryListScreen extends StatelessWidget {
  const CustomCategoryListScreen({super.key});

  /// Importiert eine JSON-Datei über den Dateimanager
  Future<void> _importCategoryFromFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      
      final jsonMap = json.decode(content);
      final name = jsonMap['category'];
      final subMap = jsonMap['subcategories'] as Map<String, dynamic>;

      final subs = subMap.entries
          .map((e) => WordSubcategory.fromJson(e.key, e.value))
          .toList();

      final newCat = WordCategory(name: name, subcategories: subs, isCustom: true);

      if (context.mounted) {
        context.read<CategoryService>().saveCustomCategory(newCat);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategorie "$name" importiert!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Import: $e')),
        );
      }
    }
  }

  /// Exportiert eine Kategorie als .json Datei
  Future<void> _exportCategoryToFile(BuildContext context, WordCategory cat) async {
    try {
      final jsonStr = json.encode(cat.toJson());
      final directory = await getTemporaryDirectory();
      // Dateiname sicher machen (keine Sonderzeichen)
      final safeName = cat.name.replaceAll(RegExp(r'[^a-zA-Z0-9äöüÄÖÜß]'), '_'); 
      final file = File('${directory.path}/$safeName.json');

      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Kategorie exportieren: ${cat.name}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryService = context.watch<CategoryService>();
    final customCats = categoryService.getWordCategories(Mode.classic)
        .where((c) => c.isCustom)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eigene Kategorien'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Importieren',
            onPressed: () => _importCategoryFromFile(context),
          ),
        ],
      ),
      body: customCats.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'Erstelle deine eigenen Themen\noder importiere sie.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: customCats.length,
              itemBuilder: (ctx, i) {
                final cat = customCats[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ListTile(
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${cat.subcategories.length} Unterkategorien'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _exportCategoryToFile(context, cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => categoryService.deleteCustomCategory(cat.name),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomCategoryEditorScreen(category: cat),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomCategoryEditorScreen(),
            ),
          );
        },
      ),
    );
  }
}