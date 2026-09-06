import 'package:alhuda/model/fiqh_model.dart';
import 'package:alhuda/services/fiqh_service.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفحة قراءة أحكام الباب والمسائل الفقهية
class FiqhChapterPage extends StatefulWidget {
  final FiqhBook book;
  final FiqhChapter chapter;
  final String? initialIssueId;

  const FiqhChapterPage({
    super.key,
    required this.book,
    required this.chapter,
    this.initialIssueId,
  });

  @override
  State<FiqhChapterPage> createState() => _FiqhChapterPageState();
}

class _FiqhChapterPageState extends State<FiqhChapterPage> {
  double _fontSize = 16.5.sp;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    FiqhService.instance.ensureBookmarksLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyIssue(FiqhIssue issue) {
    final buffer = StringBuffer();
    buffer.writeln('【 ${issue.title} 】');
    buffer.writeln('الحكم: ${issue.rulingType.label}');
    buffer.writeln('\n${issue.content}');

    if (issue.conditions.isNotEmpty) {
      buffer.writeln('\nالأركان / الشروط:');
      for (final cond in issue.conditions) {
        buffer.writeln('• $cond');
      }
    }

    if (issue.evidences.isNotEmpty) {
      buffer.writeln('\nالأدلة الشرعية:');
      for (final ev in issue.evidences) {
        buffer.writeln('«${ev.text}» [${ev.source}]');
      }
    }

    if (issue.notes.isNotEmpty) {
      buffer.writeln('\nتنبيهات:');
      for (final note in issue.notes) {
        buffer.writeln('• $note');
      }
    }

    buffer.writeln('\nالمصدر: تطبيق الهدى - ${widget.book.title} (${widget.chapter.title})');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ المسألة الفقهية مع أدلتها للحافظة',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Almarai'),
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

  Future<void> _toggleBookmark(FiqhIssue issue) async {
    HapticFeedback.mediumImpact();
    await FiqhService.instance.toggleBookmark(
      book: widget.book,
      chapter: widget.chapter,
      issue: issue,
    );
    if (mounted) {
      setState(() {});
      final isSaved = FiqhService.instance.isBookmarked(issue.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'تمت إضافة المسألة إلى المفضلة' : 'تمت إزالة المسألة من المفضلة',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Almarai'),
          ),
          backgroundColor: isSaved ? Colors.green.shade800 : AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final issues = widget.chapter.issues;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primary),
          title: Column(
            children: [
              Text(
                widget.chapter.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Almarai',
                ),
              ),
              Text(
                widget.book.title,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.primary.withAlpha(180),
                  fontFamily: 'Almarai',
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              tooltip: 'تصغير الخط',
              onPressed: () {
                if (_fontSize > 13.sp) {
                  setState(() => _fontSize -= 1.sp);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'تكبير الخط',
              onPressed: () {
                if (_fontSize < 28.sp) {
                  setState(() => _fontSize += 1.sp);
                }
              },
            ),
          ],
        ),
        body: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          children: [
            // Chapter Summary Banner
            Container(
              padding: EdgeInsets.all(14.r),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primary.withAlpha(30)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withAlpha(6),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.book.icon,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chapter.summary,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'Almarai',
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'يحتوي هذا الباب على ${issues.length} مسائل وأحكام',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.primary,
                            fontFamily: 'Almarai',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Issues Cards
            ...issues.asMap().entries.map((entry) {
              final index = entry.key;
              final issue = entry.value;
              final isSaved = FiqhService.instance.isBookmarked(issue.id);

              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withAlpha(7),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Number badge, Ruling Badge, Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 9.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
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
                                color: issue.rulingType.backgroundColor,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: issue.rulingType.foregroundColor
                                      .withAlpha(60),
                                ),
                              ),
                              child: Text(
                                issue.rulingType.label,
                                style: TextStyle(
                                  color: issue.rulingType.foregroundColor,
                                  fontSize: 11.5.sp,
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
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: isSaved
                                    ? AppColors.primary
                                    : Colors.black45,
                                size: 22.sp,
                              ),
                              tooltip: isSaved ? 'إزالة من المحفوظات' : 'حفظ في المفضلة',
                              onPressed: () => _toggleBookmark(issue),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy_rounded,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              tooltip: 'نسخ الحكم والأدلة',
                              onPressed: () => _copyIssue(issue),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Issue Title
                    Text(
                      issue.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Almarai',
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // Issue Content Text
                    Text(
                      issue.content,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontFamily: 'Rubik',
                        height: 1.8,
                        color: Colors.black87,
                      ),
                    ),

                    // Conditions / Steps / Pillars if available
                    if (issue.conditions.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.black12,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16.sp,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'الشروط / الأركان / الخطوات:',
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Almarai',
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            ...issue.conditions.map(
                              (cond) => Padding(
                                padding: EdgeInsets.only(bottom: 5.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 6.h, left: 6.w),
                                      child: Container(
                                        width: 5.w,
                                        height: 5.w,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        cond,
                                        style: TextStyle(
                                          fontSize: (_fontSize - 2.sp).clamp(11.sp, 24.sp),
                                          fontFamily: 'Rubik',
                                          height: 1.6,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Evidences Box
                    if (issue.evidences.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      ...issue.evidences.map(
                        (ev) => Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: ev.isQuran
                                ? const Color(0xFFF1F8E9)
                                : AppColors.primary.withAlpha(12),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: ev.isQuran
                                  ? const Color(0xFF81C784)
                                  : AppColors.primary.withAlpha(40),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    ev.isQuran
                                        ? Icons.menu_book_rounded
                                        : Icons.format_quote_rounded,
                                    size: 16.sp,
                                    color: ev.isQuran
                                        ? Colors.green.shade800
                                        : AppColors.primary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    ev.isQuran
                                        ? 'دليل من القرآن الكريم:'
                                        : 'دليل من السنة النبوية:',
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Almarai',
                                      color: ev.isQuran
                                          ? Colors.green.shade900
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '«${ev.text}»',
                                style: TextStyle(
                                  fontSize: (_fontSize - 1.sp).clamp(12.sp, 26.sp),
                                  fontFamily: 'Rubik',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  height: 1.7,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '[${ev.source}]',
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontFamily: 'Almarai',
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Notes / Alert Box
                    if (issue.notes.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      ...issue.notes.map(
                        (note) => Container(
                          margin: EdgeInsets.only(bottom: 6.h),
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: const Color(0xFFFFE082),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16.sp,
                                color: const Color(0xFFF57F17),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontFamily: 'Almarai',
                                    color: const Color(0xFF5D4037),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
