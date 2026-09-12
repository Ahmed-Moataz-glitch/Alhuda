import 'package:alhuda/features/quran/domain/entities/quran_entities.dart';
import 'package:alhuda/features/quran/domain/repositories/quran_repository.dart';
import 'package:alhuda/features/quran/presentation/view_models/quran_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class MockQuranRepository implements QuranRepository {
  final List<SurahData> _surahs = [
    const SurahData(
      number: 1,
      arabicName: 'الفاتحة',
      englishName: 'Al-Fatihah',
      englishTranslation: 'The Opener',
      revelationType: 'مكية',
      totalAyahs: 7,
      startPage: 1,
    ),
  ];

  final List<JuzData> _juzs = [
    const JuzData(
      number: 1,
      startSurahNumber: 1,
      startSurahName: 'الفاتحة',
      startAyahNumber: 1,
      startPage: 1,
    ),
  ];

  final List<QuranBookmark> _bookmarks = [];
  LastReadPosition? _lastRead;

  @override
  Future<void> init() async {}

  @override
  List<SurahData> getAllSurahs() => _surahs;

  @override
  SurahData? getSurah(int number) =>
      _surahs.firstWhere((s) => s.number == number);

  @override
  List<AyahData> getAyahsForSurah(int surahNumber) => [];

  @override
  List<JuzData> getAllJuzs() => _juzs;

  @override
  List<QuranSearchResult> search(String query) => [
        const QuranSearchResult(
          surahNumber: 1,
          surahName: 'الفاتحة',
          ayahNumber: 1,
          uthmaniText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          simpleText: 'بسم الله الرحمن الرحيم',
        ),
      ];

  @override
  List<QuranBookmark> getBookmarks() => _bookmarks;

  @override
  bool isBookmarked(int surahNumber, int ayahNumber) =>
      _bookmarks.any((b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber);

  @override
  bool isPageBookmarked(int pageNumber) =>
      _bookmarks.any((b) => b.pageNumber == pageNumber);

  @override
  Future<bool> togglePageBookmark(int pageNumber) async {
    final index = _bookmarks.indexWhere((b) => b.pageNumber == pageNumber);
    if (index >= 0) {
      _bookmarks.removeAt(index);
      return false;
    } else {
      _bookmarks.insert(
        0,
        QuranBookmark(
          surahNumber: 1,
          surahName: 'الفاتحة',
          ayahNumber: 1,
          pageNumber: pageNumber,
          snippet: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          timestamp: DateTime.now(),
        ),
      );
      return true;
    }
  }

  @override
  QuranBookmark? getSavedPageBookmark() => _bookmarks.isEmpty ? null : _bookmarks.first;

  @override
  Future<void> removeBookmarkByPage(int pageNumber) async {
    _bookmarks.removeWhere((b) => b.pageNumber == pageNumber);
  }

  @override
  Future<void> toggleBookmark({
    required int surah,
    required String surahName,
    required int ayah,
    required String snippet,
    int? pageNumber,
  }) async {
    _bookmarks.add(
      QuranBookmark(
        surahNumber: surah,
        surahName: surahName,
        ayahNumber: ayah,
        pageNumber: pageNumber ?? 1,
        snippet: snippet,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  LastReadPosition? get lastRead => _lastRead ?? LastReadPosition(
        surahNumber: 1,
        surahName: 'الفاتحة',
        ayahNumber: 1,
        pageNumber: 1,
        timestamp: DateTime.now(),
      );

  @override
  Future<void> setLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    int? pageNumber,
  }) async {
    _lastRead = LastReadPosition(
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber ?? 1,
      timestamp: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quran Clean Architecture Tests', () {
    late QuranViewModel viewModel;

    setUp(() {
      viewModel = QuranViewModel(repository: MockQuranRepository());
    });

    test('QuranViewModel loads surahs and juzs', () async {
      expect(viewModel.surahs, isEmpty);
      await viewModel.loadInitialData();

      expect(viewModel.surahs.length, equals(1));
      expect(viewModel.surahs.first.arabicName, equals('الفاتحة'));
      expect(viewModel.juzs.length, equals(1));
    });

    test('QuranViewModel search performs correctly', () async {
      await viewModel.loadInitialData();
      viewModel.search('الرحمن');

      expect(viewModel.searchResults.length, equals(1));
      expect(viewModel.searchResults.first.surahName, equals('الفاتحة'));

      viewModel.clearSearch();
      expect(viewModel.searchResults, isEmpty);
    });
  });
}
