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
  final List<String> crew;
  final List<String> imposter;

  WordItem({
    required this.crew,
    required this.imposter,
  });

  factory WordItem.fromJson(Map<String, dynamic> json) {
    List<String> toList(dynamic value) {
      if (value is String) return [value];
      if (value is List) return List<String>.from(value);
      return [];
    }

    return WordItem(
      crew: toList(json['crew']),
      imposter: toList(json['imposter']),
    );
  }
}


