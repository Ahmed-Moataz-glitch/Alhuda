import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/qibla_repository_impl.dart';
import '../../domain/repositories/qibla_repository.dart';
import 'qibla_state.dart';
export 'qibla_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  final QiblaRepository _repository;

  QiblaCubit({QiblaRepository? repository})
      : _repository = repository ?? QiblaRepositoryImpl(),
        super(const QiblaState()) {
    calculateQibla();
  }

  void calculateQibla({
    double? latitude,
    double? longitude,
    String? cityName,
  }) {
    final lat = latitude ?? state.latitude;
    final lng = longitude ?? state.longitude;
    final city = cityName ?? state.cityName;

    try {
      final data = _repository.calculateQibla(latitude: lat, longitude: lng);
      final facing = _repository.isFacingQibla(
        state.currentHeading,
        data.qiblaAngle,
      );

      emit(state.copyWith(
        latitude: lat,
        longitude: lng,
        cityName: city,
        qiblaData: data,
        isFacing: facing,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void updateHeading(double heading) {
    final targetAngle = state.qiblaData?.qiblaAngle ?? 0.0;
    final facing = _repository.isFacingQibla(heading, targetAngle);

    emit(state.copyWith(
      currentHeading: heading,
      isFacing: facing,
    ));
  }

  void setSensorlessMode(bool enabled) {
    emit(state.copyWith(isSensorlessMode: enabled));
  }
}
