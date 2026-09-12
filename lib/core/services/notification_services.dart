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
  if (response.actionId == NotificationServices.actionStopAdhan) {
    NotificationServices.handleStopAdhanAction();
  }
}

abstract class NotificationServices {
  static const String actionStopAdhan = 'stop_adhan';
  static const MethodChannel _adhanChannel =
      MethodChannel('com.example.alhuda/adhan');

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
        color: AppColors.primary,
        importance: Importance.max,
        priority: Priority.high,
      );

  static final NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  static Future<void> requestNotificationPermission() async {
    try {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  static Future<void> initializeNotifications() async {
    try {
      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidInitializationSettings);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.actionId == actionStopAdhan) {
            handleStopAdhanAction();
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

        // Explicitly register notification channels for all 8 Adhan sounds with alarm audio attributes
        for (final sound in AdhanData.availableSounds) {
          final rawRes = sound.source.split('/').last.replaceAll('.mp3', '');
          final channel = AndroidNotificationChannel(
            'adhan_channel_${sound.id}',
            'أذان - ${sound.title}',
            description: 'تنبيه أذان بصوت ${sound.muadhin}',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(rawRes),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            enableVibration: true,
          );
          await androidImpl.createNotificationChannel(channel);
        }
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  static void handleStopAdhanAction() {
    try {
      final sendPort = IsolateNameServer.lookupPortByName('adhan_stop_port');
      sendPort?.send('stop');
    } catch (_) {}

    try {
      AdhanAudioService().stop();
    } catch (_) {}

    try {
      _adhanChannel.invokeMethod('stopAdhan');
    } catch (_) {}

    try {
      cancelNotification();
    } catch (_) {}
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

  static Future<void> sendAdhanNotification({
    required int id,
    required String prayerName,
    AdhanSound? sound,
    String? body,
  }) async {
    try {
      final adhanSound = sound ?? AdhanData.defaultAdhan;
      final rawRes = adhanSound.source.split('/').last.replaceAll('.mp3', '');
      final channelId = 'adhan_channel_${adhanSound.id}';

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'أذان - ${adhanSound.title}',
          channelDescription: 'تنبيه أذان بصوت ${adhanSound.muadhin}',
          icon: AppConstants.notificationIcon,
          color: AppColors.primary,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(rawRes),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          actions: const [
            AndroidNotificationAction(
              NotificationServices.actionStopAdhan,
              'إيقاف الأذان',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        id: id,
        title: 'حان الآن موعد أذان $prayerName',
        body: body ?? 'حي على الصلاة .. حي على الفلاح (${adhanSound.title})',
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error sending Adhan notification: $e');
    }
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
        id: 0,
        title: title,
        body: body,
        repeatInterval: RepeatInterval.hourly,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await flutterLocalNotificationsPlugin.periodicallyShow(
          id: 0,
          title: title,
          body: body,
          repeatInterval: RepeatInterval.hourly,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
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
