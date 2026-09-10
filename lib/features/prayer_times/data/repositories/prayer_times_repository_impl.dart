import 'package:alhuda/features/prayer_times/data/datasources/prayer_times_data_source.dart';
import 'package:alhuda/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  final PrayerTimesDataSource _dataSource;

  PrayerTimesRepositoryImpl({PrayerTimesDataSource? dataSource})
      : _dataSource = dataSource ?? PrayerTimesLocalDataSource();

  @override
  Future<PrayerTime?> getPrayerTimes({
    required Location location,
    required DateTime date,
    PrayerAttribute? attribute,
  }) {
    return _dataSource.getPrayerTimes(
      location: location,
      date: date,
      attribute: attribute,
    );
  }
}
