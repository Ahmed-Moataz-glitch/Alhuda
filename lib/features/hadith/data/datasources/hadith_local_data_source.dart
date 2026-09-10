import 'dart:convert';
import 'package:alhuda/features/hadith/domain/entities/hadith_entities.dart';
import 'package:flutter/services.dart';

abstract class HadithDataSource {
  Future<List<HadithBook>> getAllBooks();
  Future<List<HadithChapter>> getChapters(String bookId);
  Future<List<HadithItem>> getChapterHadiths(String bookId, int chapterId);
  Future<List<List<dynamic>>> getSearchIndex();
}

class HadithLocalDataSource implements HadithDataSource {
  @override
  Future<List<HadithBook>> getAllBooks() async {
    final jsonStr = await rootBundle.loadString('assets/hadith/books.json');
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((item) => HadithBook.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async {
    final jsonStr =
        await rootBundle.loadString('assets/hadith/$bookId/chapters.json');
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((item) => HadithChapter.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<HadithItem>> getChapterHadiths(String bookId, int chapterId) async {
    final jsonStr = await rootBundle
        .loadString('assets/hadith/$bookId/chapters/$chapterId.json');
    final Map<String, dynamic> data =
        jsonDecode(jsonStr) as Map<String, dynamic>;
    final List<dynamic> list = data['hadiths'] as List<dynamic>? ?? [];
    return list
        .map((item) => HadithItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<List<dynamic>>> getSearchIndex() async {
    final jsonStr =
        await rootBundle.loadString('assets/hadith/search_index.json');
    final List<dynamic> raw = jsonDecode(jsonStr) as List<dynamic>;
    return raw.cast<List<dynamic>>();
  }
}
