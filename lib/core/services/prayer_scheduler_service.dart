import 'dart:async';
import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

@pragma('vm:entry-point')
void prayerAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationServices.initializeNotifications();

  final prayerName = PrayerSchedulerService.prayerNameFromId(id);
  final isEnabled = AdhanAudioService().isPrayerAlertEnabled(prayerName);

  if (!isEnabled) {
    debugPrint('Prayer alert for $prayerName is disabled by user.');
    return;
  }

  final selectedSound = AdhanAudioService().selectedSound;

  // 1. Show high-priority notification with custom Adhan sound from raw resources
  await NotificationServices.sendAdhanNotification(
    id: id,
    prayerName: prayerName,
    sound: selectedSound,
  );

  // 2. Play Adhan audio loudly and keep the background isolate alive until complete
  try {
    final player = AudioPlayer();
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
      ),
    );

    final cleanPath = selectedSound.source.startsWith('assets/')
        ? selectedSound.source.substring(7)
        : selectedSound.source;

    final completer = Completer<void>();
    final sub = player.onPlayerComplete.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });

    await player.play(AssetSource(cleanPath));

    // Keep isolate alive until audio completes, up to 4 minutes max
    await completer.future.timeout(
      const Duration(minutes: 4),
      onTimeout: () => player.stop(),
    );
    await sub.cancel();
    await player.dispose();
  } catch (e) {
    debugPrint('Error in prayerAlarmCallback audio player: $e');
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

  static String prayerNameFromId(int id) {
    switch (id) {
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

  Future<void> scheduleUpcomingPrayers(PrayerTime prayerTime) async {
    final now = DateTime.now();

    final prayers = [
      MapEntry(idFajr, prayerTime.fajr),
      MapEntry(idDhuhr, prayerTime.dhuhr),
      MapEntry(idAsr, prayerTime.asr),
      MapEntry(idMaghrib, prayerTime.maghrib),
      MapEntry(idIsha, prayerTime.isha),
    ];

    for (final entry in prayers) {
      var scheduledTime = entry.value;
      if (scheduledTime.isBefore(now)) {
        // If already passed today, schedule for tomorrow at the same time
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final prayerName = prayerNameFromId(entry.key);
      final isEnabled = AdhanAudioService().isPrayerAlertEnabled(prayerName);

      if (isEnabled) {
        try {
          await AndroidAlarmManager.oneShotAt(
            scheduledTime,
            entry.key,
            prayerAlarmCallback,
            exact: true,
            wakeup: true,
            alarmClock: true,
            allowWhileIdle: true,
            rescheduleOnReboot: true,
          );
          debugPrint(
            'Scheduled Adhan alarm for $prayerName at $scheduledTime (id: ${entry.key})',
          );
        } catch (e) {
          debugPrint(
            'Exact alarm not permitted or failed for $prayerName, falling back: $e',
          );
          try {
            await AndroidAlarmManager.oneShotAt(
              scheduledTime,
              entry.key,
              prayerAlarmCallback,
              exact: false,
              wakeup: true,
              allowWhileIdle: true,
              rescheduleOnReboot: true,
            );
          } catch (e2) {
            debugPrint('Fallback alarm failed for $prayerName: $e2');
          }
        }
      } else {
        await cancelPrayerAlarm(entry.key);
      }
    }
  }

  Future<void> cancelPrayerAlarm(int id) async {
    try {
      await AndroidAlarmManager.cancel(id);
    } catch (e) {
      debugPrint('Error canceling alarm id $id: $e');
    }
  }

  Future<void> cancelAllPrayerAlarms() async {
    for (final id in prayerNameToId.values) {
      await cancelPrayerAlarm(id);
    }
  }
}
