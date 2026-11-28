import 'package:flutter_test/flutter_test.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';

void main() {
  test('toMap dan fromMap menyimpan contoh dan sinonim', () {
    const entry = VocabularyEntry(
      word: 'candid',
      phonetic: '/ˈkændɪd/',
      meanings: [WordMeaning(partOfSpeech: 'adjective', definition: 'Honest.')],
      examples: ['He is candid.', 'A candid photo.'],
      synonyms: ['frank'],
    );

    final restored = VocabularyEntry.fromMap(entry.toMap());

    expect(restored.word, 'candid');
    expect(restored.examples, ['He is candid.', 'A candid photo.']);
    expect(restored.synonyms, ['frank']);
  });

  test('data lama tanpa field examples memakai contoh dari arti', () {
    final restored = VocabularyEntry.fromMap({
      'word': 'candid',
      'phonetic': null,
      'meanings': [
        {
          'partOfSpeech': 'adjective',
          'definition': 'Honest.',
          'example': 'He is candid.',
        },
      ],
    });

    expect(restored.examples, ['He is candid.']);
    expect(restored.synonyms, isEmpty);
  });

  test('data lama tanpa contoh sama sekali menghasilkan daftar kosong', () {
    final restored = VocabularyEntry.fromMap({
      'word': 'candid',
      'meanings': [
        {'partOfSpeech': 'adjective', 'definition': 'Honest.'},
      ],
    });

    expect(restored.examples, isEmpty);
    expect(restored.synonyms, isEmpty);
  });
}