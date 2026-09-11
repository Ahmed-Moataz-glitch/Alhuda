import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:alhuda/core/constants/app_colors.dart';

/// ويدجت عرض القبلة بدقة على الخريطة باستخدام flutter_map و OpenStreetMap
/// بديل دقيق وموثوق للأجهزة التي لا تدعم المستشعر المغناطيسي (Magnetometer)
class QiblahMap extends StatefulWidget {
  const QiblahMap({super.key});

  @override
  State<QiblahMap> createState() => _QiblahMapState();
}

class _QiblahMapState extends State<QiblahMap> {
  // إحداثيات الكعبة المشرفة بمكة المكرمة بدقة متناهية
  static const LatLng kaabaPosition = LatLng(21.422487, 39.826206);

  final MapController _mapController = MapController();

  LatLng? _userPosition;
  double? _qiblaBearing;
  double? _distanceToKaabaKm;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// حساب زاوية القبلة الجغرافية بدقة من موقع المستخدم إلى الكعبة المشرفة (Great Circle Bearing)
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lng1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lng2 = end.longitude * (math.pi / 180.0);
    final dLng = lng2 - lng1;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    var angle = math.atan2(y, x) * (180.0 / math.pi);
    return (angle % 360.0 + 360.0) % 360.0;
  }

  /// اسم الاتجاه بالعربية
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

  /// طلب إذن الموقع وجلب الإحداثيات الحالية المباشرة
  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isPermanentlyDenied = false;
    });

    try {
      // 1. فحص تفعيل الـ GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'خدمة الموقع (GPS) معطلة. يرجى تفعيلها للحصول على موقعك الفعلي.';
        });
        return;
      }

      // 2. فحص الأذونات
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'تم رفض إذن الوصول للموقع. يلزم منح الإذن لتحديد خط القبلة على الخريطة.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isPermanentlyDenied = true;
          _errorMessage = 'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله يدويًا من إعدادات التطبيق.';
        });
        return;
      }

      // 3. جلب الموقع الحي الفعلي الحالي بدقة عالية (تجنب المواقع القديمة المخزنة)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      final userLatLng = LatLng(position.latitude, position.longitude);
      final bearing = _calculateBearing(userLatLng, kaabaPosition);
      const distanceCalc = Distance();
      final distKm = distanceCalc.as(LengthUnit.Kilometer, userLatLng, kaabaPosition);

      setState(() {
        _userPosition = userLatLng;
        _qiblaBearing = bearing;
        _distanceToKaabaKm = distKm;
        _isLoading = false;
        _errorMessage = null;
      });

      // 4. ضبط الكاميرا لتشمل موقع المستخدم والكعبة معاً
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحديد موقعك الحالي بدقة: ${e.toString()}';
      });
    }
  }

  /// ضبط حدود الكاميرا لتشمل موقع المستخدم والكعبة المشرفة معاً
  void _fitBounds() {
    if (_userPosition == null) return;
    try {
      final bounds = LatLngBounds(_userPosition!, kaabaPosition);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 90.0),
        ),
      );
    } catch (_) {}
  }

  /// تقريب الكاميرا لمستوى الشارع والمنزل (Street Level Zoom) لرؤية اتجاه الخط بالنسبة لغرفتك أو شارعك
  void _zoomToUser() {
    if (_userPosition == null) return;
    try {
      _mapController.move(_userPosition!, 17.5);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 1. حالة التحميل
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'جاري تحديد موقعك الحالي بالأقمار الصناعية بدقة...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // 2. حالة الخطأ
    if (_errorMessage != null || _userPosition == null) {
      return _buildErrorView();
    }

    final bearing = _qiblaBearing ?? 0.0;
    final arabicDir = _getArabicDirection(bearing);
    final dist = _distanceToKaabaKm ?? 0.0;

    // 3. عرض الخريطة
    return Stack(
      children: [
        // خريطة OpenStreetMap التفاعلية
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds(_userPosition!, kaabaPosition),
              padding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 90.0),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // بلاطات خريطة OpenStreetMap مع خادم بديل ومعالجة انقطاع الاتصال
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              fallbackUrl: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.alhuda',
              maxZoom: 19,
              errorTileCallback: (tile, error, stackTrace) {
                // منع تصدير الاستثناءات الحمراء في الكونسول عند بطء أو انقطاع النت
              },
            ),

            // الخط المباشر الواصل بين موقع المستخدم والكعبة المشرفة
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [_userPosition!, kaabaPosition],
                  strokeWidth: 4.5,
                  color: Colors.redAccent.shade700,
                  strokeCap: StrokeCap.round,
                  strokeJoin: StrokeJoin.round,
                ),
              ],
            ),

            // العلامات الجغرافية
            MarkerLayer(
              markers: [
                // علامة موقع المستخدم
                Marker(
                  point: _userPosition!,
                  width: 75,
                  height: 75,
                  alignment: Alignment.center,
                  child: _buildUserMarker(),
                ),

                // علامة الكعبة المشرفة
                Marker(
                  point: kaabaPosition,
                  width: 75,
                  height: 75,
                  alignment: Alignment.center,
                  child: _buildKaabaMarker(),
                ),
              ],
            ),
          ],
        ),

        // لوحة التوجيه والمعلومات العلوية
        Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background.withAlpha(240),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withAlpha(80),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'زاوية القِبلة: ${bearing.toStringAsFixed(1)}° ($arabicDir)',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'المسافة للكعبة: ${dist.toStringAsFixed(0)} كم • أعلى الخريطة هو الشمال (⬆️)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'طريقة الصلاة بالخريطة: انظر إلى الشارع أو الجدار الذي يشير إليه الخط الأحمر في منزلك لتتجه إليه مباشرة.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // أزرار التحكم السريع (يمين ويسار أسفل الشاشة)
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر توسيط الكاميرا على المستخدم والكعبة معاً
                FloatingActionButton.extended(
                  heroTag: 'fit_all',
                  onPressed: _fitBounds,
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(color: AppColors.primary.withAlpha(80)),
                  ),
                  icon: const Icon(Icons.fit_screen_rounded, size: 20),
                  label: const Text(
                    'رؤية المسار كاملاً',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

                // زر تقريب على منزلي والشارع (Zoom in)
                FloatingActionButton.extended(
                  heroTag: 'zoom_home',
                  onPressed: _zoomToUser,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  icon: const Icon(Icons.my_location_rounded, size: 20),
                  label: const Text(
                    'تقريب لموقعي',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// علامة موقع المستخدم
  Widget _buildUserMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Text(
            'موقعك الحالي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  /// علامة الكعبة المشرفة
  Widget _buildKaabaMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFC59B27),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Text(
            'الكعبة المشرفة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC59B27), width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
          ),
          child: const Center(
            child: Text('🕋', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  /// شاشة الأخطاء والأذونات
  Widget _buildErrorView() {
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
              Icon(
                _isPermanentlyDenied ? Icons.location_disabled_rounded : Icons.warning_amber_rounded,
                size: 48,
                color: Colors.amber.shade700,
              ),
              const SizedBox(height: 14),
              Text(
                _isPermanentlyDenied ? 'إذن الموقع مرفوض' : 'تحديد الموقع مطلوب',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'يرجى تفعيل إذن الموقع لعرض خط القبلة على الخريطة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isPermanentlyDenied
                    ? () => Geolocator.openAppSettings()
                    : _determinePosition,
                icon: Icon(_isPermanentlyDenied ? Icons.settings : Icons.refresh),
                label: Text(_isPermanentlyDenied ? 'فتح إعدادات التطبيق' : 'إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
