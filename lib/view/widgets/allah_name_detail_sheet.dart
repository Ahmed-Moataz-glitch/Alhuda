import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/allah_names_service.dart';
import '../../services/theme_service.dart';
import 'app_colors.dart';

class AllahNameDetailSheet extends StatefulWidget {
  final List<AllahNameModel> names;
  final int initialIndex;
  final ValueChanged<int>? onFavoriteChanged;

  const AllahNameDetailSheet({
    super.key,
    required this.names,
    required this.initialIndex,
    this.onFavoriteChanged,
  });

  static void show(
    BuildContext context, {
    required List<AllahNameModel> names,
    required int initialIndex,
    ValueChanged<int>? onFavoriteChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AllahNameDetailSheet(
        names: names,
        initialIndex: initialIndex,
        onFavoriteChanged: onFavoriteChanged,
      ),
    );
  }

  @override
  State<AllahNameDetailSheet> createState() => _AllahNameDetailSheetState();
}

class _AllahNameDetailSheetState extends State<AllahNameDetailSheet> {
  late int _currentIndex;
  late PageController _pageController;
  int _tasbeehCount = 0;
  final int _targetTasbeeh = 33;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  AllahNameModel get _currentName => widget.names[_currentIndex];

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _tasbeehCount = 0; // Reset counter for new name
    });
  }

  void _navigateToIndex(int index) {
    if (index >= 0 && index < widget.names.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _incrementTasbeeh() {
    HapticFeedback.lightImpact();
    setState(() {
      _tasbeehCount++;
    });
  }

  void _resetTasbeeh() {
    HapticFeedback.mediumImpact();
    setState(() {
      _tasbeehCount = 0;
    });
  }

  Future<void> _toggleFavorite() async {
    final name = _currentName;
    await AllahNamesService.instance.toggleFavorite(name.id);
    setState(() {});
    widget.onFavoriteChanged?.call(name.id);
  }

  void _copyToClipboard() {
    final name = _currentName;
    final text =
        '''
✨ أسماء الله الحسنى: ${name.name} ✨
(${name.transliteration} - ${name.englishTranslation})

📖 معنى الاسم ودلالته:
${name.meaning}

🏷️ الشاهد:
${name.quranVerse} [${name.surahRef}]

— تطبيق الهُدى
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ تفاصيل الاسم بنجاح',
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

  @override
  Widget build(BuildContext context) {
    final isFavorite = AllahNamesService.instance.isFavorite(_currentName.id);

    return Container(
      height: 0.88.sh,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: ThemeService.instance.isDarkMode
                  ? Colors.white24
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Top Header Action Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Navigation Prev Button
                IconButton(
                  onPressed: _currentIndex < widget.names.length - 1
                      ? () => _navigateToIndex(_currentIndex + 1)
                      : null,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _currentIndex > 0
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    size: 20.sp,
                  ),
                  tooltip: 'الاسم التالي',
                ),

                // Name counter badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Text(
                    'الاسم ${_currentName.id} من ${widget.names.length}',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Action icons (Favorite & Copy & Next)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _copyToClipboard,
                      icon: Icon(
                        Icons.copy_rounded,
                        color: AppColors.textSecondary,
                        size: 20.sp,
                      ),
                      tooltip: 'نسخ',
                    ),
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: isFavorite
                            ? Colors.amber.shade700
                            : Colors.grey.shade500,
                        size: 24.sp,
                      ),
                      tooltip: 'إضافة للمفضلة',
                    ),
                    IconButton(
                      onPressed: _currentIndex > 0
                          ? () => _navigateToIndex(_currentIndex - 1)
                          : null,
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _currentIndex < widget.names.length - 1
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        size: 20.sp,
                      ),
                      tooltip: 'الاسم السابق',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Swipable PageView for smooth browsing
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.names.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final item = widget.names[index];
                return _buildNameDetails(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameDetails(AllahNameModel item) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // Featured Calligraphic Badge
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withAlpha(220),
                  const Color(0xFF4E342E),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              children: [
                // Decorative basmala / star indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 1,
                      width: 40.w,
                      color: Colors.amber.shade200.withAlpha(150),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.amber.shade300,
                        size: 16.sp,
                      ),
                    ),
                    Container(
                      height: 1,
                      width: 40.w,
                      color: Colors.amber.shade200.withAlpha(150),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Arabic Name in prominent NotoNaskhArabic font
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 38.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade100,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(120),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),

                // English Transliteration & Translation
                if (item.transliteration.isNotEmpty) ...[
                  Text(
                    item.transliteration,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 15.sp,
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
                if (item.englishTranslation.isNotEmpty)
                  Text(
                    item.englishTranslation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12.5.sp,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Meaning & Spiritual Explanation Card
          _buildInfoSection(
            icon: Icons.menu_book_rounded,
            title: 'معنى الاسم ودلالته الإيمانية',
            content: item.meaning,
            accentColor: AppColors.primary,
          ),
          SizedBox(height: 16.h),

          // Quranic Verse / Evidence Card
          if (item.quranVerse.isNotEmpty) ...[
            _buildVerseSection(item),
            SizedBox(height: 16.h),
          ],

          // Interactive Dhikr & Tasbeeh Card
          _buildTasbeehSection(item),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color accentColor,
  }) {
    final isDark = ThemeService.instance.isDarkMode;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accentColor.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: accentColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 14.5.sp,
              height: 1.8,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseSection(AllahNameModel item) {
    final isDark = ThemeService.instance.isDarkMode;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
              ? Colors.teal.shade700.withAlpha(120)
              : Colors.teal.shade200.withAlpha(120),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(30),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.format_quote_rounded,
                      color: isDark
                          ? Colors.teal.shade200
                          : Colors.teal.shade800,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'الشاهد من كتاب الله',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.teal.shade200
                          : Colors.teal.shade900,
                    ),
                  ),
                ],
              ),
              if (item.surahRef.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.teal.shade900.withAlpha(100)
                        : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.teal.shade700
                          : Colors.teal.shade300,
                    ),
                  ),
                  child: Text(
                    item.surahRef,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.teal.shade200
                          : Colors.teal.shade800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.teal.shade800 : Colors.teal.shade100,
              ),
            ),
            child: Text(
              '﴾ ${item.quranVerse} ﴿',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                height: 1.9,
                color: isDark ? Colors.teal.shade100 : Colors.teal.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasbeehSection(AllahNameModel item) {
    final progress = (_tasbeehCount / _targetTasbeeh).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'تسبيح وذكر بالاسم',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (_tasbeehCount > 0)
                TextButton.icon(
                  onPressed: _resetTasbeeh,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 16.sp,
                    color: Colors.grey,
                  ),
                  label: Text(
                    'إعادة ضبط',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Tap Counter Area
          InkWell(
            onTap: _incrementTasbeeh,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(25),
                    AppColors.primary.withAlpha(10),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Text(
                    'يا ${item.name}',
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$_tasbeehCount',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6.h,
                      backgroundColor: ThemeService.instance.isDarkMode
                          ? Colors.white12
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'اضغط للتسبيح • الهدف المقترح: $_targetTasbeeh مرة',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11.5.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
