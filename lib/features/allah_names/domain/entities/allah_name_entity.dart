class AllahNameModel {
  final int id;
  final String name;
  final String normalizedName;
  final String transliteration;
  final String englishTranslation;
  final String meaning;
  final String quranVerse;
  final String surahRef;
  final bool isFavorite;

  const AllahNameModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.transliteration,
    required this.englishTranslation,
    required this.meaning,
    required this.quranVerse,
    required this.surahRef,
    this.isFavorite = false,
  });

  AllahNameModel copyWith({
    int? id,
    String? name,
    String? normalizedName,
    String? transliteration,
    String? englishTranslation,
    String? meaning,
    String? quranVerse,
    String? surahRef,
    bool? isFavorite,
  }) {
    return AllahNameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      transliteration: transliteration ?? this.transliteration,
      englishTranslation: englishTranslation ?? this.englishTranslation,
      meaning: meaning ?? this.meaning,
      quranVerse: quranVerse ?? this.quranVerse,
      surahRef: surahRef ?? this.surahRef,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Remove Arabic diacritics / tashkeel for normalization and search
  static String removeDiacritics(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('\u0640', '')
        .trim();
  }

  /// Remove accents and diacritics from transliteration for forgiving search
  static String normalizeTransliteration(String input) {
    return input
        .replaceAll('ā', 'a')
        .replaceAll('ī', 'i')
        .replaceAll('ū', 'u')
        .replaceAll('ḥ', 'h')
        .replaceAll('ṣ', 's')
        .replaceAll('ḍ', 'd')
        .replaceAll('ṭ', 't')
        .replaceAll('ẓ', 'z')
        .replaceAll('ʿ', '')
        .replaceAll('’', '')
        .replaceAll('ʾ', '')
        .replaceAll('\'', '')
        .replaceAll('-', ' ')
        .toLowerCase()
        .trim();
  }
}

typedef AllahNameEntity = AllahNameModel;
