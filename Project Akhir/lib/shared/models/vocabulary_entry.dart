class VocabularyEntry {
  final String word;
  final String? phonetic;            // bisa null: tidak semua kata punya
  final List<WordMeaning> meanings;

  const VocabularyEntry({required this.word, this.phonetic, required this.meanings});

  Map<String, dynamic> toMap() => {
        'word': word,
        'phonetic': phonetic,
        'meanings': meanings.map((m) => m.toMap()).toList(),
      };

  factory VocabularyEntry.fromMap(Map<String, dynamic> m) => VocabularyEntry(
        word: m['word'] as String,
        phonetic: m['phonetic'] as String?,
        meanings: ((m['meanings'] as List?) ?? [])
            .map((e) => WordMeaning.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class WordMeaning {
  final String partOfSpeech;   // noun, verb, ...
  final String definition;
  final String? example;       // sering tidak tersedia di API

  const WordMeaning({required this.partOfSpeech, required this.definition, this.example});

  Map<String, dynamic> toMap() =>
      {'partOfSpeech': partOfSpeech, 'definition': definition, 'example': example};

  factory WordMeaning.fromMap(Map<String, dynamic> m) => WordMeaning(
        partOfSpeech: m['partOfSpeech'] as String? ?? '',
        definition: m['definition'] as String? ?? '',
        example: m['example'] as String?,
      );
}