import 'package:alhuda/features/azkar/domain/entities/azkar_quick_item.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

abstract class AzkarRepository {
  Future<List<AzkarCategory>> getCategories();
  Future<List<AzkarChapter>> getChapters({int categoryId = -1});
  Future<List<AzkarChapter>> getAllChapters();
  Future<List<AzkarItem>> getAzkarItems(int chapterId);
  List<AzkarQuickItem> getQuickAzkarList();
  String normalizeArabic(String input);
  List<AzkarChapter> filterChapters(List<AzkarChapter> list, String query);
  int parseRepeatCount(String rawCount);
}
