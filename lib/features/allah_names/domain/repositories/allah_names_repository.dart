import 'package:alhuda/features/allah_names/domain/entities/allah_name_entity.dart';

abstract class AllahNamesRepository {
  Future<List<AllahNameEntity>> getAllNames();
  Future<bool> toggleFavorite(int nameId);
  bool isFavorite(int nameId);
  Future<List<AllahNameEntity>> getFavorites();
  List<AllahNameEntity> filterNames(
    List<AllahNameEntity> names, {
    String query = '',
    bool favoritesOnly = false,
  });
  AllahNameEntity? getNameOfTheDay(List<AllahNameEntity> names);
}
