import 'package:alhuda/view/widgets/qibla_widget.dart';
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

    test('Bearing from Medina towards Kaaba is almost directly South (~175-177 deg)', () {
      // Medina: 24.5247° N, 39.5692° E
      final medinaBearing = qiblaAngle(24.5247, 39.5692);
      expect(medinaBearing, greaterThan(170));
      expect(medinaBearing, lessThan(180));
    });

    test('Bearing from Riyadh towards Kaaba is Southwest (~240-245 deg)', () {
      // Riyadh: 24.7136° N, 46.6753° E
      final riyadhBearing = qiblaAngle(24.7136, 46.6753);
      expect(riyadhBearing, greaterThan(240));
      expect(riyadhBearing, lessThan(246));
      expect(compassDir(riyadhBearing), equals('SW'));
    });
  });

  group('QiblaHelper Tests for Sensorless Mode', () {
    test('Arabic cardinal directions are accurate across 360 degrees', () {
      expect(QiblaHelper.getArabicDirection(0), equals('الشمال'));
      expect(QiblaHelper.getArabicDirection(10), equals('الشمال'));
      expect(QiblaHelper.getArabicDirection(355), equals('الشمال'));
      expect(QiblaHelper.getArabicDirection(45), equals('الشمال الشرقي'));
      expect(QiblaHelper.getArabicDirection(90), equals('الشرق'));
      expect(QiblaHelper.getArabicDirection(136), equals('الجنوب الشرقي'));
      expect(QiblaHelper.getArabicDirection(180), equals('الجنوب'));
      expect(QiblaHelper.getArabicDirection(225), equals('الجنوب الغربي'));
      expect(QiblaHelper.getArabicDirection(270), equals('الغرب'));
      expect(QiblaHelper.getArabicDirection(315), equals('الشمال الغربي'));
    });

    test('Difference between headings correctly handles angle wrap-around', () {
      expect(QiblaHelper.calculateDifference(136, 136), equals(0.0));
      expect(QiblaHelper.calculateDifference(140, 136), equals(4.0));
      expect(QiblaHelper.calculateDifference(136, 140), equals(4.0));
      expect(QiblaHelper.calculateDifference(2, 358), equals(4.0));
      expect(QiblaHelper.calculateDifference(358, 2), equals(4.0));
      expect(QiblaHelper.calculateDifference(0, 180), equals(180.0));
    });

    test('isFacingQibla detects alignment correctly', () {
      // Cairo Qibla ~136°
      expect(QiblaHelper.isFacingQibla(136.0, 136.0), isTrue);
      expect(QiblaHelper.isFacingQibla(138.0, 136.0, threshold: 4.0), isTrue);
      expect(QiblaHelper.isFacingQibla(140.0, 136.0, threshold: 4.0), isTrue);
      expect(QiblaHelper.isFacingQibla(141.0, 136.0, threshold: 4.0), isFalse);

      // Edge case across 0° / 360° boundary
      expect(QiblaHelper.isFacingQibla(1.0, 359.0, threshold: 4.0), isTrue);
      expect(QiblaHelper.isFacingQibla(358.0, 1.0, threshold: 4.0), isTrue);
      expect(QiblaHelper.isFacingQibla(350.0, 1.0, threshold: 4.0), isFalse);
    });
  });
}
