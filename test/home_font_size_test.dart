import 'package:alhuda/core/services/font_size_service.dart';
import 'package:alhuda/core/view/pages/home_page.dart';
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async => ['wifi'],
    );
  });

  testWidgets('HomePage font size button opens bottom sheet and adjusts scale', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fontService = FontSizeService.instance;
    await fontService.resetAllScales();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(411, 869),
        builder: (context, child) => const MaterialApp(
          home: HomePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify initial home scale is 1.0 (default)
    expect(fontService.getScale(AppFeature.home), closeTo(1.0, 0.01));
    expect(fontService.isFeatureDefault(AppFeature.home), isTrue);

    // Verify font size button exists in HomePage AppBar
    final fontSizeButton = find.byIcon(Icons.format_size_rounded);
    expect(fontSizeButton, findsOneWidget);

    // Tap on the font size button
    await tester.tap(fontSizeButton);
    await tester.pumpAndSettle();

    // Verify bottom sheet opened with 'الصفحة الرئيسية' selected
    expect(find.text('حجم خط الصفحة الرئيسية'), findsOneWidget);
    expect(find.text('معاينة حية لـ الصفحة الرئيسية:'), findsOneWidget);

    // Choose preset 'كبير' (125%)
    final largePreset = find.text('كبير');
    expect(largePreset, findsOneWidget);
    await tester.ensureVisible(largePreset);
    await tester.tap(largePreset);
    await tester.pumpAndSettle();

    // Verify Home Page font scale updated to 1.25
    expect(fontService.getScale(AppFeature.home), closeTo(1.25, 0.01));
    expect(fontService.isFeatureDefault(AppFeature.home), isFalse);

    // Dismiss bottom sheet
    final doneButton = find.textContaining('تَمّ الاعتماد');
    await tester.ensureVisible(doneButton);
    await tester.tap(doneButton);
    await tester.pumpAndSettle();

    // Verify custom indicator is displayed on the font size toggle button
    expect(fontService.getScale(AppFeature.home), closeTo(1.25, 0.01));

    // Test long press to cycle to next preset (1.35)
    await tester.longPress(fontSizeButton);
    await tester.pumpAndSettle();
    expect(fontService.getScale(AppFeature.home), closeTo(1.35, 0.01));

    // Reset scales
    await fontService.resetAllScales();
    expect(fontService.getScale(AppFeature.home), closeTo(1.0, 0.01));

    // Drain pending update timer
    await tester.pump(const Duration(seconds: 5));
  });
}
