import 'package:alhuda/services/azkar_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AzkarService Tests', () {
    test('Quick azkar items are defined with correct chapter IDs', () {
      final quickItems = AzkarService.quickAzkarList;
      expect(quickItems.length, equals(5));

      final morning = quickItems.firstWhere((i) => i.title == 'أذكار الصباح');
      expect(morning.chapterId, equals(27));

      final evening = quickItems.firstWhere((i) => i.title == 'أذكار المساء');
      expect(evening.chapterId, equals(28));

      final sleep = quickItems.firstWhere((i) => i.title == 'أذكار النوم');
      expect(sleep.chapterId, equals(29));

      final wakeUp = quickItems.firstWhere((i) => i.title == 'أذكار الاستيقاظ');
      expect(wakeUp.chapterId, equals(1));

      final postPrayer = quickItems.firstWhere((i) => i.title == 'أذكار بعد الصلاة');
      expect(postPrayer.chapterId, equals(25));
    });

    test('Normalize Arabic text removes tashkeel and normalizes characters', () {
      expect(
        AzkarService.normalizeArabic('أَذْكَارُ الصَّـبَاحِ '),
        equals('اذكار الصباح'),
      );
      expect(
        AzkarService.normalizeArabic('إِلَهَ إِلاَّ اللَّهُ'),
        equals('اله الا الله'),
      );
      expect(
        AzkarService.normalizeArabic('الصَّلاَةِ'),
        equals('الصلاه'),
      );
    });

    test('Filter chapters by normalized query', () {
      const chapters = [
        AzkarChapter(id: 27, categoryId: 1, name: 'أَذْكَارُ الصَّـبَاحِ '),
        AzkarChapter(id: 28, categoryId: 1, name: 'أَذْكَارُ الْمَسَــاءِ'),
        AzkarChapter(id: 29, categoryId: 1, name: 'أَذْكَارُ النَّــوْمِ'),
      ];

      final morningMatch = AzkarService.instance.filterChapters(chapters, 'صباح');
      expect(morningMatch.length, equals(1));
      expect(morningMatch.first.id, equals(27));

      final eveningMatch = AzkarService.instance.filterChapters(chapters, 'مساء');
      expect(eveningMatch.length, equals(1));
      expect(eveningMatch.first.id, equals(28));
    });

    test('Parse repetition counts accurately', () {
      final item3 = AzkarItem(
        id: 1,
        chapterId: 27,
        item: 'قل هو الله أحد (ثلاث مرات)',
        translation: '',
        reference: '',
      );
      expect(AzkarService.parseRepeatCount(item3), equals(3));

      final item4 = AzkarItem(
        id: 2,
        chapterId: 27,
        item: 'اللهم إني أصبحت أشهدك (أربع مرات)',
        translation: '',
        reference: '',
      );
      expect(AzkarService.parseRepeatCount(item4), equals(4));

      final item7 = AzkarItem(
        id: 3,
        chapterId: 27,
        item: 'حسبي الله لا إله إلا هو (سبع مرات)',
        translation: '',
        reference: '',
      );
      expect(AzkarService.parseRepeatCount(item7), equals(7));

      final item100 = AzkarItem(
        id: 4,
        chapterId: 27,
        item: 'سبحان الله وبحمده (مائة مرة)',
        translation: '',
        reference: '',
      );
      expect(AzkarService.parseRepeatCount(item100), equals(100));

      final itemDefault = AzkarItem(
        id: 5,
        chapterId: 27,
        item: 'آية الكرسي',
        translation: '',
        reference: '',
      );
      expect(AzkarService.parseRepeatCount(itemDefault), equals(1));
    });
  });
}
