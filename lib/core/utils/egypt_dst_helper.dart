import 'package:muslim_data_flutter/muslim_data_flutter.dart';

enum EgyptDstMode {
  auto, // Automatic according to Egyptian Law No. 24 of 2023
  summer, // Force Summer Time (UTC+3, +1 hour)
  winter, // Force Standard Winter Time (UTC+2)
  device, // Use device timezone directly
}

extension EgyptDstModeExtension on EgyptDstMode {
  String get title {
    switch (this) {
      case EgyptDstMode.auto:
        return 'تلقائي (وفقاً للقانون المصري)';
      case EgyptDstMode.summer:
        return 'توقيت صيفي دائماً (+1 ساعة)';
      case EgyptDstMode.winter:
        return 'توقيت شتوي دائماً (قياسي)';
      case EgyptDstMode.device:
        return 'حسب توقيت الهاتف فقط';
    }
  }

  String get description {
    switch (this) {
      case EgyptDstMode.auto:
        return 'يُفعل التوقيت الصيفي من آخر جمعة في أبريل حتى آخر خميس في أكتوبر تلقائياً';
      case EgyptDstMode.summer:
        return 'تقديم مواقيت الصلاة بمقدار 60 دقيقة طوال العام';
      case EgyptDstMode.winter:
        return 'المواقيت القياسية بدون تقديم الساعة (توقيت شتوي)';
      case EgyptDstMode.device:
        return 'الاعتماد كلياً على فارق توقيت نظام التشغيل';
    }
  }
}

class EgyptDstHelper {
  /// Check if a given date falls within Egypt's Daylight Saving Time (التوقيت الصيفي)
  /// According to Egyptian Law No. 24 of 2023:
  /// - Starts on the last Friday of April at 00:00 (clocks move forward to 01:00, UTC+3)
  /// - Ends on the last Thursday of October at 24:00 / last Friday at 00:00 (clocks move back to 23:00, UTC+2)
  static bool isEgyptDst(DateTime date) {
    final year = date.year;

    // Find the last Friday of April:
    var lastFridayAprilDay = 30;
    while (DateTime(year, 4, lastFridayAprilDay).weekday != DateTime.friday) {
      lastFridayAprilDay--;
    }
    final dstStart = DateTime(year, 4, lastFridayAprilDay, 0, 0, 0);

    // Find the last Thursday of October:
    var lastThursdayOctoberDay = 31;
    while (DateTime(year, 10, lastThursdayOctoberDay).weekday !=
        DateTime.thursday) {
      lastThursdayOctoberDay--;
    }
    final dstEnd = DateTime(year, 10, lastThursdayOctoberDay, 23, 59, 59);

    return date.isAfter(dstStart) && date.isBefore(dstEnd);
  }

  /// Returns the official UTC offset for Egypt for the given date and mode:
  /// - Summer: UTC+3
  /// - Winter: UTC+2
  static double getExpectedEgyptOffset(
    DateTime date, {
    EgyptDstMode mode = EgyptDstMode.auto,
  }) {
    switch (mode) {
      case EgyptDstMode.auto:
        return isEgyptDst(date) ? 3.0 : 2.0;
      case EgyptDstMode.summer:
        return 3.0;
      case EgyptDstMode.winter:
        return 2.0;
      case EgyptDstMode.device:
        return date.timeZoneOffset.inMinutes.toDouble() / 60.0;
    }
  }

  /// Checks whether a location belongs to Egypt
  static bool isEgyptLocation(Location location) {
    if (location.countryCode.toUpperCase() == 'EG') return true;
    final nameLower = location.name.toLowerCase();
    final countryLower = location.countryName.toLowerCase();
    if (countryLower.contains('egypt') ||
        countryLower.contains('مصر') ||
        nameLower.contains('cairo') ||
        nameLower.contains('alexandria') ||
        nameLower.contains('giza')) {
      return true;
    }
    // Latitude/longitude bounding box for Egypt (approx: 22.0°N - 32.0°N, 25.0°E - 36.0°E)
    if (location.latitude >= 21.5 &&
        location.latitude <= 32.0 &&
        location.longitude >= 24.5 &&
        location.longitude <= 37.0) {
      return true;
    }
    return false;
  }

  /// Calculates the adjustment in minutes needed to correct prayer times for Egypt
  static int getDstAdjustmentMinutes({
    required Location location,
    required DateTime date,
    required EgyptDstMode mode,
  }) {
    if (mode == EgyptDstMode.device) return 0;
    if (!isEgyptLocation(location)) return 0;

    final targetOffset = getExpectedEgyptOffset(date, mode: mode);
    final deviceOffset = date.timeZoneOffset.inMinutes.toDouble() / 60.0;

    final diffHours = targetOffset - deviceOffset;
    return (diffHours * 60).round();
  }

  /// Adjusts a PrayerTime object by applying the Egypt DST correction
  static PrayerTime adjustPrayerTimesForEgypt({
    required PrayerTime prayer,
    required Location location,
    required DateTime date,
    required EgyptDstMode mode,
    int additionalMinutesOffset = 0,
  }) {
    final dstAdjustment = getDstAdjustmentMinutes(
      location: location,
      date: date,
      mode: mode,
    );

    final totalMinutes = dstAdjustment + additionalMinutesOffset;
    if (totalMinutes == 0) return prayer;

    final duration = Duration(minutes: totalMinutes);
    return prayer.copyWith(
      fajr: prayer.fajr.add(duration),
      sunrise: prayer.sunrise.add(duration),
      dhuhr: prayer.dhuhr.add(duration),
      asr: prayer.asr.add(duration),
      maghrib: prayer.maghrib.add(duration),
      isha: prayer.isha.add(duration),
    );
  }

  /// Returns a formatted human-readable badge text describing current status
  static String getStatusBadgeText(DateTime date, EgyptDstMode mode) {
    switch (mode) {
      case EgyptDstMode.summer:
        return 'التوقيت الصيفي (+1 ساعة)';
      case EgyptDstMode.winter:
        return 'التوقيت الشتوي (قياسي)';
      case EgyptDstMode.device:
        return 'توقيت الهاتف';
      case EgyptDstMode.auto:
        return isEgyptDst(date)
            ? 'التوقيت الصيفي (مُفعّل تلقائياً)'
            : 'التوقيت الشتوي (مُفعّل تلقائياً)';
    }
  }
}
