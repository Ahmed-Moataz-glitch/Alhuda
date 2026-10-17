import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/core/utils/egypt_dst_helper.dart';
import 'package:alhuda/features/prayer_times/domain/entities/adhan_sound_entity.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
void prayerAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationServices.initializeNotifications();
  await AdhanAudioService.instance.init();

  final baseId = PrayerSchedulerService.basePrayerId(id);
  final prayerName = PrayerSchedulerService.prayerNameFromId(id);

  // 1. Strict guard: Sunrise has no Adhan in Islam
  if (prayerName == 'الشروق') {
    debugPrint('Sunrise has no Adhan alert.');
    return;
  }

  final isEnabled = AdhanAudioService().isPrayerAlertEnabled(prayerName);
  if (!isEnabled) {
    debugPrint('Prayer alert for $prayerName is disabled by user.');
    return;
  }

  // 2. Refresh rolling 7-day schedule in background so future alarms never expire
  try {
    await PrayerSchedulerService().rescheduleAfterAlarm(id);
  } catch (e) {
    debugPrint('Error refreshing upcoming alarms: $e');
  }

  final selectedSound = AdhanAudioService().selectedSound;
  final adhanVolume = AdhanAudioService().adhanVolume;

  // 3. Show interactive Adhan notification with controls (visible on lock screen)
  await NotificationServices.showAdhanControlNotification(
    id: baseId,
    prayerName: prayerName,
    sound: selectedSound,
    isPlaying: true,
    enableFullScreenIntent: true,
  );

  // 4. Setup control port & MethodChannel listeners to support pause, resume, stop
  final controlPort = ReceivePort();
  IsolateNameServer.removePortNameMapping(NotificationServices.adhanControlPort);
  IsolateNameServer.registerPortWithName(
    controlPort.sendPort,
    NotificationServices.adhanControlPort,
  );

  IsolateNameServer.removePortNameMapping('adhan_stop_port');
  IsolateNameServer.registerPortWithName(controlPort.sendPort, 'adhan_stop_port');

  const channel = MethodChannel('com.example.alhuda/adhan');
  try {
    await channel.invokeMethod('setAdhanVolume', {'volume': adhanVolume});
    await channel.invokeMethod('startAdhanMonitoring');
  } catch (_) {}

  // 5. Play Adhan audio and handle control events
  final player = AudioPlayer();
  StreamSubscription? sub;
  final completer = Completer<void>();

  try {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'stopAdhan') {
        try {
          await player.stop();
        } catch (_) {}
        if (!completer.isCompleted) completer.complete();
      } else if (call.method == 'pauseAdhan') {
        try {
          await player.pause();
          await NotificationServices.showAdhanControlNotification(
            id: baseId,
            prayerName: prayerName,
            sound: selectedSound,
            isPlaying: false,
            enableFullScreenIntent: false,
          );
        } catch (_) {}
      } else if (call.method == 'resumeAdhan') {
        try {
          await player.resume();
          await NotificationServices.showAdhanControlNotification(
            id: baseId,
            prayerName: prayerName,
            sound: selectedSound,
            isPlaying: true,
            enableFullScreenIntent: false,
          );
        } catch (_) {}
      }
    });

    controlPort.listen((message) async {
      if (message == 'stop') {
        try {
          await player.stop();
        } catch (_) {}
        if (!completer.isCompleted) completer.complete();
      } else if (message == 'pause') {
        try {
          await player.pause();
          await NotificationServices.showAdhanControlNotification(
            id: baseId,
            prayerName: prayerName,
            sound: selectedSound,
            isPlaying: false,
            enableFullScreenIntent: false,
          );
        } catch (_) {}
      } else if (message == 'resume') {
        try {
          await player.resume();
          await NotificationServices.showAdhanControlNotification(
            id: baseId,
            prayerName: prayerName,
            sound: selectedSound,
            isPlaying: true,
            enableFullScreenIntent: false,
          );
        } catch (_) {}
      }
    });

    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );

    final cleanPath = selectedSound.source.startsWith('assets/')
        ? selectedSound.source.substring(7)
        : selectedSound.source;

    sub = player.onPlayerComplete.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });

    await player.setVolume(adhanVolume);

    if (selectedSound.sourceType == AdhanAudioSourceType.asset) {
      await player.play(AssetSource(cleanPath));
    } else {
      await player.play(UrlSource(selectedSound.source));
    }

    // Keep isolate alive until audio completes or stopped, up to 5 minutes max
    await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => player.stop(),
    );
  } catch (e) {
    debugPrint('Error in prayerAlarmCallback audio player: $e');
    // Fallback: trigger system notification with native pre-bundled raw sound
    try {
      await NotificationServices.showAdhanNotification(
        id: baseId,
        prayerName: prayerName,
        sound: selectedSound,
      );
    } catch (_) {}
  } finally {
    try {
      await sub?.cancel();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
    controlPort.close();
    IsolateNameServer.removePortNameMapping(NotificationServices.adhanControlPort);
    IsolateNameServer.removePortNameMapping('adhan_stop_port');
    try {
      await channel.invokeMethod('restoreAlarmVolume');
    } catch (_) {}
    try {
      await channel.invokeMethod('stopAdhanMonitoring');
    } catch (_) {}
    await NotificationServices.cancelAdhanNotification(id: baseId);
  }
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

  static const Map<String, int> prayerNameToId = {
    'الفجر': idFajr,
    'الظهر': idDhuhr,
    'العصر': idAsr,
    'المغرب': idMaghrib,
    'العشاء': idIsha,
  };

  /// Normalizes any day-offset prayer alarm id (e.g. 1001, 1101, 1201) to the base id (1001).
  static int basePrayerId(int id) {
    if (id >= 1000 && id < 2000) {
      return 1000 + (id % 100);
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

        // Skip if already in the past
        if (scheduledTime.isBefore(now)) {
          continue;
        }

        final isEnabled = AdhanAudioService().isPrayerAlertEnabled(prayerName);
        if (isEnabled) {
          await _scheduleSingleAlarm(alarmId, scheduledTime);
        } else {
          try {
            await AndroidAlarmManager.cancel(alarmId);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _scheduleSingleAlarm(int id, DateTime scheduledTime) async {
    // 1. Try setAlarmClock (bypasses Doze mode & OEM battery killers like Xiaomi, Samsung, Huawei)
    try {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        prayerAlarmCallback,
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
        prayerAlarmCallback,
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
        prayerAlarmCallback,
        exact: false,
        wakeup: true,
        alarmClock: false,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    } catch (e3) {
      debugPrint('Non-exact alarm failed for id $id: $e3');
    }
  }

  Future<void> rescheduleAfterAlarm(int id) async {
    await scheduleUpcomingPrayers(null);
  }

  Future<void> cancelPrayerAlarm(int baseId) async {
    try {
      final normalizedBase = basePrayerId(baseId);
      for (int day = 0; day < 10; day++) {
        await AndroidAlarmManager.cancel((day * 100) + normalizedBase);
      }
    } catch (e) {
      debugPrint('Error canceling prayer alarm: $e');
    }
  }

  Future<void> cancelAllPrayerAlarms() async {
    for (final baseId in prayerNameToId.values) {
      await cancelPrayerAlarm(baseId);
    }
  }
}
