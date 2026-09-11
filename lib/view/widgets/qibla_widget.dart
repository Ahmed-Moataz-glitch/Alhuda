import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:alhuda/model/city_locations_data.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qibla/qibla.dart' as qibla_math;

/// مساعد حسابات القبلة والاتجاهات
class QiblaHelper {
  static const double defaultLat = 30.0444; // Cairo
  static const double defaultLng = 31.2357;

  /// اسم الاتجاه الجغرافي بالعربية بناءً على الزاوية
  static String getArabicDirection(double bearing) {
    final b = (bearing % 360 + 360) % 360;
    if (b >= 337.5 || b < 22.5) return 'الشمال';
    if (b >= 22.5 && b < 67.5) return 'الشمال الشرقي';
    if (b >= 67.5 && b < 112.5) return 'الشرق';
    if (b >= 112.5 && b < 157.5) return 'الجنوب الشرقي';
    if (b >= 157.5 && b < 202.5) return 'الجنوب';
    if (b >= 202.5 && b < 247.5) return 'الجنوب الغربي';
    if (b >= 247.5 && b < 292.5) return 'الغرب';
    return 'الشمال الغربي';
  }

  /// حساب فرق الزاوية بين اتجاهين (0 إلى 180 درجة)
  static double calculateDifference(double heading, double targetAngle) {
    return ((heading - targetAngle + 180) % 360 - 180).abs();
  }

  /// التحقق مما إذا كان الاتجاه يواجه القبلة ضمن نطاق التسامح المحدد
  static bool isFacingQibla(double heading, double qiblaAngle,
      {double threshold = 4.0}) {
    return calculateDifference(heading, qiblaAngle) <= threshold;
  }
}

class QiblaWidget extends StatefulWidget {
  const QiblaWidget({super.key});

  @override
  State<QiblaWidget> createState() => _QiblaWidgetState();
}

class _QiblaWidgetState extends State<QiblaWidget>
    with SingleTickerProviderStateMixin {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  // قناة الاتصال الأصلية لفحص وجود مستشعر مغناطيسي حقيقي
  static const MethodChannel _customSensorChannel =
      MethodChannel('com.example.alhuda/sensors');

  // متحكم حركة الطفو الانسيابي للبوصلة العائمة (Floating Compass)
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  // اشتراك تيار موقع وتوجيه الـ GPS الحي
  StreamSubscription<Position>? _positionStreamSubscription;

  // هل يدعم الجهاز مستشعر البوصلة المغناطيسي الحقيقي؟ (null = جاري الفحص)
  bool? _hasHardwareSensor;

  // هل تم تفعيل وضع بوصلة GPS العائمة (بدون مستشعر مغناطيسي)؟
  bool _isSensorlessMode = false;

  // الإحداثيات الحالية (افتراضياً القاهرة حتى يتم جلب الموقع أو اختيار مدينة)
  double? _currentLat;
  double? _currentLng;
  String _locationTitle = 'جاري تحديد الموقع...';
  double? _distanceToKaabaKm;

  // زاوية تدوير البوصلة في الوضع اليدوي (0 = الشمال في الأعلى)
  double _manualHeading = 0.0;
  double _panStartTouchAngle = 0.0;
  double _panStartHeading = 0.0;

  // حالة خدمة الموقع
  LocationStatus? _lastLocationStatus;

  @override
  void initState() {
    super.initState();

    // تشغيل أنيميشن الطفو الانسيابي للبوصلة
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _checkSensorSupport();
    _checkLocationStatus();
    _fetchCurrentPosition();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _positionStreamSubscription?.cancel();
    _locationStreamController.close();
    FlutterQiblah().dispose();
    super.dispose();
  }

  /// فحص دعم مستشعر البوصلة المغناطيسي الحقيقي (Magnetometer)
  Future<void> _checkSensorSupport() async {
    try {
      bool hasMagnetometer = false;
      if (Platform.isAndroid) {
        try {
          final nativeResult = await _customSensorChannel
              .invokeMethod<bool>('hasMagnetometer');
          if (nativeResult != null) {
            hasMagnetometer = nativeResult;
          } else {
            final support =
                await FlutterQiblah.androidDeviceSensorSupport();
            hasMagnetometer = support == true;
          }
        } catch (_) {
          final support =
              await FlutterQiblah.androidDeviceSensorSupport();
          hasMagnetometer = support == true;
        }
      } else {
        // في نظام iOS أجهزة الآيفون تحتوي بوصلة قياسية
        hasMagnetometer = true;
      }

      if (mounted) {
        setState(() {
          _hasHardwareSensor = hasMagnetometer;
          // في حال عدم توفر مستشعر مغناطيسي، يتم تفعيل بوصلة GPS العائمة فوراً
          if (!hasMagnetometer) {
            _isSensorlessMode = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasHardwareSensor = false;
          _isSensorlessMode = true;
        });
      }
    }
  }

  /// زاوية القبلة المحسوبة جغرافياً
  double get _calculatedQiblaAngle {
    final lat = _currentLat ?? QiblaHelper.defaultLat;
    final lng = _currentLng ?? QiblaHelper.defaultLng;
    return qibla_math.qiblaAngle(lat, lng);
  }

  /// المسافة إلى الكعبة المحسوبة بالكيلومتر
  double get _calculatedDistanceKm {
    if (_distanceToKaabaKm != null) return _distanceToKaabaKm!;
    final lat = _currentLat ?? QiblaHelper.defaultLat;
    final lng = _currentLng ?? QiblaHelper.defaultLng;
    return qibla_math.distanceKm(
      lat,
      lng,
      qibla_math.kaabaLat,
      qibla_math.kaabaLng,
    );
  }

  Future<void> _fetchCurrentPosition() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always ||
          hasPermission == LocationPermission.whileInUse) {
        final position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            );
        if (mounted) {
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;
            _locationTitle = 'موقعك الحالي (GPS)';
            _distanceToKaabaKm = qibla_math.distanceKm(
              position.latitude,
              position.longitude,
              qibla_math.kaabaLat,
              qibla_math.kaabaLng,
            );
          });
          _startPositionStream();
        }
      } else {
        if (mounted && _currentLat == null) {
          setState(() {
            _locationTitle = 'القاهرة (افتراضي)';
          });
        }
      }
    } catch (_) {
      if (mounted && _currentLat == null) {
        setState(() {
          _locationTitle = 'القاهرة (افتراضي)';
        });
      }
    }
  }

  /// الاستماع لتيار موقع الـ GPS المباشر للحصول على الإحداثيات وزاوية التحرك الفعلي
  void _startPositionStream() {
    _positionStreamSubscription?.cancel();
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      );
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          if (!mounted) return;
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;
            _locationTitle = 'موقعك الحالي (GPS)';
            _distanceToKaabaKm = qibla_math.distanceKm(
              position.latitude,
              position.longitude,
              qibla_math.kaabaLat,
              qibla_math.kaabaLng,
            );
            // إذا كان المستخدم يتحرك، فإن الـ GPS يزودنا باتجاه السير الفعلي (heading)
            if (position.heading > 0 && position.speed > 0.4) {
              _manualHeading = position.heading;
            }
          });
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  Future<void> _checkLocationStatus() async {
    try {
      final locationStatus = await FlutterQiblah.checkLocationStatus();
      _lastLocationStatus = locationStatus;
      if (locationStatus.enabled &&
          locationStatus.status == LocationPermission.denied) {
        await FlutterQiblah.requestPermissions();
        final updatedStatus = await FlutterQiblah.checkLocationStatus();
        _lastLocationStatus = updatedStatus;
        _locationStreamController.sink.add(updatedStatus);
      } else {
        _locationStreamController.sink.add(locationStatus);
      }

      if (locationStatus.enabled &&
          (locationStatus.status == LocationPermission.always ||
              locationStatus.status == LocationPermission.whileInUse)) {
        await _fetchCurrentPosition();
      }
    } catch (e) {
      _locationStreamController.sink.add(
        const LocationStatus(false, LocationPermission.denied),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا اختار المستخدم وضع الحساب الجغرافي أو كان المستشعر غير مدعوم في الجهاز
    if (_isSensorlessMode || _hasHardwareSensor == false) {
      return _buildSensorlessView();
    }

    // إذا كان الجهاز يدعم المستشعر والمستخدم في وضع البوصلة الحية
    return StreamBuilder<LocationStatus>(
      stream: _locationStreamController.stream,
      builder: (context, locationSnapshot) {
        final status = locationSnapshot.data ?? _lastLocationStatus;

        if (status == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!status.enabled) {
          return _buildLocationDisabledCard(
            title: 'خدمة الموقع غير مفعلة',
            message:
                'لتحديد اتجاه القبلة بدقة عبر البوصلة الحية، يرجى تفعيل الـ GPS أو التبديل إلى وضع الحساب الجغرافي بدون مستشعر.',
          );
        }

        switch (status.status) {
          case LocationPermission.always:
          case LocationPermission.whileInUse:
            return _buildLiveSensorView();

          case LocationPermission.denied:
            return _buildPermissionRequestCard(
              title: 'إذن الموقع مطلوب للبوصلة',
              message:
                  'يحتاج تطبيق الهدى إذن الوصول لموقعك لحساب القبلة المباشرة. يمكنك أيضاً استخدام وضع الحساب الجغرافي أو اختيار مدينتك يدوياً.',
              actionText: 'منح الإذن',
              onAction: () async {
                await FlutterQiblah.requestPermissions();
                await _checkLocationStatus();
              },
            );

          case LocationPermission.deniedForever:
            return _buildPermissionRequestCard(
              title: 'تم رفض إذن الموقع',
              message:
                  'يمكنك تفعيل الإذن من إعدادات الهاتف، أو الاستمتاع بالقبلة الآن عبر وضع الحساب الجغرافي باختيار مدينتك.',
              actionText: 'فتح الإعدادات',
              onAction: () async {
                await Geolocator.openAppSettings();
                await _checkLocationStatus();
              },
            );

          default:
            return _buildSensorlessView();
        }
      },
    );
  }

  // ===========================================================================
  // واجهة وضع الحساب الجغرافي (تعمل 100% بدون أي مستشعر في الجهاز)
  // ===========================================================================
  Widget _buildSensorlessView() {
    final qiblaAngle = _calculatedQiblaAngle;
    final arabicDirection = QiblaHelper.getArabicDirection(qiblaAngle);
    final distanceKm = _calculatedDistanceKm;
    final isFacing =
        QiblaHelper.isFacingQibla(_manualHeading, qiblaAngle, threshold: 5.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Column(
        children: [
          // شريط التحكم بالوضع والموقع
          _buildTopBar(isSensorless: true),
          SizedBox(height: 12.h),

          // شارة الحالة (التوافق مع القبلة)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isFacing
                  ? const Color(0xFF2E7D32).withAlpha(35)
                  : AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: isFacing
                    ? const Color(0xFF2E7D32)
                    : AppColors.primary,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFacing
                      ? Icons.check_circle_rounded
                      : Icons.explore_rounded,
                  color: isFacing
                      ? const Color(0xFF2E7D32)
                      : AppColors.primary,
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    isFacing
                        ? 'أنت باتجاه القبلة الآن 🕋'
                        : 'اتجاه القبلة: ${qiblaAngle.toInt()}° ($arabicDirection) • الإبرة العائمة تشير للكعبة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isFacing
                          ? const Color(0xFF2E7D32)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // منطقة البوصلة العائمة التفاعلية (Floating Compass)
          Center(
            child: SizedBox(
              width: 280.w,
              height: 280.w,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final centerOffset = Offset(140.w, 140.w);
                  final touchOffset = details.localPosition - centerOffset;
                  _panStartTouchAngle =
                      math.atan2(touchOffset.dy, touchOffset.dx) * 180 / math.pi;
                  _panStartHeading = _manualHeading;
                },
                onPanUpdate: (details) {
                  final centerOffset = Offset(140.w, 140.w);
                  final touchOffset = details.localPosition - centerOffset;
                  final currentTouchAngle =
                      math.atan2(touchOffset.dy, touchOffset.dx) * 180 / math.pi;
                  final angleDiff = currentTouchAngle - _panStartTouchAngle;
                  final newHeading =
                      (_panStartHeading - angleDiff + 360) % 360;

                  final wasFacing = QiblaHelper.isFacingQibla(
                      _manualHeading, qiblaAngle,
                      threshold: 5.0);
                  final isNowFacing = QiblaHelper.isFacingQibla(
                      newHeading, qiblaAngle,
                      threshold: 5.0);

                  if (!wasFacing && isNowFacing) {
                    HapticFeedback.mediumImpact();
                  }

                  setState(() {
                    _manualHeading = newHeading;
                  });
                },
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    // حركة طفو انسيابية هادئة لمحاكاة استقرار إبرة البوصلة في سائل (Floating Liquid Effect)
                    final floatSway = _floatingAnimation.value * 1.5;
                    final floatDy =
                        math.sin(_floatingAnimation.value * math.pi) * 3.0;

                    return Transform.translate(
                      offset: Offset(0, floatDy),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow with breathing float effect
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 270.w,
                            height: 270.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isFacing
                                      ? const Color(0xFF2E7D32).withAlpha(
                                          70 +
                                              (_floatingAnimation.value.abs() *
                                                      25)
                                                  .toInt())
                                      : AppColors.primary.withAlpha(25 +
                                          (_floatingAnimation.value.abs() * 15)
                                              .toInt()),
                                  blurRadius: isFacing ? 26 : 14,
                                  spreadRadius: isFacing ? 6 : 2,
                                ),
                              ],
                            ),
                          ),

                          // Rotating Compass Dial with float sway
                          Transform.rotate(
                            angle:
                                ((_manualHeading + floatSway) * (math.pi / 180) * -1),
                            child: CustomPaint(
                              size: Size(260.w, 260.w),
                              painter: CompassDialPainter(
                                primaryColor: AppColors.primary,
                                isFacingQibla: isFacing,
                              ),
                            ),
                          ),

                          // Floating Qibla Needle pointing towards Mecca
                          Transform.rotate(
                            angle: (((qiblaAngle - _manualHeading) + floatSway) *
                                (math.pi / 180)),
                            child: CustomPaint(
                              size: Size(260.w, 260.w),
                              painter: QiblaNeedlePainter(
                                needleColor: isFacing
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC59B27),
                                isFacingQibla: isFacing,
                              ),
                            ),
                          ),

                          // Center Pivot Point with Kaaba icon
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFacing
                                    ? const Color(0xFF2E7D32)
                                    : AppColors.primary,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '🕋',
                                style: TextStyle(fontSize: 20.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // تلميح تفاعلي
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 16.sp, color: AppColors.primary.withAlpha(180)),
              SizedBox(width: 6.w),
              Text(
                'البوصلة عائمة وتتحرك بالـ GPS، ويمكنك تدوير القرص يدوياً باللمس',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primary.withAlpha(200),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // أزرار التوجيه والمحاذاة السريعة
          _buildQuickPresetButtons(qiblaAngle),
          SizedBox(height: 16.h),

          // بطاقة التفاصيل والأرقام
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withAlpha(80),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn(
                    label: 'اتجاه القبلة',
                    value: '${qiblaAngle.toInt()}°',
                    subtitle: arabicDirection,
                    icon: Icons.navigation_rounded,
                  ),
                  Container(
                    height: 44.h,
                    width: 1,
                    color: AppColors.primary.withAlpha(60),
                  ),
                  _buildInfoColumn(
                    label: 'توجيه البوصلة',
                    value: '${_manualHeading.toInt()}°',
                    subtitle: QiblaHelper.getArabicDirection(_manualHeading),
                    icon: Icons.rotate_right_rounded,
                  ),
                  Container(
                    height: 44.h,
                    width: 1,
                    color: AppColors.primary.withAlpha(60),
                  ),
                  _buildInfoColumn(
                    label: 'المسافة للكعبة',
                    value: '${distanceKm.toStringAsFixed(0)} كم',
                    subtitle: 'مسافة مباشرة',
                    icon: Icons.place_rounded,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // دليل إرشادي لكيفية معرفة القبلة بدون مستشعر
          _buildSensorlessGuideCard(qiblaAngle, arabicDirection),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // ===========================================================================
  // واجهة وضع المستشعر التلقائي (عند توفر Magnetometer في الهاتف)
  // ===========================================================================
  Widget _buildLiveSensorView() {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16.h),
                Text(
                  'جاري معايرة البوصلة وتحديد القبلة...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSensorlessMode = true;
                    });
                  },
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('التبديل إلى بوصلة GPS العائمة'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildMessageCard(
            icon: Icons.sensors_off_rounded,
            title: 'تعذر قراءة المستشعر',
            message:
                'حدث خطأ في قراءة مستشعر البوصلة (${snapshot.error}). يمكنك المتابعة عبر وضع بوصلة GPS العائمة الدقيقة.',
            actionText: 'استخدام بوصلة GPS العائمة',
            onAction: () {
              setState(() {
                _isSensorlessMode = true;
              });
            },
          );
        }

        final qiblahDirection = snapshot.data;
        if (qiblahDirection == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final direction = qiblahDirection.direction;
        final qiblah = qiblahDirection.qiblah;
        final offset = qiblahDirection.offset;

        final diff = ((direction - offset + 180) % 360 - 180).abs();
        final isFacingQibla = diff <= 4.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 12.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
          ),
          child: Column(
            children: [
              _buildTopBar(isSensorless: false),
              SizedBox(height: 12.h),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isFacingQibla
                      ? const Color(0xFF2E7D32).withAlpha(35)
                      : AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(
                    color: isFacingQibla
                        ? const Color(0xFF2E7D32)
                        : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFacingQibla
                          ? Icons.check_circle_rounded
                          : Icons.explore_rounded,
                      color: isFacingQibla
                          ? const Color(0xFF2E7D32)
                          : AppColors.primary,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        isFacingQibla
                            ? 'أنت باتجاه القبلة الآن 🕋'
                            : 'قم بتدوير الهاتف حتى تتطابق الإبرة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isFacingQibla
                              ? const Color(0xFF2E7D32)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              SizedBox(
                width: 280.w,
                height: 280.w,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    final floatDy =
                        math.sin(_floatingAnimation.value * math.pi) * 2.0;

                    return Transform.translate(
                      offset: Offset(0, floatDy),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 270.w,
                            height: 270.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isFacingQibla
                                      ? const Color(0xFF2E7D32).withAlpha(70 +
                                          (_floatingAnimation.value.abs() * 20)
                                              .toInt())
                                      : AppColors.primary.withAlpha(25 +
                                          (_floatingAnimation.value.abs() * 10)
                                              .toInt()),
                                  blurRadius: isFacingQibla ? 25 : 12,
                                  spreadRadius: isFacingQibla ? 6 : 1,
                                ),
                              ],
                            ),
                          ),

                          Transform.rotate(
                            angle: (direction * (math.pi / 180) * -1),
                            child: CustomPaint(
                              size: Size(260.w, 260.w),
                              painter: CompassDialPainter(
                                primaryColor: AppColors.primary,
                                isFacingQibla: isFacingQibla,
                              ),
                            ),
                          ),

                          Transform.rotate(
                            angle: (qiblah * (math.pi / 180) * -1),
                            child: CustomPaint(
                              size: Size(260.w, 260.w),
                              painter: QiblaNeedlePainter(
                                needleColor: isFacingQibla
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC59B27),
                                isFacingQibla: isFacingQibla,
                              ),
                            ),
                          ),

                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFacingQibla
                                    ? const Color(0xFF2E7D32)
                                    : AppColors.primary,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '🕋',
                                style: TextStyle(fontSize: 20.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(80),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        label: 'اتجاه القبلة',
                        value: '${offset.toInt()}°',
                        subtitle: QiblaHelper.getArabicDirection(offset),
                        icon: Icons.navigation_rounded,
                      ),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: AppColors.primary.withAlpha(60),
                      ),
                      _buildInfoColumn(
                        label: 'اتجاه الهاتف',
                        value: '${direction.toInt()}°',
                        subtitle: QiblaHelper.getArabicDirection(direction),
                        icon: Icons.phone_android_rounded,
                      ),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: AppColors.primary.withAlpha(60),
                      ),
                      _buildInfoColumn(
                        label: 'المسافة للكعبة',
                        value: '${_calculatedDistanceKm.toStringAsFixed(0)} كم',
                        subtitle: 'مسافة مباشرة',
                        icon: Icons.place_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'لأفضل دقة، ضع الهاتف بشكل أفقي مستوٍ وابتعد عن الأجهزة الإلكترونية والمعادن.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.primary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // المكونات الفرعية المشتركة
  // ===========================================================================

  Widget _buildTopBar({required bool isSensorless}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withAlpha(40)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _showCityPickerBottomSheet,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 6.w),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'اضغط لتغيير المدينة',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.primary.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_hasHardwareSensor == true)
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isSensorlessMode = !_isSensorlessMode;
                  });
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSensorless
                        ? const Color(0xFFC59B27).withAlpha(30)
                        : AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSensorless
                          ? const Color(0xFFC59B27)
                          : AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSensorless
                            ? Icons.architecture_rounded
                            : Icons.sensors_rounded,
                        size: 15.sp,
                        color: isSensorless
                            ? const Color(0xFFC59B27)
                            : AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isSensorless ? 'بوصلة GPS العائمة' : 'مستشعر تلقائي',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isSensorless
                              ? const Color(0xFFC59B27)
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withAlpha(25),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withAlpha(120),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gps_fixed_rounded,
                      size: 14.sp,
                      color: const Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'بوصلة GPS العائمة',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPresetButtons(double qiblaAngle) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPresetChip(
            title: 'محاذاة للقبلة 🕋',
            icon: Icons.my_location_rounded,
            isSelected: QiblaHelper.isFacingQibla(_manualHeading, qiblaAngle),
            isHighlighted: true,
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _manualHeading = qiblaAngle;
              });
            },
          ),
          SizedBox(width: 8.w),
          _buildPresetChip(
            title: 'الشمال (0°)',
            icon: Icons.arrow_upward_rounded,
            isSelected: _manualHeading == 0.0,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _manualHeading = 0.0;
              });
            },
          ),
          SizedBox(width: 8.w),
          _buildPresetChip(
            title: 'الشرق (90°)',
            icon: Icons.east_rounded,
            isSelected: (_manualHeading - 90).abs() < 2,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _manualHeading = 90.0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String title,
    required IconData icon,
    required bool isSelected,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    final activeColor =
        isHighlighted ? const Color(0xFF2E7D32) : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.primary.withAlpha(60),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            SizedBox(width: 4.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorlessGuideCard(double qiblaAngle, String arabicDirection) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: const Color(0xFFC59B27), size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'كيف تعمل بوصلة GPS العائمة بدون مستشعر؟',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _buildGuideStep(
              number: '١',
              title: 'تحديد القبلة عبر GPS:',
              description:
                  'يحسب التطبيق إحداثيات موقعك بالأقمار الصناعية وزاوية الكعبة المشرفة بدقة ($arabicDirection بزاوية ${qiblaAngle.toInt()}°)، وتتحدث البوصلة تلقائياً عند مسيرك.',
            ),
            SizedBox(height: 8.h),
            _buildGuideStep(
              number: '٢',
              title: 'الإبرة العائمة الذكية:',
              description:
                  'تتحرك الإبرة الذهبية 🕋 بحركة عائمة انسيابية لتشاور على اتجاه القبلة، مع إمكانية تدوير القرص يدوياً باللمس.',
            ),
            SizedBox(height: 8.h),
            _buildGuideStep(
              number: '٣',
              title: 'المحاذاة المباشرة:',
              description:
                  'اضغط زر (محاذاة للقبلة 🕋) لتطابق واجهة الهاتف مباشرة مع اتجاه القبلة، وعند التطابق يضيء القرص باللون الأخضر.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.black.withAlpha(200),
                height: 1.4,
                fontFamily: 'Almarai',
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCityPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CitySelectionModal(
          onCitySelected: (city) {
            setState(() {
              _currentLat = city.latitude;
              _currentLng = city.longitude;
              _locationTitle = '${city.nameAr} (${city.countryAr})';
              _distanceToKaabaKm = qibla_math.distanceKm(
                city.latitude,
                city.longitude,
                qibla_math.kaabaLat,
                qibla_math.kaabaLng,
              );
            });
            Navigator.pop(context);
          },
          onUseGps: () async {
            Navigator.pop(context);
            await _checkLocationStatus();
            await _fetchCurrentPosition();
          },
        );
      },
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.primary.withAlpha(180),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.primary.withAlpha(150),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationDisabledCard({
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withAlpha(90)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 48.sp, color: AppColors.primary),
              SizedBox(height: 14.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.black.withAlpha(180),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 18.h),
              ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  await _checkLocationStatus();
                },
                icon: const Icon(Icons.settings_rounded),
                label: const Text('تفعيل خدمة الموقع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isSensorlessMode = true;
                  });
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('استخدام وضع الحساب الجغرافي بدون GPS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequestCard({
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withAlpha(90)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 48.sp, color: AppColors.primary),
              SizedBox(height: 14.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.black.withAlpha(180),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 18.h),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(actionText),
              ),
              SizedBox(height: 8.h),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isSensorlessMode = true;
                  });
                },
                icon: const Icon(Icons.location_city_rounded),
                label: const Text('المتابعة باختيار مدينتي يدوياً'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withAlpha(90)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48.sp, color: AppColors.primary),
              SizedBox(height: 14.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.black.withAlpha(180),
                  height: 1.5,
                ),
              ),
              if (actionText != null && onAction != null) ...[
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// نافذة منبثقة لاختيار المدينة يدوياً
class _CitySelectionModal extends StatefulWidget {
  final ValueChanged<AppCity> onCitySelected;
  final VoidCallback onUseGps;

  const _CitySelectionModal({
    required this.onCitySelected,
    required this.onUseGps,
  });

  @override
  State<_CitySelectionModal> createState() => _CitySelectionModalState();
}

class _CitySelectionModalState extends State<_CitySelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  List<AppCity> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = LocationDataHelper.allCities.take(40).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredCities = LocationDataHelper.allCities.take(40).toList();
      } else {
        _filteredCities = LocationDataHelper.searchCities(query: query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(100),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 12.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر مدينتك لحساب القبلة',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: AppColors.primary.withAlpha(60)),
                ),
                tileColor: AppColors.primary.withAlpha(15),
                leading: Icon(Icons.my_location_rounded, color: AppColors.primary),
                title: Text(
                  'استخدام موقع GPS الحالي',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                subtitle: Text(
                  'جلب الإحداثيات تلقائياً عبر القمر الصناعي',
                  style: TextStyle(fontSize: 11.sp),
                ),
                onTap: widget.onUseGps,
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TextField(
                controller: _searchController,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم المدينة أو المحافظة...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary.withAlpha(60)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary.withAlpha(60)),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _filteredCities.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد مدينة مطابقة للبحث',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primary.withAlpha(180),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        return ListTile(
                          leading: Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                city.countryCode,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            city.nameAr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${city.countryAr} • ${city.nameEn}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.black.withAlpha(150),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14),
                          onTap: () => widget.onCitySelected(city),
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

/// Custom painter for the rotating compass dial with cardinal points and ticks
class CompassDialPainter extends CustomPainter {
  final Color primaryColor;
  final bool isFacingQibla;

  CompassDialPainter({
    required this.primaryColor,
    required this.isFacingQibla,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle
    final outerCirclePaint = Paint()
      ..color = primaryColor.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, outerCirclePaint);

    // Inner dial background
    final dialBgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, dialBgPaint);

    // Minor and major tick marks
    final majorTickPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = primaryColor.withAlpha(80)
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i += 5) {
      final angle = i * (math.pi / 180);
      final isMajor = i % 30 == 0;
      final tickLength = isMajor ? 12.0 : 6.0;

      final startPoint = Offset(
        center.dx + (radius - 10) * math.sin(angle),
        center.dy - (radius - 10) * math.cos(angle),
      );
      final endPoint = Offset(
        center.dx + (radius - 10 - tickLength) * math.sin(angle),
        center.dy - (radius - 10 - tickLength) * math.cos(angle),
      );

      canvas.drawLine(
        startPoint,
        endPoint,
        isMajor ? majorTickPaint : minorTickPaint,
      );
    }

    // Cardinal Points (Arabic: ش=North, ق=East, ج=South, غ=West)
    _drawCardinalText(
        canvas, center, radius - 34, 0, 'ش', Colors.red.shade700, true);
    _drawCardinalText(
        canvas, center, radius - 34, 90, 'ق', primaryColor, false);
    _drawCardinalText(
        canvas, center, radius - 34, 180, 'ج', primaryColor, false);
    _drawCardinalText(
        canvas, center, radius - 34, 270, 'غ', primaryColor, false);
  }

  void _drawCardinalText(
    Canvas canvas,
    Offset center,
    double r,
    double angleDeg,
    String text,
    Color color,
    bool isBold,
  ) {
    final angleRad = angleDeg * (math.pi / 180);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 16.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          fontFamily: 'Almarai',
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    final x = center.dx + r * math.sin(angleRad) - (textPainter.width / 2);
    final y = center.dy - r * math.cos(angleRad) - (textPainter.height / 2);

    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CompassDialPainter oldDelegate) {
    return oldDelegate.isFacingQibla != isFacingQibla ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Custom painter for the Qibla needle pointing towards Mecca
class QiblaNeedlePainter extends CustomPainter {
  final Color needleColor;
  final bool isFacingQibla;

  QiblaNeedlePainter({
    required this.needleColor,
    required this.isFacingQibla,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw needle pointing upwards (towards Qiblah)
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - (radius - 38)); // Top tip
    needlePath.lineTo(center.dx - 10, center.dy); // Left waist
    needlePath.lineTo(center.dx, center.dy + 25); // Tail
    needlePath.lineTo(center.dx + 10, center.dy); // Right waist
    needlePath.close();

    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, needlePaint);

    // Decorative center stripe on needle
    final stripePath = Path();
    stripePath.moveTo(center.dx, center.dy - (radius - 38));
    stripePath.lineTo(center.dx, center.dy + 25);
    final stripePaint = Paint()
      ..color = Colors.white.withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(stripePath, stripePaint);

    // Kaaba marker at the tip of the needle
    final tipCenter = Offset(center.dx, center.dy - (radius - 24));

    final kaabaMarkerPaint = Paint()
      ..color =
          isFacingQibla ? const Color(0xFF2E7D32) : const Color(0xFFC59B27)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tipCenter, 7, kaabaMarkerPaint);

    final innerKaabaDot = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tipCenter, 3.5, innerKaabaDot);
  }

  @override
  bool shouldRepaint(covariant QiblaNeedlePainter oldDelegate) {
    return oldDelegate.needleColor != needleColor ||
        oldDelegate.isFacingQibla != isFacingQibla;
  }
}
