import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/view/widgets/app_constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class NotificationServices {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static AndroidInitializationSettings androidInitializationSettings =
      const AndroidInitializationSettings(AppConstants.notificationIcon);
  static AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        'channelId',
        'channelName',
        channelDescription: 'channel_description',
        icon: AppConstants.notificationIcon,
        color: AppColors.primary,
        importance: Importance.max,
        priority: Priority.high,
      );
  static NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  static void requestNotificationPermission() async {
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImpl?.requestNotificationsPermission();
  }

  static void initializeNotifications() async {
    requestNotificationPermission();
    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  static void sendNotification({
    required String title,
    required String body,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  static void periodicNotification({
    required String title,
    required String body,
  }) async {
    await flutterLocalNotificationsPlugin.periodicallyShow(
      id: 0,
      title: title,
      body: body,
      repeatInterval: RepeatInterval.hourly,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static void cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
