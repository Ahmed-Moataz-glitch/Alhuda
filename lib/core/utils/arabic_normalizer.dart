/// Centralized utility for Arabic text normalization, diacritic stripping,
/// and Quranic/Hadith search optimization.
class ArabicNormalizer {
  ArabicNormalizer._();

  /// Regular expression matching standard Arabic diacritics / tashkeel
  static final RegExp tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');

  /// Regular expression matching Quranic annotations, small letters, and symbols
  static final RegExp quranicAnnotationsRegex =
      RegExp(r'[\u06D6-\u06ED\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]');

  /// Strips all diacritics / tashkeel and Quranic annotations from Arabic text.
  static String removeDiacritics(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll(tashkeelRegex, '')
        .replaceAll(quranicAnnotationsRegex, '')
        .replaceAll('ـ', ''); // remove tatweel / kashida
  }

  /// Normalizes Arabic text for flexible, diacritic-insensitive & variant-insensitive search.
  /// Converts all forms of Alif to bare Alif, Taa Marbuta to Haa, Yaa/Alif Maqsura to Yaa, etc.
  static String normalize(String input) {
    if (input.isEmpty) return '';

    var result = removeDiacritics(input);

    // Normalize Alif variants (أ، إ، آ، ٱ -> ا)
    result = result
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا');

    // Normalize Taa Marbuta (ة -> ه)
    result = result.replaceAll('ة', 'ه');

    // Normalize Alif Maqsura (ى -> ي)
    result = result.replaceAll('ى', 'ي');

    // Normalize Waw with Hamza (ؤ -> و) and Yaa with Hamza (ئ -> ي)
    result = result.replaceAll('ؤ', 'و').replaceAll('ئ', 'ي');

    return result.trim().toLowerCase();
  }
}
