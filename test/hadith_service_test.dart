import 'package:alhuda/services/hadith_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('HadithService & HadithData Tests', () {
    final service = HadithService.instance;

    test('All Hadith books are loaded correctly', () async {
      final books = await service.getAllBooks();
      expect(books.length, equals(3));

      final bukhari = await service.getBookById('bukhari');
      expect(bukhari, isNotNull);
      expect(bukhari!.title, contains('البخاري'));
      expect(bukhari.totalHadiths, greaterThan(7000));
      expect(bukhari.totalChapters, equals(97));

      final muslim = await service.getBookById('muslim');
      expect(muslim, isNotNull);
      expect(muslim!.title, contains('مسلم'));
      expect(muslim.totalHadiths, greaterThan(7000));
      expect(muslim.totalChapters, equals(57));

      final nawawi = await service.getBookById('nawawi40');
      expect(nawawi, isNotNull);
      expect(nawawi!.title, contains('النووية'));
      expect(nawawi.totalHadiths, equals(42));
    });

    test('Bukhari chapters are loaded and valid', () async {
      final chapters = await service.getChapters('bukhari');
      expect(chapters.length, equals(97));

      final firstChapter = chapters.first;
      expect(firstChapter.id, equals(1));
      expect(firstChapter.title, contains('بدء'));
      expect(firstChapter.hadithsCount, equals(7));
    });

    test('Muslim chapters are loaded and valid', () async {
      final chapters = await service.getChapters('muslim');
      expect(chapters.length, equals(57));

      final firstChapter = chapters.first;
      expect(firstChapter.id, equals(1));
      expect(firstChapter.title, contains('الإيمان'));
      expect(firstChapter.hadithsCount, greaterThan(100));
    });

    test('Chapter hadiths content loading', () async {
      final hadiths = await service.getChapterHadiths('bukhari', 1);
      expect(hadiths.length, equals(7));

      final firstHadith = hadiths.first;
      expect(firstHadith.idInBook, equals(1));
      expect(firstHadith.arabic, contains('الْأَعْمَالُ بِالنِّيَّاتِ'));
    });

    test('Forty Nawawi hadiths loading', () async {
      final hadiths = await service.getChapterHadiths('nawawi40', 0);
      expect(hadiths.length, equals(42));
      expect(hadiths.first.arabic, contains('الْأَعْمَالُ بِالنِّيَّاتِ'));
    });

    test('Arabic text normalization', () {
      const original = 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى';
      final normalized = HadithService.normalizeArabic(original);

      expect(normalized, isNot(contains('َ'))); // no fatha
      expect(normalized, isNot(contains('ِ'))); // no kasra
      expect(normalized, contains('الاعمال'));
      expect(normalized, contains('بالنيات'));
    });

    test('Search functionality finds relevant hadiths', () async {
      final results = await service.searchHadiths('النيات');
      expect(results, isNotEmpty);
      expect(results.first.bookTitle, isNotEmpty);
      expect(results.first.matchedSnippet, contains('النيات'));
    });

    test('Font size adjustment works within limits', () {
      service.resetFontSize();
      expect(service.fontSize, equals(20.0));

      service.increaseFontSize();
      expect(service.fontSize, equals(22.0));

      service.decreaseFontSize();
      expect(service.fontSize, equals(20.0));
    });

    test('HadithBookmark serialization and uniqueKey', () {
      const bookmark = HadithBookmark(
        bookId: 'bukhari',
        bookTitle: 'صحيح البخاري',
        chapterId: 1,
        chapterTitle: 'كتاب بدء الوحي',
        hadithNumber: 1,
        snippet: 'إنما الأعمال بالنيات...',
        addedDate: '2026-09-09',
      );

      expect(bookmark.uniqueKey, equals('bukhari_1_1'));
      final json = bookmark.toJson();
      final restored = HadithBookmark.fromJson(json);

      expect(restored.bookId, equals(bookmark.bookId));
      expect(restored.bookTitle, equals(bookmark.bookTitle));
      expect(restored.chapterId, equals(bookmark.chapterId));
      expect(restored.chapterTitle, equals(bookmark.chapterTitle));
      expect(restored.hadithNumber, equals(bookmark.hadithNumber));
      expect(restored.snippet, equals(bookmark.snippet));
    });
  });
}
