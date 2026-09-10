import 'dart:convert';
import 'dart:io';
import 'package:alhuda/model/hadith_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// خدمة الأحاديث النبوية الشريفة المركزية
class HadithService extends ChangeNotifier {
  HadithService._();
  static final HadithService instance = HadithService._();

  List<HadithBook>? _cachedBooks;
  final Map<String, List<HadithChapter>> _cachedChapters = {};
  final Map<String, List<HadithItem>> _cachedChapterHadiths = {};
  List<List<dynamic>>? _cachedSearchIndex;

  final List<HadithBookmark> _bookmarks = [];
  File? _bookmarksFile;
  bool _isBookmarksLoaded = false;

  double _fontSize = 20.0;
  double get fontSize => _fontSize;

  void increaseFontSize() {
    if (_fontSize < 32.0) {
      _fontSize += 2.0;
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_fontSize > 14.0) {
      _fontSize -= 2.0;
      notifyListeners();
    }
  }

  void resetFontSize() {
    _fontSize = 20.0;
    notifyListeners();
  }

  /// تحميل جميع كتب الحديث المتاحة
  Future<List<HadithBook>> getAllBooks() async {
    if (_cachedBooks != null && _cachedBooks!.isNotEmpty) {
      return _cachedBooks!;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/hadith/books.json');
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedBooks = list
          .map((item) => HadithBook.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedBooks!;
    } catch (e) {
      debugPrint('Error loading hadith books: $e');
      return [];
    }
  }

  /// الحصول على كتاب بواسطة معرفه
  Future<HadithBook?> getBookById(String bookId) async {
    final books = await getAllBooks();
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  /// تحميل جميع أبواب وفصول كتاب محدد
  Future<List<HadithChapter>> getChapters(String bookId) async {
    if (_cachedChapters.containsKey(bookId)) {
      return _cachedChapters[bookId]!;
    }
    try {
      final jsonStr =
          await rootBundle.loadString('assets/hadith/$bookId/chapters.json');
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      final chapters = list
          .map((item) => HadithChapter.fromJson(item as Map<String, dynamic>))
          .toList();
      _cachedChapters[bookId] = chapters;
      return chapters;
    } catch (e) {
      debugPrint('Error loading chapters for $bookId: $e');
      return [];
    }
  }

  /// تحميل أحاديث باب معين داخل كتاب
  Future<List<HadithItem>> getChapterHadiths(
      String bookId, int chapterId) async {
    final cacheKey = '${bookId}_$chapterId';
    if (_cachedChapterHadiths.containsKey(cacheKey)) {
      return _cachedChapterHadiths[cacheKey]!;
    }
    try {
      final jsonStr = await rootBundle
          .loadString('assets/hadith/$bookId/chapters/$chapterId.json');
      final Map<String, dynamic> data =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> list = data['hadiths'] as List<dynamic>? ?? [];
      final hadiths = list
          .map((item) => HadithItem.fromJson(item as Map<String, dynamic>))
          .toList();
      _cachedChapterHadiths[cacheKey] = hadiths;
      return hadiths;
    } catch (e) {
      debugPrint('Error loading hadiths for $bookId chapter $chapterId: $e');
      return [];
    }
  }

  /// تطبيع النصوص العربية للبحث الدقيق المتجاهل للتشكيل والحروف المتشابهة
  static String normalizeArabic(String input) {
    if (input.isEmpty) return '';

    var result = input;
    // إزالة التشكيل
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // إزالة التطويل
    result = result.replaceAll('\u0640', '');
    // توحيد الهمزات والألف
    result = result.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    // توحيد الياء والألف المقصورة
    result = result.replaceAll(RegExp(r'[يى]'), 'ي');
    // توحيد التاء المربوطة والهاء
    result = result.replaceAll('ة', 'ه');
    // إزالة المسافات الزائدة
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  /// تحميل فهرس البحث السريع
  Future<List<List<dynamic>>> _loadSearchIndex() async {
    if (_cachedSearchIndex != null) return _cachedSearchIndex!;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/hadith/search_index.json');
      final List<dynamic> raw = jsonDecode(jsonStr) as List<dynamic>;
      _cachedSearchIndex = raw.cast<List<dynamic>>();
      return _cachedSearchIndex!;
    } catch (e) {
      debugPrint('Error loading search index: $e');
      return [];
    }
  }

  /// البحث في الأحاديث مع دعم الفلترة حسب الكتاب
  Future<List<HadithSearchResult>> searchHadiths(
    String query, {
    String? filterBookId,
    int limit = 50,
  }) async {
    final cleanQuery = normalizeArabic(query);
    if (cleanQuery.isEmpty || cleanQuery.length < 2) return [];

    final index = await _loadSearchIndex();
    final books = await getAllBooks();
    final bookMap = {for (var b in books) b.id: b.title};

    // خريطة لعناوين الأبواب
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

  /// إرجاع حديث نبوي مختار لـ "حديث اليوم" بصورة متجددة يومياً
  Future<({HadithBook book, HadithChapter chapter, HadithItem hadith})?>
      getHadithOfTheDay() async {
    try {
      final books = await getAllBooks();
      if (books.isEmpty) return null;

      // اختيار بناءً على رقم اليوم في السنة ليكون ثابتاً طوال اليوم
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

      // تدوير بين الأربعين النووية وأول 10 أبواب من البخاري ومسلم
      final book = books[dayOfYear % books.length];
      final chapters = await getChapters(book.id);
      if (chapters.isEmpty) return null;

      final chapterIndex = dayOfYear % chapters.length;
      final chapter = chapters[chapterIndex];

      final hadiths = await getChapterHadiths(book.id, chapter.id);
      if (hadiths.isEmpty) return null;

      final hadith = hadiths[dayOfYear % hadiths.length];
      return (book: book, chapter: chapter, hadith: hadith);
    } catch (e) {
      debugPrint('Error getting Hadith of the day: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // إدارة المفضلة (Bookmarks)
  // ════════════════════════════════════════════════════════════════════════

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

  Future<List<HadithBookmark>> getBookmarks() async {
    await _initBookmarksFile();
    return List.unmodifiable(_bookmarks);
  }

  bool isBookmarked(String bookId, int chapterId, int hadithNumber) {
    final key = '${bookId}_${chapterId}_$hadithNumber';
    return _bookmarks.any((b) => b.uniqueKey == key);
  }

  Future<void> toggleBookmark(HadithBookmark bookmark) async {
    await _initBookmarksFile();
    final index =
        _bookmarks.indexWhere((b) => b.uniqueKey == bookmark.uniqueKey);
    if (index >= 0) {
      _bookmarks.removeAt(index);
    } else {
      _bookmarks.insert(0, bookmark);
    }
    await _saveBookmarks();
    notifyListeners();
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
