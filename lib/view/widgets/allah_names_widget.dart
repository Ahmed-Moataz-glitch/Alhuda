import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/allah_names_service.dart';
import 'allah_name_detail_sheet.dart';
import 'app_colors.dart';

class AllahNamesWidget extends StatefulWidget {
  const AllahNamesWidget({super.key});

  @override
  State<AllahNamesWidget> createState() => _AllahNamesWidgetState();
}

class _AllahNamesWidgetState extends State<AllahNamesWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<AllahNameModel> _allNames = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final names = await AllahNamesService.instance.getAllNames();
    if (mounted) {
      setState(() {
        _allNames = names;
        _isLoading = false;
      });
    }
  }

  List<AllahNameModel> get _filteredNames {
    return AllahNamesService.instance.filterNames(
      sourceList: _allNames,
      query: _searchQuery,
      favoritesOnly: _showFavoritesOnly,
    );
  }

  void _openDetailSheet(int targetNameId) {
    final displayedList = _filteredNames;
    final index = displayedList.indexWhere((item) => item.id == targetNameId);
    if (index != -1) {
      AllahNameDetailSheet.show(
        context,
        names: displayedList,
        initialIndex: index,
        onFavoriteChanged: (_) {
          setState(() {});
        },
      );
    }
  }

  Future<void> _toggleFavorite(int id) async {
    await AllahNamesService.instance.toggleFavorite(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16.h),
            Text(
              'جارٍ تحميل أسماء الله الحسنى...',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14.sp,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    final filteredList = _filteredNames;
    final nameOfTheDay = AllahNamesService.instance.getNameOfTheDay(_allNames);
    final isSearching = _searchQuery.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Hero Islamic Header Banner
            SliverToBoxAdapter(
              child: _buildHeroBanner(),
            ),

            // 2. Name of the Day Card (Visible when not searching)
            if (!isSearching && !_showFavoritesOnly && nameOfTheDay != null)
              SliverToBoxAdapter(
                child: _buildNameOfTheDayCard(nameOfTheDay),
              ),

            // 3. Search & View Mode Controls
            SliverToBoxAdapter(
              child: _buildSearchAndControls(),
            ),

            // 4. Content (Grid or List or Empty)
            if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else if (_isGridView)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.88,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredList[index];
                      return _buildGridCard(item);
                    },
                    childCount: filteredList.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredList[index];
                      return _buildListItem(item, index);
                    },
                    childCount: filteredList.length,
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

  // --- Header Banner ---
  Widget _buildHeroBanner() {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha(230),
            const Color(0xFF42281D),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quranic Ayah
          Text(
            '﴿ وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا ﴾',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade200,
            ),
          ),
          SizedBox(height: 10.h),

          // Hadith Snippet
          Text(
            '«إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمًا، مِائَةً إِلَّا وَاحِدًا، مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ»',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 13.5.sp,
              color: Colors.white.withAlpha(235),
              height: 1.6,
            ),
          ),
          SizedBox(height: 14.h),

          // Counter chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.amber.shade300,
                  size: 15.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '٩٩ اسماً مباركاً موثقة من السنة والقرآن',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Name of the Day Card ---
  Widget _buildNameOfTheDayCard(AllahNameModel item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.amber.shade300.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Name Calligraphy Badge
          GestureDetector(
            onTap: () => _openDetailSheet(item.id),
            child: Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(200),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.all(6.r),
                    child: Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade100,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),

          // Details & Action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 13.sp,
                            color: Colors.amber.shade900,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'اسم اليوم للتأمل',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${item.id}',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  item.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 12.sp,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () => _openDetailSheet(item.id),
                  child: Text(
                    'عرض الشرح والتسبيح ←',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Search Bar & Filtering Controls ---
  Widget _buildSearchAndControls() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Column(
        children: [
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 13.5.sp,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث في أسماء الله الحسنى أو المعاني...',
                hintStyle: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 13.sp,
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
                        color: Colors.black45,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
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
          SizedBox(height: 12.h),

          // Filters and view switch row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter Chips: All & Favorites
              Row(
                children: [
                  _buildFilterChip(
                    label: 'الكل',
                    isSelected: !_showFavoritesOnly,
                    onTap: () => setState(() => _showFavoritesOnly = false),
                  ),
                  SizedBox(width: 6.w),
                  _buildFilterChip(
                    label: 'المفضلة',
                    icon: Icons.star_rounded,
                    isSelected: _showFavoritesOnly,
                    onTap: () => setState(() => _showFavoritesOnly = true),
                  ),
                ],
              ),

              // View Switcher (Grid vs List)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.grid_view_rounded,
                        size: 20.sp,
                        color: _isGridView ? AppColors.primary : Colors.grey.shade400,
                      ),
                      onPressed: () => setState(() => _isGridView = true),
                      tooltip: 'عرض الشبكة',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(8.r),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.view_agenda_rounded,
                        size: 20.sp,
                        color: !_isGridView ? AppColors.primary : Colors.grey.shade400,
                      ),
                      onPressed: () => setState(() => _isGridView = false),
                      tooltip: 'عرض القائمة',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(8.r),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15.sp,
                color: isSelected ? Colors.amber.shade200 : Colors.amber.shade700,
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Grid View Card ---
  Widget _buildGridCard(AllahNameModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: item.isFavorite
              ? Colors.amber.shade300
              : AppColors.primary.withAlpha(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetailSheet(item.id),
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: ID badge & Favorite star
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${item.id}',
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleFavorite(item.id),
                      child: Icon(
                        item.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: item.isFavorite
                            ? Colors.amber.shade700
                            : Colors.grey.shade400,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),

                // Center: Name in Arabic Calligraphy
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Bottom: Transliteration & concise meaning
                Column(
                  children: [
                    if (item.transliteration.isNotEmpty)
                      Text(
                        item.transliteration,
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Text(
                      item.meaning,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 10.sp,
                        color: Colors.black54,
                        height: 1.3,
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

  // --- List View Item ---
  Widget _buildListItem(AllahNameModel item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: item.isFavorite
              ? Colors.amber.shade300
              : AppColors.primary.withAlpha(25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetailSheet(item.id),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${item.id}',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),

                // Name & Explanation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (item.transliteration.isNotEmpty)
                            Text(
                              '(${item.transliteration})',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 11.5.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.meaning,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11.5.sp,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Favorite button & arrow
                IconButton(
                  onPressed: () => _toggleFavorite(item.id),
                  icon: Icon(
                    item.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: item.isFavorite
                        ? Colors.amber.shade700
                        : Colors.grey.shade400,
                    size: 22.sp,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary.withAlpha(120),
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showFavoritesOnly ? Icons.star_outline_rounded : Icons.search_off_rounded,
              size: 56.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              _showFavoritesOnly
                  ? 'لا توجد أسماء في المفضلة بعد'
                  : 'لم يتم العثور على نتائج مطابقة',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _showFavoritesOnly
                  ? 'يمكنك إضافة أي اسم للمفضلة بالنقر على أيقونة النجمة'
                  : 'جرب البحث بكلمة أخرى أو برقم الاسم',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
