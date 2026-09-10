import 'package:muslim_data_flutter/muslim_data_flutter.dart';

abstract class PrayerTimesDataSource {
  Future<PrayerTime?> getPrayerTimes({
    required Location location,
    required DateTime date,
    PrayerAttribute? attribute,
  });
}

class PrayerTimesLocalDataSource implements PrayerTimesDataSource {
  final MuslimRepository _repo;

  PrayerTimesLocalDataSource({MuslimRepository? repo})
      : _repo = repo ?? MuslimRepository();

  @override
  Future<PrayerTime?> getPrayerTimes({
    required Location location,
    required DateTime date,
    PrayerAttribute? attribute,
  }) {
    final attr = attribute ??
        const PrayerAttribute(
          calculationMethod: CalculationMethod.egypt,
          asrMethod: AsrMethod.shafii,
          higherLatitudeMethod: HigherLatitudeMethod.angleBased,
        );

    return _repo.getPrayerTimes(
      location: location,
      date: date,
      attribute: attr,
    );
  }
}
