import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alhuda/features/allah_names/presentation/cubit/allah_names_cubit.dart';
import 'package:alhuda/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';
import 'package:alhuda/features/fiqh/presentation/cubit/fiqh_cubit.dart';
import 'package:alhuda/features/hadith/presentation/cubit/hadith_cubit.dart';
import 'package:alhuda/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:alhuda/features/quran/domain/entities/quran_entities.dart';
import 'package:alhuda/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:alhuda/features/quran/presentation/cubit/tafsir_cubit.dart';
import 'package:alhuda/features/tasbeeh/domain/entities/tasbeeh_item.dart';
import 'package:alhuda/features/tasbeeh/domain/repositories/tasbeeh_repository.dart';
import 'package:alhuda/features/tasbeeh/presentation/cubit/tasbeeh_cubit.dart';

class MockTasbeehRepository implements TasbeehRepository {
  @override
  List<TasbeehItem> getDefaultItems() => const [
        TasbeehItem(id: 1, text: 'سبحان الله', targetCount: 33),
        TasbeehItem(id: 2, text: 'الحمد لله', targetCount: 33),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasbeehCubit Tests', () {
    blocTest<TasbeehCubit, TasbeehState>(
      'emits correct counter and totalCount on increment',
      build: () => TasbeehCubit(repository: MockTasbeehRepository()),
      act: (cubit) {
        cubit.increment();
        cubit.increment();
      },
      verify: (cubit) {
        expect(cubit.state.counter, equals(2));
        expect(cubit.state.totalCount, equals(2));
      },
    );

    blocTest<TasbeehCubit, TasbeehState>(
      'cycles to next item when reaching target count',
      build: () => TasbeehCubit(repository: MockTasbeehRepository()),
      act: (cubit) {
        for (int i = 0; i < 33; i++) {
          cubit.increment();
        }
      },
      verify: (cubit) {
        expect(cubit.state.currentIndex, equals(1));
        expect(cubit.state.counter, equals(0));
        expect(cubit.state.totalCount, equals(33));
      },
    );

    blocTest<TasbeehCubit, TasbeehState>(
      'resets counter on resetCounter()',
      build: () => TasbeehCubit(repository: MockTasbeehRepository()),
      act: (cubit) {
        cubit.increment();
        cubit.resetCounter();
      },
      verify: (cubit) {
        expect(cubit.state.counter, equals(0));
      },
    );
  });

  group('FiqhCubit Tests', () {
    blocTest<FiqhCubit, FiqhState>(
      'selects and filters by category',
      build: () => FiqhCubit(),
      act: (cubit) => cubit.selectCategory(FiqhCategory.ibadat),
      expect: () => [
        isA<FiqhState>().having(
          (s) => s.selectedCategory,
          'selectedCategory',
          FiqhCategory.ibadat,
        ),
      ],
    );

    blocTest<FiqhCubit, FiqhState>(
      'updates search query and clears search',
      build: () => FiqhCubit(),
      act: (cubit) {
        cubit.setSearchQuery('وضوء');
        cubit.clearSearch();
      },
      expect: () => [
        isA<FiqhState>().having((s) => s.searchQuery, 'searchQuery', 'وضوء'),
        isA<FiqhState>().having((s) => s.searchQuery, 'searchQuery', ''),
      ],
    );
  });

  group('HadithCubit Tests', () {
    blocTest<HadithCubit, HadithState>(
      'increases, decreases, and resets font size within bounds',
      build: () => HadithCubit(),
      act: (cubit) {
        cubit.increaseFontSize(); // 22.0
        cubit.decreaseFontSize(); // 20.0
        cubit.resetFontSize();    // 20.0
      },
      expect: () => [
        isA<HadithState>().having((s) => s.fontSize, 'fontSize', 22.0),
        isA<HadithState>().having((s) => s.fontSize, 'fontSize', 20.0),
      ],
    );
  });

  group('TafsirCubit Tests', () {
    blocTest<TafsirCubit, TafsirState>(
      'selects tafsir source correctly',
      build: () => TafsirCubit(),
      act: (cubit) => cubit.selectTafsir('saadi'),
      expect: () => [
        isA<TafsirState>().having((s) => s.selectedTafsirId, 'selectedTafsirId', 'saadi'),
      ],
    );
  });

  group('QuranCubit Tests', () {
    blocTest<QuranCubit, QuranState>(
      'saves last read position in state',
      build: () => QuranCubit(),
      act: (cubit) => cubit.saveLastRead(LastReadPosition(
        surahNumber: 2,
        surahName: 'البقرة',
        ayahNumber: 255,
        pageNumber: 42,
        timestamp: DateTime(2026, 1, 1),
      )),
      expect: () => [
        isA<QuranState>().having((s) => s.lastRead?.ayahNumber, 'ayahNumber', 255),
      ],
    );
  });

  group('AllahNamesCubit Tests', () {
    test('search and favorites filtering state updates correctly', () {
      final cubit = AllahNamesCubit();
      cubit.setSearchQuery('الملك');
      expect(cubit.state.searchQuery, equals('الملك'));
      cubit.clearSearch();
      expect(cubit.state.searchQuery, isEmpty);
      cubit.toggleFavoritesFilter();
      expect(cubit.state.favoritesOnly, isTrue);
      cubit.close();
    });
  });

  group('AzkarCubit Tests', () {
    test('category selection and search query work properly', () {
      final cubit = AzkarCubit();
      cubit.selectCategory(5);
      expect(cubit.state.selectedCategoryId, equals(5));
      cubit.setSearchQuery('صباح');
      expect(cubit.state.searchQuery, equals('صباح'));
      cubit.clearSearch();
      expect(cubit.state.searchQuery, isEmpty);
      cubit.close();
    });
  });

  group('PrayerTimesCubit Tests', () {
    test('prayer times calculation and date modification', () {
      final cubit = PrayerTimesCubit();
      final newDate = DateTime(2026, 5, 1);
      cubit.setDate(newDate);
      expect(cubit.state.currentDate, equals(newDate));
      cubit.close();
    });
  });
}
