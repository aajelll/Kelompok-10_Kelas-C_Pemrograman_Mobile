class VocabularyEntry {
  final String word;
  final String? phonetic; // bisa null: tidak semua kata punya
  final List<WordMeaning> meanings;

  /// Contoh kalimat (maksimal 3). Kosong jika API tidak menyediakannya.
  final List<String> examples;

  /// Sinonim (maksimal 3). Kosong jika API tidak menyediakannya.
  final List<String> synonyms;

  const VocabularyEntry({
    required this.word,
    this.phonetic,
    required this.meanings,
    this.examples = const [],
    this.synonyms = const [],
  });

  Map<String, dynamic> toMap() => {
        'word': word,
        'phonetic': phonetic,
        'meanings': meanings.map((m) => m.toMap()).toList(),
        'examples': examples,
        'synonyms': synonyms,
      };

  factory VocabularyEntry.fromMap(Map<String, dynamic> m) {
    final meanings = ((m['meanings'] as List?) ?? [])
        .map((e) => WordMeaning.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return VocabularyEntry(
      word: m['word'] as String,
      phonetic: m['phonetic'] as String?,
      meanings: meanings,
      // Data lama (sebelum ada field examples) memakai contoh dari arti.
      examples: _stringList(m['examples']) ??
          [
            for (final meaning in meanings)
              if (meaning.example != null) meaning.example!,
          ],
      synonyms: _stringList(m['synonyms']) ?? const [],
    );
  }
}

List<String>? _stringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : null;

class WordMeaning {
  final String partOfSpeech; // noun, verb, ...
  final String definition;
  final String? example; // sering tidak tersedia di API

  const WordMeaning({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });

  Map<String, dynamic> toMap() =>
      {'partOfSpeech': partOfSpeech, 'definition': definition, 'example': example};

  factory WordMeaning.fromMap(Map<String, dynamic> m) => WordMeaning(
        partOfSpeech: m['partOfSpeech'] as String? ?? '',
        definition: m['definition'] as String? ?? '',
        example: m['example'] as String?,
      );
}