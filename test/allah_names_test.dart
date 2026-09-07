import 'package:alhuda/model/allah_name_model.dart';
import 'package:alhuda/services/allah_names_data.dart';
import 'package:alhuda/services/allah_names_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AllahNames Tests', () {
    test('AllahNamesData covers all 99 names with authentic enrichments', () {
      expect(AllahNamesData.enrichments.length, equals(99));

      for (int i = 1; i <= 99; i++) {
        final item = AllahNamesData.enrichments[i];
        expect(item, isNotNull, reason: 'Name #$i should exist in enrichments');
        expect(item!.arabicMeaning.isNotEmpty, isTrue, reason: 'Name #$i meaning must not be empty');
        expect(item.quranVerse.isNotEmpty, isTrue, reason: 'Name #$i verse must not be empty');
        expect(item.surahRef.isNotEmpty, isTrue, reason: 'Name #$i surahRef must not be empty');
      }
    });

    test('removeDiacritics strips tashkeel and normalizes Arabic letters', () {
      expect(
        AllahNameModel.removeDiacritics('ٱلرَّحْمَٰنُ'),
        equals('الرحمن'),
      );
      expect(
        AllahNameModel.removeDiacritics('ٱلْقُدُّوسُ'),
        equals('القدوس'),
      );
      expect(
        AllahNameModel.removeDiacritics('ٱلْعَزِيزُ'),
        equals('العزيز'),
      );
    });

    test('Filter names by Arabic text, transliteration, ID and favorites', () {
      final sampleList = [
        const AllahNameModel(
          id: 1,
          name: 'الله',
          normalizedName: 'الله',
          transliteration: 'Allāh',
          englishTranslation: 'The Name of Allah',
          meaning: 'عَلَم على الذات الإلهية',
          quranVerse: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
          surahRef: 'البقرة: 255',
          isFavorite: true,
        ),
        const AllahNameModel(
          id: 2,
          name: 'ٱلرَّحْمَٰنُ',
          normalizedName: 'الرحمن',
          transliteration: 'Ar-Raḥmān',
          englishTranslation: 'The Exceedingly Compassionate',
          meaning: 'ذو الرحمة الواسعة العظيمة',
          quranVerse: 'الرَّحْمَٰنِ الرَّحِيمِ',
          surahRef: 'الفاتحة: 3',
          isFavorite: false,
        ),
        const AllahNameModel(
          id: 3,
          name: 'ٱلرَّحِيمُ',
          normalizedName: 'الرحيم',
          transliteration: 'Ar-Raḥīm',
          englishTranslation: 'The Exceedingly Merciful',
          meaning: 'ذو الرحمة الواصلة',
          quranVerse: 'وَكَانَ بِالْمُؤْمِنِينَ رَحِيمًا',
          surahRef: 'الأحزاب: 43',
          isFavorite: true,
        ),
      ];

      // Filter by Arabic query without tashkeel
      final result1 = AllahNamesService.instance.filterNames(
        sourceList: sampleList,
        query: 'رحمن',
      );
      expect(result1.length, equals(1));
      expect(result1.first.id, equals(2));

      // Filter by Transliteration query
      final result2 = AllahNamesService.instance.filterNames(
        sourceList: sampleList,
        query: 'Rahim',
      );
      expect(result2.length, equals(1));
      expect(result2.first.id, equals(3));

      // Filter by ID query
      final result3 = AllahNamesService.instance.filterNames(
        sourceList: sampleList,
        query: '1',
      );
      expect(result3.length, equals(1));
      expect(result3.first.id, equals(1));

      // Filter favorites only
      final resultFav = AllahNamesService.instance.filterNames(
        sourceList: sampleList,
        query: '',
        favoritesOnly: true,
      );
      expect(resultFav.length, equals(2));
      expect(resultFav.map((e) => e.id), containsAll([1, 3]));
    });

    test('getNameOfTheDay returns a valid name', () {
      final sampleList = [
        const AllahNameModel(
          id: 1,
          name: 'الله',
          normalizedName: 'الله',
          transliteration: 'Allāh',
          englishTranslation: 'The Name of Allah',
          meaning: 'عَلَم على الذات الإلهية',
          quranVerse: '',
          surahRef: '',
        ),
      ];

      final today = AllahNamesService.instance.getNameOfTheDay(sampleList);
      expect(today, isNotNull);
      expect(today!.id, equals(1));
    });
  });
}
