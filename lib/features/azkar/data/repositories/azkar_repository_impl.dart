import 'package:alhuda/features/azkar/data/datasources/azkar_data_source.dart';
import 'package:alhuda/features/azkar/domain/entities/azkar_quick_item.dart';
import 'package:alhuda/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  final AzkarDataSource _dataSource;

  List<AzkarCategory>? _cachedCategories;
  List<AzkarChapter>? _cachedAllChapters;

  AzkarRepositoryImpl({AzkarDataSource? dataSource})
      : _dataSource = dataSource ?? AzkarLocalDataSource();

  static const List<AzkarQuickItem> _quickAzkarList = [
    AzkarQuickItem(
      chapterId: 27,
      title: 'أذكار الصباح',
      subtitle: 'حفظ وبركة ليومك',
      timeLabel: 'بعد الفجر حتى الضحى',
    ),
    AzkarQuickItem(
      chapterId: 28,
      title: 'أذكار المساء',
      subtitle: 'سكينة وحصن لليلتك',
      timeLabel: 'بعد العصر حتى الغروب',
    ),
    AzkarQuickItem(
      chapterId: 29,
      title: 'أذكار النوم',
      subtitle: 'طمأنينة وراحة للبال',
      timeLabel: 'قبل النوم',
    ),
    AzkarQuickItem(
      chapterId: 1,
      title: 'أذكار الاستيقاظ',
      subtitle: 'حمد لله على نعمة الحياة',
      timeLabel: 'عند الاستيقاظ',
    ),
    AzkarQuickItem(
      chapterId: 25,
      title: 'أذكار بعد الصلاة',
      subtitle: 'تثبيت الأجر بعد الفريضة',
      timeLabel: 'عقب الصلوات المكتوبة',
    ),
  ];

  @override
  Future<List<AzkarCategory>> getCategories() async {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    final categories = await _dataSource.getAzkarCategories();
    _cachedCategories = categories;
    return categories;
  }

  @override
  Future<List<AzkarChapter>> getChapters({int categoryId = -1}) async {
    return await _dataSource.getAzkarChapters(categoryId: categoryId);
  }

  @override
  Future<List<AzkarChapter>> getAllChapters() async {
    if (_cachedAllChapters != null && _cachedAllChapters!.isNotEmpty) {
      return _cachedAllChapters!;
    }
    final chapters = await _dataSource.getAzkarChapters();
    _cachedAllChapters = chapters;
    return chapters;
  }

  @override
  Future<List<AzkarItem>> getAzkarItems(int chapterId) async {
    return await _dataSource.getAzkarItems(chapterId);
  }

  @override
  List<AzkarQuickItem> getQuickAzkarList() => _quickAzkarList;

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
  List<AzkarChapter> filterChapters(List<AzkarChapter> chapters, String query) {
    if (query.trim().isEmpty) return chapters;
    final normalizedQuery = normalizeArabic(query);
    return chapters.where((ch) {
      final normalizedName = normalizeArabic(ch.name);
      return normalizedName.contains(normalizedQuery);
    }).toList();
  }

  @override
  int parseRepeatCount(String rawCount) {
    if (rawCount.contains('مائة مرة') ||
        rawCount.contains('مئة مرة') ||
        rawCount.contains('100 مرة') ||
        rawCount.contains('١٠٠ مرة')) {
      return 100;
    }
    if (rawCount.contains('ثلاث وثلاثين') ||
        rawCount.contains('33 مرة') ||
        rawCount.contains('٣٣ مرة')) {
      return 33;
    }
    if (rawCount.contains('عشر مرات') ||
        rawCount.contains('10 مرات') ||
        rawCount.contains('١٠ مرات')) {
      return 10;
    }
    if (rawCount.contains('سبع مرات') ||
        rawCount.contains('7 مرات') ||
        rawCount.contains('٧ مرات')) {
      return 7;
    }
    if (rawCount.contains('أربع مرات') ||
        rawCount.contains('اربع مرات') ||
        rawCount.contains('4 مرات') ||
        rawCount.contains('٤ مرات')) {
      return 4;
    }
    if (rawCount.contains('ثلاث مرات') ||
        rawCount.contains('3 مرات') ||
        rawCount.contains('٣ مرات')) {
      return 3;
    }
    if (rawCount.contains('مرتان') || rawCount.contains('مرتين')) {
      return 2;
    }
    return 1;
  }
}
