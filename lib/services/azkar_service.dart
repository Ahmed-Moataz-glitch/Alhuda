import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class AzkarQuickItem {
  final int chapterId;
  final String title;
  final String subtitle;
  final String timeLabel;

  const AzkarQuickItem({
    required this.chapterId,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
  });
}

class AzkarService {
  AzkarService._internal();
  static final AzkarService instance = AzkarService._internal();

  final MuslimRepository _repo = MuslimRepository();

  List<AzkarCategory>? _cachedCategories;
  List<AzkarChapter>? _cachedAllChapters;

  /// Fetch all categories in Arabic
  Future<List<AzkarCategory>> getCategories() async {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    final categories = await _repo.getAzkarCategories(language: Language.ar);
    _cachedCategories = categories;
    return categories;
  }

  /// Fetch all chapters or by categoryId
  Future<List<AzkarChapter>> getChapters({int categoryId = -1}) async {
    return await _repo.getAzkarChapters(
      language: Language.ar,
      categoryId: categoryId,
    );
  }

  /// Fetch and cache all chapters across all categories
  Future<List<AzkarChapter>> getAllChapters() async {
    if (_cachedAllChapters != null && _cachedAllChapters!.isNotEmpty) {
      return _cachedAllChapters!;
    }
    final chapters = await _repo.getAzkarChapters(language: Language.ar);
    _cachedAllChapters = chapters;
    return chapters;
  }

  /// Fetch azkar items for a chapter
  Future<List<AzkarItem>> getAzkarItems(int chapterId) async {
    return await _repo.getAzkarItems(
      language: Language.ar,
      chapterId: chapterId,
    );
  }

  /// Essential quick access chapters
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

  /// Normalize Arabic text for diacritic-insensitive & variant-insensitive search
  static String normalizeArabic(String input) {
    if (input.isEmpty) return '';

    var result = input;

    // Remove Tashkeel (diacritics)
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Remove Tatweel (kashida)
    result = result.replaceAll('\u0640', '');

    // Normalize Alefs
    result = result.replaceAll(RegExp(r'[إأآٱ]'), 'ا');

    // Normalize Yaa
    result = result.replaceAll('ى', 'ي');

    // Normalize Taa Marbuta
    result = result.replaceAll('ة', 'ه');

    // Remove extra spaces and punctuation
    result = result.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

    return result;
  }

  /// Search chapters by query
  List<AzkarChapter> filterChapters(List<AzkarChapter> chapters, String query) {
    if (query.trim().isEmpty) return chapters;

    final normalizedQuery = normalizeArabic(query);
    return chapters.where((ch) {
      final normalizedName = normalizeArabic(ch.name);
      return normalizedName.contains(normalizedQuery);
    }).toList();
  }

  /// Parse recommended repetition count from AzkarItem text or reference
  static int parseRepeatCount(AzkarItem item) {
    final combined = '${item.item} ${item.reference}';

    if (combined.contains('مائة مرة') ||
        combined.contains('مئة مرة') ||
        combined.contains('100 مرة') ||
        combined.contains('١٠٠ مرة')) {
      return 100;
    }
    if (combined.contains('ثلاث وثلاثين') ||
        combined.contains('33 مرة') ||
        combined.contains('٣٣ مرة')) {
      return 33;
    }
    if (combined.contains('عشر مرات') ||
        combined.contains('10 مرات') ||
        combined.contains('١٠ مرات')) {
      return 10;
    }
    if (combined.contains('سبع مرات') ||
        combined.contains('7 مرات') ||
        combined.contains('٧ مرات')) {
      return 7;
    }
    if (combined.contains('أربع مرات') ||
        combined.contains('اربع مرات') ||
        combined.contains('4 مرات') ||
        combined.contains('٤ مرات')) {
      return 4;
    }
    if (combined.contains('ثلاث مرات') ||
        combined.contains('3 مرات') ||
        combined.contains('٣ مرات')) {
      return 3;
    }
    if (combined.contains('مرتان') || combined.contains('مرتين')) {
      return 2;
    }

    // Default repetition is 1
    return 1;
  }

  /// Clean display text by normalizing whitespace and line endings
  static String cleanText(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }
}
