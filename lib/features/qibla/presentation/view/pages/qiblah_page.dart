import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/features/qibla/core/qibla_sensor_helper.dart';
import 'package:alhuda/features/qibla/presentation/view/widgets/qibla_widget.dart';
import 'package:alhuda/features/qibla/presentation/view/widgets/qiblah_offline_view.dart';

enum QiblaMode {
  compass, // البوصلة (المستشعر المغناطيسي)
  sunAndMoon, // طريقة الشمس والقمر (الفلكية)
}

/// شاشة تحديد اتجاه القبلة:
/// تفحص وجود مستشعر البوصلة (Magnetometer) في الهاتف:
/// - إذا كان التليفون فيه sensor: تعرض البوصلة المباشرة افتراضياً، مع إمكانية التبديل لطريقة الشمس والقمر.
/// - إذا كان التليفون مفيهوش sensor: تعرض طريقة الشمس والقمر الفلكية تلقائياً مع تنبيه توضيحي.
class QiblahPage extends StatefulWidget {
  final bool hasScaffold;

  const QiblahPage({super.key, this.hasScaffold = true});

  @override
  State<QiblahPage> createState() => _QiblahPageState();
}

class _QiblahPageState extends State<QiblahPage> {
  bool _isChecking = true;
  bool _hasSensor = false;
  QiblaMode _currentMode = QiblaMode.compass;

  @override
  void initState() {
    super.initState();
    _checkDeviceSensor();
  }

  Future<void> _checkDeviceSensor() async {
    final hasSensor = await QiblaSensorHelper.hasCompassSensor();

    if (mounted) {
      setState(() {
        _hasSensor = hasSensor;
        _isChecking = false;
        // إذا كان التليفون فيه sensor اعرض البوصلة، وإذا مفيهوش sensor اعرض طريقة الشمس والقمر
        _currentMode = hasSensor ? QiblaMode.compass : QiblaMode.sunAndMoon;
      });
    }
  }

  void _showSensorUnavailableSnackbar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 10.w),
              const Expanded(
                child: Text(
                  'عفواً، هاتفك لا يحتوي على مستشعر بوصلة مغناطيسي (Magnetometer). تم تفعيل طريقة الشمس والقمر الفلكية لتعمل بدقة 100% بدون مستشعر.',
                  style: TextStyle(fontSize: 13, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.amber.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              mode: QiblaMode.compass,
              title: 'البوصلة المباشرة',
              icon: Icons.explore_rounded,
              isSupported: _hasSensor,
              badgeText: _hasSensor ? 'المستشعر' : 'غير مدعوم',
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: _buildModeTab(
              mode: QiblaMode.sunAndMoon,
              title: 'طريقة الشمس والقمر',
              icon: Icons.wb_sunny_rounded,
              isSupported: true,
              badgeText: 'فلكي أوفلاين',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required QiblaMode mode,
    required String title,
    required IconData icon,
    required bool isSupported,
    required String badgeText,
  }) {
    final isSelected = _currentMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (!isSupported) {
            _showSensorUnavailableSnackbar();
            return;
          }
          if (_currentMode != mode) {
            setState(() {
              _currentMode = mode;
            });
          }
        },
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(50),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16.sp,
                    color: isSelected
                        ? Colors.white
                        : (isSupported ? AppColors.primary : Colors.grey),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isSupported
                              ? AppColors.textPrimary
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(40)
                      : (isSupported
                          ? AppColors.primary.withAlpha(20)
                          : Colors.grey.withAlpha(30)),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isSupported
                            ? AppColors.primary
                            : Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSensorBanner() {
    return Container(
      margin: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withAlpha(20),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.amber.shade800.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors_off_rounded,
              color: Colors.amber.shade900, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'الهاتف لا يحتوي على مستشعر بوصلة مغناطيسي • تم تفعيل طريقة الشمس والقمر الفلكية تلقائياً ☀️🌙',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isChecking) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              'جاري فحص مستشعر البوصلة في الهاتف...',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildModeSwitcher(),
        if (!_hasSensor) _buildNoSensorBanner(),
        Expanded(
          child: _currentMode == QiblaMode.compass && _hasSensor
              ? const QiblaWidget()
              : const QiblahOfflineView(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Directionality(
      textDirection: TextDirection.rtl,
      child: _buildBody(),
    );

    if (!widget.hasScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'القبلة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: content,
    );
  }
}
