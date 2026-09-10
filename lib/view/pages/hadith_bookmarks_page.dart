import 'package:alhuda/services/hadith_service.dart';
import 'package:alhuda/view/pages/hadith_chapter_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفحة الأحاديث المحفوظة (المفضلة)
class HadithBookmarksPage extends StatefulWidget {
  const HadithBookmarksPage({super.key});

  @override
  State<HadithBookmarksPage> createState() => _HadithBookmarksPageState();
}

class _HadithBookmarksPageState extends State<HadithBookmarksPage> {
  final HadithService _service = HadithService.instance;
  List<HadithBookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final list = await _service.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = list;
        _isLoading = false;
      });
    }
  }

  void _openBookmark(HadithBookmark bookmark) async {
    HapticFeedback.lightImpact();
    final book = await _service.getBookById(bookmark.bookId);
    if (book == null) return;

    final chapters = await _service.getChapters(bookmark.bookId);
    final chapter = chapters.firstWhere(
      (c) => c.id == bookmark.chapterId,
      orElse: () => HadithChapter(
        id: bookmark.chapterId,
        title: bookmark.chapterTitle,
        hadithsCount: 1,
        startHadith: 1,
        endHadith: 1,
      ),
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HadithChapterPage(
            book: book,
            chapter: chapter,
            targetHadithNumber: bookmark.hadithNumber,
          ),
        ),
      );
    }
  }

  void _removeBookmark(HadithBookmark bookmark) async {
    HapticFeedback.mediumImpact();
    await _service.toggleBookmark(bookmark);
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
            'الأحاديث المحفوظة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Almarai',
            ),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _bookmarks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = _bookmarks[index];
                      return _buildBookmarkCard(bookmark);
                    },
                  ),
      ),
    );
  }

  Widget _buildBookmarkCard(HadithBookmark bookmark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _openBookmark(bookmark),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      bookmark.bookTitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      bookmark.chapterTitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontFamily: 'Almarai',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '#${bookmark.hadithNumber}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_remove_rounded,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    tooltip: 'حذف من المحفوظات',
                    onPressed: () => _removeBookmark(bookmark),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                bookmark.snippet,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoNaskhArabic',
                  height: 1.6,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد أحاديث محفوظة في المفضلة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Almarai',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'أثناء قراءة أي حديث، يمكنك الضغط على أيقونة الإشارة المرجعية لحفظه والرجوع إليه بسهولة لاحقاً.',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Almarai',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
