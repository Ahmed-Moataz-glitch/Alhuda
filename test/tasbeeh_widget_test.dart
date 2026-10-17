import 'package:alhuda/features/tasbeeh/data/repositories/tasbeeh_repository_impl.dart';
import 'package:alhuda/features/tasbeeh/presentation/view/widgets/tasbeeh_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  group('TasbeehRepository Tests', () {
    test('Default items contain 35 authentic Azkar with fadl and targetCount', () {
      final repo = TasbeehRepositoryImpl();
      final items = repo.getDefaultItems();

      expect(items.length, equals(35));
      expect(items.first.text, contains('سبحان الله وبحمده سبحان الله العظيم'));
      expect(items.first.targetCount, equals(100));
      expect(items.first.fadl, isNotNull);

      // Verify essential Adhkar exist
      expect(items.any((i) => i.text.contains('سيد الاستغفار') || i.text.contains('اللهم أنت ربي لا إله إلا أنت')), isTrue);
      expect(items.any((i) => i.text.contains('لا حول ولا قوة إلا بالله')), isTrue);
      expect(items.any((i) => i.text.contains('حسبي الله ونعم الوكيل')), isTrue);
      expect(items.any((i) => i.text.contains('الصلاة الإبراهيمية') || i.text.contains('اللهم صل على محمد وعلى آل محمد')), isTrue);
    });
  });

  group('TasbeehWidget UI Tests', () {
    Widget buildTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(411, 869),
        builder: (context, child) => const MaterialApp(
          home: Scaffold(
            body: TasbeehWidget(),
          ),
        ),
      );
    }

    testWidgets('Renders initial dhikr, counter, and target chips including 1', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('إعادة'), findsOneWidget);
      // Target chips
      expect(find.text('1'), findsWidgets);
      expect(find.text('33'), findsWidgets);
      expect(find.text('100'), findsWidgets);
      expect(find.text('مفتوح'), findsWidgets);
    });

    testWidgets('Tapping + increments counter while preserving dhikr text when target > 1', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select target 33
      await tester.tap(find.text('33'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.add_rounded));
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Counter should be 1
      expect(find.text('1'), findsWidgets);
      // Dhikr should remain the same (NOT cycle unexpectedly)
      expect(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), findsOneWidget);

      // Tap reset
      await tester.ensureVisible(find.text('إعادة'));
      await tester.tap(find.text('إعادة'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Swipe navigation cycles between Azkar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Next dhikr via fling left
      await tester.fling(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.textContaining('لا حول ولا قوة إلا بالله'), findsOneWidget);

      // Previous dhikr via fling right
      await tester.fling(find.textContaining('لا حول ولا قوة إلا بالله'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), findsOneWidget);
    });

    testWidgets('Opens Dhikr bottom sheet list modal by tapping dhikr card and selects item', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Dhikr card
      await tester.tap(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title
      expect(find.textContaining('قائمة الأذكار والتسبيحات'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Select item (e.g. لا حول ولا قوة إلا بالله)
      final targetDhikr = find.text('لا حول ولا قوة إلا بالله').first;
      await tester.tap(targetDhikr);
      await tester.pumpAndSettle();

      // Sheet closed and new item selected
      expect(find.textContaining('لا حول ولا قوة إلا بالله'), findsWidgets);
    });

    testWidgets('Completing default target count (1) automatically cycles to next dhikr and resets counter', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // First dhikr is 'سبحان الله وبحمده سبحان الله العظيم'
      expect(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), findsOneWidget);

      // Tap + once (target is 1 by default)
      final addBtn = find.byIcon(Icons.add_rounded);
      await tester.tap(addBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Should automatically transition to next dhikr ('لا حول ولا قوة إلا بالله')
      expect(find.textContaining('لا حول ولا قوة إلا بالله'), findsOneWidget);
      // Counter should reset to 0
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Long dhikr text with fadl renders without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open sheet and filter to Yunus prayer
      await tester.tap(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'سبحانك');
      await tester.pumpAndSettle();

      final yunusDhikr = find.textContaining('لا إله إلا أنت سبحانك إني كنت من الظالمين').first;
      await tester.tap(yunusDhikr);
      await tester.pumpAndSettle();

      expect(find.textContaining('لا إله إلا أنت سبحانك إني كنت من الظالمين'), findsWidgets);
      expect(find.textContaining('دعوة ذي النون'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
