import 'dart:convert';
import 'dart:io';
import 'package:alhuda/features/hadith/data/datasources/hadith_local_data_source.dart';
import 'package:alhuda/features/hadith/domain/entities/hadith_entities.dart';
import 'package:alhuda/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class HadithRepositoryImpl implements HadithRepository {
  final HadithDataSource _dataSource;

  List<HadithBook>? _cachedBooks;
  final Map<String, List<HadithChapter>> _cachedChapters = {};
  final Map<String, List<HadithItem>> _cachedChapterHadiths = {};
  List<List<dynamic>>? _cachedSearchIndex;

  final List<HadithBookmark> _bookmarks = [];
  File? _bookmarksFile;
  bool _isBookmarksLoaded = false;

  HadithRepositoryImpl({HadithDataSource? dataSource})
      : _dataSource = dataSource ?? HadithLocalDataSource();

  @override
  Future<List<HadithBook>> getAllBooks() async {
    if (_cachedBooks != null && _cachedBooks!.isNotEmpty) {
      return _cachedBooks!;
    }
    try {
      final books = await _dataSource.getAllBooks();
      _cachedBooks = books;
      return books;
    } catch (e) {
      debugPrint('Error loading hadith books: $e');
      return [];
    }
  }

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async {
    if (_cachedChapters.containsKey(bookId)) {
      return _cachedChapters[bookId]!;
    }
    try {
      final chapters = await _dataSource.getChapters(bookId);
      _cachedChapters[bookId] = chapters;
      return chapters;
    } catch (e) {
      debugPrint('Error loading chapters for $bookId: $e');
      return [];
    }
  }

  @override
  Future<List<HadithItem>> getChapterHadiths(
      String bookId, int chapterId) async {
    final cacheKey = '${bookId}_$chapterId';
    if (_cachedChapterHadiths.containsKey(cacheKey)) {
      return _cachedChapterHadiths[cacheKey]!;
    }
    try {
      final hadiths = await _dataSource.getChapterHadiths(bookId, chapterId);
      _cachedChapterHadiths[cacheKey] = hadiths;
      return hadiths;
    } catch (e) {
      debugPrint('Error loading hadiths for $bookId chapter $chapterId: $e');
      return [];
    }
  }

  @override
  Future<List<HadithItem>> getFortyNawawiHadiths() async {
    return await getChapterHadiths('nawawi40', 1);
  }

  @override
  String normalizeArabic(String input) {
    if (input.isEmpty) return '';

    var result = input;
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    result = result.replaceAll('\u0640', '');
    result = result.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    result = result.replaceAll(RegExp(r'[يى]'), 'ي');
    result = result.replaceAll('ة', 'ه');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  @override
  Future<List<HadithSearchResult>> searchHadiths(
    String query, {
    String? filterBookId,
    int limit = 50,
  }) async {
    final cleanQuery = normalizeArabic(query);
    if (cleanQuery.isEmpty || cleanQuery.length < 2) return [];

    _cachedSearchIndex ??= await _dataSource.getSearchIndex();
    final index = _cachedSearchIndex!;
    final books = await getAllBooks();
    final bookMap = {for (var b in books) b.id: b.title};

    final Map<String, Map<int, String>> chapterTitles = {};
    final List<HadithSearchResult> results = [];

    for (final entry in index) {
      final String bId = entry[0] as String;
      if (filterBookId != null &&
          filterBookId.isNotEmpty &&
          bId != filterBookId) {
        continue;
      }

      final int cId = entry[1] as int;
      final int hNum = entry[2] as int;
      final String text = entry[3] as String;

      if (text.contains(cleanQuery)) {
        if (!chapterTitles.containsKey(bId)) {
          final chs = await getChapters(bId);
          chapterTitles[bId] = {for (var c in chs) c.id: c.title};
        }

        final bTitle = bookMap[bId] ?? bId;
        final cTitle = chapterTitles[bId]?[cId] ?? 'باب $cId';

        results.add(
          HadithSearchResult(
            bookId: bId,
            bookTitle: bTitle,
            chapterId: cId,
            chapterTitle: cTitle,
            hadithNumber: hNum,
            matchedSnippet: text,
          ),
        );

        if (results.length >= limit) break;
      }
    }

    return results;
  }

  @override
  bool isBookmarked(String bookId, int chapterId, int hadithNumber) {
    final key = '${bookId}_${chapterId}_$hadithNumber';
    return _bookmarks.any((b) => b.uniqueKey == key);
  }

  @override
  Future<List<HadithBookmark>> getBookmarks() async {
    await _initBookmarksFile();
    return List.unmodifiable(_bookmarks);
  }

  @override
  Future<bool> toggleBookmark({
    required String bookId,
    required String bookTitle,
    required int chapterId,
    required String chapterTitle,
    required int hadithNumber,
    required String snippet,
  }) async {
    await _initBookmarksFile();
    final bookmark = HadithBookmark(
      bookId: bookId,
      bookTitle: bookTitle,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      hadithNumber: hadithNumber,
      snippet: snippet,
      addedDate: DateTime.now().toIso8601String(),
    );

    final index =
        _bookmarks.indexWhere((b) => b.uniqueKey == bookmark.uniqueKey);
    if (index >= 0) {
      _bookmarks.removeAt(index);
      await _saveBookmarks();
      return false;
    } else {
      _bookmarks.insert(0, bookmark);
      await _saveBookmarks();
      return true;
    }
  }

  Future<void> _initBookmarksFile() async {
    if (_isBookmarksLoaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _bookmarksFile = File('${dir.path}/alhuda_hadith_bookmarks.json');

      if (await _bookmarksFile!.exists()) {
        final content = await _bookmarksFile!.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
          _bookmarks.clear();
          _bookmarks.addAll(
            jsonList.map(
                (e) => HadithBookmark.fromJson(e as Map<String, dynamic>)),
          );
        }
      }
      _isBookmarksLoaded = true;
    } catch (e) {
      debugPrint('Error initializing Hadith bookmarks file: $e');
      _isBookmarksLoaded = true;
    }
  }

  Future<void> _saveBookmarks() async {
    if (_bookmarksFile == null) return;
    try {
      final jsonList = _bookmarks.map((e) => e.toJson()).toList();
      await _bookmarksFile!.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving Hadith bookmarks: $e');
    }
  }
}
