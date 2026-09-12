import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qibla/qibla.dart' as qibla_math;
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/models/city_locations_data.dart';

/// حاسبة فلكية دقيقة لحساب زاوية وموقع الشمس الحقيقي في السماء (Solar Position)
/// تعمل 100% أوفلاين بدون أي إنترنت أو مستشعر
class SolarCalculator {
  /// زاوية السمت الأفقي للشمس (Azimuth) بالدرجات من الشمال الجغرافي (0° إلى 360°)
  static double getSunAzimuth({
    required double latitude,
    required double longitude,
    DateTime? time,
  }) {
    final now = (time ?? DateTime.now()).toUtc();
    final year = now.year;
    final month = now.month;
    final day = now.day;
    final hour = now.hour + now.minute / 60.0 + now.second / 3600.0;

    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    double jdn = day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
    double jd = jdn + (hour - 12.0) / 24.0;

    double t = (jd - 2451545.0) / 36525.0;
    double l0 = (280.46646 + t * (36000.76983 + 0.0003032 * t)) % 360.0;
    double mSun = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    double mRad = mSun * math.pi / 180.0;

    double c = math.sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(2 * mRad) * (0.019993 - 0.000101 * t) +
        math.sin(3 * mRad) * 0.000289;
    double sunTrueLong = l0 + c;

    double eps0 = 23.439291 - t * (0.0130042 + 0.00000016 * t);
    double epsRad = eps0 * math.pi / 180.0;
    double lambdaRad = sunTrueLong * math.pi / 180.0;

    double sinDec = math.sin(epsRad) * math.sin(lambdaRad);
    double dec = math.asin(sinDec);

    double yRa = math.cos(epsRad) * math.sin(lambdaRad);
    double xRa = math.cos(lambdaRad);
    double ra = math.atan2(yRa, xRa);

    double gmst = 280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        t * t * 0.000387933 -
        t * t * t / 38710000.0;
    gmst = (gmst % 360.0 + 360.0) % 360.0;

    double lst = (gmst + longitude) % 360.0;
    double lstRad = lst * math.pi / 180.0;
    double haRad = lstRad - ra;
    double latRad = latitude * math.pi / 180.0;

    double sinAlt = math.sin(latRad) * math.sin(dec) +
        math.cos(latRad) * math.cos(dec) * math.cos(haRad);
    double alt = math.asin(sinAlt);

    double cosAz = (math.sin(dec) - math.sin(latRad) * math.sin(alt)) /
        (math.cos(latRad) * math.cos(alt));
    cosAz = cosAz.clamp(-1.0, 1.0);
    double az = math.acos(cosAz) * 180.0 / math.pi;

    if (math.sin(haRad) > 0) {
      az = 360.0 - az;
    }

    return (az % 360.0 + 360.0) % 360.0;
  }

  /// هل الشمس ظاهرة فوق الأفق حالياً؟
  static bool isSunAboveHorizon({
    required double latitude,
    required double longitude,
    DateTime? time,
  }) {
    final now = (time ?? DateTime.now()).toUtc();
    final year = now.year;
    final month = now.month;
    final day = now.day;
    final hour = now.hour + now.minute / 60.0 + now.second / 3600.0;

    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    double jdn = day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
    double jd = jdn + (hour - 12.0) / 24.0;
    double t = (jd - 2451545.0) / 36525.0;

    double mSun = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    double mRad = mSun * math.pi / 180.0;
    double c = math.sin(mRad) * 1.914602;
    double sunTrueLong = (280.46646 + t * 36000.76983) + c;

    double eps0 = 23.439291 * math.pi / 180.0;
    double lambdaRad = sunTrueLong * math.pi / 180.0;
    double dec = math.asin(math.sin(eps0) * math.sin(lambdaRad));

    double gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0);
    double lst = (gmst + longitude) % 360.0;
    double lstRad = lst * math.pi / 180.0;
    double yRa = math.cos(eps0) * math.sin(lambdaRad);
    double xRa = math.cos(lambdaRad);
    double ra = math.atan2(yRa, xRa);
    double haRad = lstRad - ra;

    double latRad = latitude * math.pi / 180.0;
    double sinAlt = math.sin(latRad) * math.sin(dec) +
        math.cos(latRad) * math.cos(dec) * math.cos(haRad);

    return sinAlt > -0.0145;
  }
}

/// ويدجت تحديد القبلة بطريقة الشمس الفلكية (100% أوفلاين بدون نت وبدون مستشعر)
class QiblahOfflineView extends StatefulWidget {
  const QiblahOfflineView({super.key});

  @override
  State<QiblahOfflineView> createState() => _QiblahOfflineViewState();
}

class _QiblahOfflineViewState extends State<QiblahOfflineView> {
  // موقع افتراضي (القاهرة) حتى يتم تحديد الموقع أو اختيار مدينة
  double _currentLat = 30.0444;
  double _currentLng = 31.2357;
  String _locationName = 'القاهرة (افتراضي)';

  // زاوية توجيه الهاتف يدوياً (الافتراضي متطابق مع زاوية الشمس)
  double _manualHeading = 0.0;
  double _panStartAngle = 0.0;
  double _panStartHeading = 0.0;
  bool _isAlignedWithSun = true;

  Timer? _solarTimer;

  @override
  void initState() {
    super.initState();
    _fetchPositionOffline();
    // ضبط التوجيه المبدئي مباشرة ليتطابق مع الشمس
    _manualHeading = _sunAzimuth;

    // تحديث موقع الشمس دورياً كل 30 ثانية
    _solarTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          if (_isAlignedWithSun) {
            _manualHeading = _sunAzimuth;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _solarTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPositionOffline() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always ||
          hasPermission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null && mounted) {
          setState(() {
            _currentLat = pos.latitude;
            _currentLng = pos.longitude;
            _locationName = 'موقعك الحالي (GPS)';
            _manualHeading = _sunAzimuth;
          });
        }
      }
    } catch (_) {}
  }

  double get _qiblaAngle => qibla_math.qiblaAngle(_currentLat, _currentLng);

  double get _sunAzimuth => SolarCalculator.getSunAzimuth(
        latitude: _currentLat,
        longitude: _currentLng,
      );

  bool get _isSunVisible => SolarCalculator.isSunAboveHorizon(
        latitude: _currentLat,
        longitude: _currentLng,
      );

  double get _distanceKm => qibla_math.distanceKm(
        _currentLat,
        _currentLng,
        qibla_math.kaabaLat,
        qibla_math.kaabaLng,
      );

  String _getArabicDirection(double degree) {
    final b = (degree % 360.0 + 360.0) % 360.0;
    if (b >= 337.5 || b < 22.5) return 'الشمال';
    if (b >= 22.5 && b < 67.5) return 'الشمال الشرقي';
    if (b >= 67.5 && b < 112.5) return 'الشرق';
    if (b >= 112.5 && b < 157.5) return 'الجنوب الشرقي';
    if (b >= 157.5 && b < 202.5) return 'الجنوب';
    if (b >= 202.5 && b < 247.5) return 'الجنوب الغربي';
    if (b >= 247.5 && b < 292.5) return 'الغرب';
    return 'الشمال الغربي';
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cities = LocationDataHelper.allCities;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'اختر مدينتك (محفوظة أوفلاين بدون نت)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return ListTile(
                      title: Text(
                        city.nameAr,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        city.countryAr,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        setState(() {
                          _currentLat = city.latitude;
                          _currentLng = city.longitude;
                          _locationName = '${city.nameAr} (${city.countryAr})';
                          _manualHeading = _sunAzimuth;
                          _isAlignedWithSun = true;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final qibla = _qiblaAngle;
    final sun = _sunAzimuth;

    // الفرق بين توجيه الهاتف وزاوية الشمس
    final isAlignedToSun = ((_manualHeading - sun + 180) % 360 - 180).abs() <= 3.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // بطاقة المدينة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_city_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'أوفلاين: اضغط لتغيير المدينة',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showCityPicker,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('تغيير المدينة'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // شارة التوجيه بالشمس
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isAlignedToSun
                    ? const Color(0xFF2E7D32).withAlpha(35)
                    : Colors.amber.shade900.withAlpha(25),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isAlignedToSun
                      ? const Color(0xFF2E7D32)
                      : Colors.amber.shade800,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSunVisible ? '☀️' : '🌙',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isAlignedToSun
                          ? 'الهاتف محاذٍ للشمس ☀️ • السهم يشير للقبلة 🕋'
                          : 'قم بمحاذاة الهاتف للشمس لتظهر القبلة فوراً',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isAlignedToSun
                            ? const Color(0xFF2E7D32)
                            : Colors.amber.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // قرص البوصلة الشمسية
            SizedBox(
              width: 290,
              height: 290,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final center = const Offset(145, 145);
                  final touch = details.localPosition - center;
                  _panStartAngle =
                      math.atan2(touch.dy, touch.dx) * 180 / math.pi;
                  _panStartHeading = _manualHeading;
                },
                onPanUpdate: (details) {
                  final center = const Offset(145, 145);
                  final touch = details.localPosition - center;
                  final currentAngle =
                      math.atan2(touch.dy, touch.dx) * 180 / math.pi;
                  final diff = currentAngle - _panStartAngle;
                  final newHeading = (_panStartHeading - diff + 360) % 360;

                  setState(() {
                    _manualHeading = newHeading;
                    _isAlignedWithSun =
                        ((_manualHeading - sun + 180) % 360 - 180).abs() <= 3.0;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // إطار خارجي وظل
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                        border: Border.all(
                          color: isAlignedToSun
                              ? const Color(0xFF2E7D32)
                              : AppColors.primary.withAlpha(80),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isAlignedToSun
                                ? const Color(0xFF2E7D32).withAlpha(40)
                                : Colors.black.withAlpha(15),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),

                    // قرص دوران الشمس
                    Transform.rotate(
                      angle: (_manualHeading * math.pi / 180 * -1),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // أيقونة الشمس الحية ☀️ في موضعها الفلكي الدقيق الآن
                          Transform.rotate(
                            angle: (sun * math.pi / 180),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isSunVisible ? '☀️' : '🌙',
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade900,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _isSunVisible ? 'الشمس الآن' : 'القمر',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
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

                    // سهم القبلة المتجه للكعبة المشرفة
                    Transform.rotate(
                      angle: ((qibla - _manualHeading) * math.pi / 180),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            size: 95,
                            color: isAlignedToSun
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC59B27),
                          ),
                          const SizedBox(height: 70),
                        ],
                      ),
                    ),

                    // المركز مع الكعبة
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAlignedToSun
                              ? const Color(0xFF2E7D32)
                              : AppColors.primary,
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Text('🕋', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // الزر الرئيسي الكبير: محاذاة الهاتف للشمس ☀️
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  setState(() {
                    _manualHeading = _sunAzimuth;
                    _isAlignedWithSun = true;
                  });
                },
                icon: const Text('☀️', style: TextStyle(fontSize: 20)),
                label: const Text(
                  'محاذاة الهاتف للشمس الآن',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAlignedToSun
                      ? const Color(0xFF2E7D32)
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // بطاقة الأرقام الفلكية
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    'اتجاه القبلة',
                    '${qibla.toInt()}°',
                    _getArabicDirection(qibla),
                  ),
                  Container(
                    height: 38,
                    width: 1,
                    color: AppColors.primary.withAlpha(40),
                  ),
                  _buildStatColumn(
                    'موقع الشمس الآن',
                    '${sun.toInt()}°',
                    _getArabicDirection(sun),
                  ),
                  Container(
                    height: 38,
                    width: 1,
                    color: AppColors.primary.withAlpha(40),
                  ),
                  _buildStatColumn(
                    'المسافة للكعبة',
                    '${_distanceKm.toStringAsFixed(0)} كم',
                    'مسافة مباشرة',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // دليل الاستخدام المبسط والعملي
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          color: Colors.amber.shade800, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'خطوات تحديد القبلة بالشمس في غرفتك:',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStepRow(
                    number: '١',
                    text:
                        'انظر للشمس في السماء من النافذة أو الشارع (أو انظر لاتجاه ظلك).',
                  ),
                  const SizedBox(height: 8),
                  _buildStepRow(
                    number: '٢',
                    text:
                        'اضغط زر (محاذاة الهاتف للشمس الآن ☀️) ووجّه أعلى الهاتف نحو قرص الشمس.',
                  ),
                  const SizedBox(height: 8),
                  _buildStepRow(
                    number: '٣',
                    text:
                        'في هذه اللحظة، يشير سهم الكعبة 🕋 مباشرة إلى اتجاه صلاتك في الغرفة بدقة 100%!',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String subtitle) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
