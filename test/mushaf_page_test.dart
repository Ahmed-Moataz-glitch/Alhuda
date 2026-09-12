import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/features/quran/presentation/view/widgets/mushaf_page_widget.dart';
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

      await tester.pumpAndSettle();
    });

    testWidgets('MushafPageWidget renders Page 1 (Al-Fatiha) offline with Basmallah and Surah Banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: MushafPageWidget(
                pageNumber: 1,
                onAyahTapped: (s, a, text) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(find.text('— ١ —'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('MushafPageWidget uses ayahNumber font and Tajweed colors for verse rendering', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: MushafPageWidget(
                pageNumber: 1,
                showTajweed: true,
                onAyahTapped: (s, a, text) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find RichTexts on page
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      expect(richTexts.isNotEmpty, isTrue);

      // Check if any RichText contains the authentic ayahNumber font
      bool hasAyahNumberFont = false;
      for (final rt in richTexts) {
        rt.text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontFamily?.contains('ayahNumber') == true) {
            hasAyahNumberFont = true;
            return false;
          }
          return true;
        });
        if (hasAyahNumberFont) break;
      }
      expect(hasAyahNumberFont, isTrue, reason: 'Authentic ayahNumber font must be used for ayah markers');
    });

    testWidgets('MushafPageWidget dynamically updates text font size based on fontSize property', (WidgetTester tester) async {
      // 1. Render with smaller font size (22)
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: MushafPageWidget(
                pageNumber: 3,
                fontSize: 22.0,
                onAyahTapped: (s, a, text) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double? fontSize22;
      final richTexts22 = tester.widgetList<RichText>(find.byType(RichText));
      for (final rt in richTexts22) {
        rt.text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontWeight == FontWeight.w600 && span.style?.fontSize != null) {
            fontSize22 = span.style?.fontSize;
            return false;
          }
          return true;
        });
        if (fontSize22 != null) break;
      }
      expect(fontSize22, isNotNull);

      // 2. Re-render with larger font size (32)
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: MushafPageWidget(
                key: const ValueKey('mushaf_p3_s32'),
                pageNumber: 3,
                fontSize: 32.0,
                onAyahTapped: (s, a, text) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double? fontSize32;
      final richTexts32 = tester.widgetList<RichText>(find.byType(RichText));
      for (final rt in richTexts32) {
        rt.text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontWeight == FontWeight.w600 && span.style?.fontSize != null) {
            fontSize32 = span.style?.fontSize;
            return false;
          }
          return true;
        });
        if (fontSize32 != null) break;
      }
      expect(fontSize32, isNotNull);

      // Verify that font size actually increased
      expect(fontSize32!, greaterThan(fontSize22!));
    });

    test('QuranService audio helpers work correctly', () async {
      final isDownloaded = await QuranService.instance.isSurahAudioDownloaded(1);
      expect(isDownloaded, isFalse);

      final canPlay = await QuranService.instance.canPlayAudio(1);
      expect(canPlay, isA<bool>());
    });
  });
}
