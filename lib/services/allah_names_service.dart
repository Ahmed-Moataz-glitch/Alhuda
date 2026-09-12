import 'package:alhuda/features/allah_names/data/repositories/allah_names_repository_impl.dart';
import 'package:alhuda/features/allah_names/domain/entities/allah_name_entity.dart';
import 'package:alhuda/features/allah_names/domain/repositories/allah_names_repository.dart';
export 'package:alhuda/features/allah_names/domain/entities/allah_name_entity.dart';
export 'package:alhuda/features/allah_names/domain/repositories/allah_names_repository.dart';
export 'package:alhuda/features/allah_names/data/repositories/allah_names_repository_impl.dart';

class AllahNamesService {
  AllahNamesService._internal();
  static final AllahNamesService instance = AllahNamesService._internal();

  final AllahNamesRepository _repository = AllahNamesRepositoryImpl();

  Future<List<AllahNameEntity>> getAllNames() => _repository.getAllNames();

  List<AllahNameEntity> filterNames({
    required List<AllahNameEntity> sourceList,
    required String query,
    bool favoritesOnly = false,
  }) {
    return _repository.filterNames(
      sourceList,
      query: query,
      favoritesOnly: favoritesOnly,
    );
  }

  AllahNameEntity? getNameOfTheDay(List<AllahNameEntity> names) {
    return _repository.getNameOfTheDay(names);
  }

  Future<bool> toggleFavorite(int nameId) =>
      _repository.toggleFavorite(nameId);

  bool isFavorite(int nameId) => _repository.isFavorite(nameId);
}
