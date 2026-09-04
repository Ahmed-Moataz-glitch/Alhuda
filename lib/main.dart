import 'package:alhuda/view/pages/home_page.dart';
import 'package:alhuda/view/widgets/app_constants.dart';
import 'package:alhuda/view/widgets/notification_services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AndroidAlarmManager.initialize();
  } catch (e) {
    debugPrint('AndroidAlarmManager initialization error: $e');
  }

  try {
    await NotificationServices.initializeNotifications();
    NotificationServices.periodicNotification(
      title: AppConstants.notificationTitle,
      body: AppConstants.notificationBody,
    );
  } catch (e) {
    debugPrint('NotificationServices initialization error: $e');
  }

  FlutterNativeSplash.remove();
  runApp(const MyApp());

  // Request permissions asynchronously after UI has drawn
  NotificationServices.requestNotificationPermission();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(411, 869),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: ThemeData(
          fontFamily: "Almarai",
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const HomePage(),
      ),
    );
  }
}
