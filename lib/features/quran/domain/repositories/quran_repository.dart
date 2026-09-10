import 'package:alhuda/features/quran/domain/entities/quran_entities.dart';

abstract class QuranRepository {
  Future<void> init();
  List<SurahData> getAllSurahs();
  SurahData? getSurah(int number);
  List<AyahData> getAyahsForSurah(int surahNumber);
  List<JuzData> getAllJuzs();
  List<QuranSearchResult> search(String query);
  List<QuranBookmark> getBookmarks();
  Future<void> toggleBookmark({
    required int surah,
    required String surahName,
    required int ayah,
    required String snippet,
    int? pageNumber,
  });
  bool isBookmarked(int surah, int ayah);
  LastReadPosition? get lastRead;
  Future<void> setLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    int? pageNumber,
  });
}
