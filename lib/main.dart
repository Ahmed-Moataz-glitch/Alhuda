import 'package:alhuda/core/constants/app_constants.dart';
import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/core/services/prayer_scheduler_service.dart';
import 'package:alhuda/core/theme/app_theme.dart';
import 'package:alhuda/services/font_size_service.dart';
import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/tajweed_page_cache_service.dart';
import 'package:alhuda/services/tafsir_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/core/view/pages/home_page.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri_date/hijri_date.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure memory and image cache limits for low-RAM devices
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024; // 30 MB

  // Initialize Hijri date in Arabic
  HijriDate.setLocal('ar');

  try {
    await ThemeService.instance.init();
  } catch (e) {
    debugPrint('ThemeService initialization error: $e');
  }

  try {
    await FontSizeService.instance.init();
  } catch (e) {
    debugPrint('FontSizeService initialization error: $e');
  }

  try {
    await AdhanAudioService.instance.init();
  } catch (e) {
    debugPrint('AdhanAudioService initialization error: $e');
  }

  try {
    await AndroidAlarmManager.initialize();
  } catch (e) {
    debugPrint('AndroidAlarmManager initialization error: $e');
  }

  try {
    await NotificationServices.initializeNotifications();
    await NotificationServices.cancelPeriodicNotification();

    final launchDetails = await NotificationServices
        .flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final response = launchDetails.notificationResponse;
      if (response?.actionId == NotificationServices.actionStopAdhan) {
        NotificationServices.handleStopAdhanAction();
      } else if (response?.actionId == NotificationServices.actionPauseAdhan) {
        NotificationServices.handlePauseAdhanAction();
      } else if (response?.actionId == NotificationServices.actionResumeAdhan) {
        NotificationServices.handleResumeAdhanAction();
      } else if (response?.actionId == NotificationServices.actionStopPersistent) {
        NotificationServices.handleStopPersistentAction();
      }
    }

    if (AdhanAudioService.instance.isPersistentNotificationEnabled) {
      PrayerSchedulerService().updatePersistentPrayerNotification();
    }
  } catch (e) {
    debugPrint('NotificationServices initialization error: $e');
  }

  FlutterNativeSplash.remove();
  runApp(const MyApp());

  // Asynchronously initialize secondary services and permissions after UI has painted
  _initPostLaunchServices();
}

Future<void> _initPostLaunchServices() async {
  try {
    // 1. Initialize secondary background services without blocking UI
    try {
      await QuranService.instance.init();
    } catch (e) {
      debugPrint('QuranService init error: $e');
    }

    try {
      await TajweedPageCacheService.instance.init();
    } catch (e) {
      debugPrint('TajweedPageCacheService init error: $e');
    }

    try {
      await TafsirService.instance.init();
    } catch (e) {
      debugPrint('TafsirService init error: $e');
    }

    // 2. Request notification and exact alarm permissions and show persistent notification immediately if granted
    final isNotificationGranted =
        await NotificationServices.requestNotificationPermission();
    if (isNotificationGranted &&
        AdhanAudioService.instance.isPersistentNotificationEnabled) {
      await PrayerSchedulerService().updatePersistentPrayerNotification();
    }

    // 3. Automatically schedule rolling 7-day prayers
    await PrayerSchedulerService().scheduleUpcomingPrayers(null);

    // 4. Request battery optimization exemption
    final isIgnoring =
        await AdhanAudioService.instance.isIgnoringBatteryOptimizations();
    if (!isIgnoring) {
      await Future.delayed(const Duration(milliseconds: 1500));
      await AdhanAudioService.instance.requestIgnoreBatteryOptimizations();
    }
  } catch (e) {
    debugPrint('Error in post-launch services initialization: $e');
  }
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
