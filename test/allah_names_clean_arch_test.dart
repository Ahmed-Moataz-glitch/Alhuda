import 'package:alhuda/features/allah_names/domain/entities/allah_name_entity.dart';
import 'package:alhuda/features/allah_names/domain/repositories/allah_names_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAllahNamesRepository implements AllahNamesRepository {
  final List<AllahNameEntity> _names = [
    const AllahNameEntity(
      id: 1,
      name: 'الله',
      normalizedName: 'الله',
      transliteration: 'Allah',
      englishTranslation: 'God',
      meaning: 'علم على الذات العلية',
      quranVerse: 'الله لا إله إلا هو',
      surahRef: 'البقرة: 255',
      isFavorite: false,
    ),
    const AllahNameEntity(
      id: 2,
      name: 'الرحمن',
      normalizedName: 'الرحمن',
      transliteration: 'Ar-Rahman',
      englishTranslation: 'The Most Gracious',
      meaning: 'ذو الرحمة الواسعة',
      quranVerse: 'الرحمن على العرش استوى',
      surahRef: 'طه: 5',
      isFavorite: true,
    ),
  ];

  @override
  Future<List<AllahNameEntity>> getAllNames() async => List.of(_names);

  @override
  List<AllahNameEntity> filterNames(
    List<AllahNameEntity> names, {
    String query = '',
    bool favoritesOnly = false,
  }) {
    var result = names;
    if (favoritesOnly) result = result.where((n) => n.isFavorite).toList();
    if (query.isNotEmpty) {
      result = result.where((n) => n.name.contains(query)).toList();
    }
    return result;
  }

  @override
  AllahNameEntity? getNameOfTheDay(List<AllahNameEntity> names) =>
      names.isNotEmpty ? names.first : null;

  @override
  Future<List<AllahNameEntity>> getFavorites() async =>
      _names.where((n) => n.isFavorite).toList();

  @override
  Future<bool> toggleFavorite(int nameId) async {
    final idx = _names.indexWhere((n) => n.id == nameId);
    if (idx != -1) {
      final updated = _names[idx].copyWith(isFavorite: !_names[idx].isFavorite);
      _names[idx] = updated;
      return updated.isFavorite;
    }
    return false;
  }

  @override
  bool isFavorite(int nameId) =>
      _names.any((n) => n.id == nameId && n.isFavorite);
}

void main() {
}
