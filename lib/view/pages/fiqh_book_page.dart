import 'package:alhuda/services/fiqh_service.dart';
import 'package:alhuda/view/pages/fiqh_chapter_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفحة استعراض كتاب الفقه وجميع أبوابه وفصوله
class FiqhBookPage extends StatefulWidget {
  final FiqhBook book;

  const FiqhBookPage({
    super.key,
    required this.book,
  });

  @override
  State<FiqhBookPage> createState() => _FiqhBookPageState();
}

class _FiqhBookPageState extends State<FiqhBookPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FiqhChapter> get _filteredChapters {
    if (_searchQuery.trim().isEmpty) {
      return widget.book.chapters;
    }
    final normQuery = FiqhService.normalizeArabic(_searchQuery);
    return widget.book.chapters.where((ch) {
      final titleMatch = FiqhService.normalizeArabic(ch.title).contains(normQuery);
      final summaryMatch =
          FiqhService.normalizeArabic(ch.summary).contains(normQuery);
      final issuesMatch = ch.issues.any((iss) =>
          FiqhService.normalizeArabic(iss.title).contains(normQuery) ||
          FiqhService.normalizeArabic(iss.content).contains(normQuery));
      return titleMatch || summaryMatch || issuesMatch;
    }).toList();
  }

  void _openChapter(FiqhChapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FiqhChapterPage(
          book: widget.book,
          chapter: chapter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _filteredChapters;

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
            widget.book.title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Almarai',
            ),
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Book Info Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6D4C41),
                        AppColors.primary,
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.book.icon,
                              color: Colors.white,
                              size: 26.sp,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(35),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              widget.book.category.label,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white,
                                fontFamily: 'Almarai',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        widget.book.title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Almarai',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.book.subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withAlpha(220),
                          fontFamily: 'Almarai',
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Divider(color: Colors.white.withAlpha(40)),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            label: 'الأبواب الفقهية',
                            value: '${widget.book.chaptersCount}',
                          ),
                          Container(
                            width: 1.w,
                            height: 24.h,
                            color: Colors.white.withAlpha(50),
                          ),
                          _buildStatItem(
                            label: 'إجمالي المسائل والأحكام',
                            value: '${widget.book.totalIssuesCount}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Search inside this book
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withAlpha(6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontFamily: 'Almarai',
                      color: AppColors.textPrimary,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث في أبواب ومسائل ${widget.book.title}...',
                      hintStyle: TextStyle(
                        fontSize: 12.5.sp,
                        fontFamily: 'Almarai',
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              color: AppColors.textSecondary,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 11.h,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أبواب وفصول الكتاب',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    Text(
                      '${chapters.length} أبواب',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary.withAlpha(180),
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Chapters List
            chapters.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 44.sp,
                            color: AppColors.primary.withAlpha(100),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'لم يتم العثور على أبواب تطابق بحثك',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final chapter = chapters[index];

                          return Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(30),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openChapter(chapter),
                                borderRadius: BorderRadius.circular(16.r),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 14.h,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38.w,
                                        height: 38.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(20),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chapter.title,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'Almarai',
                                              ),
                                            ),
                                            SizedBox(height: 3.h),
                                            Text(
                                              chapter.summary,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5.sp,
                                                color: AppColors.textSecondary,
                                                fontFamily: 'Almarai',
                                                height: 1.3,
                                              ),
                                            ),
                                            SizedBox(height: 5.h),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withAlpha(15),
                                                borderRadius: BorderRadius.circular(6.r),
                                              ),
                                              child: Text(
                                                '${chapter.issuesCount} مسائل وأحكام',
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Almarai',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: AppColors.primary.withAlpha(150),
                                        size: 16.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: chapters.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Almarai',
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5.sp,
            color: Colors.white.withAlpha(200),
            fontFamily: 'Almarai',
          ),
        ),
      ],
    );
  }
}
