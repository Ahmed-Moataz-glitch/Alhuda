import 'dart:async';
import 'dart:math' as math;
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qibla/qibla.dart' as qibla_math;

class QiblaWidget extends StatefulWidget {
  const QiblaWidget({super.key});

  @override
  State<QiblaWidget> createState() => _QiblaWidgetState();
}

class _QiblaWidgetState extends State<QiblaWidget> {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  double? _distanceToKaabaKm;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
    _fetchCurrentPosition();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    FlutterQiblah().dispose();
    super.dispose();
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
            _distanceToKaabaKm = qibla_math.distanceKm(
              position.latitude,
              position.longitude,
              qibla_math.kaabaLat,
              qibla_math.kaabaLng,
            );
          });
        }
      }
    } catch (_) {
      // Gracefully handle if position cannot be fetched immediately
    }
  }

  Future<void> _checkLocationStatus() async {
    try {
      final locationStatus = await FlutterQiblah.checkLocationStatus();
      if (locationStatus.enabled &&
          locationStatus.status == LocationPermission.denied) {
        await FlutterQiblah.requestPermissions();
        final updatedStatus = await FlutterQiblah.checkLocationStatus();
        _locationStreamController.sink.add(updatedStatus);
      } else {
        _locationStreamController.sink.add(locationStatus);
      }

      if (locationStatus.enabled &&
          (locationStatus.status == LocationPermission.always ||
              locationStatus.status == LocationPermission.whileInUse)) {
        _fetchCurrentPosition();
      }
    } catch (e) {
      _locationStreamController.sink.add(
        const LocationStatus(false, LocationPermission.denied),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: FlutterQiblah.androidDeviceSensorSupport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return _buildMessageCard(
            icon: Icons.error_outline_rounded,
            title: 'خطأ في المستشعر',
            message: 'حدث خطأ أثناء فحص مستشعر البوصلة: ${snapshot.error}',
            actionText: 'إعادة المحاولة',
            onAction: () => setState(() {}),
          );
        }

        if (snapshot.data == false) {
          return _buildMessageCard(
            icon: Icons.sensors_off_rounded,
            title: 'المستشعر غير مدعوم',
            message:
                'للأسف، لا يحتوي جهازك على مستشعر البوصلة (Magnetometer) المطلوب لتحديد اتجاه القبلة بدقة.',
          );
        }

        return StreamBuilder<LocationStatus>(
          stream: _locationStreamController.stream,
          builder: (context, locationSnapshot) {
            if (locationSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final status = locationSnapshot.data;
            if (status == null) {
              return _buildMessageCard(
                icon: Icons.location_searching_rounded,
                title: 'تحديد الموقع',
                message: 'جاري فحص حالة خدمة الموقع...',
                actionText: 'تحديث',
                onAction: _checkLocationStatus,
              );
            }

            if (!status.enabled) {
              return _buildMessageCard(
                icon: Icons.location_off_rounded,
                title: 'خدمة الموقع غير مفعلة',
                message:
                    'يرجى تفعيل خدمة تحديد الموقع (GPS) لنتمكن من حساب اتجاه القبلة والمسافة للكعبة.',
                actionText: 'تفعيل الموقع',
                onAction: () async {
                  await Geolocator.openLocationSettings();
                  await _checkLocationStatus();
                },
              );
            }

            switch (status.status) {
              case LocationPermission.always:
              case LocationPermission.whileInUse:
                return _buildCompassView();

              case LocationPermission.denied:
                return _buildMessageCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'إذن الموقع مطلوب',
                  message:
                      'يحتاج التطبيق إلى إذن الوصول للموقع الجغرافي لحساب زاوية القبلة لموقعك الحالي بدقة.',
                  actionText: 'منح الإذن',
                  onAction: () async {
                    await FlutterQiblah.requestPermissions();
                    await _checkLocationStatus();
                  },
                );

              case LocationPermission.deniedForever:
                return _buildMessageCard(
                  icon: Icons.gpp_bad_rounded,
                  title: 'تم رفض الإذن بشكل دائم',
                  message:
                      'تم رفض إذن الوصول للموقع بشكل دائم، يرجى تفعيله من إعدادات التطبيق للاستفادة من البوصلة.',
                  actionText: 'فتح الإعدادات',
                  onAction: () async {
                    await Geolocator.openAppSettings();
                    await _checkLocationStatus();
                  },
                );

              default:
                return _buildMessageCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'تنبيه',
                  message: 'حالة إذن الموقع غير معروفة.',
                  actionText: 'إعادة المحاولة',
                  onAction: _checkLocationStatus,
                );
            }
          },
        );
      },
    );
  }

  Widget _buildCompassView() {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16.h),
                Text(
                  'جاري معايرة البوصلة وتحديد القبلة...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildMessageCard(
            icon: Icons.error_outline_rounded,
            title: 'خطأ في القراءة',
            message: 'تعذر قراءة بيانات البوصلة: ${snapshot.error}',
            actionText: 'إعادة المحاولة',
            onAction: _checkLocationStatus,
          );
        }

        final qiblahDirection = snapshot.data;
        if (qiblahDirection == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final direction = qiblahDirection.direction;
        final qiblah = qiblahDirection.qiblah;
        final offset = qiblahDirection.offset;

        // Calculate angular difference between device direction and Qiblah
        final diff = ((direction - offset + 180) % 360 - 180).abs();
        final isFacingQibla = diff <= 4.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              // Status Badge
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
                    Text(
                      isFacingQibla
                          ? 'أنت باتجاه القبلة الآن 🕋'
                          : 'قم بتدوير الهاتف حتى تتطابق الإبرة',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isFacingQibla
                            ? const Color(0xFF2E7D32)
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Compass Display Area
              SizedBox(
                width: 290.w,
                height: 290.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow when facing Qibla
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 280.w,
                      height: 280.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isFacingQibla
                                ? const Color(0xFF2E7D32).withAlpha(70)
                                : AppColors.primary.withAlpha(25),
                            blurRadius: isFacingQibla ? 25 : 12,
                            spreadRadius: isFacingQibla ? 6 : 1,
                          ),
                        ],
                      ),
                    ),

                    // Rotating Compass Dial
                    Transform.rotate(
                      angle: (direction * (math.pi / 180) * -1),
                      child: CustomPaint(
                        size: Size(270.w, 270.w),
                        painter: CompassDialPainter(
                          primaryColor: AppColors.primary,
                          isFacingQibla: isFacingQibla,
                        ),
                      ),
                    ),

                    // Rotating Qiblah Needle with Kaaba Marker
                    Transform.rotate(
                      angle: (qiblah * (math.pi / 180) * -1),
                      child: CustomPaint(
                        size: Size(270.w, 270.w),
                        painter: QiblaNeedlePainter(
                          needleColor: isFacingQibla
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC59B27),
                          isFacingQibla: isFacingQibla,
                        ),
                      ),
                    ),

                    // Center Pivot Point
                    Container(
                      width: 52.w,
                      height: 52.w,
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
                          style: TextStyle(fontSize: 22.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28.h),

              // Direction Details Card
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
                        icon: Icons.phone_android_rounded,
                      ),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: AppColors.primary.withAlpha(60),
                      ),
                      _buildInfoColumn(
                        label: 'المسافة للكعبة',
                        value: _distanceToKaabaKm != null
                            ? '${_distanceToKaabaKm!.toStringAsFixed(0)} كم'
                            : '---',
                        icon: Icons.place_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Calibration & Usage Tip
              Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.primary.withAlpha(180),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
              ),
            ],
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
    _drawCardinalText(canvas, center, radius - 34, 0, 'ش', Colors.red.shade700, true);
    _drawCardinalText(canvas, center, radius - 34, 90, 'ق', primaryColor, false);
    _drawCardinalText(canvas, center, radius - 34, 180, 'ج', primaryColor, false);
    _drawCardinalText(canvas, center, radius - 34, 270, 'غ', primaryColor, false);
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
      ..color = isFacingQibla ? const Color(0xFF2E7D32) : const Color(0xFFC59B27)
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
