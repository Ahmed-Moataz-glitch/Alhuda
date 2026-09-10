import 'package:alhuda/services/hadith_service.dart';
import 'package:alhuda/view/pages/hadith_chapter_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفحة البحث الشامل اللحظي في الأحاديث النبوية
class HadithSearchPage extends StatefulWidget {
  final String? initialBookId;

  const HadithSearchPage({
    super.key,
    this.initialBookId,
  });

  @override
  State<HadithSearchPage> createState() => _HadithSearchPageState();
}

class _HadithSearchPageState extends State<HadithSearchPage> {
  final HadithService _service = HadithService.instance;
  final TextEditingController _controller = TextEditingController();

  List<HadithSearchResult> _results = [];
  bool _isSearching = false;
  String? _selectedBookId;
  List<HadithBook> _books = [];

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.initialBookId;
    _loadBooks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final list = await _service.getAllBooks();
    if (mounted) {
      setState(() => _books = list);
    }
  }

  void _onSearch(String query) async {
    final clean = query.trim();
    if (clean.length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _service.searchHadiths(
      clean,
      filterBookId: _selectedBookId,
      limit: 60,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  void _openResult(HadithSearchResult result) async {
    HapticFeedback.lightImpact();
    final book = await _service.getBookById(result.bookId);
    if (book == null) return;

    final chapters = await _service.getChapters(result.bookId);
    final chapter = chapters.firstWhere(
      (c) => c.id == result.chapterId,
      orElse: () => HadithChapter(
        id: result.chapterId,
        title: result.chapterTitle,
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
            targetHadithNumber: result.hadithNumber,
          ),
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
            'بحث في الأحاديث النبوية',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Almarai',
            ),
          ),
        ),
        body: Column(
          children: [
            // حقل البحث
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
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
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالكلمة أو العبارة (مثال: النيات، الصلاة، الجنة)...',
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Almarai',
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _controller.clear();
                              _onSearch('');
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

            // فلاتر الكتب
            SizedBox(
              height: 38.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildFilterChip(
                    label: 'الكل',
                    isSelected: _selectedBookId == null,
                    onSelected: () {
                      setState(() => _selectedBookId = null);
                      _onSearch(_controller.text);
                    },
                  ),
                  SizedBox(width: 8.w),
                  ..._books.map((b) {
                    return Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: _buildFilterChip(
                        label: b.title,
                        isSelected: _selectedBookId == b.id,
                        onSelected: () {
                          setState(() => _selectedBookId = b.id);
                          _onSearch(_controller.text);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // نتائج البحث
            Expanded(
              child: _isSearching
                  ? Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _controller.text.trim().length < 2
                      ? _buildSearchPlaceholder()
                      : _results.isEmpty
                          ? _buildNoResults()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final res = _results[index];
                                return _buildResultCard(res);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontFamily: 'Almarai',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(HadithSearchResult res) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () => _openResult(res),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      res.bookTitle,
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
                      res.chapterTitle,
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '#${res.hadithNumber}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                res.matchedSnippet,
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

  Widget _buildSearchPlaceholder() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 54.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              'ابحث في آلاف الأحاديث النبوية بدون إنترنت',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Almarai',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'اكتب كلمة أو نصاً للبحث في صحيح البخاري، صحيح مسلم، والأربعين النووية فوراً',
              style: TextStyle(
                fontSize: 12.sp,
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

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              'لم يتم العثور على نتائج تطابق بحثك',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Almarai',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'جرب البحث بكلمات أخرى أو اختر "الكل" لإلغاء فلتر الكتاب',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Almarai',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
