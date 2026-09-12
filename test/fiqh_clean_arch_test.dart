import 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';
import 'package:alhuda/features/fiqh/domain/repositories/fiqh_repository.dart';
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
}
