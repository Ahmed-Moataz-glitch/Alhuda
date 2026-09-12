import 'package:alhuda/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:alhuda/features/hadith/domain/entities/hadith_entities.dart';
import 'package:alhuda/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:flutter/foundation.dart';
export 'package:alhuda/features/hadith/domain/entities/hadith_entities.dart';
export 'package:alhuda/features/hadith/domain/repositories/hadith_repository.dart';
export 'package:alhuda/features/hadith/data/repositories/hadith_repository_impl.dart';

class HadithService extends ChangeNotifier {
  HadithService._();
  static final HadithService instance = HadithService._();

  final HadithRepository _repository = HadithRepositoryImpl();

  double _fontSize = 20.0;
  double get fontSize => _fontSize;

  void increaseFontSize() {
    if (_fontSize < 32.0) {
      _fontSize += 2.0;
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_fontSize > 14.0) {
      _fontSize -= 2.0;
      notifyListeners();
    }
  }

  void resetFontSize() {
    _fontSize = 20.0;
    notifyListeners();
  }

  Future<List<HadithBook>> getAllBooks() => _repository.getAllBooks();

  Future<HadithBook?> getBookById(String bookId) async {
    final books = await getAllBooks();
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  Future<List<HadithChapter>> getChapters(String bookId) =>
      _repository.getChapters(bookId);

  Future<List<HadithItem>> getChapterHadiths(String bookId, int chapterId) =>
      _repository.getChapterHadiths(bookId, chapterId);

  static String normalizeArabic(String input) =>
      HadithRepositoryImpl().normalizeArabic(input);

  Future<List<HadithSearchResult>> searchHadiths(
    String query, {
    String? filterBookId,
    int limit = 50,
  }) =>
      _repository.searchHadiths(query, filterBookId: filterBookId, limit: limit);

  Future<({HadithBook book, HadithChapter chapter, HadithItem hadith})?>
      getHadithOfTheDay() async {
    try {
      final books = await getAllBooks();
      if (books.isEmpty) return null;

      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

      final book = books[dayOfYear % books.length];
      final chapters = await getChapters(book.id);
      if (chapters.isEmpty) return null;

      final chapterIndex = dayOfYear % chapters.length;
      final chapter = chapters[chapterIndex];

      final hadiths = await getChapterHadiths(book.id, chapter.id);
      if (hadiths.isEmpty) return null;

      final hadith = hadiths[dayOfYear % hadiths.length];
      return (book: book, chapter: chapter, hadith: hadith);
    } catch (e) {
      debugPrint('Error getting Hadith of the day: $e');
      return null;
    }
  }

  Future<List<HadithBookmark>> getBookmarks() => _repository.getBookmarks();

  bool isBookmarked(String bookId, int chapterId, int hadithNumber) =>
      _repository.isBookmarked(bookId, chapterId, hadithNumber);

  Future<void> toggleBookmark(HadithBookmark bookmark) async {
    await _repository.toggleBookmark(
      bookId: bookmark.bookId,
      bookTitle: bookmark.bookTitle,
      chapterId: bookmark.chapterId,
      chapterTitle: bookmark.chapterTitle,
      hadithNumber: bookmark.hadithNumber,
      snippet: bookmark.snippet,
    );
    notifyListeners();
  }
}
