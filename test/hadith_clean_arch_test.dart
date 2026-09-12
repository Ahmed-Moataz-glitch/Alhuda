import 'package:alhuda/features/hadith/domain/entities/hadith_entities.dart';
import 'package:alhuda/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHadithRepository implements HadithRepository {
  final List<HadithBook> _books = [
    const HadithBook(
      id: 'bukhari',
      numericId: 1,
      title: 'صحيح البخاري',
      author: 'الإمام البخاري',
      subtitle: 'الجامع المسند الصحيح',
      badge: 'أصح الكتب',
      colorValue: 0xFF1B5E20,
      totalHadiths: 7563,
      totalChapters: 97,
      iconName: 'auto_stories_rounded',
    ),
  ];

  @override
  Future<List<HadithBook>> getAllBooks() async => _books;

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async => [
        const HadithChapter(
          id: 1,
          title: 'بدء الوحي',
          hadithsCount: 7,
          startHadith: 1,
          endHadith: 7,
        ),
      ];

  @override
  Future<List<HadithItem>> getChapterHadiths(
          String bookId, int chapterId) async =>
      [
        const HadithItem(
          id: 1,
          idInBook: 1,
          chapterId: 1,
          bookId: 1,
          arabic: 'إنما الأعمال بالنيات',
        ),
      ];

  @override
  Future<List<HadithItem>> getFortyNawawiHadiths() async => [];

  @override
  String normalizeArabic(String input) => input;

  @override
  Future<List<HadithSearchResult>> searchHadiths(String query,
          {String? filterBookId, int limit = 50}) async =>
      [];

  @override
  Future<List<HadithBookmark>> getBookmarks() async => [];

  @override
  bool isBookmarked(String bookId, int chapterId, int hadithNumber) => false;

  @override
  Future<bool> toggleBookmark({
    required String bookId,
    required String bookTitle,
    required int chapterId,
    required String chapterTitle,
    required int hadithNumber,
    required String snippet,
  }) async =>
      true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
}
