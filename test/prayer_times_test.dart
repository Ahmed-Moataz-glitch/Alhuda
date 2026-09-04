import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prayer Times Tests via muslim_data_flutter', () {
    final muslimRepo = MuslimRepository();
    const cairoLocation = Location(
      id: 1,
      name: 'Cairo',
      latitude: 30.0444,
      longitude: 31.2357,
      countryCode: 'EG',
      countryName: 'Egypt',
      hasFixedPrayerTime: false,
    );

    test('Calculates 6 prayer times in chronological order for Cairo', () async {
      final date = DateTime(2026, 9, 2);
      final attribute = PrayerAttribute(
        calculationMethod: CalculationMethod.egypt,
        asrMethod: AsrMethod.shafii,
        higherLatitudeMethod: HigherLatitudeMethod.angleBased,
      );

      final prayerTime = await muslimRepo.getPrayerTimes(
        location: cairoLocation,
        date: date,
        attribute: attribute,
      );

      expect(prayerTime, isNotNull);
      expect(prayerTime!.fajr.isBefore(prayerTime.sunrise), isTrue);
      expect(prayerTime.sunrise.isBefore(prayerTime.dhuhr), isTrue);
      expect(prayerTime.dhuhr.isBefore(prayerTime.asr), isTrue);
      expect(prayerTime.asr.isBefore(prayerTime.maghrib), isTrue);
      expect(prayerTime.maghrib.isBefore(prayerTime.isha), isTrue);
    });

    test('PrayerTime index operator returns correct prayer by index', () async {
      final date = DateTime(2026, 9, 2);
      final attribute = PrayerAttribute(
        calculationMethod: CalculationMethod.makkah,
        asrMethod: AsrMethod.shafii,
        higherLatitudeMethod: HigherLatitudeMethod.angleBased,
      );

      final prayerTime = await muslimRepo.getPrayerTimes(
        location: cairoLocation,
        date: date,
        attribute: attribute,
      );

      expect(prayerTime![0], equals(prayerTime.fajr));
      expect(prayerTime[1], equals(prayerTime.sunrise));
      expect(prayerTime[2], equals(prayerTime.dhuhr));
      expect(prayerTime[3], equals(prayerTime.asr));
      expect(prayerTime[4], equals(prayerTime.maghrib));
      expect(prayerTime[5], equals(prayerTime.isha));
    });
  });
}
