import 'dart:convert';
import 'dart:io';
import 'package:alhuda/features/fiqh/data/datasources/fiqh_data_source.dart';
import 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';
import 'package:alhuda/features/fiqh/domain/repositories/fiqh_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FiqhRepositoryImpl implements FiqhRepository {
  final FiqhDataSource _dataSource;

  List<FiqhBook>? _cachedBooks;
  final List<FiqhBookmark> _bookmarks = [];
  File? _bookmarksFile;
  bool _isBookmarksLoaded = false;

  FiqhRepositoryImpl({FiqhDataSource? dataSource})
      : _dataSource = dataSource ?? FiqhLocalDataSource();

  @override
  List<FiqhBook> getAllBooks() {
    _cachedBooks ??= _dataSource.getBooks();
    return _cachedBooks!;
  }

  @override
  List<FiqhBook> getBooksByCategory(FiqhCategory category) {
    return getAllBooks().where((b) => b.category == category).toList();
  }

  @override
  FiqhBook? getBookById(String bookId) {
    try {
      return getAllBooks().firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  @override
  FiqhChapter? getChapterById(String bookId, String chapterId) {
    final book = getBookById(bookId);
    if (book == null) return null;
    try {
      return book.chapters.firstWhere((c) => c.id == chapterId);
    } catch (_) {
      return null;
    }
  }

  @override
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

  @override
  String normalizeArabic(String input) {
    if (input.isEmpty) return '';

    var result = input;
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    result = result.replaceAll('\u0640', '');
    result = result.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    result = result.replaceAll('ى', 'ي');
    result = result.replaceAll('ة', 'ه');
    result = result.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

    return result;
  }

  @override
  List<FiqhSearchResult> searchIssues(String rawQuery) {
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
    var query = rawQuery.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
    final normText = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
    final idx = normText.indexOf(query);
    if (idx == -1) return text.length > 80 ? '${text.substring(0, 80)}...' : text;

    final start = (idx - 30).clamp(0, text.length);
    final end = (idx + query.length + 50).clamp(0, text.length);
    var snippet = text.substring(start, end).replaceAll('\n', ' ').trim();
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';
    return snippet;
  }

  @override
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
      final item = getIssueById(id);
      if (item != null) list.add(item);
    }
    return list;
  }

  @override
  bool isBookmarked(String issueId) {
    return _bookmarks.any((b) => b.issueId == issueId);
  }

  @override
  Future<void> ensureBookmarksLoaded() => _ensureBookmarksLoaded();

  @override
  List<FiqhBookmark> getBookmarks() {
    return List.unmodifiable(_bookmarks);
  }

  @override
  Future<void> removeBookmark(String issueId) async {
    await _ensureBookmarksLoaded();
    _bookmarks.removeWhere((b) => b.issueId == issueId);
    await _saveBookmarks();
  }

  @override
  Future<bool> toggleBookmark({
    required FiqhBook book,
    required FiqhChapter chapter,
    required FiqhIssue issue,
  }) async {
    await _ensureBookmarksLoaded();

    final existingIndex =
        _bookmarks.indexWhere((b) => b.issueId == issue.id);

    if (existingIndex >= 0) {
      _bookmarks.removeAt(existingIndex);
      await _saveBookmarks();
      return false;
    } else {
      final snippet = issue.content.length > 80
          ? '${issue.content.substring(0, 80)}...'
          : issue.content;

      _bookmarks.insert(
        0,
        FiqhBookmark(
          issueId: issue.id,
          chapterId: chapter.id,
          bookId: book.id,
          issueTitle: issue.title,
          chapterTitle: chapter.title,
          bookTitle: book.title,
          snippet: snippet,
          savedAt: DateTime.now(),
        ),
      );
      await _saveBookmarks();
      return true;
    }
  }

  Future<void> _ensureBookmarksLoaded() async {
    if (_isBookmarksLoaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _bookmarksFile = File('${dir.path}/alhuda_fiqh_bookmarks.json');

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
      debugPrint('Error loading fiqh bookmarks: $e');
    } finally {
      _isBookmarksLoaded = true;
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      if (_bookmarksFile == null) {
        final dir = await getApplicationDocumentsDirectory();
        _bookmarksFile = File('${dir.path}/alhuda_fiqh_bookmarks.json');
      }
      final jsonStr =
          jsonEncode(_bookmarks.map((b) => b.toJson()).toList());
      await _bookmarksFile!.writeAsString(jsonStr, flush: true);
    } catch (e) {
      debugPrint('Error saving fiqh bookmarks: $e');
    }
  }
}
