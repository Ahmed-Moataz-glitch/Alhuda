import 'package:alhuda/features/qibla/domain/entities/qibla_data.dart';

abstract class QiblaRepository {
  QiblaData calculateQibla({
    required double latitude,
    required double longitude,
  });
  String getArabicDirection(double degree);
  double calculateDifference(double heading, double target);
  bool isFacingQibla(double heading, double target, {double threshold = 4.0});
}
