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
  final List<WordItem> items;
  final Set<int> _usedIndices = {};

  WordSubcategory({required this.name, required this.items});

  factory WordSubcategory.fromJson(String name, dynamic json) {
    final list = (json as List<dynamic>)
        .map((e) => WordItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return WordSubcategory(name: name, items: list);
  }

  WordItem getRandomItem() {
    if (items.isEmpty) throw StateError('Keine Wörter in "$name" vorhanden');

    if (_usedIndices.length == items.length) {
      _usedIndices.clear();
    }

    final remaining = List<int>.generate(items.length, (i) => i)
        .where((i) => !_usedIndices.contains(i))
        .toList();

    final index = remaining[DateTime.now().millisecondsSinceEpoch % remaining.length];
    _usedIndices.add(index);

    return items[index];
  }

  int get remainingCount => items.length - _usedIndices.length;
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


