import 'package:alhuda/features/qibla/data/repositories/qibla_repository_impl.dart';
import 'package:alhuda/features/qibla/presentation/view_models/cubit/qibla_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Qibla Clean Architecture Tests', () {
    late QiblaRepositoryImpl repository;
    late QiblaCubit cubit;

    setUp(() {
      repository = QiblaRepositoryImpl();
      cubit = QiblaCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('QiblaRepositoryImpl calculates correct Qibla angle for Cairo', () {
      final data = repository.calculateQibla(latitude: 30.0444, longitude: 31.2357);
      expect(data.qiblaAngle, greaterThan(130));
      expect(data.qiblaAngle, lessThan(145));
      expect(data.cardinalDirection, equals('الجنوب الشرقي'));
      expect(data.distanceKm, greaterThan(1250));
      expect(data.distanceKm, lessThan(1350));
    });

    test('QiblaRepositoryImpl checks if facing Qibla accurately', () {
      expect(repository.isFacingQibla(136.0, 136.0), isTrue);
      expect(repository.isFacingQibla(138.0, 136.0), isTrue);
      expect(repository.isFacingQibla(150.0, 136.0), isFalse);
    });

    test('QiblaCubit updates heading and facing state', () {
      expect(cubit.state.qiblaData, isNotNull);
      final target = cubit.state.qiblaData!.qiblaAngle;

      cubit.updateHeading(target);
      expect(cubit.state.isFacing, isTrue);

      cubit.updateHeading((target + 180) % 360);
      expect(cubit.state.isFacing, isFalse);
    });

    test('QiblaCubit recalculates for a different location', () {
      cubit.calculateQibla(latitude: 24.7136, longitude: 46.6753, cityName: 'الرياض');
      expect(cubit.state.cityName, equals('الرياض'));
      expect(cubit.state.qiblaData?.cardinalDirection, equals('الجنوب الغربي'));
    });
  });
}
