import 'package:alhuda/services/tajweed_span_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TajweedSpanBuilder Tests', () {
    const baseStyle = TextStyle(color: Colors.black, fontSize: 20);

    test('colors Madd Lazim red for letter with maddah followed by shaddah', () {
      const text = 'وَلَا ٱلضَّآلِّينَ';
      final spans = TajweedSpanBuilder.buildVerseSpans(
        verseText: text,
        baseStyle: baseStyle,
        isDark: false,
      );

      // Verify spans were generated
      expect(spans.isNotEmpty, isTrue);

      // Verify that Madd Lazim color is present
      final maddSpan = spans.whereType<TextSpan>().firstWhere(
        (s) => s.style?.color == TajweedPalette.maddLazimLight,
      );
      expect(maddSpan.text, contains('آ'));
    });

    test('colors Dagger Alif (Madd Tabii) with coral/rose color', () {
      const text = 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      final spans = TajweedSpanBuilder.buildVerseSpans(
        verseText: text,
        baseStyle: baseStyle,
        isDark: false,
      );

      final daggerAlifSpan = spans.whereType<TextSpan>().firstWhere(
        (s) => s.style?.color == TajweedPalette.maddTabiiLight,
      );
      expect(daggerAlifSpan.text, contains('\u0670'));
    });

    test('colors Hamzat Wasl with gray color', () {
      const text = 'ٱلْحَمْدُ';
      final spans = TajweedSpanBuilder.buildVerseSpans(
        verseText: text,
        baseStyle: baseStyle,
        isDark: false,
      );

      final waslSpan = spans.whereType<TextSpan>().firstWhere(
        (s) => s.style?.color == TajweedPalette.sakinLight,
      );
      expect(waslSpan.text, contains('ٱ'));
    });

    test('colors Ghunna on Noon Mushaddadah with green color', () {
      const text = 'إِنَّ ٱللَّهَ';
      final spans = TajweedSpanBuilder.buildVerseSpans(
        verseText: text,
        baseStyle: baseStyle,
        isDark: false,
      );

      final ghunnaSpan = spans.whereType<TextSpan>().firstWhere(
        (s) => s.style?.color == TajweedPalette.ghunnaLight,
      );
      expect(ghunnaSpan.text, contains('نّ'));
    });

    test('colors Qalqala letters with sukun with blue/cyan color', () {
      const text = 'يَجْعَلُونَ';
      final spans = TajweedSpanBuilder.buildVerseSpans(
        verseText: text,
        baseStyle: baseStyle,
        isDark: false,
      );

      final qalqalaSpan = spans.whereType<TextSpan>().firstWhere(
        (s) => s.style?.color == TajweedPalette.qalqalaLight,
      );
      expect(qalqalaSpan.text, contains('جْ'));
    });

    test('adapts colors for dark mode', () {
      const text = 'وَلَا ٱلضَّآلِّينَ';
      final spans = TajweedSpanBuilder.buildVerseSpans(
        verseText: text,
        baseStyle: baseStyle,
        isDark: true,
      );

      expect(
        spans.whereType<TextSpan>().any((s) => s.style?.color == TajweedPalette.maddLazimDark),
        isTrue,
      );
    });

    test('when highlighted uses highlightColor for all text', () {
      const text = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      final spans = TajweedSpanBuilder.buildVerseSpans(
        verseText: text,
        baseStyle: baseStyle,
        isDark: false,
        isHighlighted: true,
        highlightColor: Colors.amber,
      );

      expect(spans.length, 1);
      expect((spans.first as TextSpan).style?.color, Colors.amber);
    });
  });
}
