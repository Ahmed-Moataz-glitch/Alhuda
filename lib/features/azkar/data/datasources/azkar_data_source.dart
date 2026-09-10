import 'package:muslim_data_flutter/muslim_data_flutter.dart';

abstract class AzkarDataSource {
  Future<List<AzkarCategory>> getAzkarCategories();
  Future<List<AzkarChapter>> getAzkarChapters({int categoryId = -1});
  Future<List<AzkarItem>> getAzkarItems(int chapterId);
}

class AzkarLocalDataSource implements AzkarDataSource {
  final MuslimRepository _repo;

  AzkarLocalDataSource({MuslimRepository? repo})
      : _repo = repo ?? MuslimRepository();

  @override
  Future<List<AzkarCategory>> getAzkarCategories() {
    return _repo.getAzkarCategories(language: Language.ar);
  }

  @override
  Future<List<AzkarChapter>> getAzkarChapters({int categoryId = -1}) {
    return _repo.getAzkarChapters(
      language: Language.ar,
      categoryId: categoryId,
    );
  }

  @override
  Future<List<AzkarItem>> getAzkarItems(int chapterId) {
    return _repo.getAzkarItems(
      language: Language.ar,
      chapterId: chapterId,
    );
  }
}
