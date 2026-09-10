import 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';
import 'package:alhuda/features/fiqh/domain/repositories/fiqh_repository.dart';
import 'package:alhuda/features/fiqh/presentation/view_models/fiqh_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFiqhRepository implements FiqhRepository {
  final List<FiqhBook> _books = [
    const FiqhBook(
      id: 'book_taharah',
      title: 'كتاب الطهارة',
      subtitle: 'أحكام الوضوء والغسل',
      category: FiqhCategory.ibadat,
      icon: Icons.water_drop_rounded,
      chapters: [
        FiqhChapter(
          id: 'chap_wudu',
          bookId: 'book_taharah',
          title: 'باب الوضوء',
          summary: 'فرائض الوضوء وسننه',
          issues: [
            FiqhIssue(
              id: 'issue_wudu_faraid',
              title: 'فرائض الوضوء',
              rulingType: FiqhRulingType.fard,
              content: 'فرائض الوضوء ستة',
            ),
          ],
        ),
      ],
    ),
    const FiqhBook(
      id: 'book_buyoo',
      title: 'كتاب البيوع',
      subtitle: 'أحكام المعاملات المالية',
      category: FiqhCategory.muamalat,
      icon: Icons.storefront_rounded,
      chapters: [],
    ),
  ];

  @override
  List<FiqhBook> getAllBooks() => _books;

  @override
  List<FiqhBook> getBooksByCategory(FiqhCategory category) =>
      _books.where((b) => b.category == category).toList();

  @override
  FiqhBook? getBookById(String bookId) =>
      _books.firstWhere((b) => b.id == bookId);

  @override
  FiqhChapter? getChapterById(String bookId, String chapterId) => null;

  @override
  ({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})? getIssueById(
          String issueId) =>
      null;

  @override
  List<({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})>
      getFeaturedIssues() => [];

  @override
  String normalizeArabic(String input) => input;

  @override
  List<FiqhSearchResult> searchIssues(String query) => [];

  @override
  Future<void> ensureBookmarksLoaded() async {}

  @override
  List<FiqhBookmark> getBookmarks() => [];

  @override
  Future<void> removeBookmark(String issueId) async {}

  @override
  bool isBookmarked(String issueId) => false;

  @override
  Future<bool> toggleBookmark({
    required FiqhBook book,
    required FiqhChapter chapter,
    required FiqhIssue issue,
  }) async =>
      true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fiqh Clean Architecture Tests', () {
    late FiqhViewModel viewModel;

    setUp(() {
      viewModel = FiqhViewModel(repository: MockFiqhRepository());
    });

    test('FiqhViewModel loads and filters books by category', () {
      expect(viewModel.allBooks.length, equals(2));
      expect(viewModel.displayedBooks.length, equals(2));

      viewModel.selectCategory(FiqhCategory.ibadat);
      expect(viewModel.selectedCategory, equals(FiqhCategory.ibadat));
      expect(viewModel.displayedBooks.length, equals(1));
      expect(viewModel.displayedBooks.first.id, equals('book_taharah'));

      viewModel.selectCategory(null);
      expect(viewModel.displayedBooks.length, equals(2));
    });

    test('FiqhViewModel search query updates', () {
      viewModel.setSearchQuery('وضوء');
      expect(viewModel.searchQuery, equals('وضوء'));

      viewModel.clearSearch();
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.searchResults, isEmpty);
    });
  });
}
