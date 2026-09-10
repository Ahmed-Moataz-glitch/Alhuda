import 'package:alhuda/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:alhuda/features/azkar/presentation/view_models/azkar_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class MockAzkarRepository extends AzkarRepositoryImpl {
  @override
  Future<List<AzkarCategory>> getCategories() async => [
        const AzkarCategory(id: 1, name: 'أذكار اليوم والليلة'),
        const AzkarCategory(id: 2, name: 'أذكار الصلاة'),
      ];

  @override
  Future<List<AzkarChapter>> getAllChapters() async => [
        const AzkarChapter(id: 27, categoryId: 1, name: 'أذكار الصباح'),
        const AzkarChapter(id: 28, categoryId: 1, name: 'أذكار المساء'),
        const AzkarChapter(id: 25, categoryId: 2, name: 'أذكار بعد الصلاة'),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Azkar Clean Architecture Tests', () {
    late AzkarViewModel viewModel;

    setUp(() {
      viewModel = AzkarViewModel(repository: MockAzkarRepository());
    });

    test('AzkarViewModel loads categories and chapters correctly', () async {
      expect(viewModel.isLoading, isTrue);
      await viewModel.loadInitialData();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.categories.length, equals(2));
      expect(viewModel.allChapters.length, equals(3));
      expect(viewModel.filteredChapters.length, equals(3));
    });

    test('AzkarViewModel filters by categoryId', () async {
      await viewModel.loadInitialData();
      viewModel.selectCategory(2);

      expect(viewModel.selectedCategoryId, equals(2));
      expect(viewModel.filteredChapters.length, equals(1));
      expect(viewModel.filteredChapters.first.id, equals(25));
    });

    test('AzkarViewModel filters by search query', () async {
      await viewModel.loadInitialData();
      viewModel.setSearchQuery('مساء');

      expect(viewModel.filteredChapters.length, equals(1));
      expect(viewModel.filteredChapters.first.id, equals(28));

      viewModel.clearSearch();
      expect(viewModel.filteredChapters.length, equals(3));
    });
  });
}
