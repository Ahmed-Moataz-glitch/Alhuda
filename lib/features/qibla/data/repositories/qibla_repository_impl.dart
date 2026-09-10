import 'dart:math' as math;
import '../../domain/entities/qibla_data.dart';
import '../../domain/repositories/qibla_repository.dart';

class QiblaRepositoryImpl implements QiblaRepository {
  static const double kaabaLat = 21.422487;
  static const double kaabaLng = 39.826206;

  @override
  QiblaData calculateQibla({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = latitude * (math.pi / 180.0);
    final lng1 = longitude * (math.pi / 180.0);
    final lat2 = kaabaLat * (math.pi / 180.0);
    final lng2 = kaabaLng * (math.pi / 180.0);

    final dLng = lng2 - lng1;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    var angle = math.atan2(y, x) * (180.0 / math.pi);
    angle = (angle % 360.0 + 360.0) % 360.0;

    // Haversine distance
    final dLat = lat2 - lat1;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = 6371.0 * c;

    final direction = getArabicDirection(angle);

    return QiblaData(
      qiblaAngle: angle,
      distanceKm: distance,
      cardinalDirection: direction,
    );
  }

  @override
  String getArabicDirection(double degree) {
    final b = (degree % 360.0 + 360.0) % 360.0;
    if (b >= 337.5 || b < 22.5) return 'الشمال';
    if (b >= 22.5 && b < 67.5) return 'الشمال الشرقي';
    if (b >= 67.5 && b < 112.5) return 'الشرق';
    if (b >= 112.5 && b < 157.5) return 'الجنوب الشرقي';
    if (b >= 157.5 && b < 202.5) return 'الجنوب';
    if (b >= 202.5 && b < 247.5) return 'الجنوب الغربي';
    if (b >= 247.5 && b < 292.5) return 'الغرب';
    return 'الشمال الغربي';
  }

  @override
  double calculateDifference(double heading, double target) {
    return ((heading - target + 180.0) % 360.0 - 180.0).abs();
  }

  @override
  bool isFacingQibla(double heading, double target, {double threshold = 4.0}) {
    return calculateDifference(heading, target) <= threshold;
  }
}
