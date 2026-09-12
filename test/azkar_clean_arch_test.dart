import 'package:alhuda/features/azkar/data/repositories/azkar_repository_impl.dart';
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
}
