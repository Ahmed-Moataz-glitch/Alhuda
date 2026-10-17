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

    testWidgets('Renders initial dhikr and counter', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('إعادة'), findsOneWidget);
      expect(find.textContaining('الذكر 1 من 35'), findsOneWidget);
    });

    testWidgets('Tapping + increments counter while preserving dhikr text', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.add_rounded));
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Counter should be 1
      expect(find.text('1'), findsOneWidget);
      // Dhikr should remain the same (NOT cycle unexpectedly)
      expect(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), findsOneWidget);

      // Tap reset
      await tester.ensureVisible(find.text('إعادة'));
      await tester.tap(find.text('إعادة'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Next and previous navigation cycles between Azkar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Next dhikr
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('لا حول ولا قوة إلا بالله'), findsOneWidget);
      expect(find.textContaining('الذكر 2 من 35'), findsOneWidget);

      // Previous dhikr
      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('سبحان الله وبحمده سبحان الله العظيم'), findsOneWidget);
      expect(find.textContaining('الذكر 1 من 35'), findsOneWidget);
    });

    testWidgets('Opens Dhikr bottom sheet list modal and selects item', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Dhikr list chip
      await tester.tap(find.textContaining('الذكر 1 من 35'));
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

    testWidgets('Completing target count automatically cycles to next dhikr and resets counter', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // First dhikr is 'سبحان الله وبحمده سبحان الله العظيم'
      expect(find.textContaining('الذكر 1 من 35'), findsOneWidget);

      // Select target 33 for faster testing
      await tester.tap(find.text('33'));
      await tester.pumpAndSettle();

      // Tap + 33 times to reach target
      final addBtn = find.byIcon(Icons.add_rounded);
      for (int i = 0; i < 33; i++) {
        await tester.tap(addBtn);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Should automatically transition to next dhikr ('لا حول ولا قوة إلا بالله')
      expect(find.textContaining('الذكر 2 من 35'), findsOneWidget);
      expect(find.textContaining('لا حول ولا قوة إلا بالله'), findsOneWidget);
      // Counter should reset to 0
      expect(find.text('0'), findsOneWidget);
    });
  });
}
