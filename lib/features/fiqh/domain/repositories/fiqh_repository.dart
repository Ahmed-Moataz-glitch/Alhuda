import 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';

abstract class FiqhRepository {
  List<FiqhBook> getAllBooks();
  List<FiqhBook> getBooksByCategory(FiqhCategory category);
  FiqhBook? getBookById(String bookId);
  FiqhChapter? getChapterById(String bookId, String chapterId);
  ({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})? getIssueById(String issueId);
  List<FiqhSearchResult> searchIssues(String query);
  List<({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})> getFeaturedIssues();
  String normalizeArabic(String input);
  Future<void> ensureBookmarksLoaded();
  List<FiqhBookmark> getBookmarks();
  Future<void> removeBookmark(String issueId);
  Future<bool> toggleBookmark({
    required FiqhBook book,
    required FiqhChapter chapter,
    required FiqhIssue issue,
  });
  bool isBookmarked(String issueId);
}
