import 'package:alhuda/services/hadith_service.dart';
import 'package:alhuda/view/pages/hadith_book_page.dart';
import 'package:alhuda/view/pages/hadith_bookmarks_page.dart';
import 'package:alhuda/view/pages/hadith_chapter_page.dart';
import 'package:alhuda/view/pages/hadith_search_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ودجت موسوعة الأحاديث النبوية الشريفة في تطبيق الهدى
class HadithWidget extends StatefulWidget {
  const HadithWidget({super.key});

  @override
  State<HadithWidget> createState() => _HadithWidgetState();
}

class _HadithWidgetState extends State<HadithWidget> {
  final HadithService _service = HadithService.instance;

  List<HadithBook> _books = [];
  bool _isLoading = true;
  ({HadithBook book, HadithChapter chapter, HadithItem hadith})? _dailyHadith;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final books = await _service.getAllBooks();
    final daily = await _service.getHadithOfTheDay();
    if (mounted) {
      setState(() {
        _books = books;
        _dailyHadith = daily;
        _isLoading = false;
      });
    }
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HadithSearchPage(),
      ),
    );
  }

  void _openBookmarks() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HadithBookmarksPage(),
      ),
    );
  }

  void _openBook(HadithBook book) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HadithBookPage(book: book),
      ),
    );
  }

  void _copyDailyHadith() {
    if (_dailyHadith == null) return;
    HapticFeedback.lightImpact();
    final d = _dailyHadith!;
    final text = '«${d.hadith.arabic}»\n\n'
        '【 ${d.book.title} - ${d.chapter.title} - حديث رقم ${d.hadith.idInBook} 】\n'
        'تطبيق الهدى';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('تم نسخ حديث اليوم وتخريجه',
                  style: TextStyle(fontFamily: 'Almarai')),
            ],
          ),
        ),
        backgroundColor: d.book.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDailyInChapter() {
    if (_dailyHadith == null) return;
    HapticFeedback.lightImpact();
    final d = _dailyHadith!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HadithChapterPage(
          book: d.book,
          chapter: d.chapter,
          targetHadithNumber: d.hadith.idInBook,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. شريط الإجراءات السريعة (بحث + مفضلة)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _openSearch,
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 22.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'ابحث في الأحاديث أوفلاين...',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textSecondary,
                                fontFamily: 'Almarai',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // زر المفضلة
                  InkWell(
                    onTap: _openBookmarks,
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. بطاقة حديث اليوم
          if (_dailyHadith != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _dailyHadith!.book.color,
                        _dailyHadith!.book.color.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // رأس البطاقة
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'حديث اليوم النبوي',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Almarai',
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded,
                                  color: Colors.white, size: 20),
                              tooltip: 'نسخ الحديث',
                              onPressed: _copyDailyHadith,
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded,
                                  color: Colors.white, size: 20),
                              tooltip: 'فتح في الباب',
                              onPressed: _openDailyInChapter,
                            ),
                          ],
                        ),
                      ),
                      // نص الحديث
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          _dailyHadith!.hadith.arabic,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontFamily: 'Amiri',
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // التخريج
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '${_dailyHadith!.book.title} - ${_dailyHadith!.chapter.title}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Almarai',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. شريط إحصائي مختصر
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.library_books_rounded,
                      label: 'دواوين السنة',
                      value: '${_books.length} كتب',
                    ),
                    Container(
                      width: 1,
                      height: 32.h,
                      color: AppColors.border,
                    ),
                    _buildStatItem(
                      icon: Icons.menu_book_rounded,
                      label: 'الأبواب والفصول',
                      value: '155 باباً',
                    ),
                    Container(
                      width: 1,
                      height: 32.h,
                      color: AppColors.border,
                    ),
                    _buildStatItem(
                      icon: Icons.format_quote_rounded,
                      label: 'الأحاديث الصحيحة',
                      value: '14,778 حديثاً',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. عنوان قسم كتب الحديث
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
              child: Text(
                'أمهات كتب الحديث النبوي',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Almarai',
                ),
              ),
            ),
          ),

          // 5. بطاقات الكتب
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = _books[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: InkWell(
                      onTap: () => _openBook(book),
                      borderRadius: BorderRadius.circular(18.r),
                      child: Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // أيقونة الكتاب ملونة
                            Container(
                              width: 52.w,
                              height: 52.w,
                              decoration: BoxDecoration(
                                color: book.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Icon(
                                book.icon,
                                color: book.color,
                                size: 28.sp,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            // نصوص وبيانات الكتاب
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        book.title,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Almarai',
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: book.color.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          book.badge,
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                            color: book.color,
                                            fontFamily: 'Almarai',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    book.author,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Almarai',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Text(
                                        '${book.totalChapters} باباً',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Almarai',
                                        ),
                                      ),
                                      Text(
                                        '  •  ',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${book.totalHadiths} حديثاً',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Almarai',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16.sp,
                              color:
                                  AppColors.textSecondary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _books.length,
              ),
            ),
          ),

          // مساحة سفلية
          SliverToBoxAdapter(
            child: SizedBox(height: 24.h),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primary),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Almarai',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Almarai',
          ),
        ),
      ],
    );
  }
}
