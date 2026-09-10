import 'package:muslim_data_flutter/muslim_data_flutter.dart';

abstract class PrayerTimesRepository {
  Future<PrayerTime?> getPrayerTimes({
    required Location location,
    required DateTime date,
    PrayerAttribute? attribute,
  });
}
