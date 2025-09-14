class WordCategory {
  final String name;
  final String assetPath;
  final List<WordSubcategory> subcategories;

  WordCategory({
    required this.name,
    required this.assetPath,
    required this.subcategories,
  });
}

class WordSubcategory {
  final String name;
  final List<WordItem> items; // statt List<String>

  WordSubcategory({required this.name, required this.items});

  factory WordSubcategory.fromJson(String name, dynamic json) {
    // json ist eine Liste von Maps
    final list = (json as List<dynamic>)
        .map((e) => WordItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return WordSubcategory(name: name, items: list);
  }
}

class WordItem {
  final String main;
  final List<String> related;
  final String hint;

  WordItem({
    required this.main,
    required this.related,
    required this.hint,
  });

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      main: json['main'] ?? "",
      hint: json['hint'] ?? "",
      related: List<String>.from(json['related'] ?? []),
    );
  }
}

