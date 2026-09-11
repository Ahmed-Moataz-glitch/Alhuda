import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/view/pages/section_detail_page.dart';
import 'package:alhuda/view/widgets/allah_names_widget.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/view/widgets/azkar_widget.dart';
import 'package:alhuda/view/widgets/fiqh_widget.dart';
import 'package:alhuda/view/widgets/hadith_widget.dart';
import 'package:alhuda/view/widgets/hijri_calendar_widget.dart';
import 'package:alhuda/view/widgets/prayer_times_widget.dart';
import 'package:alhuda/view/widgets/qiblah_main_screen.dart';
import 'package:alhuda/view/widgets/quran_widget.dart';
import 'package:alhuda/view/widgets/tasbeeh_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri_date/hijri_date.dart';

/// Data model representing a main section card in the home page grid.
class _HomeFeatureItem {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Widget Function() builder;

  const _HomeFeatureItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.builder,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  static const List<String> _gregorianMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  List<_HomeFeatureItem> _getFeatures() => [
        _HomeFeatureItem(
          title: 'المصحف الشريف',
          subtitle: 'تلاوة، تفسير، وبحث الآيات',
          badge: '١١٤ سورة',
          icon: Icons.menu_book_rounded,
          builder: () => const QuranWidget(),
        ),
        _HomeFeatureItem(
          title: 'الأحاديث النبوية',
          subtitle: 'صحيح البخاري، صحيح مسلم، والأربعون',
          badge: 'السنة النبوية',
          icon: Icons.auto_stories_rounded,
          builder: () => const HadithWidget(),
        ),
        _HomeFeatureItem(
          title: 'مواقيت الصلاة',
          subtitle: 'مواقيت الصلاة وإعدادات الأذان',
          badge: 'الصلوات الخمس',
          icon: Icons.access_time_filled_rounded,
          builder: () => const PrayerTimesWidget(),
        ),
        _HomeFeatureItem(
          title: 'التقويم الهجري',
          subtitle: 'المناسبات وأطوار القمر ومحوّل التاريخ',
          badge: 'هجري وميلادي',
          icon: Icons.calendar_month_rounded,
          builder: () => const HijriCalendarWidget(),
        ),
        _HomeFeatureItem(
          title: 'التسبيح الحر',
          subtitle: 'سبحة إلكترونية وتتبع الأوراد',
          badge: 'عداد الأوراد',
          icon: Icons.fingerprint_rounded,
          builder: () => const TasbeehWidget(),
        ),
        _HomeFeatureItem(
          title: 'الأذكار',
          subtitle: 'حصن المسلم وأذكار اليوم والليلة',
          badge: 'أدعية وأذكار',
          icon: Icons.auto_stories_rounded,
          builder: () => const AzkarWidget(),
        ),
        _HomeFeatureItem(
          title: 'أسماء الله الحسنى',
          subtitle: '٩٩ اسماً بشواهدها ومعانيها',
          badge: '٩٩ اسماً',
          icon: Icons.stars_rounded,
          builder: () => const AllahNamesWidget(),
        ),
        _HomeFeatureItem(
          title: 'الفقه الإسلامي',
          subtitle: 'موسوعة الأحكام الفقهية الميسرة',
          badge: 'أحكام ومسائل',
          icon: Icons.library_books_rounded,
          builder: () => const FiqhWidget(),
        ),
        _HomeFeatureItem(
          title: 'القبلة',
          subtitle: 'تحديد القبلة بالشمس بدون إنترنت ومستشعر',
          badge: 'طريقة الشمس',
          icon: Icons.wb_sunny_rounded,
          builder: () => const QiblahMainScreen(hasScaffold: false),
        ),
      ];

  void _navigateToSection(String title, Widget child) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionDetailPage(
          title: title,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijriDate = HijriDate.fromDate(now);
    final features = _getFeatures();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 65.h,
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // يمين كلمة الهدى: التاريخ الهجري (الضغط عليه يفتح صفحة التقويم)
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildHijriBadge(hijriDate),
                ),
              ),

              // الوسط: كلمة الهُدى مع شعار فرعي جمالي
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _buildCenterTitle(),
              ),

              // شمال كلمة الهدى: التاريخ الميلادي وزر تبديل المظهر
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: _buildGregorianBadge(now)),
                      SizedBox(width: 5.w),
                      _buildThemeToggleButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. بطاقة روحانية ترحيبية في أعلى الصفحة
            SliverToBoxAdapter(
              child: _buildTopBanner(hijriDate),
            ),

            // 2. شبكة الأقسام (عنصرين في كل صف)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = features[index];
                    return _buildFeatureCard(item);
                  },
                  childCount: features.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة إيمانية ترحيبية أعلى شبكة الميزات
  Widget _buildTopBanner(HijriDate hijriDate) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 14.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha(200),
            const Color(0xFF4E342E),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.amber.shade300,
                      size: 15.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'مَرْحَباً بِكَ فِي الهُدَى',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade200,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${hijriDate.dayWeName}، ${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} هـ',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 11.sp,
                    color: Colors.white.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 28.sp,
              color: Colors.amber.shade200,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة القسم داخل الـ GridView (عنصرين في كل صف)
  Widget _buildFeatureCard(_HomeFeatureItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.primary.withAlpha(30),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSection(item.title, item.builder()),
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصف العلوي: الأيقونة مع شارة التصنيف
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(35),
                            AppColors.primary.withAlpha(12),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(45),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primary,
                        size: 21.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.badge,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // اسم القسم
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),

                // وصف مختصر للقسم
                Expanded(
                  child: Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),

                // سهم الانتقال
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.sp,
                      color: AppColors.primary.withAlpha(140),
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

  /// بطاقة التاريخ الهجري التفاعلية (النقر عليها ينقل للتقويم)
  Widget _buildHijriBadge(HijriDate hijriDate) {
    return InkWell(
      onTap: () => _navigateToSection(
        'التقويم الهجري',
        const HijriCalendarWidget(),
      ),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${hijriDate.hDay} ${hijriDate.longMonthName}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            Text(
              '${hijriDate.hYear} هـ',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// العنوان الرئيسي وشعار التطبيق
  Widget _buildCenterTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'الهُدى',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
        Text(
          'نُورٌ وَهِدَايَة',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 9.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// بطاقة التاريخ الميلادي
  Widget _buildGregorianBadge(DateTime now) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${now.day} ${_gregorianMonths[now.month - 1]}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            '${now.year} م',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// زر التبديل بين الوضع الليلي والنهاري
  Widget _buildThemeToggleButton() {
    final themeService = ThemeService.instance;
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return Tooltip(
          message: 'تبديل المظهر (${themeService.themeModeName})',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                await themeService.toggleTheme();
                if (mounted) {
                  setState(() {});
                }
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showThemePickerDialog();
              },
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(50),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    themeService.themeModeIcon,
                    key: ValueKey(themeService.themeMode),
                    size: 16.r,
                    color: themeService.isDarkMode
                        ? Colors.amber
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// حوار اختيار نمط المظهر
  void _showThemePickerDialog() {
    final themeService = ThemeService.instance;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'اختيار المظهر',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOptionTile(
                  title: 'الوضع النهاري (فاتح)',
                  subtitle: 'مظهر فاتح مناسب للقراءة نهاراً',
                  icon: Icons.wb_sunny_rounded,
                  iconColor: Colors.amber.shade700,
                  isSelected: themeService.themeMode == ThemeMode.light,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await themeService.setThemeMode(ThemeMode.light);
                    if (mounted) setState(() {});
                  },
                ),
                SizedBox(height: 8.h),
                _buildThemeOptionTile(
                  title: 'الوضع الليلي (داكن)',
                  subtitle: 'مظهر داكن مريح للعينين في الإضاءة المنخفضة',
                  icon: Icons.nightlight_round,
                  iconColor: Colors.indigo.shade300,
                  isSelected: themeService.themeMode == ThemeMode.dark,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await themeService.setThemeMode(ThemeMode.dark);
                    if (mounted) setState(() {});
                  },
                ),
                SizedBox(height: 8.h),
                _buildThemeOptionTile(
                  title: 'تلقائي (حسب النظام)',
                  subtitle: 'يتغير تلقائياً بحسب إعدادات هاتفك',
                  icon: Icons.brightness_auto_rounded,
                  iconColor: AppColors.primary,
                  isSelected: themeService.themeMode == ThemeMode.system,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await themeService.setThemeMode(ThemeMode.system);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withAlpha(30),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(30)
                      : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontFamily: 'Almarai',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
