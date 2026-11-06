import 'dart:io';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/utils/adaptive_layout_helper.dart';
import 'package:alhuda/features/app_guide/data/repositories/app_guide_data.dart';
import 'package:alhuda/features/app_guide/presentation/view/widgets/app_features_tab.dart';
import 'package:alhuda/features/app_guide/presentation/view/widgets/app_guide_steps_tab.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';

/// صفحة دليل استخدام ومميزات التطبيق مع مشغل فيديو Better Player محلي يعمل بدون إنترنت
class AppGuidePage extends StatefulWidget {
  final bool hasScaffold;

  const AppGuidePage({super.key, this.hasScaffold = true});

  @override
  State<AppGuidePage> createState() => _AppGuidePageState();
}

class _AppGuidePageState extends State<AppGuidePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _betterPlayerKey = GlobalKey();
  BetterPlayerController? _betterPlayerController;
  late TabController _tabController;
  bool _isPlayerReady = false;
  bool _hasError = false;
  bool _isVideoInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeBetterPlayer();
  }

  Future<void> _initializeBetterPlayer() async {
    try {
      // تجهيز ملف الفيديو المحلي من الأصول إلى مجلد مؤقت للتشغيل عبر Better Player
      final tempDir = await getTemporaryDirectory();
      final localVideoFile = File('${tempDir.path}/app_guide.mp4');

      if (!await localVideoFile.exists() || await localVideoFile.length() == 0) {
        final byteData = await rootBundle.load(AppGuideData.videoAssetPath);
        final buffer = byteData.buffer;
        await localVideoFile.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          flush: true,
        );
      }

      final betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        localVideoFile.path,
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
      );

      final controlsConfiguration = BetterPlayerControlsConfiguration(
        enableFullscreen: true,
        enableMute: true,
        enablePlayPause: true,
        enableProgressBar: true,
        enableProgressBarDrag: true,
        enableProgressText: true,
        enableSkips: true,
        enableQualities: false,
        enableSubtitles: false,
        enableAudioTracks: false,
        enablePlaybackSpeed: true,
        enablePip: false,
        showControlsOnInitialize: false,
        progressBarPlayedColor: AppColors.primary,
        progressBarHandleColor: AppColors.primary,
        progressBarBufferedColor: AppColors.primary.withAlpha(80),
        progressBarBackgroundColor: Colors.white24,
        controlBarColor: Colors.black.withAlpha(150),
        iconsColor: Colors.white,
        loadingColor: AppColors.primary,
      );

      final betterPlayerConfiguration = BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: false,
        looping: false,
        handleLifecycle: true,
        autoDispose: false,
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
        controlsConfiguration: controlsConfiguration,
      );

      final controller = BetterPlayerController(
        betterPlayerConfiguration,
        betterPlayerDataSource: betterPlayerDataSource,
      );

      if (mounted) {
        setState(() {
          _betterPlayerController = controller;
          _isPlayerReady = true;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isPlayerReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose(forceDispose: true);
    _tabController.dispose();
    super.dispose();
  }

  void _restartVideo() {
    HapticFeedback.lightImpact();
    final controller = _betterPlayerController;
    if (controller == null) return;
    try {
      controller.seekTo(Duration.zero);
      controller.play();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = MediaQuery.of(context).size.shortestSide;
        final isLandscapeTablet = shortestSide >= AdaptiveBreakpoints.tabletMin &&
            MediaQuery.of(context).orientation == Orientation.landscape;
        if (isLandscapeTablet) {
          return Row(
            children: [
              // الجانب الأيمن: مشغل BetterPlayer وأدوات التحكم
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildVideoPlayer(),
                    _buildVideoControlsBar(),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              // الجانب الأيسر: شريط التبويبات والمحتوى
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [AppFeaturesTab(), AppGuideStepsTab()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            // مشغل الفيديو
            _buildVideoPlayer(),

            // شريط التحكم ومعلومات الفيديو
            _buildVideoControlsBar(),

            // شريط التبويبات
            _buildTabBar(),

            // محتوى التبويبين
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [AppFeaturesTab(), AppGuideStepsTab()],
              ),
            ),
          ],
        );
      },
    );

    if (!widget.hasScaffold) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          toolbarHeight: 60.h,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 24.sp,
            ),
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'دليل ومميزات التطبيق',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.replay_rounded,
                color: AppColors.primary,
                size: 24.sp,
              ),
              tooltip: 'إعادة تشغيل الفيديو',
              onPressed: _restartVideo,
            ),
          ],
        ),
        body: content,
      ),
    );
  }

  /// ويدجت مشغل BetterPlayer
  Widget _buildVideoPlayer() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _hasError
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade400, size: 36.sp),
                      SizedBox(height: 8.h),
                      Text(
                        'تعذر تحميل الفيديو المحلي',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Almarai',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() => _hasError = false);
                          _initializeBetterPlayer();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            : !_isPlayerReady || _betterPlayerController == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'جاري تجهيز مشغل Better Player...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Almarai',
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : BetterPlayer(
                    key: _betterPlayerKey,
                    controller: _betterPlayerController!,
                  ),
      ),
    );
  }

  /// شريط معلومات وتحكم إضافي بالفيديو
  Widget _buildVideoControlsBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withAlpha(25), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // شارة الفيديو المحلي
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.green.withAlpha(90), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.green.shade700,
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'فيديو محلي (بدون نت)',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // عنوان الفيديو
              Expanded(
                child: Text(
                  AppGuideData.videoTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // زر طي/فتح تفاصيل الفيديو
              InkWell(
                onTap: () {
                  setState(() {
                    _isVideoInfoExpanded = !_isVideoInfoExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(6.r),
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    _isVideoInfoExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),

          // تفاصيل إضافية عند التوسيع
          if (_isVideoInfoExpanded) ...[
            SizedBox(height: 6.h),
            Text(
              AppGuideData.videoDescription,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// شريط التبويبات العلوي
  Widget _buildTabBar() {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        height: 42.h,
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary.withAlpha(35), width: 1),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10.r),
          ),
          dividerColor: Colors.transparent,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'استعراض المميزات'),
            Tab(text: 'طريقة الاستخدام'),
          ],
        ),
      ),
    );
  }
}
