import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/view/pages/home_page.dart';
import 'package:alhuda/view/theme/app_theme.dart';
import 'package:alhuda/view/widgets/app_constants.dart';
import 'package:alhuda/view/widgets/notification_services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri_date/hijri_date.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hijri date in Arabic
  HijriDate.setLocal('ar');

  try {
    await ThemeService.instance.init();
  } catch (e) {
    debugPrint('ThemeService initialization error: $e');
  }

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

  try {
    await QuranService.instance.init();
  } catch (e) {
    debugPrint('QuranService initialization error: $e');
  }

  FlutterNativeSplash.remove();
  runApp(const MyApp());

  // Request permissions asynchronously after UI has drawn
  NotificationServices.requestNotificationPermission();
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
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
      child: ListenableBuilder(
        listenable: ThemeService.instance,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeService.instance.themeMode,
            scrollBehavior: const AppScrollBehavior(),
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
