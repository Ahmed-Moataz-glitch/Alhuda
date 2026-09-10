import 'package:alhuda/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:alhuda/features/azkar/domain/entities/azkar_quick_item.dart';
import 'package:alhuda/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

export 'package:alhuda/features/azkar/domain/entities/azkar_quick_item.dart';
export 'package:alhuda/features/azkar/domain/repositories/azkar_repository.dart';
export 'package:alhuda/features/azkar/data/repositories/azkar_repository_impl.dart';
export 'package:alhuda/features/azkar/presentation/view_models/azkar_view_model.dart';

class AzkarService {
  AzkarService._internal();
  static final AzkarService instance = AzkarService._internal();

  final AzkarRepository _repository = AzkarRepositoryImpl();

  static const List<AzkarQuickItem> quickAzkarList = [
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

  Future<List<AzkarCategory>> getCategories() => _repository.getCategories();

  Future<List<AzkarChapter>> getChapters({int categoryId = -1}) =>
      _repository.getChapters(categoryId: categoryId);

  Future<List<AzkarChapter>> getAllChapters() => _repository.getAllChapters();

  Future<List<AzkarItem>> getAzkarItems(int chapterId) =>
      _repository.getAzkarItems(chapterId);

  static String normalizeArabic(String input) {
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

  List<AzkarChapter> filterChapters(List<AzkarChapter> chapters, String query) =>
      _repository.filterChapters(chapters, query);

  static int parseRepeatCount(AzkarItem item) {
    final combined = '${item.item} ${item.reference}';
    return AzkarRepositoryImpl().parseRepeatCount(combined);
  }

  static String cleanText(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }
}
