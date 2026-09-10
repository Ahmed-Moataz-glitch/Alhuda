import 'dart:convert';
import 'dart:io';
import 'package:alhuda/features/allah_names/domain/entities/allah_name_entity.dart';
import 'package:alhuda/features/allah_names/domain/repositories/allah_names_repository.dart';
import 'package:alhuda/services/allah_names_data.dart';
import 'package:flutter/foundation.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:path_provider/path_provider.dart';

class AllahNamesRepositoryImpl implements AllahNamesRepository {
  final MuslimRepository _repo;

  List<AllahNameEntity>? _cachedNames;
  final Set<int> _favoriteIds = {};
  bool _isInitialized = false;

  AllahNamesRepositoryImpl({MuslimRepository? repo})
      : _repo = repo ?? MuslimRepository();

  @override
  Future<List<AllahNameEntity>> getAllNames() async {
    if (_cachedNames != null && _cachedNames!.isNotEmpty) {
      return _cachedNames!;
    }

    if (!_isInitialized) {
      await _loadFavorites();
      _isInitialized = true;
    }

    try {
      final arabicList = await _repo.getNames(language: Language.ar);
      final englishList = await _repo.getNames(language: Language.en);

      final Map<int, NameOfAllah> englishMap = {
        for (var item in englishList) item.id: item,
      };

      final List<AllahNameEntity> combined = [];

      for (var arItem in arabicList) {
        final enItem = englishMap[arItem.id];
        final enrichment = AllahNamesData.enrichments[arItem.id];
        final nameStr = arItem.name;
        final normalized = AllahNameEntity.removeDiacritics(nameStr);

        combined.add(
          AllahNameEntity(
            id: arItem.id,
            name: nameStr,
            normalizedName: normalized,
            transliteration: enItem?.transliteration ?? '',
            englishTranslation: enItem?.translation ?? '',
            meaning: enrichment?.arabicMeaning ?? '',
            quranVerse: enrichment?.quranVerse ?? '',
            surahRef: enrichment?.surahRef ?? '',
            isFavorite: _favoriteIds.contains(arItem.id),
          ),
        );
      }

      combined.sort((a, b) => a.id.compareTo(b.id));
      _cachedNames = combined;
      return combined;
    } catch (e) {
      debugPrint('Error loading names of Allah: $e');
      return _cachedNames ?? [];
    }
  }

  @override
  List<AllahNameEntity> filterNames(
    List<AllahNameEntity> names, {
    String query = '',
    bool favoritesOnly = false,
  }) {
    var result = names;

    if (favoritesOnly) {
      result = result.where((n) => n.isFavorite).toList();
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return result;
    }

    final cleanQuery = AllahNameEntity.removeDiacritics(trimmed).toLowerCase();
    final cleanTransQuery = AllahNameEntity.normalizeTransliteration(trimmed);
    final isNumeric = int.tryParse(trimmed) != null;
    final targetId = isNumeric ? int.parse(trimmed) : null;

    return result.where((n) {
      if (targetId != null && n.id == targetId) return true;

      final normalizedArabic = n.normalizedName.toLowerCase();
      final transliteration = n.transliteration.toLowerCase();
      final normalizedTrans =
          AllahNameEntity.normalizeTransliteration(n.transliteration);
      final meaning = AllahNameEntity.removeDiacritics(n.meaning).toLowerCase();
      final english = n.englishTranslation.toLowerCase();

      return normalizedArabic.contains(cleanQuery) ||
          transliteration.contains(cleanQuery) ||
          normalizedTrans.contains(cleanTransQuery) ||
          meaning.contains(cleanQuery) ||
          english.contains(cleanQuery);
    }).toList();
  }

  @override
  AllahNameEntity? getNameOfTheDay(List<AllahNameEntity> names) {
    if (names.isEmpty) return null;
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    final index = (dayOfYear % names.length);
    return names[index];
  }

  @override
  Future<bool> toggleFavorite(int nameId) async {
    final willBeFavorite = !_favoriteIds.contains(nameId);

    if (willBeFavorite) {
      _favoriteIds.add(nameId);
    } else {
      _favoriteIds.remove(nameId);
    }

    if (_cachedNames != null) {
      _cachedNames = _cachedNames!.map((item) {
        if (item.id == nameId) {
          return item.copyWith(isFavorite: willBeFavorite);
        }
        return item;
      }).toList();
    }

    await _saveFavorites();
    return willBeFavorite;
  }

  @override
  bool isFavorite(int nameId) => _favoriteIds.contains(nameId);

  @override
  Future<List<AllahNameEntity>> getFavorites() async {
    final all = await getAllNames();
    return all.where((n) => n.isFavorite).toList();
  }

  Future<File> _getFavoritesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/allah_names_favorites.json');
  }

  Future<void> _loadFavorites() async {
    try {
      final file = await _getFavoritesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _favoriteIds.clear();
        for (var id in list) {
          if (id is int) _favoriteIds.add(id);
        }
      }
    } catch (e) {
      debugPrint('Error loading Allah names favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final file = await _getFavoritesFile();
      final content = jsonEncode(_favoriteIds.toList());
      await file.writeAsString(content);
    } catch (e) {
      debugPrint('Error saving Allah names favorites: $e');
    }
  }
}
