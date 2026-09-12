import 'package:alhuda/view/widgets/prayer_scheduler_service.dart';
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
  });

  group('PrayerSchedulerService Tests', () {
    test('Prayer ID mappings are unique and consistent', () {
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

    test('Prayer scheduler maps prayerNameToId correctly', () {
      final map = PrayerSchedulerService.prayerNameToId;
      expect(map['الفجر'], equals(1001));
      expect(map['الظهر'], equals(1002));
      expect(map['العصر'], equals(1003));
      expect(map['المغرب'], equals(1004));
      expect(map['العشاء'], equals(1005));
    });

    test('scheduleUpcomingPrayers runs without exception', () async {
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
      await scheduler.scheduleUpcomingPrayers(prayerTime);
    });
  });
}
