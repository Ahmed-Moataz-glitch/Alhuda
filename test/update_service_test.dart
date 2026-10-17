import 'package:alhuda/core/constants/app_constants.dart';
import 'package:alhuda/core/services/update_service.dart';
import 'package:alhuda/core/view/widgets/force_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateService Tests', () {
    final updateService = UpdateService.instance;

    test('isVersionHigher correctly compares versions', () {
      // Newer versions
      expect(updateService.isVersionHigher('1.2.0', '1.1.0'), isTrue);
      expect(updateService.isVersionHigher('2.0.0', '1.9.9'), isTrue);
      expect(updateService.isVersionHigher('1.1.1', '1.1.0'), isTrue);
      expect(updateService.isVersionHigher('1.1.1', '1.1.0+3'), isTrue);
      expect(updateService.isVersionHigher('1.10.0', '1.9.0'), isTrue);

      // Same versions
      expect(updateService.isVersionHigher('1.1.0', '1.1.0'), isFalse);
      expect(updateService.isVersionHigher('1.1.0+4', '1.1.0+3'), isFalse);

      // Older versions
      expect(updateService.isVersionHigher('1.0.0', '1.1.0'), isFalse);
      expect(updateService.isVersionHigher('1.0.9', '1.1.0'), isFalse);
      expect(updateService.isVersionHigher('0.9.9', '1.0.0'), isFalse);
    });

    test('AppConstants has valid Play Store configuration', () {
      expect(AppConstants.playStorePackageName, equals('dev.glitch.alhuda'));
      expect(
        AppConstants.playStoreUrl,
        equals('https://play.google.com/store/apps/details?id=dev.glitch.alhuda'),
      );
      expect(
        AppConstants.playStoreMarketUrl,
        equals('market://details?id=dev.glitch.alhuda'),
      );
    });

    test('debugForce returns mock update result', () async {
      final result = await updateService.checkForUpdate(debugForce: true);
      expect(result.hasUpdate, isTrue);
      expect(result.isForceUpdate, isTrue);
      expect(result.storeVersion, equals('1.2.0'));
    });

    test('minRequiredVersion policy enforces update for older versions', () {
      expect(
        updateService.isVersionHigher(
          AppConstants.minRequiredVersion,
          '1.0.0',
        ),
        isTrue,
      );
      expect(
        updateService.isVersionHigher(
          AppConstants.minRequiredVersion,
          '1.1.0',
        ),
        isFalse,
      );
    });
  });

  group('ForceUpdateDialog Widget Tests', () {
    testWidgets('renders dialog correctly and responds to update tap',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool updatePressed = false;
      bool recheckPressed = false;

      const result = UpdateCheckResult(
        hasUpdate: true,
        currentVersion: '1.0.0',
        storeVersion: '1.1.0',
        isForceUpdate: true,
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(411, 869),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: ForceUpdateDialog(
                result: result,
                onUpdatePressed: () {
                  updatePressed = true;
                },
                onRecheckPressed: () {
                  recheckPressed = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title and labels
      expect(find.text('تحديث إجباري متوفر'), findsOneWidget);
      expect(find.text('يرجى تحديث التطبيق للمتابعة'), findsOneWidget);
      expect(find.text('تطبيق الهُدى'), findsOneWidget);
      expect(find.text('الإصدار الحالي: v1.0.0'), findsOneWidget);
      expect(find.text('الجديد: v1.1.0'), findsOneWidget);
      expect(find.text('تحديث التطبيق الآن'), findsOneWidget);

      // Tap update button
      await tester.tap(find.text('تحديث التطبيق الآن'));
      await tester.pump();
      expect(updatePressed, isTrue);

      // Tap recheck button
      await tester.tap(find.text('تحققت بالفعل؟ إعادة الفحص'));
      await tester.pump();
      expect(recheckPressed, isTrue);
    });
  });
}
