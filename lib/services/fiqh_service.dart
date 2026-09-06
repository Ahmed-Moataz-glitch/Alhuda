import 'dart:convert';
import 'dart:io';
import 'package:alhuda/model/fiqh_model.dart';
import 'package:alhuda/services/fiqh_data.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// نتيجة بحث في الفقه الإسلامي
class FiqhSearchResult {
  final FiqhBook book;
  final FiqhChapter chapter;
  final FiqhIssue issue;
  final String matchedSnippet;

  const FiqhSearchResult({
    required this.book,
    required this.chapter,
    required this.issue,
    required this.matchedSnippet,
  });
}

/// خدمة الفقه الإسلامي المركزية (إدارة البيانات، البحث، والمفضلات)
class FiqhService {
  FiqhService._();
  static final FiqhService instance = FiqhService._();

  List<FiqhBook>? _cachedBooks;
  final List<FiqhBookmark> _bookmarks = [];
  File? _bookmarksFile;
  bool _isBookmarksLoaded = false;

  /// الحصول على جميع كتب الفقه الـ 12
  List<FiqhBook> getAllBooks() {
    _cachedBooks ??= FiqhData.getBooks();
    return _cachedBooks!;
  }

  /// فلترة الكتب حسب التصنيف
  List<FiqhBook> getBooksByCategory(FiqhCategory category) {
    return getAllBooks().where((b) => b.category == category).toList();
  }

  /// البحث عن كتاب بواسطة معرفه
  FiqhBook? getBookById(String bookId) {
    try {
      return getAllBooks().firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  /// البحث عن باب بواسطة معرفه ومعرف الكتاب
  FiqhChapter? getChapterById(String bookId, String chapterId) {
    final book = getBookById(bookId);
    if (book == null) return null;
    try {
      return book.chapters.firstWhere((c) => c.id == chapterId);
    } catch (_) {
      return null;
    }
  }

  /// البحث عن مسألة بواسطة معرفها
  ({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})? getIssueById(
      String issueId) {
    for (final book in getAllBooks()) {
      for (final chapter in book.chapters) {
        for (final issue in chapter.issues) {
          if (issue.id == issueId) {
            return (book: book, chapter: chapter, issue: issue);
          }
        }
      }
    }
    return null;
  }

  /// إجمالي عدد الأبواب الفقهية في التطبيق
  int get totalChaptersCount {
    return getAllBooks().fold(0, (sum, book) => sum + book.chaptersCount);
  }

  /// إجمالي عدد المسائل الفقهية في التطبيق
  int get totalIssuesCount {
    return getAllBooks().fold(0, (sum, book) => sum + book.totalIssuesCount);
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
    result = result.replaceAll('ى', 'ي');
    // توحيد التاء المربوطة والهاء
    result = result.replaceAll('ة', 'ه');
    // إزالة علامات الترقيم والرموز
    result = result.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

    return result;
  }

  /// محرك بحث سريع في جميع الكتب والأبواب والمسائل والأدلة
  List<FiqhSearchResult> search(String rawQuery) {
    final query = normalizeArabic(rawQuery);
    if (query.isEmpty) return [];

    final results = <FiqhSearchResult>[];

    for (final book in getAllBooks()) {
      for (final chapter in book.chapters) {
        for (final issue in chapter.issues) {
          final normTitle = normalizeArabic(issue.title);
          final normContent = normalizeArabic(issue.content);
          final normChapter = normalizeArabic(chapter.title);
          final normBook = normalizeArabic(book.title);

          String? matchedSnippet;

          if (normTitle.contains(query)) {
            matchedSnippet = issue.title;
          } else if (normContent.contains(query)) {
            matchedSnippet = _extractSnippet(issue.content, rawQuery);
          } else if (normChapter.contains(query)) {
            matchedSnippet = '${chapter.title} - ${issue.title}';
          } else if (normBook.contains(query)) {
            matchedSnippet = '${book.title} - ${chapter.title}';
          } else {
            // البحث في الأدلة والشروط
            for (final ev in issue.evidences) {
              if (normalizeArabic(ev.text).contains(query)) {
                matchedSnippet = ev.text;
                break;
              }
            }
            if (matchedSnippet == null) {
              for (final cond in issue.conditions) {
                if (normalizeArabic(cond).contains(query)) {
                  matchedSnippet = cond;
                  break;
                }
              }
            }
            if (matchedSnippet == null) {
              for (final note in issue.notes) {
                if (normalizeArabic(note).contains(query)) {
                  matchedSnippet = note;
                  break;
                }
              }
            }
          }

          if (matchedSnippet != null) {
            results.add(FiqhSearchResult(
              book: book,
              chapter: chapter,
              issue: issue,
              matchedSnippet: matchedSnippet,
            ));
          }
        }
      }
    }

    return results;
  }

  static String _extractSnippet(String text, String rawQuery) {
    final normText = normalizeArabic(text);
    final normQuery = normalizeArabic(rawQuery);
    final idx = normText.indexOf(normQuery);
    if (idx == -1) return text.length > 80 ? '${text.substring(0, 80)}...' : text;

    final start = (idx - 30).clamp(0, text.length);
    final end = (idx + normQuery.length + 50).clamp(0, text.length);
    var snippet = text.substring(start, end).replaceAll('\n', ' ').trim();
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';
    return snippet;
  }

  /// أهم المسائل الفقهية الشائعة واليومية (الوصول السريع)
  List<({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})>
      getFeaturedIssues() {
    const featuredIds = [
      'issue_wudu_faraid_detail',
      'issue_wudu_nawaqid_list',
      'issue_sujood_sahw_rules',
      'issue_patient_traveler_salah',
      'issue_zakat_fitr_all',
      'issue_mufattirat_all_details',
      'issue_umrah_steps_all',
      'issue_riba_and_sarf_detail',
      'issue_faraid_principles',
      'issue_oaths_classification',
      'issue_parents_and_neighbors',
      'issue_jihad_fadl_shuroot',
    ];

    final list = <({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})>[];
    for (final id in featuredIds) {
      final res = getIssueById(id);
      if (res != null) list.add(res);
    }
    return list;
  }

  // ════════════════════════════════════════════════════════════════════════
  // إدارة المفضلة والإشارات المرجعية (Bookmarks)
  // ════════════════════════════════════════════════════════════════════════

  Future<void> ensureBookmarksLoaded() async {
    if (_isBookmarksLoaded) return;
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      _bookmarksFile = File('${appDoc.path}/alhuda_fiqh_bookmarks.json');
      if (await _bookmarksFile!.exists()) {
        final jsonStr = await _bookmarksFile!.readAsString();
        final List<dynamic> list = jsonDecode(jsonStr);
        _bookmarks.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _bookmarks.add(FiqhBookmark.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('FiqhService ensureBookmarksLoaded error: $e');
    } finally {
      _isBookmarksLoaded = true;
    }
  }

  List<FiqhBookmark> getBookmarks() => List.unmodifiable(_bookmarks);

  bool isBookmarked(String issueId) {
    return _bookmarks.any((b) => b.issueId == issueId);
  }

  Future<void> toggleBookmark({
    required FiqhBook book,
    required FiqhChapter chapter,
    required FiqhIssue issue,
  }) async {
    await ensureBookmarksLoaded();
    final index = _bookmarks.indexWhere((b) => b.issueId == issue.id);
    if (index >= 0) {
      _bookmarks.removeAt(index);
    } else {
      _bookmarks.insert(
        0,
        FiqhBookmark(
          issueId: issue.id,
          chapterId: chapter.id,
          bookId: book.id,
          issueTitle: issue.title,
          chapterTitle: chapter.title,
          bookTitle: book.title,
          snippet: issue.content.length > 90
              ? '${issue.content.substring(0, 90)}...'
              : issue.content,
          savedAt: DateTime.now(),
        ),
      );
    }
    await _saveBookmarksToDisk();
  }

  Future<void> removeBookmark(String issueId) async {
    await ensureBookmarksLoaded();
    _bookmarks.removeWhere((b) => b.issueId == issueId);
    await _saveBookmarksToDisk();
  }

  Future<void> _saveBookmarksToDisk() async {
    if (_bookmarksFile == null) return;
    try {
      final list = _bookmarks.map((b) => b.toJson()).toList();
      await _bookmarksFile!.writeAsString(jsonEncode(list), flush: true);
    } catch (e) {
      debugPrint('FiqhService _saveBookmarksToDisk error: $e');
    }
  }
}
