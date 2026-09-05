import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/view/widgets/mushaf_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  group('Mushaf Page & Layout Tests', () {
    setUpAll(() async {
      await QuranService.instance.init();
    });

    test('getPageData returns accurate surahs and ayah bounds', () {
      // Page 1: Al-Fatiha
      final p1 = QuranService.instance.getPageData(1);
      expect(p1.isNotEmpty, isTrue);
      expect(p1.first['surah'], 1);
      expect(p1.first['start'], 1);
      expect(p1.first['end'], 7);

      // Page 77: An-Nisa (starts from Ayah 1)
      final p77 = QuranService.instance.getPageData(77);
      expect(p77.isNotEmpty, isTrue);
      expect(p77.first['surah'], 4);
      expect(p77.first['start'], 1);
      expect(p77.first['end'], 6);

      // Page 604: Al-Ikhlas, Al-Falaq, An-Nas
      final p604 = QuranService.instance.getPageData(604);
      expect(p604.length, 3);
      expect(p604[0]['surah'], 112);
      expect(p604[1]['surah'], 113);
      expect(p604[2]['surah'], 114);
    });

    test('getPageNumber resolves correct page for given Surah and Ayah', () {
      expect(QuranService.instance.getPageNumber(1, 1), 1);
      expect(QuranService.instance.getPageNumber(4, 1), 77);
      expect(QuranService.instance.getPageNumber(114, 6), 604);
    });

    test('toArabicDigits converts English numerals to Arabic numerals', () {
      expect(QuranService.toArabicDigits(1), '١');
      expect(QuranService.toArabicDigits(77), '٧٧');
      expect(QuranService.toArabicDigits(604), '٦٠٤');
    });

    test('getPageSurahName and getPageJuzName work correctly', () {
      expect(QuranService.instance.getPageSurahName(1), 'الفاتحة');
      expect(QuranService.instance.getPageSurahName(77), 'النساء');
      expect(QuranService.instance.getPageJuzNumber(77), 4);
      expect(QuranService.instance.getPageJuzName(77), 'الجزء الرابع');
    });

    test('LastRead and Bookmarks preserve pageNumber', () async {
      await QuranService.instance.setLastRead(
        surahNumber: 4,
        surahName: 'النساء',
        ayahNumber: 1,
        pageNumber: 77,
      );
      expect(QuranService.instance.lastRead?.pageNumber, 77);

      await QuranService.instance.toggleBookmark(
        surah: 4,
        surahName: 'النساء',
        ayah: 1,
        snippet: 'يَـٰٓأَيُّهَا ٱلنَّاسُ ٱتَّقُواْ رَبَّكُمُ...',
        pageNumber: 77,
      );
      expect(QuranService.instance.isBookmarked(4, 1), isTrue);
      final bm = QuranService.instance.getBookmarks().firstWhere((b) => b.surahNumber == 4);
      expect(bm.pageNumber, 77);

      await QuranService.instance.removeBookmark(4, 1);
      expect(QuranService.instance.isBookmarked(4, 1), isFalse);
    });

    testWidgets('MushafPageWidget renders Page 77 with Islamic frame, Surah Banner and Footer', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: MushafPageWidget(
                pageNumber: 77,
                onAyahTapped: (s, a, text) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Top Header: Juz 4 and Surah An-Nisa
      expect(find.text('الجزء الرابع'), findsOneWidget);
      expect(find.text('سورة النساء'), findsWidgets);

      // Footer with Arabic Page Number
      expect(find.text('— ٧٧ —'), findsOneWidget);

      // Advance fake timer to allow any font loader timeouts to complete cleanly in test environment
      await tester.pump(const Duration(seconds: 16));
    });
  });
}
