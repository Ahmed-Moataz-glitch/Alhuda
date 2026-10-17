import 'dart:io';
import 'package:alhuda/services/font_size_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('font_size_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('FontSizeService Tests', () {
    late FontSizeService service;

    setUp(() async {
      service = FontSizeService.instance;
      await service.resetAllScales();
    });

    test('Initial scale and default properties', () {
      expect(service.fontScale, inInclusiveRange(0.80, 1.40));
      expect(FontSizeService.minScale, 0.80);
      expect(FontSizeService.maxScale, 1.40);
      expect(FontSizeService.defaultScale, 1.0);
      expect(FontSizeService.step, 0.05);
      expect(service.areAllDefault, isTrue);
    });

    test('Per-feature font scale isolation and persistence', () async {
      // Set Azkar scale to 1.25
      await service.setScale(AppFeature.azkar, 1.25);
      expect(service.getScale(AppFeature.azkar), closeTo(1.25, 0.001));
      expect(service.percentageText(AppFeature.azkar), '125%');
      expect(service.isFeatureDefault(AppFeature.azkar), isFalse);

      // Verify other features remain completely unaffected
      expect(service.getScale(AppFeature.hadith), closeTo(1.0, 0.001));
      expect(service.getScale(AppFeature.quran), closeTo(1.0, 0.001));
      expect(service.getScale(AppFeature.prayerTimes), closeTo(1.0, 0.001));
      expect(service.isFeatureDefault(AppFeature.hadith), isTrue);

      // Set Hadith scale to 1.15
      await service.setScale(AppFeature.hadith, 1.15);
      expect(service.getScale(AppFeature.hadith), closeTo(1.15, 0.001));
      expect(service.getScale(AppFeature.azkar), closeTo(1.25, 0.001));

      // Reload settings from file to verify persistence
      await service.init();
      expect(service.getScale(AppFeature.azkar), closeTo(1.25, 0.001));
      expect(service.getScale(AppFeature.hadith), closeTo(1.15, 0.001));
      expect(service.getScale(AppFeature.quran), closeTo(1.0, 0.001));

      // Reset single feature
      await service.resetScale(AppFeature.azkar);
      expect(service.getScale(AppFeature.azkar), closeTo(1.0, 0.001));
      expect(service.getScale(AppFeature.hadith), closeTo(1.15, 0.001));

      // Reset all scales
      await service.resetAllScales();
      expect(service.areAllDefault, isTrue);
      expect(service.getScale(AppFeature.hadith), closeTo(1.0, 0.001));
    });

    test('Set, reset and persist font scale with backward compatibility', () async {
      await service.setFontScale(1.15);
      expect(service.fontScale, closeTo(1.15, 0.001));
      expect(service.isDefault, isFalse);
      expect(service.percentageText(), '115%');
      expect(service.scaleLabel(), 'متوسط');

      // Test file persistence and init
      await service.init();
      expect(service.fontScale, closeTo(1.15, 0.001));

      await service.resetFontScale();
      expect(service.fontScale, closeTo(1.0, 0.001));
      expect(service.isDefault, isTrue);
      expect(service.percentageText(), '100%');
      expect(service.scaleLabel(), 'افتراضي (عادي)');
    });

    test('Clamping behavior for min and max bounds per feature', () async {
      // Below min
      await service.setScale(AppFeature.prayerTimes, 0.50);
      expect(service.getScale(AppFeature.prayerTimes), FontSizeService.minScale);
      expect(service.percentageText(AppFeature.prayerTimes), '80%');

      // Above max
      await service.setScale(AppFeature.prayerTimes, 2.00);
      expect(service.getScale(AppFeature.prayerTimes), FontSizeService.maxScale);
      expect(service.percentageText(AppFeature.prayerTimes), '140%');

      // Clean up
      await service.resetScale(AppFeature.prayerTimes);
    });

    test('Increase and decrease scale step-by-step per feature', () async {
      await service.resetScale(AppFeature.takweem); // 1.0
      expect(service.getScale(AppFeature.takweem), 1.0);

      await service.increaseScale(AppFeature.takweem);
      expect(service.getScale(AppFeature.takweem), closeTo(1.05, 0.001));

      await service.decreaseScale(AppFeature.takweem);
      expect(service.getScale(AppFeature.takweem), closeTo(1.0, 0.001));

      // Clean up
      await service.resetScale(AppFeature.takweem);
    });

    test('AppFeature helpers and title mapping', () {
      expect(AppFeature.fromTitle('الصفحة الرئيسية'), AppFeature.home);
      expect(AppFeature.fromTitle('الرئيسية'), AppFeature.home);
      expect(AppFeature.fromTitle('المصحف الشريف'), AppFeature.quran);
      expect(AppFeature.fromTitle('الأحاديث النبوية'), AppFeature.hadith);
      expect(AppFeature.fromTitle('الأذكار'), AppFeature.azkar);
      expect(AppFeature.fromTitle('التسبيح الحر'), AppFeature.tasbeeh);
      expect(AppFeature.fromTitle('مواقيت الصلاة'), AppFeature.prayerTimes);
      expect(AppFeature.fromTitle('التقويم الهجري'), AppFeature.takweem);
      expect(AppFeature.fromTitle('أسماء الله الحسنى'), AppFeature.allahNames);
      expect(AppFeature.fromTitle('الفقه الإسلامي'), AppFeature.fiqh);
      expect(AppFeature.fromTitle('القبلة'), AppFeature.qibla);
      expect(AppFeature.fromTitle('دليل ومميزات التطبيق'), AppFeature.appGuide);

      expect(AppFeature.fromKey('home'), AppFeature.home);
      expect(AppFeature.fromKey('quran'), AppFeature.quran);
      expect(AppFeature.fromKey('tasbeeh'), AppFeature.tasbeeh);
    });

    test('Preset names helper', () {
      expect(FontSizeService.presetName(0.85), 'صغير');
      expect(FontSizeService.presetName(1.0), 'افتراضي');
      expect(FontSizeService.presetName(1.15), 'متوسط');
      expect(FontSizeService.presetName(1.25), 'كبير');
      expect(FontSizeService.presetName(1.35), 'كبير جداً');
    });
  });
}
