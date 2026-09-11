import 'package:alhuda/services/hadith_service.dart';
import 'package:alhuda/view/pages/hadith_chapter_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفحة استعراض كتاب الحديث النبوي وجميع أبوابه وفصوله
class HadithBookPage extends StatefulWidget {
  final HadithBook book;

  const HadithBookPage({
    super.key,
    required this.book,
  });

  @override
  State<HadithBookPage> createState() => _HadithBookPageState();
}

class _HadithBookPageState extends State<HadithBookPage> {
  final HadithService _service = HadithService.instance;
  List<HadithChapter> _chapters = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);
    final list = await _service.getChapters(widget.book.id);
    if (mounted) {
      setState(() {
        _chapters = list;
        _isLoading = false;
      });
    }
  }

  List<HadithChapter> get _filteredChapters {
    if (_searchQuery.trim().isEmpty) return _chapters;
    final cleanQuery = HadithService.normalizeArabic(_searchQuery);
    return _chapters.where((ch) {
      final cleanTitle = HadithService.normalizeArabic(ch.title);
      final idStr = ch.id.toString();
      return cleanTitle.contains(cleanQuery) || idStr == _searchQuery.trim();
    }).toList();
  }

  void _openChapter(HadithChapter chapter) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HadithChapterPage(
          book: widget.book,
          chapter: chapter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredChapters;

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
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. بطاقة ترويسة الكتاب
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
                      child: Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.book.color,
                              widget.book.color.withValues(alpha: 0.82),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    widget.book.icon,
                                    color: Colors.white,
                                    size: 26.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                        widget.book.author,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontFamily: 'Almarai',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (widget.book.subtitle.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              Text(
                                widget.book.subtitle,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontFamily: 'Almarai',
                                  height: 1.4,
                                ),
                              ),
                            ],
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                _buildHeaderBadge(
                                  icon: Icons.menu_book_rounded,
                                  text: '${_chapters.length} باباً',
                                ),
                                SizedBox(width: 10.w),
                                _buildHeaderBadge(
                                  icon: Icons.format_quote_rounded,
                                  text: '${widget.book.totalHadiths} حديثاً',
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    widget.book.badge,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Almarai',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. شريط البحث داخل الأبواب
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث عن باب أو موضوع في الكتاب...',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                              fontFamily: 'Almarai',
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. قائمة الأبواب
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.h),
                        child: Center(
                          child: Text(
                            'لم يتم العثور على أبواب تطابق بحثك',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final chapter = filtered[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: InkWell(
                                onTap: () => _openChapter(chapter),
                                borderRadius: BorderRadius.circular(14.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 14.h),
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
                                      // رقم الباب
                                      Container(
                                        width: 38.w,
                                        height: 38.w,
                                        decoration: BoxDecoration(
                                          color: widget.book.color
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${chapter.id}',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color: widget.book.color,
                                              fontFamily: 'Almarai',
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      // عنوان الباب ومعلومات الأحاديث
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
                                                height: 1.3,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                Text(
                                                  '${chapter.hadithsCount} حديث',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontFamily: 'Almarai',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (chapter.startHadith >
                                                    0) ...[
                                                  Text(
                                                    '  •  الأحاديث (${chapter.startHadith} - ${chapter.endHadith})',
                                                    style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color: AppColors
                                                          .textSecondary
                                                          .withValues(alpha: 0.8),
                                                      fontFamily: 'Almarai',
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16.sp,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 24.h),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderBadge({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
          SizedBox(width: 5.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Almarai',
            ),
          ),
        ],
      ),
    );
  }
}
