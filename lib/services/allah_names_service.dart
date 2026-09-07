import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../model/allah_name_model.dart';
import 'allah_names_data.dart';

class AllahNamesService {
  AllahNamesService._internal();
  static final AllahNamesService instance = AllahNamesService._internal();

  final MuslimRepository _repo = MuslimRepository();

  List<AllahNameModel>? _cachedNames;
  final Set<int> _favoriteIds = {};
  bool _isInitialized = false;

  /// Ensure names and favorites are loaded
  Future<List<AllahNameModel>> getAllNames() async {
    if (_cachedNames != null && _cachedNames!.isNotEmpty) {
      return _cachedNames!;
    }

    if (!_isInitialized) {
      await _loadFavorites();
      _isInitialized = true;
    }

    try {
      // 1. Fetch Arabic names from muslim_data_flutter
      final arabicList = await _repo.getNames(language: Language.ar);
      // 2. Fetch English transliterations & translations from muslim_data_flutter
      final englishList = await _repo.getNames(language: Language.en);

      final Map<int, NameOfAllah> englishMap = {
        for (var item in englishList) item.id: item,
      };

      final List<AllahNameModel> combined = [];

      for (var arItem in arabicList) {
        final enItem = englishMap[arItem.id];
        final enrichment = AllahNamesData.enrichments[arItem.id];

        final nameStr = arItem.name;
        final normalized = AllahNameModel.removeDiacritics(nameStr);

        combined.add(
          AllahNameModel(
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

      // Sort by ID to guarantee order 1..99
      combined.sort((a, b) => a.id.compareTo(b.id));
      _cachedNames = combined;
      return combined;
    } catch (e) {
      debugPrint('Error loading names of Allah from muslim_data_flutter: $e');
      return _cachedNames ?? [];
    }
  }

  /// Filter names by search query and favorite status
  List<AllahNameModel> filterNames({
    required List<AllahNameModel> sourceList,
    required String query,
    bool favoritesOnly = false,
  }) {
    var result = sourceList;

    if (favoritesOnly) {
      result = result.where((n) => n.isFavorite).toList();
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return result;
    }

    final cleanQuery = AllahNameModel.removeDiacritics(trimmed).toLowerCase();
    final cleanTransQuery = AllahNameModel.normalizeTransliteration(trimmed);
    final isNumeric = int.tryParse(trimmed) != null;
    final targetId = isNumeric ? int.parse(trimmed) : null;

    return result.where((n) {
      if (targetId != null && n.id == targetId) return true;

      final normalizedArabic = n.normalizedName.toLowerCase();
      final transliteration = n.transliteration.toLowerCase();
      final normalizedTrans = AllahNameModel.normalizeTransliteration(n.transliteration);
      final meaning = AllahNameModel.removeDiacritics(n.meaning).toLowerCase();
      final english = n.englishTranslation.toLowerCase();

      return normalizedArabic.contains(cleanQuery) ||
          transliteration.contains(cleanQuery) ||
          normalizedTrans.contains(cleanTransQuery) ||
          meaning.contains(cleanQuery) ||
          english.contains(cleanQuery);
    }).toList();
  }

  /// Get Name of the Day (اسم اليوم للتأمل)
  AllahNameModel? getNameOfTheDay(List<AllahNameModel> names) {
    if (names.isEmpty) return null;
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    final index = (dayOfYear % names.length);
    return names[index];
  }

  /// Toggle favorite status of a name
  Future<bool> toggleFavorite(int nameId) async {
    final willBeFavorite = !_favoriteIds.contains(nameId);

    if (willBeFavorite) {
      _favoriteIds.add(nameId);
    } else {
      _favoriteIds.remove(nameId);
    }

    // Update in-memory cached list if present
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

  bool isFavorite(int nameId) => _favoriteIds.contains(nameId);

  // --- Local Persistence for Favorites ---

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
