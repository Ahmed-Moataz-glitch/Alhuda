import 'package:alhuda/features/fiqh/data/repositories/fiqh_repository_impl.dart';
import 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';
import 'package:alhuda/features/fiqh/domain/repositories/fiqh_repository.dart';
export 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';
export 'package:alhuda/features/fiqh/domain/repositories/fiqh_repository.dart';
export 'package:alhuda/features/fiqh/data/repositories/fiqh_repository_impl.dart';

class FiqhService {
  FiqhService._();
  static final FiqhService instance = FiqhService._();

  final FiqhRepository _repository = FiqhRepositoryImpl();

  List<FiqhBook> getAllBooks() => _repository.getAllBooks();

  List<FiqhBook> getBooksByCategory(FiqhCategory category) =>
      _repository.getBooksByCategory(category);

  FiqhBook? getBookById(String bookId) => _repository.getBookById(bookId);

  FiqhChapter? getChapterById(String bookId, String chapterId) =>
      _repository.getChapterById(bookId, chapterId);

  ({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})? getIssueById(
          String issueId) =>
      _repository.getIssueById(issueId);

  int get totalChaptersCount =>
      getAllBooks().fold(0, (sum, book) => sum + book.chaptersCount);

  int get totalIssuesCount =>
      getAllBooks().fold(0, (sum, book) => sum + book.totalIssuesCount);

  static String normalizeArabic(String input) =>
      FiqhRepositoryImpl().normalizeArabic(input);

  List<FiqhSearchResult> search(String rawQuery) =>
      _repository.searchIssues(rawQuery);

  List<({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})>
      getFeaturedIssues() => _repository.getFeaturedIssues();

  bool isBookmarked(String issueId) => _repository.isBookmarked(issueId);

  Future<void> ensureBookmarksLoaded() => _repository.ensureBookmarksLoaded();

  List<FiqhBookmark> getBookmarks() => _repository.getBookmarks();

  Future<void> removeBookmark(String issueId) =>
      _repository.removeBookmark(issueId);

  Future<bool> toggleBookmark({
    required FiqhBook book,
    required FiqhChapter chapter,
    required FiqhIssue issue,
  }) =>
      _repository.toggleBookmark(
        book: book,
        chapter: chapter,
        issue: issue,
      );
}
