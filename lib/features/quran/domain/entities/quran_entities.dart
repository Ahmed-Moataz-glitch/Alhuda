import 'package:quran/quran.dart' as quran;

/// Representation of a Quran Surah
class SurahData {
  final int number;
  final String arabicName;
  final String englishName;
  final String englishTranslation;
  final String revelationType; // 'مكية' or 'مدنية'
  final int totalAyahs;
  final int startPage;

  const SurahData({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.englishTranslation,
    required this.revelationType,
    required this.totalAyahs,
    required this.startPage,
  });
}

/// Representation of a Quran Ayah
class AyahData {
  final int surahNumber;
  final int ayahNumber;
  final String uthmaniText;
  final String simpleText;

  const AyahData({
    required this.surahNumber,
    required this.ayahNumber,
    required this.uthmaniText,
    required this.simpleText,
  });
}

/// Representation of a Juz
class JuzData {
  final int number;
  final int startSurahNumber;
  final String startSurahName;
  final int startAyahNumber;
  final int startPage;

  const JuzData({
    required this.number,
    required this.startSurahNumber,
    required this.startSurahName,
    required this.startAyahNumber,
    required this.startPage,
  });
}

/// Bookmark model
class QuranBookmark {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final int pageNumber;
  final String snippet;
  final DateTime timestamp;

  const QuranBookmark({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.pageNumber,
    required this.snippet,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'pageNumber': pageNumber,
        'snippet': snippet,
        'timestamp': timestamp.toIso8601String(),
      };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    final sNum = json['surahNumber'] as int? ?? 1;
    final aNum = json['ayahNumber'] as int? ?? 1;
    final pNum = json['pageNumber'] as int? ?? quran.getPageNumber(sNum, aNum);
    return QuranBookmark(
      surahNumber: sNum,
      surahName: json['surahName'] as String? ?? 'الفاتحة',
      ayahNumber: aNum,
      pageNumber: pNum,
      snippet: json['snippet'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Last read position
class LastReadPosition {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final int pageNumber;
  final DateTime timestamp;

  const LastReadPosition({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.pageNumber,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'pageNumber': pageNumber,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LastReadPosition.fromJson(Map<String, dynamic> json) {
    final sNum = json['surahNumber'] as int? ?? 1;
    final aNum = json['ayahNumber'] as int? ?? 1;
    final pNum = json['pageNumber'] as int? ?? quran.getPageNumber(sNum, aNum);
    return LastReadPosition(
      surahNumber: sNum,
      surahName: json['surahName'] as String? ?? 'الفاتحة',
      ayahNumber: aNum,
      pageNumber: pNum,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Search result model
class QuranSearchResult {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String uthmaniText;
  final String simpleText;

  const QuranSearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.uthmaniText,
    required this.simpleText,
  });
}

/// Reciter model
class ReciterInfo {
  final String id;
  final String name;
  final String subgrade;

  const ReciterInfo({
    required this.id,
    required this.name,
    required this.subgrade,
  });
}
