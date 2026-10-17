import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/prayer_scheduler_service.dart';
import 'package:alhuda/core/utils/egypt_dst_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/android_alarm_manager'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
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
      const MethodChannel('com.example.alhuda/adhan'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  group('PrayerSchedulerService Tests', () {
    test('Prayer ID mappings are unique and consistent for the 5 prayers', () {
      expect(PrayerSchedulerService.idFajr, equals(1001));
      expect(PrayerSchedulerService.idDhuhr, equals(1002));
      expect(PrayerSchedulerService.idAsr, equals(1003));
      expect(PrayerSchedulerService.idMaghrib, equals(1004));
      expect(PrayerSchedulerService.idIsha, equals(1005));

      expect(
        PrayerSchedulerService.prayerNameFromId(PrayerSchedulerService.idFajr),
        equals('الفجر'),
      );
      expect(
        PrayerSchedulerService.prayerNameFromId(PrayerSchedulerService.idDhuhr),
        equals('الظهر'),
      );
      expect(
        PrayerSchedulerService.prayerNameFromId(PrayerSchedulerService.idAsr),
        equals('العصر'),
      );
      expect(
        PrayerSchedulerService.prayerNameFromId(PrayerSchedulerService.idMaghrib),
        equals('المغرب'),
      );
      expect(
        PrayerSchedulerService.prayerNameFromId(PrayerSchedulerService.idIsha),
        equals('العشاء'),
      );
    });

    test('basePrayerId normalizes rolling 7-day IDs to the correct base ID', () {
      // Day 0
      expect(PrayerSchedulerService.basePrayerId(1001), equals(1001));
      expect(PrayerSchedulerService.basePrayerId(1002), equals(1002));
      expect(PrayerSchedulerService.basePrayerId(1003), equals(1003));
      expect(PrayerSchedulerService.basePrayerId(1004), equals(1004));
      expect(PrayerSchedulerService.basePrayerId(1005), equals(1005));

      // Day 1 (1101..1105)
      expect(PrayerSchedulerService.basePrayerId(1101), equals(1001));
      expect(PrayerSchedulerService.basePrayerId(1102), equals(1002));
      expect(PrayerSchedulerService.basePrayerId(1103), equals(1003));
      expect(PrayerSchedulerService.basePrayerId(1104), equals(1004));
      expect(PrayerSchedulerService.basePrayerId(1105), equals(1005));

      // Day 6 (1601..1605)
      expect(PrayerSchedulerService.basePrayerId(1601), equals(1001));
      expect(PrayerSchedulerService.basePrayerId(1605), equals(1005));

      // Names from rolling IDs
      expect(PrayerSchedulerService.prayerNameFromId(1101), equals('الفجر'));
      expect(PrayerSchedulerService.prayerNameFromId(1202), equals('الظهر'));
      expect(PrayerSchedulerService.prayerNameFromId(1303), equals('العصر'));
      expect(PrayerSchedulerService.prayerNameFromId(1404), equals('المغرب'));
      expect(PrayerSchedulerService.prayerNameFromId(1505), equals('العشاء'));

      // Special non-prayer IDs
      expect(PrayerSchedulerService.basePrayerId(9998), equals(9998));
      expect(PrayerSchedulerService.basePrayerId(9999), equals(9999));
    });

    test('Prayer scheduler maps prayerNameToId correctly without Sunrise', () {
      final map = PrayerSchedulerService.prayerNameToId;
      expect(map.containsKey('الشروق'), isFalse);
      expect(map['الفجر'], equals(1001));
      expect(map['الظهر'], equals(1002));
      expect(map['العصر'], equals(1003));
      expect(map['المغرب'], equals(1004));
      expect(map['العشاء'], equals(1005));
    });

    test('Sunrise is strictly not enabled in AdhanAudioService and cannot be toggled', () {
      final service = AdhanAudioService();
      expect(service.isPrayerAlertEnabled('الشروق'), isFalse);

      service.togglePrayerAlert('الشروق', true);
      expect(service.isPrayerAlertEnabled('الشروق'), isFalse);

      // Verify all other 5 prayers are enabled
      expect(service.isPrayerAlertEnabled('الفجر'), isTrue);
      expect(service.isPrayerAlertEnabled('الظهر'), isTrue);
      expect(service.isPrayerAlertEnabled('العصر'), isTrue);
      expect(service.isPrayerAlertEnabled('المغرب'), isTrue);
      expect(service.isPrayerAlertEnabled('العشاء'), isTrue);
    });

    test('Save and load schedule configuration works correctly', () async {
      final scheduler = PrayerSchedulerService();
      const testLoc = Location(
        id: 2,
        name: 'الإسكندرية',
        latitude: 31.2001,
        longitude: 29.9187,
        countryCode: 'EG',
        countryName: 'مصر',
        hasFixedPrayerTime: false,
      );

      await scheduler.saveScheduleConfig(
        location: testLoc,
        method: CalculationMethod.egypt,
        dstMode: EgyptDstMode.auto,
        manualMinutesOffset: 2,
      );

      final loaded = await scheduler.loadScheduleConfig();
      expect(loaded, isNotNull);
      expect(loaded!['location']['name'], equals('الإسكندرية'));
      expect(loaded['method'], equals(CalculationMethod.egypt.name));
      expect(loaded['dstMode'], equals(EgyptDstMode.auto.name));
      expect(loaded['manualMinutesOffset'], equals(2));
    });

    test('scheduleUpcomingPrayers runs without exception for 7 days', () async {
      final now = DateTime.now();
      final prayerTime = PrayerTime(
        fajr: now.add(const Duration(hours: 1)),
        sunrise: now.add(const Duration(hours: 2)),
        dhuhr: now.add(const Duration(hours: 4)),
        asr: now.add(const Duration(hours: 7)),
        maghrib: now.add(const Duration(hours: 9)),
        isha: now.add(const Duration(hours: 11)),
      );

      final scheduler = PrayerSchedulerService();
      await expectLater(
        scheduler.scheduleUpcomingPrayers(prayerTime),
        completes,
      );
    });

    test('rescheduleAfterAlarm and cancelAllPrayerAlarms complete cleanly', () async {
      final scheduler = PrayerSchedulerService();
      await expectLater(
        scheduler.rescheduleAfterAlarm(1001),
        completes,
      );
      await expectLater(
        scheduler.cancelAllPrayerAlarms(),
        completes,
      );
    });
  });
}
