import 'package:alhuda/model/fiqh_model.dart';
import 'package:alhuda/services/fiqh_service.dart';
import 'package:alhuda/view/pages/fiqh_book_page.dart';
import 'package:alhuda/view/pages/fiqh_chapter_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// واجهة الفقه الإسلامي الشاملة لجميع كتب وأبواب الفقه
class FiqhWidget extends StatefulWidget {
  const FiqhWidget({super.key});

  @override
  State<FiqhWidget> createState() => _FiqhWidgetState();
}

class _FiqhWidgetState extends State<FiqhWidget> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0; // 0: الكل, 1: العبادات, 2: المعاملات, 3: الأسرة, 4: العامة, 5: المفضلة

  @override
  void initState() {
    super.initState();
    FiqhService.instance.ensureBookmarksLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FiqhBook> get _filteredBooks {
    final all = FiqhService.instance.getAllBooks();
    switch (_selectedFilterIndex) {
      case 1:
        return all.where((b) => b.category == FiqhCategory.ibadat).toList();
      case 2:
        return all.where((b) => b.category == FiqhCategory.muamalat).toList();
      case 3:
        return all.where((b) => b.category == FiqhCategory.family).toList();
      case 4:
        return all.where((b) => b.category == FiqhCategory.general).toList();
      default:
        return all;
    }
  }

  void _openBook(FiqhBook book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FiqhBookPage(book: book),
      ),
    );
  }

  void _openChapter(FiqhBook book, FiqhChapter chapter, {String? issueId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FiqhChapterPage(
          book: book,
          chapter: chapter,
          initialIssueId: issueId,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.trim().isNotEmpty;
    final searchResults =
        isSearching ? FiqhService.instance.search(_searchQuery) : <FiqhSearchResult>[];
    final isBookmarksSelected = _selectedFilterIndex == 5;
    final bookmarks = FiqhService.instance.getBookmarks();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Search Bar Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'Almarai',
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث في أبواب ومسائل وأدلة الفقه الإسلامي...',
                    hintStyle: TextStyle(
                      fontSize: 12.5.sp,
                      fontFamily: 'Almarai',
                      color: Colors.black38,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 22.sp,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            color: Colors.black45,
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
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Filter Category Chips (when not searching)
          if (!isSearching)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44.h,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    _buildChip(index: 0, label: 'جميع الأبواب (14)'),
                    SizedBox(width: 8.w),
                    _buildChip(index: 1, label: 'العبادات (5)'),
                    SizedBox(width: 8.w),
                    _buildChip(index: 2, label: 'المعاملات والمواريث (2)'),
                    SizedBox(width: 8.w),
                    _buildChip(index: 3, label: 'الأسرة والأحوال'),
                    SizedBox(width: 8.w),
                    _buildChip(index: 4, label: 'الآداب والأحكام العامة (6)'),
                    SizedBox(width: 8.w),
                    _buildChip(
                      index: 5,
                      label: 'المفضلة (${bookmarks.length})',
                      icon: Icons.bookmark_rounded,
                    ),
                  ],
                ),
              ),
            ),

          // 3. Featured Horizontal Cards (When not searching and "الكل" selected)
          if (!isSearching && _selectedFilterIndex == 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'مسائل فقهية هامة ويومية',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 145.h,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: _buildFeaturedCards(),
                ),
              ),
            ),
          ],

          // 4. Content Area: Search Results OR Bookmarks OR Books List
          if (isSearching) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
                child: Text(
                  'نتائج البحث (${searchResults.length})',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Almarai',
                  ),
                ),
              ),
            ),
            searchResults.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48.sp,
                            color: AppColors.primary.withAlpha(120),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'لم يتم العثور على مسائل فقهية تطابق بحثك',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppColors.primary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 24.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = searchResults[index];
                          return _buildSearchResultCard(item);
                        },
                        childCount: searchResults.length,
                      ),
                    ),
                  ),
          ] else if (isBookmarksSelected) ...[
            // Bookmarks view
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
                child: Text(
                  'المسائل المحفوظة في المفضلة',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Almarai',
                  ),
                ),
              ),
            ),
            bookmarks.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border_rounded,
                            size: 48.sp,
                            color: AppColors.primary.withAlpha(100),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'لم تقم بحفظ أي مسائل فقهية في المفضلة بعد',
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              color: AppColors.primary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'اضغط على أيقونة الإشارة المرجعية داخل أي مسألة لحفظها هنا',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black45,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 24.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final b = bookmarks[index];
                          return _buildBookmarkCard(b);
                        },
                        childCount: bookmarks.length,
                      ),
                    ),
                  ),
          ] else ...[
            // Books Grid / List
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'كتب الفقه الإسلامي',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    Text(
                      '${_filteredBooks.length} كتب',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary.withAlpha(180),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = _filteredBooks[index];
                    return _buildBookCard(book, index);
                  },
                  childCount: _filteredBooks.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required int index,
    required String label,
    IconData? icon,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withAlpha(40),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withAlpha(60),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15.sp,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primary,
                fontFamily: 'Almarai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(FiqhBook book, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 11.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withAlpha(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openBook(book),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    book.icon,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              book.title,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'Almarai',
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              book.category.label,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Almarai',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        book.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppColors.textSecondary,
                          fontFamily: 'Almarai',
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 13.sp,
                            color: AppColors.primary.withAlpha(180),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${book.chaptersCount} أبواب',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.primary,
                              fontFamily: 'Almarai',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Icon(
                            Icons.gavel_rounded,
                            size: 13.sp,
                            color: AppColors.primary.withAlpha(180),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${book.totalIssuesCount} مسائل',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.primary,
                              fontFamily: 'Almarai',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary.withAlpha(140),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeaturedCards() {
    final featured = FiqhService.instance.getFeaturedIssues();
    return featured.map((item) {
      return Padding(
        padding: EdgeInsets.only(left: 10.w),
        child: GestureDetector(
          onTap: () => _openChapter(item.book, item.chapter, issueId: item.issue.id),
          child: Container(
            width: 175.w,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF795548),
                  AppColors.primary,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(70),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.book.icon,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        item.issue.rulingType.label,
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          color: Colors.white,
                          fontFamily: 'Almarai',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Almarai',
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: Colors.white.withAlpha(210),
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSearchResultCard(FiqhSearchResult result) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChapter(result.book, result.chapter,
              issueId: result.issue.id),
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        result.issue.title,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: result.issue.rulingType.backgroundColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        result.issue.rulingType.label,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: result.issue.rulingType.foregroundColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  result.matchedSnippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Rubik',
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 13.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${result.book.title} > ${result.chapter.title}',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: AppColors.primary,
                        fontFamily: 'Almarai',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(FiqhBookmark bookmark) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final book = FiqhService.instance.getBookById(bookmark.bookId);
            final chapter = FiqhService.instance
                .getChapterById(bookmark.bookId, bookmark.chapterId);
            if (book != null && chapter != null) {
              _openChapter(book, chapter, issueId: bookmark.issueId);
            }
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookmark.issueTitle,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'Almarai',
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        bookmark.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppColors.textSecondary,
                          fontFamily: 'Rubik',
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        '${bookmark.bookTitle} > ${bookmark.chapterTitle}',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.primary,
                          fontFamily: 'Almarai',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bookmark_remove_rounded,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'إزالة من المفضلة',
                  onPressed: () async {
                    await FiqhService.instance.removeBookmark(bookmark.issueId);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
