import 'package:alhuda/features/quran/data/dua_khatm_quran_data.dart';
import 'package:alhuda/features/quran/presentation/view/pages/dua_khatm_quran_page.dart';
import 'package:alhuda/features/quran/presentation/view/pages/mushaf_page_view.dart';
import 'package:alhuda/features/quran/presentation/view/widgets/dua_khatm_quran_mushaf_page.dart';
import 'package:alhuda/features/quran/presentation/view/widgets/quran_widget.dart';
import 'package:alhuda/services/quran_service.dart';
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

  group('DuaKhatmQuranData Tests', () {
    test('Contains canonical supplications and sections', () {
      expect(DuaKhatmQuranData.title, contains('خَتْمِ القُرْآنِ'));
      expect(DuaKhatmQuranData.basmalah, contains('بِسْمِ اللَّهِ'));
      expect(DuaKhatmQuranData.sections.length, greaterThanOrEqualTo(10));

      final full = DuaKhatmQuranData.fullText;
      expect(full, contains('اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ'));
      expect(full, contains('اللَّهُمَّ أَصْلِحْ لِي دِينِي'));
      expect(full, contains('اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ'));
      expect(full, contains('يَا أَرْحَمَ الرَّاحِمِينَ'));
      expect(full, contains('وَصَلَّى اللهُ عَلَى نَبِيِّنَا مُحَمَّدٍ'));
    });
  });

  group('Dua Khatm Widgets Tests', () {
    Widget createTestApp(Widget child) {
      return ScreenUtilInit(
        designSize: const Size(411, 869),
        builder: (context, _) => MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('DuaKhatmQuranMushafPage renders title, basmalah, and page 605 badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const DuaKhatmQuranMushafPage()));
      await tester.pumpAndSettle();

      expect(find.text(DuaKhatmQuranData.title), findsOneWidget);
      expect(find.text(DuaKhatmQuranData.basmalah), findsOneWidget);
      expect(find.text('٦٠٥'), findsOneWidget);
      expect(find.text('خَاتِمَةُ المُصْحَفِ الشَّرِيفِ'), findsOneWidget);
      expect(find.textContaining('اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ'), findsOneWidget);
    });

    testWidgets('DuaKhatmQuranPage renders correctly and switches between modes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const DuaKhatmQuranPage()));
      await tester.pumpAndSettle();

      expect(find.text('دعاء ختم القرآن الكريم'), findsOneWidget);
      expect(find.text('فقرات مبوبة بالعناوين'), findsOneWidget);
      expect(find.text('نص متصل كالمصحف'), findsOneWidget);

      // Switch to continuous mode
      await tester.tap(find.text('نص متصل كالمصحف'));
      await tester.pumpAndSettle();

      expect(find.textContaining('۞'), findsOneWidget);
    });

    testWidgets('QuranWidget Surahs tab includes Dua Khatm Al-Quran card after Surah An-Nas', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const QuranWidget()));
      await tester.pumpAndSettle();

      // Jump to the end of the vertical Surahs list
      final scrollable = tester.state<ScrollableState>(
        find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ).first,
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      final khatmCard = find.text('دُعَاءُ خَتْمِ القُرْآنِ الكَرِيمِ');
      expect(khatmCard, findsOneWidget);
      expect(find.text('605'), findsWidgets);
    });

    testWidgets('MushafPageView loads page 605 successfully without throwing ArgumentError', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const MushafPageView(initialPage: 605)));
      await tester.pumpAndSettle();

      // Verify that DuaKhatmQuranMushafPage is loaded and rendered
      expect(find.byType(DuaKhatmQuranMushafPage), findsOneWidget);
      expect(find.text('خَاتِمَةُ المُصْحَفِ الشَّرِيفِ'), findsOneWidget);
      expect(find.textContaining('اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ'), findsWidgets);
    });

    testWidgets('DuaKhatmQuranMushafPage renders Page 606 correctly with concluding seal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const DuaKhatmQuranMushafPage(pageNumber: 606)));
      await tester.pumpAndSettle();

      expect(find.text('٦٠٦'), findsOneWidget);
      expect(find.text('خَاتِمَةُ المُصْحَفِ الشَّرِيفِ'), findsWidgets);
      expect(find.text('تَقَبَّلَ اللهُ طَاعَتَكُمْ'), findsOneWidget);
      expect(find.textContaining('اللَّهُمَّ أَحْسِنْ عَاقِبَتَنَا'), findsOneWidget);
      expect(find.textContaining('تَقَبَّلَ اللهُ مِنَّا وَمِنْكُمْ صَالِحَ الأَعْمَالِ'), findsOneWidget);
    });
  });

  group('QuranService Page 605 Bounds Safety Tests', () {
    test('getPageData returns empty list for page 605, 606 and out of bounds', () {
      expect(QuranService.instance.getPageData(605), isEmpty);
      expect(QuranService.instance.getPageData(606), isEmpty);
      expect(QuranService.instance.getPageData(0), isEmpty);
      expect(QuranService.instance.getPageData(999), isEmpty);
    });

    test('getPageSurahName and getPageJuzName handle pages 605 and 606 gracefully', () {
      expect(QuranService.instance.getPageSurahName(605), 'دعاء ختم القرآن');
      expect(QuranService.instance.getPageSurahName(606), 'دعاء ختم القرآن');
      expect(QuranService.instance.getPageJuzName(605), 'خاتمة المصحف');
      expect(QuranService.instance.getPageJuzName(606), 'خاتمة المصحف');
      expect(QuranService.instance.getPageJuzNumber(605), 30);
      expect(QuranService.instance.getPageJuzNumber(606), 30);
    });

    test('togglePageBookmark handles pages 605 and 606 correctly', () async {
      for (final p in [605, 606]) {
        final wasBookmarked = QuranService.instance.isPageBookmarked(p);
        final toggled = await QuranService.instance.togglePageBookmark(p);
        expect(toggled, !wasBookmarked);
        expect(QuranService.instance.isPageBookmarked(p), !wasBookmarked);

        // Toggle back
        final toggledBack = await QuranService.instance.togglePageBookmark(p);
        expect(toggledBack, wasBookmarked);
        expect(QuranService.instance.isPageBookmarked(p), wasBookmarked);
      }
    });
  });
}
