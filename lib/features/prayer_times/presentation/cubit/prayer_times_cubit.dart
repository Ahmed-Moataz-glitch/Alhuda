import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import '../../../../core/utils/egypt_dst_helper.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import 'prayer_times_state.dart';
export 'prayer_times_state.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final PrayerTimesRepository _repository;

  static const Location defaultLocation = Location(
    id: 1,
    name: 'القاهرة',
    countryName: 'مصر',
    countryCode: 'EG',
    latitude: 30.0444,
    longitude: 31.2357,
    hasFixedPrayerTime: false,
  );

  PrayerTimesCubit({PrayerTimesRepository? repository})
      : _repository = repository ?? PrayerTimesRepositoryImpl(),
        super(PrayerTimesState(
          currentDate: DateTime.now(),
          currentLocation: defaultLocation,
        ));

  bool get isLoading => state.isLoading;
  PrayerTime? get prayerTime => state.adjustedPrayerTime;
  DateTime get currentDate => state.currentDate;
  Location get currentLocation => state.currentLocation;
  CalculationMethod get calculationMethod => state.calculationMethod;
  EgyptDstMode get dstMode => state.dstMode;

  Future<void> loadPrayerTimes() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final raw = await _repository.getPrayerTimes(
        location: state.currentLocation,
        date: state.currentDate,
        attribute: PrayerAttribute(
          calculationMethod: state.calculationMethod,
          asrMethod: AsrMethod.shafii,
          higherLatitudeMethod: HigherLatitudeMethod.angleBased,
        ),
      );

      PrayerTime? adjusted;
      if (raw != null) {
        adjusted = EgyptDstHelper.adjustPrayerTimesForEgypt(
          prayer: raw,
          location: state.currentLocation,
          date: state.currentDate,
          mode: state.dstMode,
        );
      }

      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        rawPrayerTime: raw,
        adjustedPrayerTime: adjusted,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void setLocation(Location location) {
    emit(state.copyWith(currentLocation: location));
    loadPrayerTimes();
  }

  void setDate(DateTime date) {
    emit(state.copyWith(currentDate: date));
    loadPrayerTimes();
  }

  void setCalculationMethod(CalculationMethod method) {
    emit(state.copyWith(calculationMethod: method));
    loadPrayerTimes();
  }

  void setDstMode(EgyptDstMode mode) {
    if (state.rawPrayerTime != null) {
      final adjusted = EgyptDstHelper.adjustPrayerTimesForEgypt(
        prayer: state.rawPrayerTime!,
        location: state.currentLocation,
        date: state.currentDate,
        mode: mode,
      );
      emit(state.copyWith(dstMode: mode, adjustedPrayerTime: adjusted));
    } else {
      emit(state.copyWith(dstMode: mode));
      loadPrayerTimes();
    }
  }
}
