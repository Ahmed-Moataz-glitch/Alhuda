import 'dart:async';
import 'package:alhuda/model/city_locations_data.dart';
import 'package:alhuda/view/widgets/adhan_audio_service.dart';
import 'package:alhuda/view/widgets/adhan_settings_bottom_sheet.dart';
import 'package:alhuda/view/widgets/egypt_dst_helper.dart';
import 'package:alhuda/view/widgets/prayer_scheduler_service.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class PrayerTimesWidget extends StatefulWidget {
  const PrayerTimesWidget({super.key});

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget> {
  final MuslimRepository _muslimRepo = MuslimRepository();
  final AdhanAudioService _audioService = AdhanAudioService();

  PrayerTime? _prayerTime;
  Location? _currentLocation;
  String _displayName = 'القاهرة، مصر';
  CalculationMethod _selectedMethod = CalculationMethod.egypt;
  EgyptDstMode _egyptDstMode = EgyptDstMode.auto;
  final int _manualMinutesOffset = 0;

  bool _isLoading = false;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_onAudioChange);
    _initPrayerTimes();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioChange);
    _timer?.cancel();
    super.dispose();
  }

  void _onAudioChange() {
    if (mounted) setState(() {});
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  Future<void> _initPrayerTimes() async {
    setState(() => _isLoading = true);
    try {
      Position? position;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        position =
            await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 5),
              ),
            );
      }

      if (position != null) {
        Location? matchedLocation = await _muslimRepo.reverseGeocoder(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (matchedLocation != null) {
          final localizedLoc = LocationArabicHelper.toArabicLocation(
            matchedLocation,
          );
          _currentLocation = localizedLoc;
          _displayName = '${localizedLoc.name}، ${localizedLoc.countryName}';
        } else {
          _currentLocation = Location(
            id: 0,
            name: 'موقعي الحالي',
            latitude: position.latitude,
            longitude: position.longitude,
            countryCode: '',
            countryName: '',
            hasFixedPrayerTime: false,
          );
          _displayName = 'موقعي الحالي';
        }
      } else {
        // Fallback to Cairo in Arabic
        _currentLocation = const Location(
          id: 1,
          name: 'القاهرة',
          latitude: 30.0444,
          longitude: 31.2357,
          countryCode: 'EG',
          countryName: 'مصر',
          hasFixedPrayerTime: false,
        );
        _displayName = 'القاهرة، مصر';
      }

      await _fetchPrayersForLocation(_currentLocation!);
    } catch (_) {
      // Fallback default
      _currentLocation = const Location(
        id: 1,
        name: 'القاهرة',
        latitude: 30.0444,
        longitude: 31.2357,
        countryCode: 'EG',
        countryName: 'مصر',
        hasFixedPrayerTime: false,
      );
      _displayName = 'القاهرة، مصر';
      await _fetchPrayersForLocation(_currentLocation!);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPrayersForLocation(Location location) async {
    final attribute = PrayerAttribute(
      calculationMethod: _selectedMethod,
      asrMethod: AsrMethod.shafii,
      higherLatitudeMethod: HigherLatitudeMethod.angleBased,
    );

    var prayers = await _muslimRepo.getPrayerTimes(
      location: location,
      date: DateTime.now(),
      attribute: attribute,
    );

    if (prayers != null) {
      prayers = EgyptDstHelper.adjustPrayerTimesForEgypt(
        prayer: prayers,
        location: location,
        date: DateTime.now(),
        mode: _egyptDstMode,
        additionalMinutesOffset: _manualMinutesOffset,
      );
    }

    if (mounted) {
      setState(() {
        _prayerTime = prayers;
      });
    }

    if (prayers != null) {
      await PrayerSchedulerService().scheduleUpcomingPrayers(prayers);
    }
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await _initPrayerTimes();
    }
  }

  _NextPrayerInfo _getNextPrayer() {
    if (_prayerTime == null) {
      return _NextPrayerInfo(name: '', time: DateTime.now(), isToday: true);
    }

    final prayers = [
      MapEntry('الفجر', _prayerTime!.fajr),
      MapEntry('الشروق', _prayerTime!.sunrise),
      MapEntry('الظهر', _prayerTime!.dhuhr),
      MapEntry('العصر', _prayerTime!.asr),
      MapEntry('المغرب', _prayerTime!.maghrib),
      MapEntry('العشاء', _prayerTime!.isha),
    ];

    for (final entry in prayers) {
      if (_now.isBefore(entry.value)) {
        return _NextPrayerInfo(
          name: entry.key,
          time: entry.value,
          isToday: true,
        );
      }
    }

    // After Isha, next prayer is tomorrow's Fajr
    final tomorrowFajr = _prayerTime!.fajr.add(const Duration(days: 1));
    return _NextPrayerInfo(name: 'الفجر', time: tomorrowFajr, isToday: false);
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00:00';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatHijriDate() {
    final hijri = HijriDate.fromDate(_now);
    return '${hijri.dayWeName}، ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';
  }

  String _formatCurrentDate() {
    const arabicMonths = [
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
    const arabicDays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    final dayName = arabicDays[_now.weekday - 1];
    final monthName = arabicMonths[_now.month - 1];
    return '$dayName، ${_now.day} $monthName ${_now.year} م';
  }

  void _showCitySearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return _CitySearchBottomSheet(
          muslimRepo: _muslimRepo,
          onLocationSelected: (location) {
            final localizedLoc = LocationArabicHelper.toArabicLocation(
              location,
            );
            setState(() {
              _currentLocation = localizedLoc;
              _displayName =
                  '${localizedLoc.name}، ${localizedLoc.countryName}';
            });
            _fetchPrayersForLocation(localizedLoc);
          },
        );
      },
    );
  }

  void _showCalculationAndDstDialog() {
    final methods = [
      MapEntry(CalculationMethod.egypt, 'الهيئة المصرية العامة للمساحة'),
      MapEntry(CalculationMethod.makkah, 'أم القرى، مكة المكرمة'),
      MapEntry(CalculationMethod.mwl, 'رابطة العالم الإسلامي'),
      MapEntry(CalculationMethod.karachi, 'جامعة العلوم الإسلامية، كراتشي'),
      MapEntry(CalculationMethod.isna, 'الجمعية الإسلامية لأمريكا الشمالية'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isSummer = EgyptDstHelper.isEgyptDst(_now);
            final isEgypt =
                _currentLocation != null &&
                EgyptDstHelper.isEgyptLocation(_currentLocation!);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
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
                            color: AppColors.textSecondary.withAlpha(80),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'إعدادات التوقيت وطريقة الحساب',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.primary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Egypt DST Section
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(40),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isSummer
                                      ? Icons.wb_sunny_rounded
                                      : Icons.ac_unit_rounded,
                                  color: isSummer
                                      ? Colors.orange.shade800
                                      : Colors.blue.shade800,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    'التوقيت الصيفي والشتوي في مصر',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSummer
                                        ? Colors.orange.withAlpha(35)
                                        : Colors.blue.withAlpha(35),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    isSummer ? 'صيفي (UTC+3)' : 'شتوي (UTC+2)',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isSummer
                                          ? (isDark
                                                ? Colors.orange.shade300
                                                : Colors.orange.shade900)
                                          : (isDark
                                                ? Colors.blue.shade300
                                                : Colors.blue.shade900),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'وفقاً للقانون المصري رقم 24 لسنة 2023: يبدأ التوقيت الصيفي الجمعة الأخيرة من أبريل وينتهي الخميس الأخير من أكتوبر (تقديم الساعة 60 دقيقة).',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 12.h),

                            // Modes selection
                            ...EgyptDstMode.values.map((mode) {
                              final isSelected = _egyptDstMode == mode;
                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    _egyptDstMode = mode;
                                  });
                                  setState(() {
                                    _egyptDstMode = mode;
                                  });
                                  if (_currentLocation != null) {
                                    _fetchPrayersForLocation(_currentLocation!);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10.r),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 6.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withAlpha(20)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary.withAlpha(
                                                120,
                                              ),
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mode.title,
                                              style: TextStyle(
                                                fontSize: 13.5.sp,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              mode.description,
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            if (!isEgypt) ...[
                              SizedBox(height: 6.h),
                              Text(
                                '* الموقع المحدد حالياً خارج مصر، لذا لن يتم تطبيق تعديل التوقيت الصيفي المصري تلقائياً.',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark
                                      ? Colors.red.shade300
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Calculation Method Section
                      Text(
                        'طريقة الحساب المعتمدة',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ...methods.map((entry) {
                        final isSelected = _selectedMethod == entry.key;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () {
                            setModalState(() {
                              _selectedMethod = entry.key;
                            });
                            setState(() {
                              _selectedMethod = entry.key;
                            });
                            if (_currentLocation != null) {
                              _fetchPrayersForLocation(_currentLocation!);
                            }
                          },
                        );
                      }),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final nextPrayer = _getNextPrayer();
    final timeRemaining = nextPrayer.time.difference(_now);

    final prayerItems = [
      _PrayerItemData(
        name: 'الفجر',
        time: _prayerTime?.fajr,
        icon: Icons.nightlight_round,
      ),
      _PrayerItemData(
        name: 'الشروق',
        time: _prayerTime?.sunrise,
        icon: Icons.wb_twilight_rounded,
      ),
      _PrayerItemData(
        name: 'الظهر',
        time: _prayerTime?.dhuhr,
        icon: Icons.wb_sunny_rounded,
      ),
      _PrayerItemData(
        name: 'العصر',
        time: _prayerTime?.asr,
        icon: Icons.sunny_snowing,
      ),
      _PrayerItemData(
        name: 'المغرب',
        time: _prayerTime?.maghrib,
        icon: Icons.wb_twilight_outlined,
      ),
      _PrayerItemData(
        name: 'العشاء',
        time: _prayerTime?.isha,
        icon: Icons.bedtime_rounded,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          right: 16.w,
          left: 16.w,
          top: 12.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        ),
        child: Column(
          children: [
            // Top Bar with Location and Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _showCitySearchDialog,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 150.w),
                          child: Text(
                            _displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                          size: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      tooltip: 'أصوات الأذان والتنبيهات',
                      onPressed: () => AdhanSettingsBottomSheet.show(context),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                      tooltip: 'تحديد موقعي',
                      onPressed: _requestLocationPermission,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                      tooltip: 'إعدادات التوقيت وطريقة الحساب',
                      onPressed: _showCalculationAndDstDialog,
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Next Prayer Banner Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, const Color(0xFF6D4C41)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  Text(
                    _formatHijriDate(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatCurrentDate(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: _showCalculationAndDstDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withAlpha(50),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            EgyptDstHelper.isEgyptDst(_now)
                                ? Icons.wb_sunny_rounded
                                : Icons.ac_unit_rounded,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            EgyptDstHelper.getStatusBadgeText(
                              _now,
                              _egyptDstMode,
                            ),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.tune_rounded,
                            size: 14.sp,
                            color: Colors.white.withAlpha(200),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'الصلاة القادمة: ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      Text(
                        nextPrayer.name,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: 220.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(40),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.amber.shade200,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'متبقي ${_formatDuration(timeRemaining)}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // List of 6 Prayers
            ...prayerItems.map((item) {
              final isNext = item.name == nextPrayer.name;
              final isPassed = item.time != null && _now.isAfter(item.time!);

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: isNext
                      ? AppColors.primary.withAlpha(35)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isNext
                        ? AppColors.primary
                        : AppColors.primary.withAlpha(35),
                    width: isNext ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: isNext
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: isNext ? AppColors.onPrimary : AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: isNext
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isPassed && !isNext
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                          ),
                          if (isNext)
                            Text(
                              'الصلاة القادمة',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.time != null ? _formatTime(item.time!) : '--:--',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: isNext
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isPassed && !isNext
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                        ),
                        if (item.name != 'الشروق') ...[
                          SizedBox(width: 8.w),
                          IconButton(
                            icon: Icon(
                              _audioService.isPrayerAlertEnabled(item.name)
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color:
                                  _audioService.isPrayerAlertEnabled(item.name)
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withAlpha(100),
                              size: 24.sp,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'تنبيه الأذان',
                            onPressed: () {
                              final enabled = _audioService
                                  .isPrayerAlertEnabled(item.name);
                              _audioService.togglePrayerAlert(
                                item.name,
                                !enabled,
                              );
                              if (_prayerTime != null) {
                                PrayerSchedulerService()
                                    .scheduleUpcomingPrayers(_prayerTime!);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerInfo {
  final String name;
  final DateTime time;
  final bool isToday;

  _NextPrayerInfo({
    required this.name,
    required this.time,
    required this.isToday,
  });
}

class _PrayerItemData {
  final String name;
  final DateTime? time;
  final IconData icon;

  _PrayerItemData({required this.name, required this.time, required this.icon});
}

class _CitySearchBottomSheet extends StatefulWidget {
  final MuslimRepository muslimRepo;
  final ValueChanged<Location> onLocationSelected;

  const _CitySearchBottomSheet({
    required this.muslimRepo,
    required this.onLocationSelected,
  });

  @override
  State<_CitySearchBottomSheet> createState() => _CitySearchBottomSheetState();
}

class _CitySearchBottomSheetState extends State<_CitySearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'الكل';
  List<Location> _displayList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  void _loadCities() {
    final cities = LocationDataHelper.searchCities(
      query: _searchController.text,
      selectedRegion: _selectedRegion,
    );
    _displayList = cities.map((c) => c.toLocation()).toList();
  }

  void _performSearch(String query) async {
    final localMatches = LocationDataHelper.searchCities(
      query: query,
      selectedRegion: _selectedRegion,
    );

    if (localMatches.isNotEmpty || query.trim().length < 2) {
      setState(() {
        _displayList = localMatches.map((c) => c.toLocation()).toList();
        _isSearching = false;
      });
      return;
    }

    // Fallback: search external DB if local dataset has no match
    setState(() => _isSearching = true);
    try {
      final remoteResults = await widget.muslimRepo.searchLocations(
        locationName: query.trim(),
      );
      if (mounted) {
        setState(() {
          _displayList = remoteResults
              .map((loc) => LocationArabicHelper.toArabicLocation(loc))
              .toList();
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _displayList = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 12.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(80),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر المدينة',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${_displayList.length} مكان',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _searchController,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم المدينة أو المحافظة...',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.primary),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.primary.withAlpha(15),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 36.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: LocationDataHelper.regions.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final region = LocationDataHelper.regions[index];
                  final isSelected = _selectedRegion == region;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18.r),
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                        _performSearch(_searchController.text);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          region,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
            if (_isSearching)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              Expanded(
                child: _displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_rounded,
                              size: 48.sp,
                              color: AppColors.primary.withAlpha(100),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'لم يتم العثور على مدن مطابقة',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'جرّب البحث باسم آخر أو اختيار تصنيف مختلف',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _displayList.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final loc = _displayList[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            leading: Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_city_rounded,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                            ),
                            title: Text(
                              loc.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            subtitle: Text(
                              loc.countryName,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 14.sp,
                              color: AppColors.primary.withAlpha(120),
                            ),
                            onTap: () {
                              widget.onLocationSelected(loc);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
