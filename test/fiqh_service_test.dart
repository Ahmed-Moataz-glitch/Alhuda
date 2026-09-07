import 'package:alhuda/model/fiqh_model.dart';
import 'package:alhuda/services/fiqh_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FiqhService & FiqhData Comprehensive Tests', () {
    final service = FiqhService.instance;

    test('All 14 Fiqh books are loaded and properly categorized', () {
      final books = service.getAllBooks();
      expect(books.length, equals(14));

      // Verify books exist by ID
      final expectedBookIds = [
        'book_tahara',
        'book_salah',
        'book_zakah',
        'book_sawm',
        'book_hajj',
        'book_muamalat',
        'book_faraid',
        'book_family',
        'book_foods',
        'book_oaths',
        'book_hudud',
        'book_qada',
        'book_jihad',
        'book_adab',
      ];

      for (final id in expectedBookIds) {
        final book = service.getBookById(id);
        expect(book, isNotNull, reason: 'Book $id should exist');
        expect(book!.chapters, isNotEmpty, reason: 'Book $id should have chapters');
        expect(book.totalIssuesCount, greaterThan(0),
            reason: 'Book $id should have issues');
      }
    });

    test('Category filtering works accurately for all 14 books', () {
      final ibadat = service.getBooksByCategory(FiqhCategory.ibadat);
      expect(ibadat.length, equals(5)); // طهارة، صلاة، زكاة، صيام، حج

      final muamalat = service.getBooksByCategory(FiqhCategory.muamalat);
      expect(muamalat.length, equals(2)); // معاملات وبيوع، فرائض ومواريث

      final family = service.getBooksByCategory(FiqhCategory.family);
      expect(family.length, equals(1)); // أسرة ونكاح

      final general = service.getBooksByCategory(FiqhCategory.general);
      expect(general.length, equals(6)); // أطعمة، أيمان، جنايات، قضاء، جهاد، آداب
    });

    test('Chapters and Issues counts are extensive and consistent', () {
      expect(service.totalChaptersCount, greaterThanOrEqualTo(50));
      expect(service.totalIssuesCount, greaterThanOrEqualTo(55));
    });

    test('Normalize Arabic text removes tashkeel, tatweel, and normalizes letters', () {
      expect(
        FiqhService.normalizeArabic('كِتَابُ الطَّهَارَةِ'),
        equals('كتاب الطهاره'),
      );
      expect(
        FiqhService.normalizeArabic('فُرُوضُ الوُضُوءِ وَسُنَنُهُ'),
        equals('فروض الوضوء وسننه'),
      );
      expect(
        FiqhService.normalizeArabic('إِلَى الْمَرَافِقِ'),
        equals('الي المرافق'),
      );
      expect(
        FiqhService.normalizeArabic('الرِّبَا وَالْغَرَرُ'),
        equals('الربا والغرر'),
      );
      expect(
        FiqhService.normalizeArabic('الْفَرَائِضُ وَالْمَوَارِيثُ'),
        equals('الفرائض والمواريث'),
      );
    });

    test('Search finds matching issues across diverse books and topics', () {
      // 1. Search for Wudu
      final wuduResults = service.search('وضوء');
      expect(wuduResults, isNotEmpty);
      expect(wuduResults.any((r) => r.issue.id == 'issue_wudu_faraid_detail'), isTrue);

      // 2. Search for Sujood Sahw
      final sahwResults = service.search('السهو');
      expect(sahwResults, isNotEmpty);
      expect(sahwResults.any((r) => r.issue.id == 'issue_sujood_sahw_rules'), isTrue);

      // 3. Search for Riba
      final ribaResults = service.search('الربا');
      expect(ribaResults, isNotEmpty);
      expect(ribaResults.any((r) => r.issue.id == 'issue_riba_and_sarf_detail'), isTrue);

      // 4. Search for Umrah
      final umrahResults = service.search('عمرة');
      expect(umrahResults, isNotEmpty);
      expect(umrahResults.any((r) => r.issue.id == 'issue_umrah_steps_all'), isTrue);

      // 5. Search for Faraid / Inheritance
      final faraidResults = service.search('التركة');
      expect(faraidResults, isNotEmpty);

      // 6. Search for Jihad / Ribat
      final jihadResults = service.search('الرباط');
      expect(jihadResults, isNotEmpty);

      // 7. Search for Qasr and Jam' in prayer
      final qasrResults = service.search('قصر');
      expect(qasrResults, isNotEmpty);
      expect(qasrResults.any((r) => r.issue.id == 'issue_qasr_salah'), isTrue);

      final jamResults = service.search('الجمع');
      expect(jamResults, isNotEmpty);
      expect(jamResults.any((r) => r.issue.id == 'issue_jam_salah'), isTrue);

      final excusesChapter = service.getChapterById('book_salah', 'ch_excuses_salah');
      expect(excusesChapter, isNotNull);
      expect(excusesChapter!.issues.length, equals(4));
      expect(excusesChapter.issues.map((i) => i.id).toList(), containsAll([
        'issue_patient_traveler_salah',
        'issue_qasr_salah',
        'issue_jam_salah',
        'issue_jam_wa_qasr_rules',
      ]));
    });

    test('Search returns empty list for empty or whitespace query', () {
      expect(service.search(''), isEmpty);
      expect(service.search('   '), isEmpty);
    });

    test('Featured issues list is populated and covers all 12 featured issues', () {
      final featured = service.getFeaturedIssues();
      expect(featured.length, equals(12));
      for (final item in featured) {
        expect(item.book.title, isNotEmpty);
        expect(item.chapter.title, isNotEmpty);
        expect(item.issue.title, isNotEmpty);
        expect(item.issue.content, isNotEmpty);
      }
    });

    test('FiqhIssue serialization toJson and fromJson roundtrip', () {
      const issue = FiqhIssue(
        id: 'test_issue',
        title: 'مسألة تجريبية',
        rulingType: FiqhRulingType.wajib,
        content: 'محتوى تجريبي',
        conditions: ['شرط 1', 'شرط 2'],
        notes: ['تنبيه 1'],
        evidences: [
          FiqhEvidence(
            text: 'نص تجريبي',
            source: 'صحيح البخاري',
            isQuran: false,
          ),
        ],
      );

      final json = issue.toJson();
      final restored = FiqhIssue.fromJson(json);

      expect(restored.id, equals(issue.id));
      expect(restored.title, equals(issue.title));
      expect(restored.rulingType, equals(issue.rulingType));
      expect(restored.content, equals(issue.content));
      expect(restored.conditions.length, equals(2));
      expect(restored.notes.length, equals(1));
      expect(restored.evidences.length, equals(1));
      expect(restored.evidences.first.source, equals('صحيح البخاري'));
    });
  });
}
