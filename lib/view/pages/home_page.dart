import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/view/widgets/tasbeeh_widget.dart';
import 'package:alhuda/view/widgets/azkar_widget.dart';
import 'package:alhuda/view/widgets/fiqh_widget.dart';
import 'package:alhuda/view/widgets/qibla_widget.dart';
import 'package:alhuda/view/widgets/prayer_times_widget.dart';
import 'package:alhuda/view/widgets/quran_widget.dart';
import 'package:alhuda/view/widgets/hijri_calendar_widget.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri_date/hijri_date.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

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

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final now = DateTime.now();
    final hijriDate = HijriDate.fromDate(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // يمين كلمة الهدى: التاريخ الهجري
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => tabController.animateTo(2),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
                              color: Colors.brown.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // الوسط: كلمة الهُدى
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  'الهُدى',
                  style: TextStyle(
                    fontSize: 22.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // شمال كلمة الهدى: التاريخ الميلادي
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
                            color: Colors.brown.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            SizedBox(height: size.height * 0.02),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ButtonsTabBar(
                contentCenter: false,
                controller: tabController,
                tabs: const [
                  Tab(text: 'المصحف الشريف'),
                  Tab(text: 'مواقيت الصلاة'),
                  Tab(text: 'التقويم الهجري'),
                  Tab(text: 'التسبيح الحر'),
                  Tab(text: 'الاذكار'),
                  Tab(text: 'الفقه الإسلامي'),
                  Tab(text: 'القبلة'),
                ],
                labelStyle: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                ),
                contentPadding: EdgeInsets.all(8.r),
                buttonMargin: EdgeInsets.symmetric(horizontal: 16.r),
                backgroundColor: AppColors.primary,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: const [
                  QuranWidget(),
                  PrayerTimesWidget(),
                  HijriCalendarWidget(),
                  TasbeehWidget(),
                  AzkarWidget(),
                  FiqhWidget(),
                  QiblaWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
