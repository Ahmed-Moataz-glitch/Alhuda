import 'package:alhuda/services/quran_service.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranService _service;

  QuranRepositoryImpl({QuranService? service})
      : _service = service ?? QuranService.instance;

  @override
  Future<void> init() => _service.init();

  @override
  List<SurahData> getAllSurahs() => _service.getAllSurahs();

  @override
  SurahData? getSurah(int number) => _service.getSurah(number);

  @override
  List<AyahData> getAyahsForSurah(int surahNumber) =>
      _service.getAyahsForSurah(surahNumber);

  @override
  List<JuzData> getAllJuzs() => _service.getAllJuzs();

  @override
  List<QuranSearchResult> search(String query) => _service.search(query);

  @override
  List<QuranBookmark> getBookmarks() => _service.getBookmarks();

  @override
  Future<void> toggleBookmark({
    required int surah,
    required String surahName,
    required int ayah,
    required String snippet,
    int? pageNumber,
  }) =>
      _service.toggleBookmark(
        surah: surah,
        surahName: surahName,
        ayah: ayah,
        snippet: snippet,
        pageNumber: pageNumber,
      );

  @override
  bool isBookmarked(int surah, int ayah) =>
      _service.isBookmarked(surah, ayah);

  @override
  LastReadPosition? get lastRead => _service.lastRead;

  @override
  Future<void> setLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    int? pageNumber,
  }) =>
      _service.setLastRead(
        surahNumber: surahNumber,
        surahName: surahName,
        ayahNumber: ayahNumber,
        pageNumber: pageNumber,
      );
}
