import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/widgets/highlighted_text.dart';

List<String> _italics(List<TextSpan> spans) => [
      for (final s in spans)
        if (s.style?.fontStyle == FontStyle.italic) s.text!,
    ];

String _joined(List<TextSpan> spans) => spans.map((s) => s.text).join();

void main() {
  test('kata kunci dimiringkan, teks lain tetap utuh', () {
    const text = 'In such an ambitious study, some omissions are inevitable.';

    final spans = highlightSpans(text, 'inevitable');

    expect(_italics(spans), ['inevitable']);
    expect(_joined(spans), text);
  });

  test('tidak peka huruf besar-kecil dan mencakup kata berakhiran', () {
    const text = 'Candid people speak candidly.';

    final spans = highlightSpans(text, 'candid');

    expect(_italics(spans), ['Candid', 'candidly']);
    expect(_joined(spans), text);
  });

  test('tanpa kecocokan atau kata kunci kosong: satu potongan biasa', () {
    expect(_italics(highlightSpans('Tidak ada di sini.', 'candid')), isEmpty);
    expect(highlightSpans('Tidak ada di sini.', 'candid').length, 1);
    expect(highlightSpans('Teks biasa.', '  ').length, 1);
  });

  test('karakter khusus pada kata kunci tidak menyebabkan error', () {
    expect(() => highlightSpans('a.b (c) [d]', 'a.b ('), returnsNormally);
  });
}