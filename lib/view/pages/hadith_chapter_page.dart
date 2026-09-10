import 'package:alhuda/model/hadith_model.dart';
import 'package:alhuda/services/hadith_service.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفحة استعراض وقراءة الأحاديث النبوية الشريفة داخل الباب
class HadithChapterPage extends StatefulWidget {
  final HadithBook book;
  final HadithChapter chapter;
  final int? targetHadithNumber;

  const HadithChapterPage({
    super.key,
    required this.book,
    required this.chapter,
    this.targetHadithNumber,
  });

  @override
  State<HadithChapterPage> createState() => _HadithChapterPageState();
}

class _HadithChapterPageState extends State<HadithChapterPage> {
  final HadithService _service = HadithService.instance;
  List<HadithItem> _hadiths = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _loadHadiths();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHadiths() async {
    setState(() => _isLoading = true);
    final items =
        await _service.getChapterHadiths(widget.book.id, widget.chapter.id);
    if (mounted) {
      setState(() {
        _hadiths = items;
        _isLoading = false;
      });

      // إذا كان هناك حديث مستهدف من البحث، انتقل إليه
      if (widget.targetHadithNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTargetHadith();
        });
      }
    }
  }

  void _scrollToTargetHadith() {
    if (widget.targetHadithNumber == null) return;
    final index = _hadiths
        .indexWhere((h) => h.idInBook == widget.targetHadithNumber);
    if (index >= 0) {
      final key = _itemKeys[widget.targetHadithNumber!];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _copyHadith(HadithItem hadith) {
    HapticFeedback.lightImpact();
    final textToCopy = '«${hadith.arabic}»\n\n'
        '【 ${widget.book.title} - ${widget.chapter.title} - حديث رقم ${hadith.idInBook} 】\n'
        'تطبيق الهدى';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8.w),
            const Text(
              'تم نسخ الحديث والتخريج بنجاح',
              style: TextStyle(fontFamily: 'Almarai'),
            ),
          ],
        ),
        backgroundColor: widget.book.color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleBookmark(HadithItem hadith) async {
    HapticFeedback.mediumImpact();
    final bookmark = HadithBookmark(
      bookId: widget.book.id,
      bookTitle: widget.book.title,
      chapterId: widget.chapter.id,
      chapterTitle: widget.chapter.title,
      hadithNumber: hadith.idInBook,
      snippet: hadith.arabic.length > 90
          ? '${hadith.arabic.substring(0, 90)}...'
          : hadith.arabic,
      addedDate: DateTime.now().toIso8601String(),
    );
    await _service.toggleBookmark(bookmark);
    final isSaved =
        _service.isBookmarked(widget.book.id, widget.chapter.id, hadith.idInBook);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'تمت إضافة الحديث إلى المفضلة' : 'تمت إزالة الحديث من المفضلة',
            style: const TextStyle(fontFamily: 'Almarai'),
          ),
          backgroundColor: isSaved ? widget.book.color : Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.primary),
          title: Text(
            widget.chapter.title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Almarai',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // زر تصغير الخط
            IconButton(
              icon: const Icon(Icons.text_decrease_rounded),
              tooltip: 'تصغير الخط',
              onPressed: () {
                _service.decreaseFontSize();
              },
            ),
            // زر تكبير الخط
            IconButton(
              icon: const Icon(Icons.text_increase_rounded),
              tooltip: 'تكبير الخط',
              onPressed: () {
                _service.increaseFontSize();
              },
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _hadiths.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد أحاديث مسجلة في هذا الباب',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ترويسة الباب ومعلوماته
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
                          child: Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.book.color,
                                  widget.book.color.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.book.color.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        widget.book.title,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontFamily: 'Almarai',
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                      ),
                                      child: Text(
                                        '${_hadiths.length} حديث',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Almarai',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  widget.chapter.title,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Almarai',
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // قائمة الأحاديث
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final hadith = _hadiths[index];
                              final isTarget = widget.targetHadithNumber ==
                                  hadith.idInBook;
                              final key = _itemKeys.putIfAbsent(
                                hadith.idInBook,
                                () => GlobalKey(),
                              );
                              final isSaved = _service.isBookmarked(
                                widget.book.id,
                                widget.chapter.id,
                                hadith.idInBook,
                              );

                              return Padding(
                                key: key,
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isTarget
                                          ? widget.book.color
                                          : AppColors.border,
                                      width: isTarget ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // شريط علوي للحديث (رقم الحديث + المفضلة والنسخ)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 14.w, vertical: 10.h),
                                        decoration: BoxDecoration(
                                          color: widget.book.color
                                              .withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16.r),
                                            topRight: Radius.circular(16.r),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // رقم الحديث في الباب
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w, vertical: 3.h),
                                              decoration: BoxDecoration(
                                                color: widget.book.color,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Text(
                                                'حديث ${index + 1}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontFamily: 'Almarai',
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            // رقم الحديث العام في الكتاب
                                            Text(
                                              '#${hadith.idInBook}',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                                fontFamily: 'Almarai',
                                              ),
                                            ),
                                            const Spacer(),
                                            // زر النسخ
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.copy_rounded,
                                                  size: 20),
                                              color: AppColors.textSecondary,
                                              tooltip: 'نسخ الحديث',
                                              onPressed: () =>
                                                  _copyHadith(hadith),
                                            ),
                                            // زر الإشارة المرجعية
                                            IconButton(
                                              icon: Icon(
                                                isSaved
                                                    ? Icons.bookmark_rounded
                                                    : Icons
                                                        .bookmark_border_rounded,
                                                size: 22,
                                                color: isSaved
                                                    ? widget.book.color
                                                    : AppColors.textSecondary,
                                              ),
                                              tooltip: isSaved
                                                  ? 'إزالة من المفضلة'
                                                  : 'إضافة للمفضلة',
                                              onPressed: () =>
                                                  _toggleBookmark(hadith),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // نص الحديث النبوي
                                      Padding(
                                        padding: EdgeInsets.all(16.r),
                                        child: SelectableText(
                                          hadith.arabic,
                                          textAlign: TextAlign.justify,
                                          style: TextStyle(
                                            fontSize: _service.fontSize.sp,
                                            height: 2.0,
                                            color: AppColors.textPrimary,
                                            fontFamily: 'NotoNaskhArabic',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _hadiths.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 20.h),
                      ),
                    ],
                  ),
      ),
    );
  }
}
