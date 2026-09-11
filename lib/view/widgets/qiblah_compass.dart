import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alhuda/core/constants/app_colors.dart';

/// ويدجت عرض بوصلة القبلة التفاعلية باستخدام مستشعر الهاتف و flutter_qiblah
class QiblahCompass extends StatefulWidget {
  const QiblahCompass({super.key});

  @override
  State<QiblahCompass> createState() => _QiblahCompassState();
}

class _QiblahCompassState extends State<QiblahCompass> {
  Future<LocationStatus>? _locationStatusFuture;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  void _checkLocation() {
    setState(() {
      _locationStatusFuture = FlutterQiblah.checkLocationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocationStatus>(
      future: _locationStatusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(
            message: 'حدث خطأ أثناء فحص إذن وموقع الهاتف: ${snapshot.error}',
            buttonText: 'إعادة المحاولة',
            onPressed: _checkLocation,
          );
        }

        final status = snapshot.data;
        if (status == null || !status.enabled) {
          return _buildErrorWidget(
            message: 'خدمة تحديد الموقع (GPS) غير مفعلة في الهاتف.',
            buttonText: 'تفعيل الخدمة وإعادة المحاولة',
            onPressed: () async {
              await Geolocator.openLocationSettings();
              _checkLocation();
            },
          );
        }

        switch (status.status) {
          case LocationPermission.always:
          case LocationPermission.whileInUse:
            return const _QiblahCompassBody();

          case LocationPermission.denied:
            return _buildErrorWidget(
              message: 'تم رفض إذن الوصول للموقع، وهو ضروري لمعايرة البوصلة.',
              buttonText: 'منح الإذن',
              onPressed: () async {
                await FlutterQiblah.requestPermissions();
                _checkLocation();
              },
            );

          case LocationPermission.deniedForever:
            return _buildErrorWidget(
              message: 'تم رفض إذن الموقع بشكل دائم. يرجى منحه يدويًا من إعدادات التطبيق.',
              buttonText: 'فتح إعدادات التطبيق',
              onPressed: () async {
                await Geolocator.openAppSettings();
                _checkLocation();
              },
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildErrorWidget({
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withAlpha(80)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// جسم البوصلة الدائري التفاعلي
class _QiblahCompassBody extends StatelessWidget {
  const _QiblahCompassBody();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'جاري معايرة البوصلة وتحديد القبلة...',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'خطأ في قراءة بيانات البوصلة: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final qiblahDirection = snapshot.data;
        if (qiblahDirection == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // حساب ما إذا كان المستخدم يواجه القبلة حالياً بدقة ±5 درجات
        final diff = ((qiblahDirection.direction - qiblahDirection.offset + 180) % 360 - 180).abs();
        final isFacingQibla = diff <= 5.0;

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // شارة التوجيه
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFacingQibla
                          ? const Color(0xFF2E7D32).withAlpha(35)
                          : AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isFacingQibla ? const Color(0xFF2E7D32) : AppColors.primary,
                      ),
                    ),
                    child: Text(
                      isFacingQibla ? 'أنت باتجاه القبلة الآن 🕋' : 'قم بتدوير الهاتف حتى تتطابق الإبرة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isFacingQibla ? const Color(0xFF2E7D32) : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // قرص البوصلة وإبرة القبلة
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // قرص البوصلة الخارجي (يدور مع دوران الهاتف)
                        Transform.rotate(
                          angle: (qiblahDirection.direction * (math.pi / 180) * -1),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.background,
                              border: Border.all(
                                color: isFacingQibla ? const Color(0xFF2E7D32) : AppColors.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: const [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'ش (N)',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: Text('ج (S)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Text('ق (E)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text('غ (W)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // إبرة اتجاه القبلة (تشير دائماً إلى الكعبة)
                        Transform.rotate(
                          angle: (qiblahDirection.qiblah * (math.pi / 180) * -1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.navigation_rounded,
                                size: 85,
                                color: isFacingQibla ? const Color(0xFF2E7D32) : const Color(0xFFC59B27),
                              ),
                              const SizedBox(height: 70),
                            ],
                          ),
                        ),

                        // النقطة المركزية مع أيقونة الكعبة
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFacingQibla ? const Color(0xFF2E7D32) : AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text('🕋', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // زاوية القبلة
                  Text(
                    'زاوية القبلة: ${qiblahDirection.offset.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
