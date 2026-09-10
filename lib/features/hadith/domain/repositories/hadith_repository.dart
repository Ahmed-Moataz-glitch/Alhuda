import 'package:alhuda/features/hadith/domain/entities/hadith_entities.dart';

abstract class HadithRepository {
  Future<List<HadithBook>> getAllBooks();
  Future<List<HadithChapter>> getChapters(String bookId);
  Future<List<HadithItem>> getChapterHadiths(String bookId, int chapterId);
  Future<List<HadithItem>> getFortyNawawiHadiths();
  Future<List<HadithSearchResult>> searchHadiths(
    String query, {
    String? filterBookId,
    int limit = 50,
  });
  String normalizeArabic(String input);
  Future<List<HadithBookmark>> getBookmarks();
  Future<bool> toggleBookmark({
    required String bookId,
    required String bookTitle,
    required int chapterId,
    required String chapterTitle,
    required int hadithNumber,
    required String snippet,
  });
  bool isBookmarked(String bookId, int chapterId, int hadithNumber);
}
