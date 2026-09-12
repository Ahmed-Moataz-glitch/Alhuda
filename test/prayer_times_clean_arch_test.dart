import 'package:alhuda/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class MockPrayerTimesRepository implements PrayerTimesRepository {
  @override
  Future<PrayerTime?> getPrayerTimes({
    required Location location,
    required DateTime date,
    PrayerAttribute? attribute,
  }) async {
    final base = DateTime(date.year, date.month, date.day);
    return PrayerTime(
      fajr: base.add(const Duration(hours: 4, minutes: 30)),
      sunrise: base.add(const Duration(hours: 6)),
      dhuhr: base.add(const Duration(hours: 12)),
      asr: base.add(const Duration(hours: 15, minutes: 30)),
      maghrib: base.add(const Duration(hours: 18)),
      isha: base.add(const Duration(hours: 19, minutes: 30)),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
}
