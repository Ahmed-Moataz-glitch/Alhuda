import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_kit/audio.dart';
import 'package:quran_kit/core.dart';
import 'package:quran_kit/kit.dart';
import 'package:quran_kit/text.dart';
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
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
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
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
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

/// Central service for Quran features in Alhuda app
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  bool _isInitialized = false;
  List<SurahData> _surahs = [];
  final List<QuranBookmark> _bookmarks = [];
  LastReadPosition? _lastRead;
  File? _bookmarksFile;
  File? _lastReadFile;
  QpcV4AssetsStore? _qpcStore;

  QpcV4AssetsStore? get qpcStore => _qpcStore;

  Future<QpcV4AssetsStore> ensureQpcStore() async {
    if (_qpcStore != null) return _qpcStore!;
    _qpcStore = await QuranDataLoader.load();
    return _qpcStore!;
  }

  static const List<JuzData> kDefaultJuzs = [
    JuzData(number: 1, startSurahNumber: 1, startSurahName: 'الفاتحة', startAyahNumber: 1, startPage: 1),
    JuzData(number: 2, startSurahNumber: 2, startSurahName: 'البقرة', startAyahNumber: 142, startPage: 22),
    JuzData(number: 3, startSurahNumber: 2, startSurahName: 'البقرة', startAyahNumber: 253, startPage: 42),
    JuzData(number: 4, startSurahNumber: 3, startSurahName: 'آل عمران', startAyahNumber: 93, startPage: 62),
    JuzData(number: 5, startSurahNumber: 4, startSurahName: 'النساء', startAyahNumber: 24, startPage: 82),
    JuzData(number: 6, startSurahNumber: 4, startSurahName: 'النساء', startAyahNumber: 148, startPage: 102),
    JuzData(number: 7, startSurahNumber: 5, startSurahName: 'المائدة', startAyahNumber: 82, startPage: 121),
    JuzData(number: 8, startSurahNumber: 6, startSurahName: 'الأنعام', startAyahNumber: 111, startPage: 142),
    JuzData(number: 9, startSurahNumber: 7, startSurahName: 'الأعراف', startAyahNumber: 88, startPage: 162),
    JuzData(number: 10, startSurahNumber: 8, startSurahName: 'الأنفال', startAyahNumber: 41, startPage: 182),
    JuzData(number: 11, startSurahNumber: 9, startSurahName: 'التوبة', startAyahNumber: 93, startPage: 201),
    JuzData(number: 12, startSurahNumber: 11, startSurahName: 'هود', startAyahNumber: 6, startPage: 222),
    JuzData(number: 13, startSurahNumber: 12, startSurahName: 'يوسف', startAyahNumber: 53, startPage: 242),
    JuzData(number: 14, startSurahNumber: 15, startSurahName: 'الحجر', startAyahNumber: 1, startPage: 262),
    JuzData(number: 15, startSurahNumber: 17, startSurahName: 'الإسراء', startAyahNumber: 1, startPage: 282),
    JuzData(number: 16, startSurahNumber: 18, startSurahName: 'الكهف', startAyahNumber: 75, startPage: 302),
    JuzData(number: 17, startSurahNumber: 21, startSurahName: 'الأنبياء', startAyahNumber: 1, startPage: 322),
    JuzData(number: 18, startSurahNumber: 23, startSurahName: 'المؤمنون', startAyahNumber: 1, startPage: 342),
    JuzData(number: 19, startSurahNumber: 25, startSurahName: 'الفرقان', startAyahNumber: 21, startPage: 362),
    JuzData(number: 20, startSurahNumber: 27, startSurahName: 'النمل', startAyahNumber: 56, startPage: 382),
    JuzData(number: 21, startSurahNumber: 29, startSurahName: 'العنكبوت', startAyahNumber: 46, startPage: 402),
    JuzData(number: 22, startSurahNumber: 33, startSurahName: 'الأحزاب', startAyahNumber: 31, startPage: 422),
    JuzData(number: 23, startSurahNumber: 36, startSurahName: 'يس', startAyahNumber: 28, startPage: 442),
    JuzData(number: 24, startSurahNumber: 39, startSurahName: 'الزمر', startAyahNumber: 32, startPage: 462),
    JuzData(number: 25, startSurahNumber: 41, startSurahName: 'فصلت', startAyahNumber: 47, startPage: 482),
    JuzData(number: 26, startSurahNumber: 46, startSurahName: 'الأحقاف', startAyahNumber: 1, startPage: 502),
    JuzData(number: 27, startSurahNumber: 51, startSurahName: 'الذاريات', startAyahNumber: 31, startPage: 522),
    JuzData(number: 28, startSurahNumber: 58, startSurahName: 'المجادلة', startAyahNumber: 1, startPage: 542),
    JuzData(number: 29, startSurahNumber: 67, startSurahName: 'الملك', startAyahNumber: 1, startPage: 562),
    JuzData(number: 30, startSurahNumber: 78, startSurahName: 'النبأ', startAyahNumber: 1, startPage: 582),
  ];

  static const List<int> kSurahStartPages = [
    1, 2, 50, 77, 106, 128, 151, 177, 187, 208, 221, 235, 249, 255, 262, 267,
    282, 293, 305, 312, 322, 332, 342, 350, 359, 367, 377, 385, 396, 404, 411,
    415, 418, 428, 434, 440, 446, 453, 458, 467, 477, 483, 489, 496, 499, 502,
    507, 511, 515, 518, 520, 523, 526, 528, 531, 534, 537, 542, 545, 549, 551,
    553, 554, 556, 558, 560, 562, 564, 566, 568, 570, 572, 574, 575, 577, 578,
    580, 582, 583, 585, 586, 587, 587, 589, 590, 591, 591, 592, 593, 594, 595,
    595, 596, 596, 597, 597, 598, 598, 599, 599, 600, 600, 601, 601, 601, 602,
    602, 602, 603, 603, 603, 604, 604, 604,
  ];

  /// Initialize all required Quran services and embedded texts
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize QuranKit with QFC4 Hafs font baseUrl and colored Tajweed enabled
      try {
        await QuranKit.initialize(const QuranKitConfig(
          fontBaseUrl: 'https://github.com/MoeEyani/qfc4-quran-fonts/releases/download/v1.0.0',
          enableAudio: true,
          enableTafsir: true,
          enableSearch: true,
          enableWordByWord: true,
          showTajweed: true,
        ));
      } catch (e) {
        debugPrint('QuranKit.initialize warning: $e');
      }

      // 2. Load QPC v4 page layout & word assets store
      try {
        _qpcStore = await QuranDataLoader.load();
      } catch (e) {
        debugPrint('QuranDataLoader.load warning: $e');
      }

      // 3. Load embedded text offline in memory
      await QuranEmbeddedText.instance.loadAll();

      // 4. Load Surahs metadata
      final surahInfos = await QuranDataLoader.loadSurahs();
      _surahs = surahInfos.map((info) {
        final page = (info.number >= 1 && info.number <= kSurahStartPages.length)
            ? kSurahStartPages[info.number - 1]
            : 1;
        final cleanName = info.arabicName
            .replaceAll(RegExp(r'^سُ?ورَةُ?\s*'), '')
            .replaceAll('ٱ', 'ا')
            .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u06D6-\u06ED]'), '')
            .trim();
        return SurahData(
          number: info.number,
          arabicName: cleanName,
          englishName: info.englishName,
          englishTranslation: info.englishNameTranslation,
          revelationType: getPlaceOfRevelationArabic(info.number),
          totalAyahs: info.ayahCount,
          startPage: page,
        );
      }).toList();

      // Sort by number
      _surahs.sort((a, b) => a.number.compareTo(b.number));

      // 4. Load persisted storage (bookmarks & last read)
      try {
        final appDoc = await getApplicationDocumentsDirectory();
        _bookmarksFile = File('${appDoc.path}/alhuda_quran_bookmarks.json');
        _lastReadFile = File('${appDoc.path}/alhuda_quran_last_read.json');

        await _loadBookmarksFromDisk();
        await _loadLastReadFromDisk();
      } catch (e) {
        debugPrint('Bookmarks/LastRead load warning: $e');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('QuranService init error: $e');
    }
  }

  List<SurahData> getAllSurahs() {
    if (_surahs.isNotEmpty) return List.unmodifiable(_surahs);
    final list = <SurahData>[];
    for (int i = 1; i <= 114; i++) {
      final page = (i >= 1 && i <= kSurahStartPages.length)
          ? kSurahStartPages[i - 1]
          : quran.getPageNumber(i, 1);
      final rawName = quran.getSurahNameArabic(i);
      final cleanName = rawName
          .replaceAll(RegExp(r'^سُ?ورَةُ?\s*'), '')
          .replaceAll('ٱ', 'ا')
          .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u06D6-\u06ED]'), '')
          .trim();
      list.add(SurahData(
        number: i,
        arabicName: cleanName,
        englishName: quran.getSurahName(i),
        englishTranslation: quran.getSurahNameEnglish(i),
        revelationType: getPlaceOfRevelationArabic(i),
        totalAyahs: quran.getVerseCount(i),
        startPage: page,
      ));
    }
    return list;
  }

  SurahData? getSurah(int number) {
    if (number < 1 || number > _surahs.length) return null;
    return _surahs[number - 1];
  }

  List<JuzData> getAllJuzs() => kDefaultJuzs;

  /// Get all ayahs for a given surah with Uthmani & Simple texts
  List<AyahData> getAyahsForSurah(int surahNumber) {
    final uthmaniMap = QuranEmbeddedText.instance.getUthmaniSurah(surahNumber);
    final simpleMap = QuranEmbeddedText.instance.getSimpleSurah(surahNumber);
    if (uthmaniMap == null) return [];

    final list = <AyahData>[];
    final total = uthmaniMap.length;
    for (int i = 1; i <= total; i++) {
      list.add(AyahData(
        surahNumber: surahNumber,
        ayahNumber: i,
        uthmaniText: uthmaniMap[i] ?? '',
        simpleText: simpleMap?[i] ?? '',
      ));
    }
    return list;
  }

  /// Get single ayah text
  String getAyahUthmani(int surah, int ayah) {
    return QuranEmbeddedText.instance.getUthmani(surah, ayah) ?? '';
  }

  /// Search ayahs and surahs by query text
  List<QuranSearchResult> search(String rawQuery) {
    final query = _normalizeArabic(rawQuery.trim());
    if (query.isEmpty) return [];

    final results = <QuranSearchResult>[];

    for (final surah in _surahs) {
      final simpleMap = QuranEmbeddedText.instance.getSimpleSurah(surah.number);
      final uthmaniMap = QuranEmbeddedText.instance.getUthmaniSurah(surah.number);
      if (simpleMap == null) continue;

      for (final entry in simpleMap.entries) {
        final ayahNum = entry.key;
        final simpleText = entry.value;
        final normalizedText = _normalizeArabic(simpleText);

        if (normalizedText.contains(query)) {
          results.add(QuranSearchResult(
            surahNumber: surah.number,
            surahName: surah.arabicName,
            ayahNumber: ayahNum,
            uthmaniText: uthmaniMap?[ayahNum] ?? simpleText,
            simpleText: simpleText,
          ));

          if (results.length >= 100) return results; // Cap search results for performance
        }
      }
    }

    return results;
  }

  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u06D6-\u06ED]'), '') // remove tashkeel
        .replaceAll(RegExp(r'[إأآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }

  // ── Bookmarks ──

  List<QuranBookmark> getBookmarks() => List.unmodifiable(_bookmarks);

  bool isBookmarked(int surah, int ayah) {
    return _bookmarks.any((b) => b.surahNumber == surah && b.ayahNumber == ayah);
  }

  Future<void> toggleBookmark({
    required int surah,
    required String surahName,
    required int ayah,
    required String snippet,
    int? pageNumber,
  }) async {
    final index = _bookmarks.indexWhere((b) => b.surahNumber == surah && b.ayahNumber == ayah);
    if (index >= 0) {
      _bookmarks.removeAt(index);
    } else {
      _bookmarks.insert(
        0,
        QuranBookmark(
          surahNumber: surah,
          surahName: surahName,
          ayahNumber: ayah,
          pageNumber: pageNumber ?? quran.getPageNumber(surah, ayah),
          snippet: snippet,
          timestamp: DateTime.now(),
        ),
      );
    }
    await _saveBookmarksToDisk();
  }

  Future<void> removeBookmark(int surah, int ayah) async {
    _bookmarks.removeWhere((b) => b.surahNumber == surah && b.ayahNumber == ayah);
    await _saveBookmarksToDisk();
  }

  Future<void> _loadBookmarksFromDisk() async {
    if (_bookmarksFile == null || !await _bookmarksFile!.exists()) return;
    try {
      final jsonStr = await _bookmarksFile!.readAsString();
      final List<dynamic> list = jsonDecode(jsonStr);
      _bookmarks.clear();
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _bookmarks.add(QuranBookmark.fromJson(item));
        }
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> _saveBookmarksToDisk() async {
    if (_bookmarksFile == null) return;
    try {
      final list = _bookmarks.map((b) => b.toJson()).toList();
      await _bookmarksFile!.writeAsString(jsonEncode(list), flush: true);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  // ── Last Read ──

  LastReadPosition? get lastRead => _lastRead;

  Future<void> setLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    int? pageNumber,
  }) async {
    _lastRead = LastReadPosition(
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber ?? quran.getPageNumber(surahNumber, ayahNumber),
      timestamp: DateTime.now(),
    );
    await _saveLastReadToDisk();
  }

  Future<void> _loadLastReadFromDisk() async {
    if (_lastReadFile == null || !await _lastReadFile!.exists()) return;
    try {
      final jsonStr = await _lastReadFile!.readAsString();
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      _lastRead = LastReadPosition.fromJson(map);
    } catch (e) {
      debugPrint('Error loading last read: $e');
    }
  }

  Future<void> _saveLastReadToDisk() async {
    if (_lastReadFile == null || _lastRead == null) return;
    try {
      await _lastReadFile!.writeAsString(jsonEncode(_lastRead!.toJson()), flush: true);
    } catch (e) {
      debugPrint('Error saving last read: $e');
    }
  }

  // ── Madinah Mushaf Page Helpers (604 pages) ──

  static const List<String> kJuzNames = [
    'الجزء الأول',
    'الجزء الثاني',
    'الجزء الثالث',
    'الجزء الرابع',
    'الجزء الخامس',
    'الجزء السادس',
    'الجزء السابع',
    'الجزء الثامن',
    'الجزء التاسع',
    'الجزء العاشر',
    'الجزء الحادي عشر',
    'الجزء الثاني عشر',
    'الجزء الثالث عشر',
    'الجزء الرابع عشر',
    'الجزء الخامس عشر',
    'الجزء السادس عشر',
    'الجزء السابع عشر',
    'الجزء الثامن عشر',
    'الجزء التاسع عشر',
    'الجزء العشرون',
    'الجزء الحادي والعشرون',
    'الجزء الثاني والعشرون',
    'الجزء الثالث والعشرون',
    'الجزء الرابع والعشرون',
    'الجزء الخامس والعشرون',
    'الجزء السادس والعشرون',
    'الجزء السابع والعشرون',
    'الجزء الثامن والعشرون',
    'الجزء التاسع والعشرون',
    'الجزء الثلاثون',
  ];

  int getPageNumber(int surah, int ayah) => quran.getPageNumber(surah, ayah);

  List<Map<String, int>> getPageData(int pageNumber) {
    final raw = quran.getPageData(pageNumber);
    return raw.map((item) {
      final map = item as Map;
      return {
        'surah': (map['surah'] as num).toInt(),
        'start': (map['start'] as num).toInt(),
        'end': (map['end'] as num).toInt(),
      };
    }).toList();
  }

  int getPageJuzNumber(int pageNumber) {
    final pageData = getPageData(pageNumber);
    if (pageData.isEmpty) return 1;
    final first = pageData.first;
    return quran.getJuzNumber(first['surah'] ?? 1, first['start'] ?? 1);
  }

  String getPageJuzName(int pageNumber) {
    final juzNum = getPageJuzNumber(pageNumber);
    if (juzNum >= 1 && juzNum <= kJuzNames.length) {
      return kJuzNames[juzNum - 1];
    }
    return 'الجزء ${toArabicDigits(juzNum)}';
  }

  String getPageSurahName(int pageNumber) {
    final pageData = getPageData(pageNumber);
    if (pageData.isEmpty) return '';
    final surahNum = pageData.first['surah'] ?? 1;
    final surah = getSurah(surahNum);
    return surah?.arabicName ?? quran.getSurahNameArabic(surahNum);
  }

  String getSurahNameArabic(int surahNumber) => quran.getSurahNameArabic(surahNumber);

  int getVerseCount(int surahNumber) => quran.getVerseCount(surahNumber);

  String getPlaceOfRevelationArabic(int surahNumber) {
    return quran.getPlaceOfRevelation(surahNumber) == 'Makkah' ? 'مكية' : 'مدنية';
  }

  String getVerseUthmani(int surah, int ayah) {
    return quran.getVerse(surah, ayah, verseEndSymbol: false);
  }

  String getVerseEndSymbol(int verseNumber) {
    return quran.getVerseEndSymbol(verseNumber, arabicNumeral: true);
  }

  static String toArabicDigits(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String s = number.toString();
    for (int i = 0; i < english.length; i++) {
      s = s.replaceAll(english[i], arabic[i]);
    }
    return s;
  }

  // ── Audio Helpers ──

  QuranAudioService get audioService => QuranAudioService.instance;
  List<QuranReciter> get reciters => QuranAudioService.reciters;
}
