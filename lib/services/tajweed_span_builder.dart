import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Provides colors for Tajweed rules matching the King Fahd Complex & Medina Tajweed Mushaf.
class TajweedPalette {
  // Light mode colors (optimized for readability & contrast on parchment / white paper)
  static const Color maddLazimLight = Color(0xFFB71C1C);      // 6 counts - Deep Crimson / Dark Red
  static const Color maddMuttasilLight = Color(0xFFD32F2F);   // 4-5 counts - Vivid Red
  static const Color maddMunfasilLight = Color(0xFFEF6C00);   // 2-4-6 counts - Vivid Orange
  static const Color maddTabiiLight = Color(0xFFD84315);      // 2 counts - Warm Coral / Amber (Dagger Alif & Silah Sughra)
  static const Color ghunnaLight = Color(0xFF1B5E20);         // Ghunna, Ikhfa & Idgham - Rich Emerald Green
  static const Color qalqalaLight = Color(0xFF0288D1);        // Qalqala - Vivid Royal Cyan / Blue
  static const Color sakinLight = Color(0xFF8E8E93);          // Sakin & Silent & Wasl - Soft Gray
  static const Color waqfLight = Color(0xFF9E6500);           // Waqf Marks (صلى، قلى، ج) - Golden Bronze

  // Dark mode colors (vibrant and clear against dark backgrounds)
  static const Color maddLazimDark = Color(0xFFFF1744);       // 6 counts - Vivid Crimson
  static const Color maddMuttasilDark = Color(0xFFFF5252);    // 4-5 counts - Bright Red
  static const Color maddMunfasilDark = Color(0xFFFFB74D);    // 2-4-6 counts - Warm Amber
  static const Color maddTabiiDark = Color(0xFFFF8A65);       // 2 counts - Light Coral / Peach
  static const Color ghunnaDark = Color(0xFF4CAF50);          // Ghunna & Ikhfa - Vibrant Green
  static const Color qalqalaDark = Color(0xFF00E5FF);         // Qalqala - Vivid Cyan
  static const Color sakinDark = Color(0xFFAAAAAA);           // Silent & Wasl - Soft Light Gray
  static const Color waqfDark = Color(0xFFFFD54F);            // Waqf Marks - Bright Warm Gold

  static Color maddLazim(bool isDark) => isDark ? maddLazimDark : maddLazimLight;
  static Color maddMuttasil(bool isDark) => isDark ? maddMuttasilDark : maddMuttasilLight;
  static Color maddMunfasil(bool isDark) => isDark ? maddMunfasilDark : maddMunfasilLight;
  static Color maddTabii(bool isDark) => isDark ? maddTabiiDark : maddTabiiLight;
  static Color ghunna(bool isDark) => isDark ? ghunnaDark : ghunnaLight;
  static Color qalqala(bool isDark) => isDark ? qalqalaDark : qalqalaLight;
  static Color sakin(bool isDark) => isDark ? sakinDark : sakinLight;
  static Color waqf(bool isDark) => isDark ? waqfDark : waqfLight;
}

/// Parses Arabic Uthmani text and generates colored [InlineSpan]s adhering to Tajweed rules.
class TajweedSpanBuilder {
  TajweedSpanBuilder._();

  // Waqf marks in Quran (صلى، قلى، لا، صل، ج، تعانق الوقف، سكتة)
  static bool _isWaqfSign(int codeUnit) {
    return codeUnit >= 0x06D6 && codeUnit <= 0x06DC;
  }

  // Combining mark characters (diacritics, dagger alif, tatweel, and Quranic annotations)
  static bool _isCombining(int codeUnit) {
    return (codeUnit >= 0x064B && codeUnit <= 0x065F) || // Tashkeel, shaddah, sukun, maddah
        codeUnit == 0x0670 ||                             // Dagger alif
        codeUnit == 0x0640 ||                             // Tatweel / Kashida
        (codeUnit >= 0x06D6 && codeUnit <= 0x06ED);       // Quranic annotations & small letters
  }

  // Arabic non-connecting characters that never connect to the left
  static const _nonConnectors = {
    '\u0621', // ء (Hamza)
    '\u0622', // آ (Alif Maddah)
    '\u0623', // أ (Alif Hamzah Above)
    '\u0624', // ؤ (Waw Hamzah)
    '\u0625', // إ (Alif Hamzah Below)
    '\u0627', // ا (Alif)
    '\u0671', // ٱ (Alif Wasla)
    '\u062F', // د (Dal)
    '\u0630', // ذ (Dhal)
    '\u0631', // ر (Raa)
    '\u0632', // ز (Zayn)
    '\u0648', // و (Waw)
    '\u0629', // ة (Taa Marbuta - terminal)
    '\u0649', // ى (Alif Maqsura - terminal)
  };

  static const _alifVariants = {
    '\u0622', '\u0623', '\u0625', '\u0627', '\u0671',
  };

  // Letters of Qalqala (قطب جد)
  static const _qalqalaLetters = {'\u0642', '\u0637', '\u0628', '\u062C', '\u062F'};

  // Letters of Hamzah
  static const _hamzahLetters = {'\u0621', '\u0623', '\u0625', '\u0624', '\u0626'};

  // Letters of Ikhfa & Idgham
  static const _ikhfaIdghamLetters = {
    '\u062A', '\u062B', '\u062C', '\u062F', '\u0630', '\u0632', '\u0633', '\u0634',
    '\u0635', '\u0636', '\u0637', '\u0638', '\u0641', '\u0642', '\u0643', // Ikhfa
    '\u064A', '\u0646', '\u0645', '\u0648', '\u0644', '\u0631',             // Idgham (يرملون)
  };

  /// Elongates Arabic words by inserting authentic Quranic Kashida / Tatweel ('ـ' \u0640).
  /// Words with 3-5 base letters get 1 Tatweel; words with >= 6 base letters get up to 2 Tatweels.
  static String stretchWord(String word) {
    if (word.length < 3 || word.contains('\u0640')) return word;

    final clusters = _splitClusters(word);
    if (clusters.length < 3) return word;

    final candidates = <int>[];
    for (int i = 0; i < clusters.length - 1; i++) {
      final curBase = clusters[i].isNotEmpty ? clusters[i][0] : '';
      final nextBase = clusters[i + 1].isNotEmpty ? clusters[i + 1][0] : '';

      // Must connect to the left
      if (_nonConnectors.contains(curBase)) continue;
      // Must not be standalone Hamza (does not connect from right)
      if (nextBase == '\u0621') continue;

      // Never insert Tatweel before Hamzat Wasl (ٱ) or Hamza above/below (أ, إ, آ)
      // This preserves prefixes like (فَأَنجَيْنَا, بِٱتِّخَاذِكُمْ)
      if (nextBase == '\u0671' || nextBase == '\u0623' || nextBase == '\u0625' || nextBase == '\u0622') {
        continue;
      }

      // Must not break Lam-Alif ligature (لا)
      if (curBase == '\u0644' && _alifVariants.contains(nextBase)) continue;

      // Do not elongate the 'ل' of 'ال' (definite article, whether preceded by و, ف, ب, or standalone)
      if (curBase == '\u0644' && i > 0) {
        final prevBase = clusters[i - 1].isNotEmpty ? clusters[i - 1][0] : '';
        if (_alifVariants.contains(prevBase)) continue;
      }

      // Do not elongate immediately before punctuation or waqf signs
      if (clusters[i + 1].runes.any(_isWaqfSign)) continue;

      candidates.add(i);
    }

    if (candidates.isEmpty) return word;

    // Up to 2 Kashidas for words with >= 6 clusters, 1 for shorter words
    final int maxKashidas = clusters.length >= 6 ? 2 : 1;
    final Set<int> chosenIndices = {};

    // Prioritize candidates:
    // 1. Letters before long vowels (ي, و) or common suffixes (نَا, كُم)
    for (final idx in candidates.reversed) {
      final nextBase = clusters[idx + 1].isNotEmpty ? clusters[idx + 1][0] : '';
      if (nextBase == '\u064A' || nextBase == '\u0648' || nextBase == '\u0646' || nextBase == '\u0645') {
        chosenIndices.add(idx);
        if (chosenIndices.length >= maxKashidas) break;
      }
    }

    // 2. If still need more, take middle candidates that aren't immediately adjacent
    if (chosenIndices.length < maxKashidas) {
      for (final idx in candidates) {
        if (!chosenIndices.contains(idx) &&
            (chosenIndices.isEmpty || (idx - chosenIndices.first).abs() > 1)) {
          chosenIndices.add(idx);
          if (chosenIndices.length >= maxKashidas) break;
        }
      }
    }

    if (chosenIndices.isEmpty) {
      chosenIndices.add(candidates.last);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < clusters.length; i++) {
      buffer.write(clusters[i]);
      if (chosenIndices.contains(i)) {
        buffer.write('\u0640'); // Tatweel
      }
    }

    return buffer.toString();
  }

  /// Stretches all eligible Arabic words in a verse using authentic Quranic Kashida.
  static String applyKashida(String text) {
    if (text.isEmpty) return text;
    final words = text.split(' ');
    return words.map(stretchWord).join(' ');
  }

  /// Breaks a string into grapheme clusters: [base character + any following combining marks].
  static List<String> _splitClusters(String text) {
    final clusters = <String>[];
    if (text.isEmpty) return clusters;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (_isCombining(codeUnit) && buffer.isNotEmpty) {
        buffer.writeCharCode(codeUnit);
      } else {
        if (buffer.isNotEmpty) {
          clusters.add(buffer.toString());
          buffer.clear();
        }
        buffer.writeCharCode(codeUnit);
      }
    }
    if (buffer.isNotEmpty) {
      clusters.add(buffer.toString());
    }
    return clusters;
  }

  /// Builds a list of [InlineSpan]s with Tajweed coloring, prominent diacritics, and enlarged marks.
  static List<InlineSpan> buildVerseSpans({
    required String verseText,
    required TextStyle baseStyle,
    required bool isDark,
    bool isHighlighted = false,
    Color? highlightColor,
    VoidCallback? onTap,
    void Function(LongPressStartDetails)? onLongPress,
  }) {
    if (verseText.isEmpty) return const [];

    // If verse is highlighted, use highlightColor for all text
    if (isHighlighted && highlightColor != null) {
      return [
        TextSpan(
          text: verseText,
          style: baseStyle.copyWith(color: highlightColor),
          recognizer: _createRecognizer(onTap, onLongPress),
        ),
      ];
    }

    // Replace regular spaces before waqf signs with narrow non-breaking space
    // to prevent waqf signs from floating in stretched justified spaces
    String cleanedText = verseText;
    for (int code = 0x06D6; code <= 0x06DC; code++) {
      final sign = String.fromCharCode(code);
      cleanedText = cleanedText.replaceAll(' $sign', '\u202F$sign');
    }

    final clusters = _splitClusters(cleanedText);
    if (clusters.isEmpty) return const [];

    // Attributes per cluster
    final clusterColors = List<Color?>.filled(clusters.length, null);

    for (int i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      final baseChar = c.isNotEmpty ? c[0] : '';

      // 1. Waqf signs (علامات الوقف: صلى، قلى، ج، لا، etc.) - distinct golden bronze color
      if (c.runes.any(_isWaqfSign)) {
        clusterColors[i] = TajweedPalette.waqf(isDark);
        continue;
      }

      // 2. Standalone Small Waw / Small Yaa (واو الصلة ۥ، ياء الصلة ۦ)
      if (c.contains('\u06E5') || c.contains('\u06E6')) {
        // If it has maddah ~ (صلة كبرى), use Madd Munfasil color (Orange); else Madd Tabii (Coral/Amber)
        if (c.contains('\u0653')) {
          clusterColors[i] = TajweedPalette.maddMunfasil(isDark);
        } else {
          clusterColors[i] = TajweedPalette.maddTabii(isDark);
        }
        continue;
      }

      // 3. Small High Meem for Iqlab (الميم الصغيرة فوق الحرف للإقلاب ۢ)
      if (c.contains('\u06E2') || c.contains('\u06ED')) {
        clusterColors[i] = TajweedPalette.ghunna(isDark);
        continue;
      }

      // 4. Madd rules with Maddah ~ (المد اللازم، المتصل، المنفصل)
      if (c.contains('\u0653')) {
        bool hasShaddahNext = false;
        bool hasHamzahNext = false;
        bool isNextInSameWord = false;

        for (int j = i + 1; j < clusters.length; j++) {
          final nextC = clusters[j];
          if (nextC.trim().isEmpty) continue;
          if (nextC.contains('\u0651')) {
            hasShaddahNext = true;
          }
          final nextBase = nextC[0];
          if (_hamzahLetters.contains(nextBase)) {
            hasHamzahNext = true;
            bool hasSpaceBetween = false;
            for (int k = i + 1; k < j; k++) {
              if (clusters[k].contains(' ') || clusters[k].trim().isEmpty) {
                hasSpaceBetween = true;
                break;
              }
            }
            isNextInSameWord = !hasSpaceBetween;
          }
          break;
        }

        if (hasShaddahNext) {
          clusterColors[i] = TajweedPalette.maddLazim(isDark); // المد اللازم 6 حركات
        } else if (hasHamzahNext) {
          if (isNextInSameWord) {
            clusterColors[i] = TajweedPalette.maddMuttasil(isDark); // المد المتصل 4-5 حركات
          } else {
            clusterColors[i] = TajweedPalette.maddMunfasil(isDark); // المد المنفصل 2-4-6 حركات
          }
        } else {
          clusterColors[i] = TajweedPalette.maddLazim(isDark);
        }
        continue;
      }

      // 5. Dagger Alif (الألف الخنجرية ٰ - المد الطبيعي حركتان)
      if (c.contains('\u0670')) {
        clusterColors[i] = TajweedPalette.maddTabii(isDark);
        continue;
      }

      // 6. Ghunna on Mushaddad Noon or Meem (غنة النون والميم المشددتين)
      if ((baseChar == '\u0646' || baseChar == '\u0645') && c.contains('\u0651')) {
        clusterColors[i] = TajweedPalette.ghunna(isDark);
        continue;
      }

      // 7. Tanween followed by Ikhfa or Idgham (تنوين الإخفاء / الإدغام بغنة)
      if (c.contains('\u064B') || c.contains('\u064C') || c.contains('\u064D')) {
        bool followedByGhunna = false;
        for (int j = i + 1; j < clusters.length; j++) {
          final nextC = clusters[j].trim();
          if (nextC.isEmpty) continue;
          final nextBase = nextC[0];
          if (_ikhfaIdghamLetters.contains(nextBase)) {
            followedByGhunna = true;
          }
          break;
        }
        if (followedByGhunna) {
          clusterColors[i] = TajweedPalette.ghunna(isDark);
          continue;
        }
      }

      // 8. Noon Sakinah followed by Ikhfa or Idgham (نون ساكنة متبوعة بإخفاء أو إدغام بغنة)
      if (baseChar == '\u0646' && (c.contains('\u0652') || c.contains('\u06E1') || c.length == 1)) {
        bool followedByGhunna = false;
        for (int j = i + 1; j < clusters.length; j++) {
          final nextC = clusters[j].trim();
          if (nextC.isEmpty) continue;
          final nextBase = nextC[0];
          if (_ikhfaIdghamLetters.contains(nextBase)) {
            followedByGhunna = true;
          }
          break;
        }
        if (followedByGhunna) {
          clusterColors[i] = TajweedPalette.ghunna(isDark);
          continue;
        }
      }

      // 9. Qalqala (حروف قطب جد الساكنة)
      if (_qalqalaLetters.contains(baseChar) && (c.contains('\u0652') || c.contains('\u06E1'))) {
        clusterColors[i] = TajweedPalette.qalqala(isDark);
        continue;
      }

      // 10. Silent Letters & Hamzat Wasl (ألف الوصل والحرف الساكن غير المنطوق)
      if (baseChar == '\u0671' || c.contains('\u06DF')) {
        clusterColors[i] = TajweedPalette.sakin(isDark);
        continue;
      }

      // Default: regular text color
      clusterColors[i] = null;
    }

    // Merge contiguous clusters with the same color into a single TextSpan.
    // Crucial: Keep font family, size, and weight completely uniform so HarfBuzz
    // connects Arabic cursive letters across spans seamlessly without any gaps.
    final spans = <InlineSpan>[];
    final currentText = StringBuffer();
    Color? currentColor = clusterColors.first;

    void flushSpan() {
      if (currentText.isEmpty) return;
      spans.add(TextSpan(
        text: currentText.toString(),
        style: currentColor != null
            ? baseStyle.copyWith(color: currentColor)
            : baseStyle,
        recognizer: _createRecognizer(onTap, onLongPress),
      ));
      currentText.clear();
    }

    for (int i = 0; i < clusters.length; i++) {
      final color = clusterColors[i];

      if (color == currentColor) {
        currentText.write(clusters[i]);
      } else {
        flushSpan();
        currentText.write(clusters[i]);
        currentColor = color;
      }
    }
    flushSpan();

    return spans;
  }

  static GestureRecognizer? _createRecognizer(
    VoidCallback? onTap,
    void Function(LongPressStartDetails)? onLongPress,
  ) {
    if (onTap == null && onLongPress == null) return null;

    final recognizer = TapGestureRecognizer();
    recognizer.onTap = onTap;
    return recognizer;
  }
}
