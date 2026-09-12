import 'package:alhuda/services/tajweed_span_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quranic Kashida & Justification Tests', () {
    test('elongates connectable Arabic words correctly', () {
      final testVerses = [
        "وَإِذۡ نَجَّيۡنَٰكُم مِّنۡ ءَالِ فِرۡعَوۡنَ يَسُومُونَكُمۡ سُوٓءَ ٱلۡعَذَابِ يُذَبِّحُونَ أَبۡنَآءَكُمۡ وَيَسۡتَحۡيُونَ نِسَآءَكُمۡۚ وَفِي ذَٰلِكُم بَلَآءٞ مِّن رَّبِّكُمۡ عَظِيمٞ",
        "وَإِذۡ فَرَقۡنَا بِكُمُ ٱلۡبَحۡرَ فَأَنجَيۡنَٰكُمۡ وَأَغۡرَقۡنَآ ءَالَ فِرۡعَوۡنَ وَأَنتُمۡ تَنظُرُونَ",
        "وَإِذۡ وَٰعَدۡنَا مُوسَىٰٓ أَرۡبَعِينَ لَيۡلَةٗ ثُمَّ ٱتَّخَذۡتُمُ ٱلۡعِجۡلَ مِنۢ بَعۡدِهِۦ وَأَنتُمۡ ظَٰلِمُونَ",
        "ثُمَّ عَفَوۡنَا عَنكُم مِّنۢ بَعۡدِ ذَٰلِكَ لَعَلَّكُمۡ تَشۡكُرُونَ",
        "وَإِذۡ ءَاتَيۡنَا مُوسَى ٱلۡكِتَٰبَ وَٱلۡفُرۡقَانَ لَعَلَّكُمۡ تَهۡتَدُونَ",
        "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓا۟ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓا۟ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ",
        "وَإِذۡ قُلۡتُمۡ يَٰمُوسَىٰ لَن نُّؤۡمِنَ لَكَ حَتَّىٰ نَرَى ٱللَّهَ جَهۡرَةٗ فَأَخَذَتۡكُمُ ٱلصَّٰعِقَةُ وَأَنتُمۡ تَنظُرُونَ",
      ];

      for (final v in testVerses) {
        final stretched = TajweedSpanBuilder.applyKashida(v);
        expect(stretched.contains('\u0640'), isTrue);

        // Verify that Lam-Alif ligatures are NOT broken
        expect(stretched.contains('لـا'), isFalse);
        expect(stretched.contains('لـٱ'), isFalse);
        expect(stretched.contains('لـأ'), isFalse);
        expect(stretched.contains('لـإ'), isFalse);
        expect(stretched.contains('لـآ'), isFalse);

        // Verify that definite article 'ال' is NOT broken (no 'ٱلـ' or 'الـ')
        expect(stretched.contains('ٱلـ'), isFalse);

        // Verify that prefixes before Hamzat Wasl are NOT elongated (no 'بِـٱ')
        expect(stretched.contains('ـٱ'), isFalse);
        expect(stretched.contains('ـأ'), isFalse);
        expect(stretched.contains('ـإ'), isFalse);
        expect(stretched.contains('ـآ'), isFalse);

        // Test that Tajweed spans generate successfully
        final spans = TajweedSpanBuilder.buildVerseSpans(
          verseText: stretched,
          baseStyle: const TextStyle(fontSize: 24, fontFamily: 'Amiri', fontWeight: FontWeight.w600),
          isDark: false,
        );
        expect(spans.isNotEmpty, isTrue);
      }
    });
  });
}
