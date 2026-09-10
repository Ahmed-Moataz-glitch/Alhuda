/// Represents a Tafsir book source with its metadata
class TafsirSource {
  final String id;
  final String key;
  final String name;
  final String author;
  final String language;
  final String apiType; // 'qurancdn' or 'alquran_cloud'

  const TafsirSource({
    required this.id,
    required this.key,
    required this.name,
    required this.author,
    this.language = 'ar',
    required this.apiType,
  });
}

/// Represents the parsed Tafsir text for an Ayah
class AyahTafsir {
  final String tafsirId;
  final String tafsirName;
  final int surahNumber;
  final int ayahNumber;
  final String text;

  const AyahTafsir({
    required this.tafsirId,
    required this.tafsirName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
  });
}
