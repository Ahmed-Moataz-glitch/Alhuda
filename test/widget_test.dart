// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:alhuda/view/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/android_alarm_manager'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
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

  testWidgets('App renders home page grid items smoke test', (WidgetTester tester) async {
    // Set a physical test screen size suitable for ScreenUtil
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(411, 869),
        builder: (context, child) => const MaterialApp(
          home: HomePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app title and badges exist
    expect(find.text('الهُدى'), findsOneWidget);
    expect(find.textContaining('هـ'), findsWidgets);
    expect(find.textContaining('م'), findsWidgets);

    // Verify grid features exist
    expect(find.text('المصحف الشريف'), findsOneWidget);
    expect(find.text('الأحاديث النبوية'), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('التقويم الهجري'), findsOneWidget);
    expect(find.text('التسبيح الحر'), findsOneWidget);
    expect(find.textContaining('ذكار'), findsWidgets);
    expect(find.text('أسماء الله الحسنى'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('الفقه الإسلامي'), 100);
    expect(find.text('الفقه الإسلامي'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('القبلة'), 100);
    expect(find.text('القبلة'), findsOneWidget);
  });
}
