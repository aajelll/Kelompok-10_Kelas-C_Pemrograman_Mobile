import 'package:flutter/material.dart';

/// Memecah [text] menjadi potongan; kemunculan [keyword] (tanpa membedakan
/// huruf besar-kecil, termasuk yang berakhiran, mis. "candidly") dimiringkan.
List<TextSpan> highlightSpans(String text, String keyword) {
  final word = keyword.trim();
  if (word.isEmpty) return [TextSpan(text: text)];

  final pattern = RegExp(
    '\\b${RegExp.escape(word)}\\w*',
    caseSensitive: false,
  );
  final spans = <TextSpan>[];
  var cursor = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    spans.add(TextSpan(
      text: match.group(0),
      style: const TextStyle(fontStyle: FontStyle.italic),
    ));
    cursor = match.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}

/// Teks contoh kalimat dengan kata kunci miring.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.keyword,
    this.style,
  });

  final String text;
  final String keyword;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        children: highlightSpans(text, keyword),
      ),
    );
  }
}