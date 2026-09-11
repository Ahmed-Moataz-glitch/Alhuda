import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:hijri_date/moon_phases.dart';
import 'package:hijri_date/religious_event.dart';

class HijriCalendarWidget extends StatefulWidget {
  const HijriCalendarWidget({super.key});

  @override
  State<HijriCalendarWidget> createState() => _HijriCalendarWidgetState();
}

class _HijriCalendarWidgetState extends State<HijriCalendarWidget> {
  late HijriDate _todayHijri;
  late DateTime _todayGregorian;

  late int _viewedYear;
  late int _viewedMonth;

  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  late ScrollController _scrollController;
  bool _isNext = true;

  final List<String> _weekDays = const [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  @override
  void initState() {
    super.initState();
    HijriDate.setLocal('ar');
    _scrollController = ScrollController();
    _todayGregorian = DateTime.now();
    _todayHijri = HijriDate.fromDate(_todayGregorian);

    _viewedYear = _todayHijri.hYear;
    _viewedMonth = _todayHijri.hMonth;

    _selectedYear = _todayHijri.hYear;
    _selectedMonth = _todayHijri.hMonth;
    _selectedDay = _todayHijri.hDay;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _isNext = false;
      if (_viewedMonth == 1) {
        _viewedMonth = 12;
        _viewedYear--;
      } else {
        _viewedMonth--;
      }
      if (_viewedYear == _todayHijri.hYear &&
          _viewedMonth == _todayHijri.hMonth) {
        _selectedYear = _todayHijri.hYear;
        _selectedMonth = _todayHijri.hMonth;
        _selectedDay = _todayHijri.hDay;
      } else {
        _selectedYear = null;
        _selectedMonth = null;
        _selectedDay = null;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _isNext = true;
      if (_viewedMonth == 12) {
        _viewedMonth = 1;
        _viewedYear++;
      } else {
        _viewedMonth++;
      }
      if (_viewedYear == _todayHijri.hYear &&
          _viewedMonth == _todayHijri.hMonth) {
        _selectedYear = _todayHijri.hYear;
        _selectedMonth = _todayHijri.hMonth;
        _selectedDay = _todayHijri.hDay;
      } else {
        _selectedYear = null;
        _selectedMonth = null;
        _selectedDay = null;
      }
    });
  }

  void _jumpToToday() {
    setState(() {
      _isNext = false;
      _todayGregorian = DateTime.now();
      _todayHijri = HijriDate.fromDate(_todayGregorian);
      _viewedYear = _todayHijri.hYear;
      _viewedMonth = _todayHijri.hMonth;
      _selectedYear = _todayHijri.hYear;
      _selectedMonth = _todayHijri.hMonth;
      _selectedDay = _todayHijri.hDay;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _getArabicMonthName(int month) {
    const names = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الثاني',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    if (month >= 1 && month <= 12) {
      return names[month - 1];
    }
    return '';
  }

  String _getGregorianMonthName(int month) {
    const months = [
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
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  String _formatGregorianDate(DateTime date) {
    return '${date.day} ${_getGregorianMonthName(date.month)} ${date.year} م';
  }

  IconData _getMoonIcon(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return Icons.circle_outlined;
      case MoonPhase.waxingCrescent:
      case MoonPhase.waningCrescent:
        return Icons.nightlight_round;
      case MoonPhase.firstQuarter:
      case MoonPhase.lastQuarter:
        return Icons.radio_button_checked;
      case MoonPhase.waxingGibbous:
      case MoonPhase.waningGibbous:
      case MoonPhase.fullMoon:
        return Icons.brightness_1_rounded;
    }
  }

  List<IslamicEvent> _getEventsForDay(int month, int day) {
    return IslamicEventsManager.getEventsInMonth(month)
        .where((e) => e.days.contains(day))
        .toList();
  }

  bool _isWhiteDay(int day) {
    return day == 13 || day == 14 || day == 15;
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedDay = _selectedYear != null &&
        _selectedMonth != null &&
        _selectedDay != null &&
        _selectedYear == _viewedYear &&
        _selectedMonth == _viewedMonth;

    final currentHijriSelection = hasSelectedDay
        ? HijriDate.fromHijri(_selectedYear!, _selectedMonth!, _selectedDay!)
        : null;
    final selectedGregorian = hasSelectedDay
        ? HijriDate().hijriToGregorian(
            _selectedYear!, _selectedMonth!, _selectedDay!)
        : null;
    final moonInfo = currentHijriSelection?.getMoonPhase();
    final dayEvents = hasSelectedDay
        ? _getEventsForDay(_selectedMonth!, _selectedDay!)
        : <IslamicEvent>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            // 1. Today & Moon Phase Header Card
            _buildTodayHeaderCard(),
            SizedBox(height: 16.h),

            // 2. Month Calendar Card
            _buildMonthCalendarCard(),
            SizedBox(height: 16.h),

            // 3. Selected Day Details Card
            if (hasSelectedDay &&
                currentHijriSelection != null &&
                selectedGregorian != null &&
                moonInfo != null)
              _buildSelectedDayCard(
                currentHijriSelection,
                selectedGregorian,
                moonInfo,
                dayEvents,
              )
            else
              _buildNoDaySelectedCard(),
            SizedBox(height: 16.h),

            // 4. Upcoming Islamic Occasions
            _buildUpcomingEventsCard(),
            SizedBox(height: 16.h),

            // 5. Date Converter Action Button
            _buildConverterButton(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayHeaderCard() {
    final todayMoon = _todayHijri.getMoonPhase();
    final todaysEvents = IslamicEventsManager.getTodaysEvents();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            const Color(0xFF5D4037),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'اليوم في التقويم الهجري',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _jumpToToday,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.white.withAlpha(60),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'العودة لليوم',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Full Hijri Date
          Text(
            '${_todayHijri.dayWeName}، ${_todayHijri.hDay} ${_getArabicMonthName(_todayHijri.hMonth)} ${_todayHijri.hYear} هـ',
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),

          // Gregorian Date
          Text(
            _formatGregorianDate(_todayGregorian),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withAlpha(210),
            ),
          ),
          SizedBox(height: 12.h),

          // Moon Phase & Occasion strip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(40),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  _getMoonIcon(todayMoon.phase),
                  color: const Color(0xFFFFD54F),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'طور القمر: ${todayMoon.arabicName} (إضاءة ${(todayMoon.illumination * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (todaysEvents.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00).withAlpha(40),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFFFB300),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: const Color(0xFFFFD54F),
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'مناسبة اليوم: ${todaysEvents.map((e) => e.titleArabic).join(' - ')}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthCalendarCard() {
    final daysInMonth =
        HijriDate().getDaysInMonth(_viewedYear, _viewedMonth);
    final firstDayGregorian =
        HijriDate().hijriToGregorian(_viewedYear, _viewedMonth, 1);
    final lastDayGregorian =
        HijriDate().hijriToGregorian(_viewedYear, _viewedMonth, daysInMonth);

    // Week starts on Saturday (offset calculation where Sat = 0)
    // Dart weekday: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
    final firstWeekdayOffset = (firstDayGregorian.weekday + 1) % 7;
    final totalCells = firstWeekdayOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final gregorianSpan =
        '${firstDayGregorian.day} ${_getGregorianMonthName(firstDayGregorian.month)} - ${lastDayGregorian.day} ${_getGregorianMonthName(lastDayGregorian.month)} ${lastDayGregorian.year}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        // In RTL: swipe left (negative velocity) moves to next month,
        // swipe right (positive velocity) moves to previous month
        if (velocity < -150) {
          _nextMonth();
        } else if (velocity > 150) {
          _previousMonth();
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            // Month Header Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  iconSize: 18.sp,
                  color: AppColors.primary,
                  tooltip: 'الشهر السابق',
                  onPressed: _previousMonth,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_getArabicMonthName(_viewedMonth)} $_viewedYear هـ',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        gregorianSpan,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  iconSize: 18.sp,
                  color: AppColors.primary,
                  tooltip: 'الشهر القادم',
                  onPressed: _nextMonth,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(height: 1),
            SizedBox(height: 8.h),

            // Weekdays Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDays.map((day) {
                final isFriday = day == 'الجمعة';
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: isFriday ? AppColors.primary : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8.h),

            // Calendar Days Grid with smooth animated transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetTween = Tween<Offset>(
                  begin: Offset(_isNext ? -0.15 : 0.15, 0.0),
                  end: Offset.zero,
                );
                return SlideTransition(
                  position: offsetTween.animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey('$_viewedYear-$_viewedMonth'),
                child: Column(
                  children: List.generate(totalRows, (rowIndex) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (colIndex) {
                          final cellIndex = rowIndex * 7 + colIndex;
                          final dayNum = cellIndex - firstWeekdayOffset + 1;

                          if (dayNum < 1 || dayNum > daysInMonth) {
                            return const Expanded(child: SizedBox.shrink());
                          }

                          final gregDate = HijriDate().hijriToGregorian(
                            _viewedYear,
                            _viewedMonth,
                            dayNum,
                          );
                          final isToday = dayNum == _todayHijri.hDay &&
                              _viewedMonth == _todayHijri.hMonth &&
                              _viewedYear == _todayHijri.hYear;
                          final isSelected = dayNum == _selectedDay &&
                              _viewedMonth == _selectedMonth &&
                              _viewedYear == _selectedYear;
                          final hasEvents =
                              _getEventsForDay(_viewedMonth, dayNum).isNotEmpty;
                          final isWhiteDay = _isWhiteDay(dayNum);

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedYear = _viewedYear;
                                  _selectedMonth = _viewedMonth;
                                  _selectedDay = dayNum;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.all(2.r),
                                padding: EdgeInsets.symmetric(vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isToday
                                          ? AppColors.primary.withAlpha(35)
                                          : (isWhiteDay
                                              ? const Color(0xFFFFF8E1)
                                              : Colors.transparent)),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isToday
                                            ? AppColors.primary
                                            : Colors.transparent),
                                    width: isToday && !isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.onPrimary
                                            : (isToday
                                                ? AppColors.primary
                                                : (isWhiteDay
                                                    ? const Color(0xFF5D4037)
                                                    : AppColors.textPrimary)),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${gregDate.day}',
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        color: isSelected
                                            ? AppColors.onPrimary.withAlpha(180)
                                            : (isWhiteDay
                                                ? const Color(0xFF8D6E63)
                                                : AppColors.textSecondary),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    if (hasEvents)
                                      Container(
                                        width: 4.w,
                                        height: 4.w,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFFD54F)
                                              : const Color(0xFFE65100),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    else
                                      SizedBox(height: 4.w),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Legend Hints
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.w,
              runSpacing: 6.h,
              children: [
                _buildLegendItem(
                  color: AppColors.primary,
                  borderColor: AppColors.primary,
                  label: 'اليوم المحدد',
                ),
                _buildLegendItem(
                  color: AppColors.primary.withAlpha(40),
                  borderColor: AppColors.primary,
                  label: 'اليوم الحالي',
                ),
                _buildLegendItem(
                  color: const Color(0xFFFFF8E1),
                  borderColor: const Color(0xFFFFD54F),
                  label: 'الأيام البيض',
                ),
                _buildLegendDot(
                  color: const Color(0xFFE65100),
                  label: 'مناسبة إسلامية',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required Color borderColor,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildNoDaySelectedCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'تفاصيل اليوم المحدد',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'اضغط على أي يوم في التقويم لعرض تفاصيله وأطوار القمر والمناسبات',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
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

  Widget _buildSelectedDayCard(
    HijriDate currentHijriSelection,
    DateTime selectedGregorian,
    MoonPhaseInfo moonInfo,
    List<IslamicEvent> dayEvents,
  ) {
    final isWhiteDay = _isWhiteDay(currentHijriSelection.hDay);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'تفاصيل اليوم المحدد',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Selected Day full text
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getMoonIcon(moonInfo.phase),
                  color: AppColors.primary,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentHijriSelection.dayWeName}، ${currentHijriSelection.hDay} ${_getArabicMonthName(currentHijriSelection.hMonth)} ${currentHijriSelection.hYear} هـ',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatGregorianDate(selectedGregorian),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Moon details
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'طور القمر: ${moonInfo.arabicName}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'نسبة الإضاءة: ${(moonInfo.illumination * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (isWhiteDay) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    color: const Color(0xFFF57F17),
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'هذا اليوم من الأيام البيض المستحب صيامها (13، 14، 15)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (dayEvents.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'المناسبات في هذا اليوم:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 6.h),
            ...dayEvents.map((event) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFFFB74D),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.celebration_rounded,
                          color: const Color(0xFFE65100),
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          event.titleArabic,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    if (event.hadiths.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        '«${event.hadiths.first.hadith}»',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        event.hadiths.first.bookInfo,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.brown.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsCard() {
    final allEvents = IslamicEventsManager.getMainEvents();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'أهم المناسبات والأعياد الإسلامية',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          ...allEvents.map((event) {
            final daysUntil = event.daysUntilEvent();
            final eventMonthName = _getArabicMonthName(event.month);
            final eventDay = event.days.isNotEmpty ? event.days.first : 1;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$eventDay $eventMonthName',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      event.titleArabic,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: daysUntil == 0
                          ? const Color(0xFF2E7D32)
                          : (daysUntil <= 30
                              ? const Color(0xFFEF6C00)
                              : Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      daysUntil == 0 ? 'اليوم' : 'متبقي $daysUntil يوم',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConverterButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: _showConverterDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.sync_alt_rounded, color: Colors.white),
        label: Text(
          'تحويل التاريخ (هجري / ميلادي)',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showConverterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DateConverterBottomSheet(
          initialHijri: _selectedYear != null &&
                  _selectedMonth != null &&
                  _selectedDay != null
              ? HijriDate.fromHijri(
                  _selectedYear!, _selectedMonth!, _selectedDay!)
              : HijriDate.fromHijri(_viewedYear, _viewedMonth, 1),
          onSelectDate: (hijriDate) {
            setState(() {
              _viewedYear = hijriDate.hYear;
              _viewedMonth = hijriDate.hMonth;
              _selectedYear = hijriDate.hYear;
              _selectedMonth = hijriDate.hMonth;
              _selectedDay = hijriDate.hDay;
            });
          },
        );
      },
    );
  }
}

class _DateConverterBottomSheet extends StatefulWidget {
  final HijriDate initialHijri;
  final ValueChanged<HijriDate> onSelectDate;

  const _DateConverterBottomSheet({
    required this.initialHijri,
    required this.onSelectDate,
  });

  @override
  State<_DateConverterBottomSheet> createState() =>
      _DateConverterBottomSheetState();
}

class _DateConverterBottomSheetState extends State<_DateConverterBottomSheet> {
  late DateTime _chosenGregorian;
  late HijriDate _convertedHijri;

  @override
  void initState() {
    super.initState();
    _convertedHijri = widget.initialHijri;
    _chosenGregorian = HijriDate().hijriToGregorian(
      widget.initialHijri.hYear,
      widget.initialHijri.hMonth,
      widget.initialHijri.hDay,
    );
  }

  Future<void> _pickGregorianDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _chosenGregorian,
      firstDate: DateTime(1930),
      lastDate: DateTime(2090),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surface,
                    onSurface: AppColors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _chosenGregorian = picked;
        _convertedHijri = HijriDate.fromDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ThemeService.instance.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'محوّل التاريخ الهجري والميلادي',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16.h),

            // Select Gregorian
            Text(
              'التاريخ الميلادي:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            InkWell(
              onTap: _pickGregorianDate,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_chosenGregorian.day}/${_chosenGregorian.month}/${_chosenGregorian.year} م',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(Icons.edit_calendar_rounded,
                        color: AppColors.primary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Converted Hijri Output Card
            Text(
              'التاريخ الهجري المقابل:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_convertedHijri.dayWeName}، ${_convertedHijri.hDay} ${_convertedHijri.longMonthName} ${_convertedHijri.hYear} هـ',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'طور القمر: ${_convertedHijri.getMoonPhase().arabicName}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelectDate(_convertedHijri);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'عرض هذا التاريخ في التقويم',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}
