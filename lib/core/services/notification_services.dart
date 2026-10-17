import 'dart:ui';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/constants/app_constants.dart';
import 'package:alhuda/core/services/adhan_audio_service.dart';
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
  } else {
    NotificationServices.handleStopAdhanAction(fromBackgroundIsolate: true);
  }
}

abstract class NotificationServices {
  static const String actionStopAdhan = 'stop_adhan';
  static const String actionPauseAdhan = 'pause_adhan';
  static const String actionResumeAdhan = 'resume_adhan';
  static const String adhanControlPort = 'adhan_control_port';

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
        largeIcon: const DrawableResourceAndroidBitmap(AppConstants.notificationIcon),
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
      return await androidImpl?.areNotificationsEnabled() ?? false;
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
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

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
      cancelAdhanNotification();
    } catch (_) {}
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
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  static Future<void> showAdhanControlNotification({
    int id = 9999,
    required String prayerName,
    required AdhanSound sound,
    required bool isPlaying,
    String? body,
    bool enableFullScreenIntent = false,
  }) async {
    try {
      final actions = <AndroidNotificationAction>[
        if (isPlaying)
          const AndroidNotificationAction(
            actionPauseAdhan,
            'إيقاف مؤقت',
            showsUserInterface: false,
            cancelNotification: false,
          )
        else
          const AndroidNotificationAction(
            actionResumeAdhan,
            'استئناف',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        const AndroidNotificationAction(
          actionStopAdhan,
          'إيقاف الأذان',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_control_channel_v7',
          'تنبيهات وأدوات الأذان',
          channelDescription:
              'إشعارات الأذان مع أدوات التحكم في الصوت والتشغيل',
          icon: AppConstants.notificationIcon,
          largeIcon: const DrawableResourceAndroidBitmap(AppConstants.notificationIcon),
          color: AppColors.primary,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: enableFullScreenIntent,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
          actions: actions,
        ),
      );

      final title = prayerName.isNotEmpty
          ? 'حان الآن موعد أذان $prayerName'
          : 'أذان الصلاة (${sound.title})';
      final defaultBody = isPlaying
          ? 'حي على الصلاة .. حي على الفلاح (${sound.title})'
          : 'متوقف مؤقتاً (${sound.title})';

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
    int id = 9999,
    required String prayerName,
    required AdhanSound sound,
    String? body,
  }) async {
    try {
      final rawRes = sound.source.split('/').last.replaceAll('.mp3', '');
      final channelId = 'adhan_sound_channel_${sound.id}_v7';

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
          'أذان - ${sound.title}',
          channelDescription: 'تنبيه أذان بصوت ${sound.muadhin}',
          icon: AppConstants.notificationIcon,
          largeIcon: const DrawableResourceAndroidBitmap(AppConstants.notificationIcon),
          color: AppColors.primary,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(rawRes),
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
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
      debugPrint('Error showing Adhan notification: $e');
    }
  }

  static Future<void> sendAdhanNotification({
    required int id,
    required String prayerName,
    AdhanSound? sound,
    String? body,
    bool isPlaying = true,
  }) async {
    final adhanSound = sound ?? AdhanData.defaultAdhan;
    await showAdhanNotification(
      id: id,
      prayerName: prayerName,
      sound: adhanSound,
      body: body,
    );
  }

  static Future<void> cancelAdhanNotification({int? id}) async {
    try {
      if (id != null) {
        await flutterLocalNotificationsPlugin.cancel(id: id);
      } else {
        await flutterLocalNotificationsPlugin.cancelAll();
      }
    } catch (e) {
      debugPrint('Error canceling adhan notification: $e');
    }
  }

  static void periodicNotification({
    required String title,
    required String body,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.periodicallyShow(
        id: 1,
        title: title,
        body: body,
        repeatInterval: RepeatInterval.hourly,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await flutterLocalNotificationsPlugin.periodicallyShow(
          id: 1,
          title: title,
          body: body,
          repeatInterval: RepeatInterval.hourly,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('Error scheduling periodic notification: $e');
      }
    }
  }

  static void cancelNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
