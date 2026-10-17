import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

/// مساعد فحص مستشعر البوصلة في الهاتف
class QiblaSensorHelper {
  static const MethodChannel _customSensorChannel =
      MethodChannel('com.example.alhuda/sensors');

  /// فحص دقيق وشامل لما إذا كان الجهاز يدعم مستشعر البوصلة المغناطيسي (Magnetometer / Rotation Vector)
  static Future<bool> hasCompassSensor() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        // 1. الفحص المباشر عتادياً عبر القناة الأصلية (Native MethodChannel)
        try {
          final nativeResult = await _customSensorChannel
              .invokeMethod<bool>('hasMagnetometer');
          if (nativeResult != null) {
            return nativeResult;
          }
        } catch (_) {}

        // 2. الفحص الاحتياطي عبر مكتبة flutter_qiblah
        try {
          final support = await FlutterQiblah.androidDeviceSensorSupport();
          if (support != null) {
            return support;
          }
        } catch (_) {}

        return false;
      } else if (Platform.isIOS) {
        // جميع أجهزة iPhone تحتوي مستشعر بوصلة مدمج
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
