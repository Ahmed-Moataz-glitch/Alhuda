import 'package:flutter_test/flutter_test.dart';
import 'package:qibla/qibla.dart';

void main() {
  group('Qibla Calculations Tests', () {
    test('Kaaba coordinates are valid and constant', () {
      expect(kaabaLat, closeTo(21.4225, 0.001));
      expect(kaabaLng, closeTo(39.8261, 0.001));
    });

    test('Bearing towards Kaaba from Cairo is southeast (~136 deg)', () {
      // Cairo: 30.0444° N, 31.2357° E
      final cairoBearing = qiblaAngle(30.0444, 31.2357);
      expect(cairoBearing, greaterThan(130));
      expect(cairoBearing, lessThan(145));
      expect(compassDir(cairoBearing), equals('SE'));
    });

    test('Distance from Cairo to Kaaba is approximately 1280-1300 km', () {
      final dist = distanceKm(30.0444, 31.2357, kaabaLat, kaabaLng);
      expect(dist, greaterThan(1250));
      expect(dist, lessThan(1350));
    });

    test('Distance from Kaaba to Kaaba is 0 km', () {
      final dist = distanceKm(kaabaLat, kaabaLng, kaabaLat, kaabaLng);
      expect(dist, closeTo(0, 0.01));
    });
  });
}
