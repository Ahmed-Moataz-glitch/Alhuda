import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/features/app_guide/data/repositories/app_guide_data.dart';
import 'package:alhuda/features/app_guide/presentation/view/widgets/app_features_tab.dart';
import 'package:alhuda/features/app_guide/presentation/view/widgets/app_guide_steps_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// صفحة دليل استخدام ومميزات التطبيق مع مشغل فيديو اليوتيوب
class AppGuidePage extends StatefulWidget {
  final bool hasScaffold;

  const AppGuidePage({super.key, this.hasScaffold = true});

  @override
  State<AppGuidePage> createState() => _AppGuidePageState();
}

class _AppGuidePageState extends State<AppGuidePage>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late TabController _tabController;
  bool _isPlayerReady = false;
  bool _isVideoInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _controller = YoutubePlayerController(
      initialVideoId: AppGuideData.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        isLive: false,
        forceHD: false,
        loop: false,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_isPlayerReady && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _rewind10Seconds() {
    HapticFeedback.lightImpact();
    final currentPos = _controller.value.position;
    final newPos = currentPos - const Duration(seconds: 10);
    _controller.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
  }

  void _forward10Seconds() {
    HapticFeedback.lightImpact();
    final currentPos = _controller.value.position;
    final totalDuration = _controller.metadata.duration;
    final newPos = currentPos + const Duration(seconds: 10);
    _controller.seekTo(newPos < totalDuration ? newPos : totalDuration);
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    if (_controller.value.volume == 0) {
      _controller.unMute();
    } else {
      _controller.mute();
    }
  }

  void _restartVideo() {
    HapticFeedback.lightImpact();
    _controller.seekTo(Duration.zero);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primary.withAlpha(60),
          backgroundColor: Colors.grey.shade400,
        ),
        bottomActions: [
          RemainingDuration(),
          SizedBox(width: 8.w),
          ProgressBar(isExpanded: true),
          SizedBox(width: 8.w),
          CurrentPosition(),
          const FullScreenButton(),
        ],
        topActions: [
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              AppGuideData.videoTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
      ),
      builder: (context, player) {
        final content = Column(
          children: [
            // مشغل الفيديو
            Container(color: Colors.black, child: player),

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
      },
    );
  }

  /// شريط معلومات وتحكم إضافي بالفيديو
  Widget _buildVideoControlsBar() {
    final isMuted = _controller.value.volume == 0;
    final isPlaying = _controller.value.isPlaying;

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
              // أيقونة شارة الفيديو
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.red.withAlpha(80), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.red.shade700,
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'فيديو توضيحي',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
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

          SizedBox(height: 6.h),

          // شريط أزرار التحكم السريع بالفيديو
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlIconButton(
                icon: Icons.replay_10_rounded,
                tooltip: 'تأخير 10 ثوانٍ',
                onPressed: _rewind10Seconds,
              ),
              _buildControlIconButton(
                icon: isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                iconColor: AppColors.primary,
                size: 32.sp,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                },
              ),
              _buildControlIconButton(
                icon: Icons.forward_10_rounded,
                tooltip: 'تقديم 10 ثوانٍ',
                onPressed: _forward10Seconds,
              ),
              _buildControlIconButton(
                icon: isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                tooltip: isMuted ? 'إلغاء كتم الصوت' : 'كتم الصوت',
                onPressed: _toggleMute,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? iconColor,
    double? size,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.textSecondary,
              size: size ?? 28.sp,
            ),
          ),
        ),
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
