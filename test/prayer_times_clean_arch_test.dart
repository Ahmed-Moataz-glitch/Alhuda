import 'package:alhuda/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:alhuda/features/prayer_times/presentation/view_models/prayer_times_view_model.dart';
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

  group('PrayerTimes Clean Architecture Tests', () {
    late PrayerTimesViewModel viewModel;

    setUp(() {
      viewModel =
          PrayerTimesViewModel(repository: MockPrayerTimesRepository());
    });

    test('PrayerTimesViewModel loads prayer times correctly', () async {
      expect(viewModel.prayerTime, isNull);
      await viewModel.loadPrayerTimes();

      expect(viewModel.prayerTime, isNotNull);
      expect(viewModel.currentLocation.name, equals('القاهرة'));
      expect(viewModel.calculationMethod, equals(CalculationMethod.egypt));
    });

    test('PrayerTimesViewModel updates date and recalculates', () async {
      await viewModel.loadPrayerTimes();
      final newDate = DateTime(2026, 5, 1);
      viewModel.setDate(newDate);

      expect(viewModel.currentDate, equals(newDate));
    });
  });
}
