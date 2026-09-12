import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/services/azkar_service.dart';
import 'package:alhuda/features/azkar/presentation/view/pages/azkar_chapter_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class AzkarWidget extends StatefulWidget {
  const AzkarWidget({super.key});

  @override
  State<AzkarWidget> createState() => _AzkarWidgetState();
}

class _AzkarWidgetState extends State<AzkarWidget> {
  bool _isLoading = true;
  List<AzkarCategory> _categories = [];
  List<AzkarChapter> _allChapters = [];
  int _selectedCategoryId = -1; // -1 means All
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await AzkarService.instance.getCategories();
      final chapters = await AzkarService.instance.getAllChapters();

      if (mounted) {
        setState(() {
          _categories = categories;
          _allChapters = chapters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<AzkarChapter> get _filteredChapters {
    List<AzkarChapter> list = _allChapters;

    // Filter by category if selected
    if (_selectedCategoryId != -1) {
      list = list
          .where((ch) => ch.categoryId == _selectedCategoryId)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      list = AzkarService.instance.filterChapters(list, _searchQuery);
    }

    return list;
  }

  String _getCategoryName(int categoryId) {
    final cat = _categories.where((c) => c.id == categoryId);
    if (cat.isNotEmpty) {
      return cat.first.name;
    }
    return '';
  }

  void _openChapter(int chapterId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AzkarChapterPage(
          chapterId: chapterId,
          chapterTitle: title,
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

    final filteredList = _filteredChapters;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Search Bar & Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(40),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Almarai',
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث في أذكار وأدعية حصن المسلم...',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          fontFamily: 'Almarai',
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 22.sp,
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
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Featured Daily Azkar (الورد اليومي) - Visible when not searching
          if (!isSearching && _selectedCategoryId == -1) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'الورد اليومي والأذكار الأساسية',
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
                  children: [
                    // أذكار الصباح (Morning)
                    _buildFeaturedCard(
                      title: 'أذكار الصباح',
                      subtitle: 'حفظ وبركة ليومك',
                      timeBadge: 'الفجر حتى الضحى',
                      icon: Icons.wb_sunny_rounded,
                      gradientColors: [
                        const Color(0xFF8D6E63),
                        AppColors.primary,
                      ],
                      onTap: () => _openChapter(27, 'أَذْكَارُ الصَّـبَاحِ'),
                    ),
                    SizedBox(width: 12.w),
                    // أذكار المساء (Evening)
                    _buildFeaturedCard(
                      title: 'أذكار المساء',
                      subtitle: 'سكينة وحصن لليلتك',
                      timeBadge: 'العصر حتى الغروب',
                      icon: Icons.nights_stay_rounded,
                      gradientColors: const [
                        Color(0xFF5D4037),
                        Color(0xFF3E2723),
                      ],
                      onTap: () => _openChapter(28, 'أَذْكَارُ الْمَسَــاءِ'),
                    ),
                    SizedBox(width: 12.w),
                    // أذكار النوم (Sleep)
                    _buildFeaturedCard(
                      title: 'أذكار النوم',
                      subtitle: 'طمأنينة وراحة للبال',
                      timeBadge: 'قبل النوم',
                      icon: Icons.bedtime_rounded,
                      gradientColors: const [
                        Color(0xFF4E342E),
                        Color(0xFF6D4C41),
                      ],
                      onTap: () => _openChapter(29, 'أَذْكَارُ النَّــوْمِ'),
                    ),
                    SizedBox(width: 12.w),
                    // أذكار الاستيقاظ (Wake up)
                    _buildFeaturedCard(
                      title: 'أذكار الاستيقاظ',
                      subtitle: 'حمد لنعمة الحياة',
                      timeBadge: 'عند الاستيقاظ',
                      icon: Icons.wb_twilight_rounded,
                      gradientColors: const [
                        Color(0xFF795548),
                        Color(0xFFA1887F),
                      ],
                      onTap: () =>
                          _openChapter(1, 'أَذْكَارُ الاسْـتِيقَاظِ مِنَ النَّـومِ'),
                    ),
                    SizedBox(width: 12.w),
                    // أذكار بعد الصلاة (After Prayer)
                    _buildFeaturedCard(
                      title: 'أذكار بعد الصلاة',
                      subtitle: 'تثبيت للأجر',
                      timeBadge: 'عقب الصلوات',
                      icon: Icons.mosque_rounded,
                      gradientColors: [
                        const Color(0xFF6D4C41),
                        AppColors.primary,
                      ],
                      onTap: () => _openChapter(
                        25,
                        'الأَذْكَارُ بَعْدَ السَّلاَمِ مِنَ الصَّلاَةِ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 3. Category Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أقسام وتصنيفات الأذكار',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Almarai',
                    ),
                  ),
                  Text(
                    '${filteredList.length} باباً',
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
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42.h,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  // 'All' Chip
                  _buildCategoryChip(
                    id: -1,
                    label: 'الكل (${_allChapters.length})',
                  ),
                  SizedBox(width: 8.w),
                  ..._categories.map((cat) {
                    final count = _allChapters
                        .where((ch) => ch.categoryId == cat.id)
                        .length;
                    return Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: _buildCategoryChip(
                        id: cat.id,
                        label: '${cat.name} ($count)',
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: 10.h),
          ),

          // 4. Chapters List
          filteredList.isEmpty
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
                          'لم يتم العثور على أذكار تطابق بحثك',
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
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final chapter = filteredList[index];
                        final categoryName =
                            _getCategoryName(chapter.categoryId);

                        return Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withAlpha(6),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openChapter(
                                chapter.id,
                                chapter.name,
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 12.h,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36.w,
                                      height: 36.w,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12.sp,
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
                                            chapter.name,
                                            style: TextStyle(
                                              fontSize: 14.5.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                              fontFamily: 'Rubik',
                                            ),
                                          ),
                                          if (categoryName.isNotEmpty) ...[
                                            SizedBox(height: 3.h),
                                            Text(
                                              categoryName,
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: AppColors.primary
                                                    .withAlpha(180),
                                                fontFamily: 'Almarai',
                                              ),
                                            ),
                                          ],
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
                      childCount: filteredList.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard({
    required String title,
    required String subtitle,
    required String timeBadge,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170.w,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16.r),
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
                    icon,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    timeBadge,
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      color: Colors.white,
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Almarai',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
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
    );
  }

  Widget _buildCategoryChip({required int id, required String label}) {
    final isSelected = _selectedCategoryId == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategoryId = id;
        });
      },
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withAlpha(40),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.primary,
              fontFamily: 'Almarai',
            ),
          ),
        ),
      ),
    );
  }
}
