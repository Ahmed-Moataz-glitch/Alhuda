import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/core/utils/egypt_dst_helper.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
void prayerAlarmCallback(int id) async {
  // Native AdhanForegroundService already handles exact Adhan playback, WakeLock,
  // full-screen activity, and notification natively.
  // Returning immediately prevents duplicate notifications and restarting/duplicate audio.
  return;
}

@pragma('vm:entry-point')
void prePrayerAlarmCallback(int id) async {
  // Native AdhanAlarmReceiver already handles pre-prayer voice alert natively.
  // Returning immediately prevents duplicate / echoing voice playback.
  return;
}

@pragma('vm:entry-point')
void persistentNotificationAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationServices.initializeNotifications();
  await AdhanAudioService.instance.init();

  if (AdhanAudioService().isPersistentNotificationEnabled) {
    try {
      await PrayerSchedulerService().updatePersistentPrayerNotification();
    } catch (_) {}
  }

  // Refresh rolling 7-day schedule in background so future alarms never expire
  try {
    await PrayerSchedulerService().scheduleUpcomingPrayers(null);
  } catch (_) {}
}

class PrayerSchedulerService {
  static final PrayerSchedulerService _instance =
      PrayerSchedulerService._internal();

  factory PrayerSchedulerService() => _instance;

  PrayerSchedulerService._internal();

  static const int idFajr = 1001;
  static const int idDhuhr = 1002;
  static const int idAsr = 1003;
  static const int idMaghrib = 1004;
  static const int idIsha = 1005;

  static const int idPreFajr = 2001;
  static const int idPreDhuhr = 2002;
  static const int idPreAsr = 2003;
  static const int idPreMaghrib = 2004;
  static const int idPreIsha = 2005;

  static const Map<String, int> prayerNameToId = {
    'الفجر': idFajr,
    'الظهر': idDhuhr,
    'العصر': idAsr,
    'المغرب': idMaghrib,
    'العشاء': idIsha,
  };

  static const Map<String, int> prePrayerNameToId = {
    'الفجر': idPreFajr,
    'الظهر': idPreDhuhr,
    'العصر': idPreAsr,
    'المغرب': idPreMaghrib,
    'العشاء': idPreIsha,
  };

  /// Normalizes any day-offset prayer alarm id (e.g. 1001, 1101, 1201) to the base id (1001).
  static int basePrayerId(int id) {
    if (id >= 1000 && id < 2000) {
      return 1000 + (id % 100);
    }
    return id;
  }

  static int basePrePrayerId(int id) {
    if (id >= 2000 && id < 3000) {
      return 2000 + (id % 100);
    }
    return id;
  }

  static String prayerNameFromId(int id) {
    final base = basePrayerId(id);
    switch (base) {
      case idFajr:
        return 'الفجر';
      case idDhuhr:
        return 'الظهر';
      case idAsr:
        return 'العصر';
      case idMaghrib:
        return 'المغرب';
      case idIsha:
        return 'العشاء';
      default:
        return 'الصلاة';
    }
  }

  static String prayerNameFromPreId(int id) {
    final base = basePrePrayerId(id);
    switch (base) {
      case idPreFajr:
        return 'الفجر';
      case idPreDhuhr:
        return 'الظهر';
      case idPreAsr:
        return 'العصر';
      case idPreMaghrib:
        return 'المغرب';
      case idPreIsha:
        return 'العشاء';
      default:
        return 'الصلاة';
    }
  }

  Future<void> saveScheduleConfig({
    required Location location,
    CalculationMethod method = CalculationMethod.egypt,
    EgyptDstMode dstMode = EgyptDstMode.auto,
    int manualMinutesOffset = 0,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/alhuda_prayer_schedule_config.json');
      final data = {
        'location': {
          'id': location.id,
          'name': location.name,
          'countryName': location.countryName,
          'countryCode': location.countryCode,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'hasFixedPrayerTime': location.hasFixedPrayerTime,
        },
        'method': method.name,
        'dstMode': dstMode.name,
        'manualMinutesOffset': manualMinutesOffset,
      };
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('Error saving schedule config: $e');
    }
  }

  Future<Map<String, dynamic>?> loadScheduleConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/alhuda_prayer_schedule_config.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading schedule config: $e');
    }
    return null;
  }

  /// Schedules upcoming prayers for the next 7 days in a rolling window.
  /// Sunrise is explicitly excluded from scheduling.
  Future<void> scheduleUpcomingPrayers(
    PrayerTime? prayerTime, {
    Location? location,
    CalculationMethod? method,
    EgyptDstMode? dstMode,
    int? manualMinutesOffset,
  }) async {
    if (!Platform.isAndroid) return;

    final muslimRepo = MuslimRepository();
    final now = DateTime.now();

    Location activeLocation;
    CalculationMethod activeMethod = method ?? CalculationMethod.egypt;
    EgyptDstMode activeDstMode = dstMode ?? EgyptDstMode.auto;
    int activeOffset = manualMinutesOffset ?? 0;

    if (location != null) {
      activeLocation = location;
      await saveScheduleConfig(
        location: location,
        method: activeMethod,
        dstMode: activeDstMode,
        manualMinutesOffset: activeOffset,
      );
    } else {
      final saved = await loadScheduleConfig();
      if (saved != null && saved['location'] != null) {
        final locMap = saved['location'] as Map<String, dynamic>;
        activeLocation = Location(
          id: locMap['id'] ?? 1,
          name: locMap['name'] ?? 'القاهرة',
          countryName: locMap['countryName'] ?? 'مصر',
          countryCode: locMap['countryCode'] ?? 'EG',
          latitude: (locMap['latitude'] as num?)?.toDouble() ?? 30.0444,
          longitude: (locMap['longitude'] as num?)?.toDouble() ?? 31.2357,
          hasFixedPrayerTime: locMap['hasFixedPrayerTime'] ?? false,
        );
        if (saved['method'] != null) {
          activeMethod = CalculationMethod.values.firstWhere(
            (m) => m.name == saved['method'],
            orElse: () => CalculationMethod.egypt,
          );
        }
        if (saved['dstMode'] != null) {
          activeDstMode = EgyptDstMode.values.firstWhere(
            (d) => d.name == saved['dstMode'],
            orElse: () => EgyptDstMode.auto,
          );
        }
        activeOffset = (saved['manualMinutesOffset'] as num?)?.toInt() ?? 0;
      } else {
        activeLocation = const Location(
          id: 1,
          name: 'القاهرة',
          countryName: 'مصر',
          countryCode: 'EG',
          latitude: 30.0444,
          longitude: 31.2357,
          hasFixedPrayerTime: false,
        );
      }
    }

    const int daysToSchedule = 7;
    final nativeAlarmsList = <Map<String, dynamic>>[];
    final selectedSound = AdhanAudioService().selectedSound;
    final adhanVolume = AdhanAudioService().adhanVolume;
    final isAlarmMode = AdhanAudioService().isAlarmMode;
    final preVolume = AdhanAudioService().prePrayerVolume;
    final preMinutes = AdhanAudioService().prePrayerMinutes;
    final rawRes = selectedSound.source.split('/').last.replaceAll('.mp3', '');

    for (int dayOffset = 0; dayOffset < daysToSchedule; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      PrayerTime? dayPrayers;

      if (dayOffset == 0 && prayerTime != null) {
        dayPrayers = prayerTime;
      } else {
        try {
          final raw = await muslimRepo.getPrayerTimes(
            location: activeLocation,
            date: targetDate,
            attribute: PrayerAttribute(
              calculationMethod: activeMethod,
              asrMethod: AsrMethod.shafii,
              higherLatitudeMethod: HigherLatitudeMethod.angleBased,
            ),
          );
          if (raw != null) {
            dayPrayers = EgyptDstHelper.adjustPrayerTimesForEgypt(
              prayer: raw,
              location: activeLocation,
              date: targetDate,
              mode: activeDstMode,
              additionalMinutesOffset: activeOffset,
            );
          }
        } catch (e) {
          debugPrint('Error calculating prayer times for day $dayOffset: $e');
        }
      }

      if (dayPrayers == null) {
        if (prayerTime != null) {
          dayPrayers = PrayerTime(
            fajr: prayerTime.fajr.add(Duration(days: dayOffset)),
            sunrise: prayerTime.sunrise.add(Duration(days: dayOffset)),
            dhuhr: prayerTime.dhuhr.add(Duration(days: dayOffset)),
            asr: prayerTime.asr.add(Duration(days: dayOffset)),
            maghrib: prayerTime.maghrib.add(Duration(days: dayOffset)),
            isha: prayerTime.isha.add(Duration(days: dayOffset)),
          );
        } else {
          continue;
        }
      }

      // Schedule only the 5 prescribed prayers. Sunrise is excluded!
      final dayPrayerList = [
        MapEntry(idFajr, dayPrayers.fajr),
        MapEntry(idDhuhr, dayPrayers.dhuhr),
        MapEntry(idAsr, dayPrayers.asr),
        MapEntry(idMaghrib, dayPrayers.maghrib),
        MapEntry(idIsha, dayPrayers.isha),
      ];

      for (final entry in dayPrayerList) {
        final baseId = entry.key;
        final alarmId = (dayOffset * 100) + baseId;
        final prayerName = prayerNameFromId(baseId);
        final scheduledTime = entry.value;

        // 1. Adhan Alarm (At Prayer Time)
        final isAdhanEnabled = AdhanAudioService().isPrayerAlertEnabled(prayerName);
        if (scheduledTime.isAfter(now) && isAdhanEnabled) {
          nativeAlarmsList.add({
            'id': alarmId,
            'type': 'ADHAN',
            'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
            'prayerName': prayerName,
            'soundId': selectedSound.id,
            'rawRes': rawRes,
            'title': selectedSound.title,
            'muadhin': selectedSound.muadhin,
            'volume': adhanVolume,
            'isAlarmMode': isAlarmMode,
          });
        }
        // Always cancel AndroidAlarmManager alarm so only native AdhanForegroundService triggers
        try {
          await AndroidAlarmManager.cancel(alarmId);
        } catch (_) {}

        // 2. Pre-Prayer Alarm (e.g. 15 minutes before prayer)
        final preTime = scheduledTime.subtract(Duration(minutes: preMinutes));
        final preAlarmId = (dayOffset * 100) + (baseId + 1000);
        final isPreEnabled = AdhanAudioService().isPrePrayerAlertEnabledFor(prayerName);

        if (preTime.isAfter(now) && isPreEnabled) {
          final preKey = NotificationServices.prayerNameToKey(prayerName);
          nativeAlarmsList.add({
            'id': preAlarmId,
            'type': 'PRE_PRAYER',
            'triggerAtMillis': preTime.millisecondsSinceEpoch,
            'prayerName': prayerName,
            'rawRes': 'pre_prayer_$preKey',
            'volume': preVolume,
            'prePrayerMinutes': preMinutes,
          });
        }
        // Always cancel AndroidAlarmManager alarm so only native AdhanAlarmReceiver triggers
        try {
          await AndroidAlarmManager.cancel(preAlarmId);
        } catch (_) {}

        // 3. Persistent Notification Refresh Alarms (at prayer time & 5-min fallback)
        if (AdhanAudioService().isPersistentNotificationEnabled) {
          final notifAlarmId = (dayOffset * 100) + (baseId + 2000);
          if (scheduledTime.isAfter(now)) {
            nativeAlarmsList.add({
              'id': notifAlarmId,
              'type': 'NOTIFICATION_UPDATE',
              'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
              'prayerName': prayerName,
            });
            await _scheduleSingleAlarm(
              notifAlarmId,
              scheduledTime,
              persistentNotificationAlarmCallback,
            );
          }

          final switchAlarmId = (dayOffset * 100) + (baseId + 2100);
          final switchTime = scheduledTime.add(const Duration(minutes: 3));
          if (switchTime.isAfter(now)) {
            await _scheduleSingleAlarm(
              switchAlarmId,
              switchTime,
              persistentNotificationAlarmCallback,
            );
          }
        }
      }

      // 4. Sunrise persistent notification alarm (Sunrise has no Adhan, but triggers transition to Dhuhr countdown)
      if (AdhanAudioService().isPersistentNotificationEnabled) {
        final sunriseAlarmId = (dayOffset * 100) + 2006;
        if (dayPrayers.sunrise.isAfter(now)) {
          nativeAlarmsList.add({
            'id': sunriseAlarmId,
            'type': 'NOTIFICATION_UPDATE',
            'triggerAtMillis': dayPrayers.sunrise.millisecondsSinceEpoch,
            'prayerName': 'الشروق',
          });
          await _scheduleSingleAlarm(
            sunriseAlarmId,
            dayPrayers.sunrise,
            persistentNotificationAlarmCallback,
          );
        }
      }
    }

    // Schedule exact native alarms for 100% reliability in Doze/Lock screen
    try {
      const channel = MethodChannel('com.example.alhuda/adhan');
      await channel.invokeMethod('scheduleNativeAlarms', {
        'alarms': nativeAlarmsList,
      });
    } catch (e) {
      debugPrint('Error invoking scheduleNativeAlarms: $e');
    }

    // Immediately refresh persistent notification if enabled
    if (AdhanAudioService().isPersistentNotificationEnabled) {
      await updatePersistentPrayerNotification(prayerTime: prayerTime);
    }
  }

  Future<void> _scheduleSingleAlarm(
    int id,
    DateTime scheduledTime,
    Function(int) callback,
  ) async {
    // 1. Try setAlarmClock (bypasses Doze mode & OEM battery killers like Xiaomi, Samsung, Huawei)
    try {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        callback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
      return;
    } catch (e) {
      debugPrint('AlarmClock mode not permitted or failed for id $id: $e');
    }

    // 2. Fallback: exact allowWhileIdle
    try {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        callback,
        exact: true,
        wakeup: true,
        alarmClock: false,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
      return;
    } catch (e2) {
      debugPrint('Exact allowWhileIdle failed for id $id: $e2');
    }

    // 3. Fallback: non-exact
    try {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        callback,
        exact: false,
        wakeup: true,
        alarmClock: false,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
      return;
    } catch (e3) {
      debugPrint('Non-exact alarm failed for id $id: $e3');
    }
  }

  Future<void> updatePersistentPrayerNotification({
    PrayerTime? prayerTime,
    String? activePrayerName,
  }) async {
    if (!Platform.isAndroid) return;
    if (!AdhanAudioService().isPersistentNotificationEnabled) {
      await NotificationServices.cancelPersistentPrayerNotification();
      return;
    }

    // If an Adhan is currently actively playing natively or in Dart, and no specific active prayer is passed,
    // do not overwrite notification 8888 with the next prayer. AdhanForegroundService manages notification 8888
    // with high priority, Adhan title, muadhin, and the stop action button.
    if (activePrayerName == null || activePrayerName.isEmpty) {
      final isPlayingAdhan = await AdhanAudioService.instance.isAdhanActive();
      if (isPlayingAdhan) {
        return;
      }
    }

    final now = DateTime.now();
    PrayerTime? prayers = prayerTime;

    if (prayers == null) {
      final saved = await loadScheduleConfig();
      Location activeLocation;
      CalculationMethod activeMethod = CalculationMethod.egypt;
      EgyptDstMode activeDstMode = EgyptDstMode.auto;
      int activeOffset = 0;

      if (saved != null && saved['location'] != null) {
        final locMap = saved['location'] as Map<String, dynamic>;
        activeLocation = Location(
          id: locMap['id'] ?? 1,
          name: locMap['name'] ?? 'القاهرة',
          countryName: locMap['countryName'] ?? 'مصر',
          countryCode: locMap['countryCode'] ?? 'EG',
          latitude: (locMap['latitude'] as num?)?.toDouble() ?? 30.0444,
          longitude: (locMap['longitude'] as num?)?.toDouble() ?? 31.2357,
          hasFixedPrayerTime: locMap['hasFixedPrayerTime'] ?? false,
        );
        if (saved['method'] != null) {
          activeMethod = CalculationMethod.values.firstWhere(
            (m) => m.name == saved['method'],
            orElse: () => CalculationMethod.egypt,
          );
        }
        if (saved['dstMode'] != null) {
          activeDstMode = EgyptDstMode.values.firstWhere(
            (d) => d.name == saved['dstMode'],
            orElse: () => EgyptDstMode.auto,
          );
        }
        activeOffset = (saved['manualMinutesOffset'] as num?)?.toInt() ?? 0;
      } else {
        activeLocation = const Location(
          id: 1,
          name: 'القاهرة',
          countryName: 'مصر',
          countryCode: 'EG',
          latitude: 30.0444,
          longitude: 31.2357,
          hasFixedPrayerTime: false,
        );
      }

      final muslimRepo = MuslimRepository();
      try {
        final raw = await muslimRepo.getPrayerTimes(
          location: activeLocation,
          date: now,
          attribute: PrayerAttribute(
            calculationMethod: activeMethod,
            asrMethod: AsrMethod.shafii,
            higherLatitudeMethod: HigherLatitudeMethod.angleBased,
          ),
        );
        if (raw != null) {
          prayers = EgyptDstHelper.adjustPrayerTimesForEgypt(
            prayer: raw,
            location: activeLocation,
            date: now,
            mode: activeDstMode,
            additionalMinutesOffset: activeOffset,
          );
        }
      } catch (e) {
        debugPrint('Error getting prayer times for persistent notification: $e');
      }
    }

    if (prayers == null) return;

    final prescribedPrayers = [
      MapEntry('الفجر', prayers.fajr),
      MapEntry('الظهر', prayers.dhuhr),
      MapEntry('العصر', prayers.asr),
      MapEntry('المغرب', prayers.maghrib),
      MapEntry('العشاء', prayers.isha),
    ];

    // 1. If an Adhan is actively playing right now, show current prayer
    String displayPrayerName = '';
    DateTime displayPrayerTime = prayers.fajr;
    bool isNegativeCounter = false;
    int progressPercent = 0;

    if (activePrayerName != null && activePrayerName.isNotEmpty) {
      final matched = prescribedPrayers.firstWhere(
        (e) => e.key == activePrayerName,
        orElse: () => MapEntry(activePrayerName, now),
      );
      displayPrayerName = matched.key;
      displayPrayerTime = matched.value;
      isNegativeCounter = true;
      progressPercent = 100;
    }

    // 2. Adhan is finished (or not playing): IMMEDIATELY show the upcoming next prayer!
    if (displayPrayerName.isEmpty) {
      final allPrayersWithSunrise = [
        MapEntry('الفجر', prayers.fajr),
        MapEntry('الشروق', prayers.sunrise),
        MapEntry('الظهر', prayers.dhuhr),
        MapEntry('العصر', prayers.asr),
        MapEntry('المغرب', prayers.maghrib),
        MapEntry('العشاء', prayers.isha),
      ];

      DateTime? prevTime;
      for (int i = 0; i < allPrayersWithSunrise.length; i++) {
        final current = allPrayersWithSunrise[i];
        if (now.isBefore(current.value)) {
          displayPrayerName = current.key;
          displayPrayerTime = current.value;
          isNegativeCounter = false;

          prevTime = (i > 0)
              ? allPrayersWithSunrise[i - 1].value
              : prayers.isha.subtract(const Duration(days: 1));
          break;
        }
      }

      // If after Isha window, next prayer is tomorrow's Fajr
      if (displayPrayerName.isEmpty) {
        displayPrayerName = 'الفجر';
        displayPrayerTime = prayers.fajr.add(const Duration(days: 1));
        isNegativeCounter = false;
        prevTime = prayers.isha;
      }

      if (prevTime != null) {
        final totalSecs = displayPrayerTime.difference(prevTime).inSeconds;
        final elapsedSecs = now.difference(prevTime).inSeconds;
        if (totalSecs > 0) {
          progressPercent =
              ((elapsedSecs / totalSecs) * 100).round().clamp(0, 100);
        }
      }
    }

    // Hijri date string in authentic Arabic with day name
    String hijriString = '';
    try {
      final h = HijriDate.now();
      final dayName = NotificationServices.getArabicDayName(now.weekday);
      final monthName = NotificationServices.getArabicHijriMonthName(h.hMonth);
      hijriString = '$dayName، ${h.hDay} $monthName ${h.hYear} هـ';
    } catch (_) {}

    // Build expanded timetable of all today's prayer times
    String expandedSchedule = '';
    try {
      final fTime = NotificationServices.formatPrayerTime(prayers.fajr);
      final sTime = NotificationServices.formatPrayerTime(prayers.sunrise);
      final dTime = NotificationServices.formatPrayerTime(prayers.dhuhr);
      final aTime = NotificationServices.formatPrayerTime(prayers.asr);
      final mTime = NotificationServices.formatPrayerTime(prayers.maghrib);
      final iTime = NotificationServices.formatPrayerTime(prayers.isha);

      String pMark(String name) => (name == displayPrayerName) ? '◀ ' : '   ';

      expandedSchedule = [
        '${pMark('الفجر')}الفجر: $fTime  •  ${pMark('الشروق')}الشروق: $sTime',
        '${pMark('الظهر')}الظهر: $dTime  •  ${pMark('العصر')}العصر: $aTime',
        '${pMark('المغرب')}المغرب: $mTime  •  ${pMark('العشاء')}العشاء: $iTime',
      ].join('\n');
    } catch (_) {}

    await NotificationServices.showPersistentPrayerNotification(
      prayerName: displayPrayerName,
      prayerTime: displayPrayerTime,
      isNegativeCounter: isNegativeCounter,
      hijriDate: hijriString,
      expandedSchedule: expandedSchedule,
      progressPercent: progressPercent,
      showProgressBar: false,
    );
  }

  Future<void> rescheduleAfterAlarm(int id) async {
    await scheduleUpcomingPrayers(null);
  }

  Future<void> cancelPrayerAlarm(int baseId) async {
    try {
      final normalizedBase = basePrayerId(baseId);
      for (int day = 0; day < 10; day++) {
        await AndroidAlarmManager.cancel((day * 100) + normalizedBase);
        await AndroidAlarmManager.cancel((day * 100) + normalizedBase + 1000);
        await AndroidAlarmManager.cancel((day * 100) + normalizedBase + 2000);
        await AndroidAlarmManager.cancel((day * 100) + normalizedBase + 2100);
      }
      const channel = MethodChannel('com.example.alhuda/adhan');
      await channel.invokeMethod('cancelNativeAlarms');
    } catch (e) {
      debugPrint('Error canceling prayer alarm: $e');
    }
  }

  Future<void> cancelAllPrayerAlarms() async {
    for (final baseId in prayerNameToId.values) {
      await cancelPrayerAlarm(baseId);
    }
    for (int day = 0; day < 10; day++) {
      try {
        await AndroidAlarmManager.cancel((day * 100) + 2006);
      } catch (_) {}
    }
    try {
      const channel = MethodChannel('com.example.alhuda/adhan');
      await channel.invokeMethod('cancelNativeAlarms');
    } catch (_) {}
  }
}
