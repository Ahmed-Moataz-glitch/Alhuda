import 'package:alhuda/model/city_locations_data.dart';
import 'package:alhuda/view/widgets/egypt_dst_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

void main() {
  group('City Locations & Arabic Localization Tests', () {
    test('Contains over 140 curated locations in Arabic', () {
      expect(LocationDataHelper.allCities.length, greaterThanOrEqualTo(140));
    });

    test('All cities have non-empty Arabic names and countries', () {
      for (final city in LocationDataHelper.allCities) {
        expect(city.nameAr.trim().isNotEmpty, isTrue,
            reason: 'City id ${city.id} has empty nameAr');
        expect(city.countryAr.trim().isNotEmpty, isTrue,
            reason: 'City id ${city.id} has empty countryAr');
        expect(city.region.trim().isNotEmpty, isTrue,
            reason: 'City id ${city.id} has empty region');
        expect(city.latitude, isNotNull);
        expect(city.longitude, isNotNull);

        // Verify nameAr contains Arabic characters
        expect(RegExp(r'[\u0600-\u06FF]').hasMatch(city.nameAr), isTrue,
            reason: '${city.nameAr} does not contain Arabic text');
        expect(RegExp(r'[\u0600-\u06FF]').hasMatch(city.countryAr), isTrue,
            reason: '${city.countryAr} does not contain Arabic text');
      }
    });

    test('All Egypt cities are correctly recognized by EgyptDstHelper', () {
      final egyptCities = LocationDataHelper.allCities
          .where((c) => c.region == 'مصر' || c.countryCode == 'EG')
          .toList();

      expect(egyptCities.length, greaterThanOrEqualTo(27),
          reason: 'Must include at least all 27 governorates');

      for (final city in egyptCities) {
        final loc = city.toLocation();
        expect(EgyptDstHelper.isEgyptLocation(loc), isTrue,
            reason: '${city.nameAr} should be recognized as Egypt location');
      }
    });

    test('Arabic text normalization handles hamzas, taa marbuta, and diacritics', () {
      expect(LocationArabicHelper.normalizeArabic('الإسكندرية'),
          equals('الاسكندريه'));
      expect(LocationArabicHelper.normalizeArabic('مَكَّةُ'), equals('مكه'));
      expect(LocationArabicHelper.normalizeArabic('أسوان'), equals('اسوان'));
      expect(LocationArabicHelper.normalizeArabic('القاهرة'), equals('القاهره'));
    });

    test('Search finds cities by Arabic variations and English keywords', () {
      // Search with different Arabic forms
      final alexVariants1 =
          LocationDataHelper.searchCities(query: 'الاسكندريه');
      expect(alexVariants1.any((c) => c.nameAr.contains('الإسكندرية')), isTrue);

      final alexVariants2 =
          LocationDataHelper.searchCities(query: 'alexandria');
      expect(alexVariants2.any((c) => c.nameAr.contains('الإسكندرية')), isTrue);

      final makkah = LocationDataHelper.searchCities(query: 'مكه');
      expect(makkah.any((c) => c.nameAr.contains('مكة المكرمة')), isTrue);

      final tanta = LocationDataHelper.searchCities(query: 'طنطا');
      expect(tanta.any((c) => c.nameAr.contains('طنطا')), isTrue);

      final jerusalem = LocationDataHelper.searchCities(query: 'القدس');
      expect(jerusalem.any((c) => c.nameAr.contains('القدس')), isTrue);

      final dubai = LocationDataHelper.searchCities(query: 'دبي');
      expect(dubai.any((c) => c.nameAr.contains('دبي')), isTrue);
    });

    test('Filter by region works properly', () {
      final egyptList =
          LocationDataHelper.searchCities(query: '', selectedRegion: 'مصر');
      expect(egyptList.every((c) => c.region == 'مصر'), isTrue);
      expect(egyptList.length, greaterThanOrEqualTo(30));

      final saudiList =
          LocationDataHelper.searchCities(query: '', selectedRegion: 'السعودية');
      expect(saudiList.every((c) => c.region == 'السعودية'), isTrue);
      expect(saudiList.length, greaterThanOrEqualTo(20));

      final palestineList = LocationDataHelper.searchCities(
          query: '', selectedRegion: 'فلسطين والشام');
      expect(palestineList.every((c) => c.region == 'فلسطين والشام'), isTrue);
    });

    test('LocationArabicHelper translates external English Location to Arabic', () {
      const englishCairo = Location(
        id: 1,
        name: 'Cairo',
        latitude: 30.0444,
        longitude: 31.2357,
        countryCode: 'EG',
        countryName: 'Egypt',
        hasFixedPrayerTime: false,
      );

      final arabicCairo = LocationArabicHelper.toArabicLocation(englishCairo);
      expect(arabicCairo.name, equals('القاهرة'));
      expect(arabicCairo.countryName, equals('مصر'));

      const englishMakkah = Location(
        id: 2,
        name: 'Makkah',
        latitude: 21.4225,
        longitude: 39.8262,
        countryCode: 'SA',
        countryName: 'Saudi Arabia',
        hasFixedPrayerTime: false,
      );

      final arabicMakkah = LocationArabicHelper.toArabicLocation(englishMakkah);
      expect(arabicMakkah.name, equals('مكة المكرمة'));
      expect(arabicMakkah.countryName, contains('السعودية'));
    });
  });
}
