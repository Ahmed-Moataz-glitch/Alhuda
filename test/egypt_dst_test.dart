import 'package:alhuda/core/utils/egypt_dst_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

void main() {
  group('Egypt DST Helper Tests', () {
    const cairoLocation = Location(
      id: 1,
      name: 'Cairo',
      latitude: 30.0444,
      longitude: 31.2357,
      countryCode: 'EG',
      countryName: 'Egypt',
      hasFixedPrayerTime: false,
    );

    const londonLocation = Location(
      id: 2,
      name: 'London',
      latitude: 51.5074,
      longitude: -0.1278,
      countryCode: 'GB',
      countryName: 'United Kingdom',
      hasFixedPrayerTime: false,
    );

    test('Identifies Egypt locations correctly', () {
      expect(EgyptDstHelper.isEgyptLocation(cairoLocation), isTrue);
      expect(EgyptDstHelper.isEgyptLocation(londonLocation), isFalse);
    });

    test('Summer months (May - September) fall within Egypt DST', () {
      // May 15
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 5, 15)), isTrue);
      // July 1
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 7, 1)), isTrue);
      // September 4 (current date)
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 9, 4)), isTrue);
      // Expected offset should be UTC+3
      expect(
        EgyptDstHelper.getExpectedEgyptOffset(DateTime(2026, 9, 4)),
        equals(3.0),
      );
    });

    test('Winter months (November - March) fall outside Egypt DST', () {
      // January 15
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 1, 15)), isFalse);
      // February 10
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 2, 10)), isFalse);
      // November 20
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 11, 20)), isFalse);
      // December 25
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 12, 25)), isFalse);
      // Expected offset should be UTC+2
      expect(
        EgyptDstHelper.getExpectedEgyptOffset(DateTime(2026, 1, 15)),
        equals(2.0),
      );
    });

    test('April and October transition boundaries for 2026', () {
      // In 2026:
      // April 30 is Thursday. Last Friday is April 24.
      // April 23 should be winter (false).
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 4, 23, 12, 0)), isFalse);
      // April 25 should be summer (true).
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 4, 25, 12, 0)), isTrue);

      // In 2026:
      // October 31 is Saturday. Last Thursday is October 29.
      // October 28 should be summer (true).
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 10, 28, 12, 0)), isTrue);
      // October 30 should be winter (false).
      expect(EgyptDstHelper.isEgyptDst(DateTime(2026, 10, 30, 12, 0)), isFalse);
    });

    test('Adjusts prayer times correctly when device offset differs', () {
      final baseDate = DateTime(2026, 9, 4);
      final prayer = PrayerTime(
        fajr: DateTime(2026, 9, 4, 4, 3), // e.g. calculated in UTC+2
        sunrise: DateTime(2026, 9, 4, 5, 33),
        dhuhr: DateTime(2026, 9, 4, 11, 54),
        asr: DateTime(2026, 9, 4, 15, 28),
        maghrib: DateTime(2026, 9, 4, 18, 15),
        isha: DateTime(2026, 9, 4, 19, 35),
      );

      // In summer mode with a simulated device offset difference
      final adjusted = EgyptDstHelper.adjustPrayerTimesForEgypt(
        prayer: prayer,
        location: cairoLocation,
        date: baseDate,
        mode: EgyptDstMode.summer,
        additionalMinutesOffset: 0,
      );

      // Calculation should preserve chronological order
      expect(adjusted.fajr.isBefore(adjusted.sunrise), isTrue);
      expect(adjusted.dhuhr.isBefore(adjusted.asr), isTrue);
      expect(adjusted.asr.isBefore(adjusted.maghrib), isTrue);
    });
  });
}
