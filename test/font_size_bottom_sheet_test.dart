import 'package:alhuda/core/view/widgets/font_size_bottom_sheet.dart';
import 'package:alhuda/services/font_size_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FontSizeBottomSheet renders controls and updates font scale per feature', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = FontSizeService.instance;
    await service.resetAllScales();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(411, 869),
        minTextAdapt: true,
        splitScreenMode: true,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => FontSizeBottomSheet.show(context),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Open bottom sheet
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify header and preview exist for the default selected feature (الصفحة الرئيسية)
    expect(find.text('حجم خط الصفحة الرئيسية'), findsOneWidget);
    expect(find.text('معاينة حية لـ الصفحة الرئيسية:'), findsOneWidget);
    expect(
      find.text('الهُدى • أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ'),
      findsOneWidget,
    );

    // Tap on preset 'كبير' (125%)
    final largePreset = find.text('كبير');
    expect(largePreset, findsOneWidget);
    await tester.ensureVisible(largePreset);
    await tester.tap(largePreset);
    await tester.pumpAndSettle();

    expect(service.getScale(AppFeature.home), closeTo(1.25, 0.01));
    expect(find.text('125% • كبير'), findsOneWidget);

    // Verify other feature (like Hadith) is untouched
    expect(service.getScale(AppFeature.hadith), closeTo(1.0, 0.01));

    // Switch feature to 'المصحف الشريف'
    final quranChip = find.text('المصحف الشريف').first;
    await tester.tap(quranChip);
    await tester.pumpAndSettle();

    expect(find.text('حجم خط المصحف الشريف'), findsOneWidget);
    expect(find.text('معاينة حية لـ المصحف الشريف:'), findsOneWidget);

    // Quran scale is 100%
    expect(find.text('100% • افتراضي (عادي)'), findsOneWidget);

    // Tap on preset 'متوسط' (115%) for Quran
    final mediumPreset = find.text('متوسط');
    expect(mediumPreset, findsOneWidget);
    await tester.ensureVisible(mediumPreset);
    await tester.tap(mediumPreset);
    await tester.pumpAndSettle();

    expect(service.getScale(AppFeature.quran), closeTo(1.15, 0.01));
    expect(service.getScale(AppFeature.home), closeTo(1.25, 0.01));

    // Reset current feature (Quran)
    final resetButton = find.text('إعادة ضبط');
    expect(resetButton, findsOneWidget);
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(service.getScale(AppFeature.quran), closeTo(1.0, 0.01));
    // Home is still 125%
    expect(service.getScale(AppFeature.home), closeTo(1.25, 0.01));

    // Tap confirm / done
    final doneButton = find.textContaining('تَمّ الاعتماد');
    expect(doneButton, findsOneWidget);
    await tester.ensureVisible(doneButton);
    await tester.tap(doneButton);
    await tester.pumpAndSettle();

    // Bottom sheet is dismissed
    expect(find.text('حجم خط المصحف الشريف'), findsNothing);
  });
}
