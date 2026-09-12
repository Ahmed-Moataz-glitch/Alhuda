import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/services/azkar_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class AzkarChapterPage extends StatefulWidget {
  final int chapterId;
  final String chapterTitle;

  const AzkarChapterPage({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<AzkarChapterPage> createState() => _AzkarChapterPageState();
}

class _AzkarChapterPageState extends State<AzkarChapterPage> {
  bool _isLoading = true;
  List<AzkarItem> _items = [];
  final Map<int, int> _originalCounts = {};
  final Map<int, int> _remainingCounts = {};
  double _fontSize = 18.sp;

  @override
  void initState() {
    super.initState();
    _loadAzkar();
  }

  Future<void> _loadAzkar() async {
    setState(() => _isLoading = true);
    try {
      final items = await AzkarService.instance.getAzkarItems(widget.chapterId);
      for (final item in items) {
        final count = AzkarService.parseRepeatCount(item);
        _originalCounts[item.id] = count;
        _remainingCounts[item.id] = count;
      }
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _decrementCount(int itemId) {
    final current = _remainingCounts[itemId] ?? 1;
    if (current > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _remainingCounts[itemId] = current - 1;
      });

      if (_remainingCounts[itemId] == 0) {
        HapticFeedback.mediumImpact();
        if (_isAllCompleted && _items.isNotEmpty) {
          _showCompletionSnackBar();
        }
      }
    }
  }

  void _resetSingleCount(int itemId) {
    HapticFeedback.selectionClick();
    setState(() {
      _remainingCounts[itemId] = _originalCounts[itemId] ?? 1;
    });
  }

  void _resetAllCounts() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final item in _items) {
        _remainingCounts[item.id] = _originalCounts[item.id] ?? 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'تمت إعادة ضبط جميع العدادات',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Almarai'),
          ),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  bool get _isAllCompleted {
    if (_items.isEmpty) return false;
    return _items.every((item) => (_remainingCounts[item.id] ?? 1) == 0);
  }

  int get _completedItemsCount {
    return _items
        .where((item) => (_remainingCounts[item.id] ?? 1) == 0)
        .length;
  }

  void _showCompletionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8.w),
              const Text(
                'هنيئاً لك! أتممت قراءة الأذكار، تقبل الله منا ومنكم.',
                style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green.shade800,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _copyZikr(AzkarItem item) {
    final textToCopy = StringBuffer();
    textToCopy.writeln(AzkarService.cleanText(item.item));
    if (item.reference.trim().isNotEmpty) {
      textToCopy.writeln('\n[المصدر]: ${item.reference.trim()}');
    }

    Clipboard.setData(ClipboardData(text: textToCopy.toString()));
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'تم نسخ الذكر إلى الحافظة',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Almarai'),
          ),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _items.length;
    final completed = _completedItemsCount;
    final progress = total > 0 ? (completed / total) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.chapterTitle,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              fontFamily: 'Almarai',
            ),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.primary),
          actions: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              tooltip: 'تصغير الخط',
              onPressed: () {
                if (_fontSize > 14.sp) {
                  setState(() => _fontSize -= 1.sp);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'تكبير الخط',
              onPressed: () {
                if (_fontSize < 30.sp) {
                  setState(() => _fontSize += 1.sp);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'إعادة ضبط الجميع',
              onPressed: _items.isEmpty ? null : _resetAllCounts,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _items.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد أذكار مسجلة لهذا الباب',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.primary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Overall Progress Banner
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: _isAllCompleted
                              ? (isDark ? Colors.green.withAlpha(30) : Colors.green.shade50)
                              : AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: _isAllCompleted
                                ? (isDark ? Colors.green.withAlpha(70) : Colors.green.shade300)
                                : AppColors.primary.withAlpha(35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isAllCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.auto_stories_rounded,
                                      size: 18.sp,
                                      color: _isAllCompleted
                                          ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                          : AppColors.primary,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      _isAllCompleted
                                          ? 'تم إتمام جميع الأذكار بحمد الله'
                                          : 'المكتمل: $completed من $total ذكر',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Almarai',
                                        color: _isAllCompleted
                                            ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _isAllCompleted
                                        ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6.h,
                                backgroundColor: AppColors.primary.withAlpha(30),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isAllCompleted
                                      ? (isDark ? Colors.green.shade400 : Colors.green.shade600)
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Azkar Cards List
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 14.h),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final targetCount = _originalCounts[item.id] ?? 1;
                            final remaining = _remainingCounts[item.id] ?? 1;
                            final isDone = remaining == 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: isDone
                                    ? (ThemeService.instance.isDarkMode
                                        ? Colors.green.shade900.withAlpha(80)
                                        : Colors.green.shade50.withAlpha(120))
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isDone
                                      ? Colors.green.shade300
                                      : AppColors.primary.withAlpha(30),
                                  width: isDone ? 1.5 : 1,
                                ),
                              ),
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header: Index badge, target count badge & copy
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDone
                                                  ? Colors.green.shade700
                                                  : AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            child: Text(
                                              '${index + 1} / $total',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            child: Text(
                                              targetCount == 1
                                                  ? 'مرة واحدة'
                                                  : targetCount == 2
                                                      ? 'مرتان'
                                                      : '$targetCount مرات',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Almarai',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.copy_rounded,
                                              size: 24.sp,
                                              color: AppColors.primary,
                                            ),
                                            tooltip: 'نسخ الذكر',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _copyZikr(item),
                                          ),
                                          if (targetCount > 1 &&
                                              remaining < targetCount) ...[
                                            SizedBox(width: 8.w),
                                            IconButton(
                                              icon: Icon(
                                                Icons.refresh_rounded,
                                                size: 18.sp,
                                                color: AppColors.primary
                                                    .withAlpha(150),
                                              ),
                                              tooltip: 'إعادة ضبط هذا الذكر',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () =>
                                                  _resetSingleCount(item.id),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 14.h),

                                  // Main Zikr Arabic Text
                                  Text(
                                    AzkarService.cleanText(item.item),
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: _fontSize,
                                      height: 2.0,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  // Reference / Hadith section if exists
                                  if (item.reference.trim().isNotEmpty) ...[
                                    SizedBox(height: 12.h),
                                    Container(
                                      padding: EdgeInsets.all(10.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(12),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                          color: AppColors.primary.withAlpha(25),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.bookmark_added_outlined,
                                            size: 16.sp,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              item.reference.trim(),
                                              style: TextStyle(
                                                fontFamily: 'Almarai',
                                                fontSize: 11.5.sp,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: 14.h),

                                  // Interactive Counter Button
                                  InkWell(
                                    onTap: () => _decrementCount(item.id),
                                    borderRadius: BorderRadius.circular(14.r),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                        horizontal: 16.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? Colors.green.shade700
                                            : AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(14.r),                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isDone
                                                ? Icons.check_circle_rounded
                                                : Icons.touch_app_rounded,
                                            color: Colors.white,
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            isDone
                                                ? 'تم بحمد الله'
                                                : 'المتبقي: $remaining',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Almarai',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
