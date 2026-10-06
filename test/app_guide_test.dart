import 'package:alhuda/features/app_guide/data/repositories/app_guide_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppGuideData Tests', () {
    test('Video ID and URL match expected YouTube values', () {
      expect(AppGuideData.videoId, equals('5lrnmmRFXSI'));
      expect(
        AppGuideData.videoUrl,
        equals('https://www.youtube.com/watch?v=5lrnmmRFXSI'),
      );
      expect(AppGuideData.videoTitle, isNotEmpty);
      expect(AppGuideData.videoDescription, isNotEmpty);
    });

    test('Features list contains all key application sections with valid data', () {
      final features = AppGuideData.getFeatures();
      expect(features, isNotEmpty);
      expect(features.length, equals(9));

      for (final feature in features) {
        expect(feature.id, isNotEmpty);
        expect(feature.title, isNotEmpty);
        expect(feature.subtitle, isNotEmpty);
        expect(feature.description, isNotEmpty);
        expect(feature.badge, isNotEmpty);
        expect(feature.highlights, isNotEmpty);
        expect(feature.highlights.length, greaterThanOrEqualTo(3));
      }
    });

    test('Guide steps contain comprehensive instructions and categories', () {
      final steps = AppGuideData.getGuideSteps();
      expect(steps, isNotEmpty);

      for (final step in steps) {
        expect(step.title, isNotEmpty);
        expect(step.subtitle, isNotEmpty);
        expect(step.category, isNotEmpty);
        expect(step.steps, isNotEmpty);
        expect(step.steps.length, greaterThanOrEqualTo(3));
      }
    });
  });
}
