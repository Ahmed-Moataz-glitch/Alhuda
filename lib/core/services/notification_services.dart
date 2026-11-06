import 'dart:ui';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/constants/app_constants.dart';
import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/prayer_scheduler_service.dart';
import 'package:alhuda/features/prayer_times/data/models/adhan_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final actionId = response.actionId;
  if (actionId == NotificationServices.actionStopAdhan) {
    NotificationServices.handleStopAdhanAction(fromBackgroundIsolate: true);
  } else if (actionId == NotificationServices.actionPauseAdhan) {
    NotificationServices.handlePauseAdhanAction(fromBackgroundIsolate: true);
  } else if (actionId == NotificationServices.actionResumeAdhan) {
    NotificationServices.handleResumeAdhanAction(fromBackgroundIsolate: true);
  } else if (actionId == NotificationServices.actionStopPersistent) {
    NotificationServices.handleStopPersistentAction(fromBackgroundIsolate: true);
  }
}

abstract class NotificationServices {
  static const int notificationId = AppConstants.notificationId;
  static const int persistentNotificationId = 8888;
  static const int prePrayerNotificationId = 7777;
  static const Duration reminderInterval = AppConstants.reminderInterval;
  static const String actionStopAdhan = 'stop_adhan';
  static const String actionPauseAdhan = 'pause_adhan';
  static const String actionResumeAdhan = 'resume_adhan';
  static const String actionStopPersistent = 'stop_persistent';
  static const String actionOpenApp = 'open_app';
  static const String adhanControlPort = 'adhan_control_port';
  static const String persistentChannelId = 'alhuda_persistent_prayer_channel_v1';
  static const String prePrayerChannelId = 'pre_prayer_reminder_channel_v1';

  static const MethodChannel _adhanChannel = MethodChannel(
    'com.example.alhuda/adhan',
  );

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings(AppConstants.notificationIcon);

  static final AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        'channelId',
        'channelName',
        channelDescription: 'channel_description',
        icon: AppConstants.notificationIcon,
        largeIcon: const DrawableResourceAndroidBitmap(AppConstants.notificationLargeIcon),
        color: AppColors.primary,
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      );

  static final NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  static Future<bool> requestNotificationPermission() async {
    try {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
      final isEnabled = await androidImpl?.areNotificationsEnabled() ?? false;
      if (isEnabled && AdhanAudioService.instance.isPersistentNotificationEnabled) {
        try {
          await PrayerSchedulerService().updatePersistentPrayerNotification();
        } catch (_) {}
      }
      return isEnabled;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> initializeNotifications() async {
    try {
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            ),
          );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.actionId == actionStopAdhan) {
            handleStopAdhanAction();
          } else if (response.actionId == actionPauseAdhan) {
            handlePauseAdhanAction();
          } else if (response.actionId == actionResumeAdhan) {
            handleResumeAdhanAction();
          } else if (response.actionId == actionStopPersistent) {
            handleStopPersistentAction();
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Cancel any legacy adhan or periodic reminders (ID 0, 9991, 9999, 7777) so only persistent 8888 exists
      try {
        await flutterLocalNotificationsPlugin.cancel(id: 0);
        await flutterLocalNotificationsPlugin.cancel(id: 9991);
        await flutterLocalNotificationsPlugin.cancel(id: 9999);
        await flutterLocalNotificationsPlugin.cancel(id: prePrayerNotificationId);
      } catch (_) {}

      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImpl != null) {
        // Register default general channel
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'channelId',
            'إشعارات عامة',
            description: 'التذكيرات الدورية والأذكار',
            importance: Importance.max,
          ),
        );

        // Register dedicated Persistent Prayer notification channel (silent & low-priority)
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            persistentChannelId,
            'إشعار مواقيت الصلاة الدائم',
            description: 'عرض الصلاة القادمة والوقت المتبقي بشكل دائم في الإشعارات',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );

        // Register dedicated Pre-Prayer voice channels for each prayer (native voice audio)
        const prePrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
        const prePrayerNames = {
          'fajr': 'الفجر',
          'dhuhr': 'الظهر',
          'asr': 'العصر',
          'maghrib': 'المغرب',
          'isha': 'العشاء',
        };

        for (final key in prePrayerKeys) {
          final pName = prePrayerNames[key]!;
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              'pre_prayer_voice_channel_${key}_v3',
              'تنبيه اقتراب صلاة $pName',
              description: 'صوت بشري ينبه باقتراب صلاة $pName قبل الأذان',
              importance: Importance.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('pre_prayer_$key'),
              enableVibration: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          );
        }

        // Register dedicated Adhan control channel with silent chime for in-app mini-player
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'adhan_control_channel_v7',
            'تنبيهات وأدوات الأذان',
            description: 'إشعارات الأذان مع أدوات التحكم في الصوت والتشغيل',
            importance: Importance.max,
            playSound: false,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );

        // Register dedicated notification channels for each Adhan sound with native raw audio
        for (final sound in AdhanData.availableSounds) {
          final rawRes = sound.source.split('/').last.replaceAll('.mp3', '');
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              'adhan_sound_channel_${sound.id}_v7',
              'أذان - ${sound.title}',
              description: 'إشعارات الأذان بصوت ${sound.muadhin}',
              importance: Importance.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound(rawRes),
              enableVibration: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  static void handleStopAdhanAction({bool fromBackgroundIsolate = false}) {
    try {
      final sendPort = IsolateNameServer.lookupPortByName(adhanControlPort);
      sendPort?.send('stop');
    } catch (_) {}

    try {
      final legacyPort = IsolateNameServer.lookupPortByName('adhan_stop_port');
      legacyPort?.send('stop');
    } catch (_) {}

    try {
      _adhanChannel.invokeMethod('stopAdhan').catchError((_) => null);
    } catch (_) {}

    if (!fromBackgroundIsolate) {
      try {
        AdhanAudioService.instance.stop();
      } catch (_) {}
    }

    try {
      cancelAdhanNotification(id: notificationId);
    } catch (_) {}

    if (AdhanAudioService.instance.isPersistentNotificationEnabled) {
      try {
        PrayerSchedulerService().updatePersistentPrayerNotification();
      } catch (_) {}
    }
  }

  static void handlePauseAdhanAction({bool fromBackgroundIsolate = false}) {
    try {
      final sendPort = IsolateNameServer.lookupPortByName(adhanControlPort);
      sendPort?.send('pause');
    } catch (_) {}

    try {
      _adhanChannel.invokeMethod('pauseAdhan').catchError((_) => null);
    } catch (_) {}

    if (!fromBackgroundIsolate) {
      try {
        AdhanAudioService.instance.pause();
      } catch (_) {}
    }
  }

  static void handleResumeAdhanAction({bool fromBackgroundIsolate = false}) {
    try {
      final sendPort = IsolateNameServer.lookupPortByName(adhanControlPort);
      sendPort?.send('resume');
    } catch (_) {}

    try {
      _adhanChannel.invokeMethod('resumeAdhan').catchError((_) => null);
    } catch (_) {}

    if (!fromBackgroundIsolate) {
      try {
        AdhanAudioService.instance.resume();
      } catch (_) {}
    }
  }

  static void sendNotification({
    required String title,
    required String body,
    int id = notificationId,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  static Future<void> showAdhanControlNotification({
    int id = persistentNotificationId,
    required String prayerName,
    required AdhanSound sound,
    required bool isPlaying,
    String? body,
    bool enableFullScreenIntent = false,
  }) async {
    try {
      const channelId = 'adhan_control_channel_v7';

      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          actionStopAdhan,
          'إيقاف الأذان',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'تنبيهات وأدوات الأذان',
          channelDescription: 'إشعارات الأذان مع أدوات التحكم في الصوت والتشغيل',
          icon: AppConstants.notificationIcon,
          largeIcon: const DrawableResourceAndroidBitmap(
            AppConstants.notificationLargeIcon,
          ),
          color: AppColors.primary,
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: enableFullScreenIntent,
          ongoing: isPlaying,
          autoCancel: !isPlaying,
          actions: actions,
        ),
      );

      final title = prayerName.isNotEmpty
          ? 'حان الآن موعد أذان $prayerName'
          : 'حان الآن موعد الأذان (${sound.title})';
      final defaultBody = 'حي على الصلاة .. حي على الفلاح (${sound.muadhin})';

      await flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body ?? defaultBody,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error showing Adhan control notification: $e');
    }
  }

  static Future<void> showAdhanNotification({
    int id = persistentNotificationId,
    required String prayerName,
    required AdhanSound sound,
    String? body,
    bool enableFullScreenIntent = false,
  }) async {
    await showAdhanControlNotification(
      id: id,
      prayerName: prayerName,
      sound: sound,
      isPlaying: true,
      body: body,
      enableFullScreenIntent: enableFullScreenIntent,
    );
  }

  static Future<void> sendAdhanNotification({
    int id = persistentNotificationId,
    required String prayerName,
    AdhanSound? sound,
    String? body,
    bool isPlaying = true,
    bool enableFullScreenIntent = false,
  }) async {
    final adhanSound = sound ?? AdhanData.defaultAdhan;
    await showAdhanNotification(
      id: id,
      prayerName: prayerName,
      sound: adhanSound,
      body: body,
      enableFullScreenIntent: enableFullScreenIntent,
    );
  }

  static Future<void> cancelAdhanNotification({int? id}) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: 9999);
      await flutterLocalNotificationsPlugin.cancel(id: 0);
      if (!AdhanAudioService.instance.isPersistentNotificationEnabled) {
        await flutterLocalNotificationsPlugin.cancel(
          id: id ?? persistentNotificationId,
        );
      }
    } catch (e) {
      debugPrint('Error canceling adhan notification: $e');
    }
  }

  static Future<void> cancelPeriodicNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('Error canceling periodic notification: $e');
    }
  }

  static void periodicNotification({
    required String title,
    required String body,
    int id = notificationId,
    Duration repeatDuration = reminderInterval,
  }) async {
    // Disabled as requested: Only the persistent notification (ID 8888) is displayed.
    return;
  }

  static void handleStopPersistentAction({bool fromBackgroundIsolate = false}) async {
    try {
      await cancelPersistentPrayerNotification();
      await AdhanAudioService.instance.togglePersistentNotification(false);
    } catch (e) {
      debugPrint('Error stopping persistent notification: $e');
    }
  }

  static String getArabicDayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }

  static String getArabicHijriMonthName(int month) {
    const names = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    if (month >= 1 && month <= 12) {
      return names[month - 1];
    }
    return '';
  }

  static String formatPrayerTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  static Future<void> showPersistentPrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    required bool isNegativeCounter,
    required String hijriDate,
    String? expandedSchedule,
    int progressPercent = 0,
    bool showProgressBar = false,
  }) async {
    try {
      final formattedTime = formatPrayerTime(prayerTime);

      final String title = isNegativeCounter
          ? '📢 حان الآن: صلاة $prayerName ($formattedTime)'
          : (prayerName == 'الشروق'
              ? '🌅 موعد الشروق • $formattedTime'
              : '🕌 صلاة $prayerName • $formattedTime');

      final String subText = isNegativeCounter
          ? 'حان وقت الصلاة'
          : (prayerName == 'الشروق' ? 'موعد الشروق' : 'الصلاة القادمة');

      final String body = hijriDate.isNotEmpty
          ? '📅 $hijriDate'
          : 'تطبيق الهُدى - مواقيت الصلاة';

      final styleInformation = BigTextStyleInformation(
        expandedSchedule != null && expandedSchedule.isNotEmpty
            ? '$body\n\n$expandedSchedule'
            : body,
        contentTitle: title,
        summaryText: subText,
      );

      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          actionOpenApp,
          'فتح التطبيق',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        if (isNegativeCounter)
          const AndroidNotificationAction(
            actionStopAdhan,
            'إيقاف الأذان',
            showsUserInterface: false,
            cancelNotification: false,
          )
        else
          const AndroidNotificationAction(
            actionStopPersistent,
            'إيقاف الإشعار',
            showsUserInterface: false,
            cancelNotification: true,
          ),
      ];

      final now = DateTime.now();
      final isPast = now.isAfter(prayerTime);
      final shouldCountDown = !isNegativeCounter && !isPast;
      final enableChronometer = isNegativeCounter || (!isPast);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          persistentChannelId,
          'إشعار مواقيت الصلاة الدائم',
          channelDescription:
              'عرض الصلاة القادمة والوقت المتبقي بشكل دائم في الإشعارات',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: true,
          when: prayerTime.millisecondsSinceEpoch,
          usesChronometer: enableChronometer,
          chronometerCountDown: shouldCountDown,
          showProgress: showProgressBar,
          maxProgress: showProgressBar ? 100 : 0,
          progress: showProgressBar ? progressPercent.clamp(0, 100) : 0,
          color: AppColors.primary,
          icon: AppConstants.notificationIcon,
          largeIcon: const DrawableResourceAndroidBitmap(AppConstants.notificationLargeIcon),
          subText: subText,
          styleInformation: styleInformation,
          category: AndroidNotificationCategory.status,
          visibility: NotificationVisibility.public,
          actions: actions,
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        id: persistentNotificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error showing persistent prayer notification: $e');
    }
  }

  static Future<void> cancelPersistentPrayerNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: persistentNotificationId);
    } catch (e) {
      debugPrint('Error canceling persistent prayer notification: $e');
    }
  }

  static String prayerNameToKey(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return 'fajr';
      case 'الظهر':
        return 'dhuhr';
      case 'العصر':
        return 'asr';
      case 'المغرب':
        return 'maghrib';
      case 'العشاء':
        return 'isha';
      default:
        return 'dhuhr';
    }
  }

  static Future<void> showPrePrayerNotification({
    required String prayerName,
    required int minutesRemaining,
  }) async {
    try {
      final key = prayerNameToKey(prayerName);
      final rawSoundName = 'pre_prayer_$key';
      final channelId = 'pre_prayer_voice_channel_${key}_v3';

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'تنبيه اقتراب صلاة $prayerName',
          channelDescription:
              'صوت بشري ينبه باقتراب صلاة $prayerName قبل الأذان',
          icon: AppConstants.notificationIcon,
          largeIcon: const DrawableResourceAndroidBitmap(AppConstants.notificationLargeIcon),
          color: AppColors.primary,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(rawSoundName),
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: false,
          ongoing: false,
          autoCancel: true,
        ),
      );

      final title = 'اقتربت صلاة $prayerName';
      final body =
          'بقي $minutesRemaining دقيقة على أذان $prayerName - استعد للصلاة والوضوء';

      await flutterLocalNotificationsPlugin.show(
        id: prePrayerNotificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error showing pre-prayer notification: $e');
    }
  }

  static Future<void> cancelPrePrayerNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: prePrayerNotificationId);
    } catch (e) {
      debugPrint('Error canceling pre-prayer notification: $e');
    }
  }

  static void cancelNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
