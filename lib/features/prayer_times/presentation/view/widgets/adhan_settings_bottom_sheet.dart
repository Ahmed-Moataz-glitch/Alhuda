import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/core/services/prayer_scheduler_service.dart';
import 'package:alhuda/core/utils/adaptive_layout_helper.dart';
import 'package:alhuda/features/prayer_times/data/models/adhan_model.dart';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdhanSettingsBottomSheet extends StatefulWidget {
  const AdhanSettingsBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => const AdhanSettingsBottomSheet(),
    );
  }

  @override
  State<AdhanSettingsBottomSheet> createState() =>
      _AdhanSettingsBottomSheetState();
}

class _AdhanSettingsBottomSheetState extends State<AdhanSettingsBottomSheet> {
  final AdhanAudioService _audioService = AdhanAudioService();
  int _selectedTab = 0; // 0: الأصوات, 1: التنبيهات
  bool _isBatteryOptimized = false;

  @override
  void initState() {
    super.initState();
    NotificationServices.requestNotificationPermission();
    _audioService.addListener(_onAudioStateChange);
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    final ignoring = await _audioService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _isBatteryOptimized = !ignoring;
      });
    }
  }

  Widget _buildBatteryOptimizationBanner() {
    if (!_isBatteryOptimized) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(35),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.amber.shade700, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.battery_alert_rounded, color: Colors.amber.shade800, size: 22.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'تنبيه مهم لضمان دقة الأذان أثناء قفل الشاشة',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'نظام أندرويد قد يؤخر الأذان ومنبه الصلاة عند قفل الشاشة بسبب ميزة "توفير شحن البطارية". اضغط بالأسفل للسماح للتطبيق بالعمل بدقة وبدون قيود.',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.black.withAlpha(180),
              height: 1.4,
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text(
                'استثناء التطبيق من توفير البطارية (بدون قيود)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await _audioService.requestIgnoreBatteryOptimizations();
                await Future.delayed(const Duration(seconds: 1));
                await _checkBatteryOptimization();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChange);
    super.dispose();
  }

  void _onAudioStateChange() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AdaptiveSheetWrapper(
        maxSheetWidth: 620.0,
        child: Container(
          height: 680.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(80),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 12.h),

              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'أصوات الأذان والتنبيهات',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.primary,
                    onPressed: () {
                      _audioService.stop();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Tabs Selector (أصوات المؤذنين / تنبيهات الأذان / منبه قبل الصلاة)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(4.r),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'المؤذنين',
                        icon: Icons.record_voice_over_rounded,
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'تنبيهات الأذان',
                        icon: Icons.alarm_on_rounded,
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'منبه قبل الصلاة',
                        icon: Icons.notifications_active_rounded,
                        isSelected: _selectedTab == 2,
                        onTap: () => setState(() => _selectedTab = 2),
                      ),
                    ),
                  ],
                ),
              ),

              // Volume Control Card (controls adhan volume or pre-prayer alert volume)
              _buildVolumeControl(),

              // Content Body
              Expanded(
                child: _selectedTab == 0
                    ? _buildSoundsList()
                    : (_selectedTab == 1
                          ? _buildAlertsList()
                          : _buildPrePrayerAlertsTab()),
              ),

              // Mini Player Controls Bar
              if (_audioService.currentPlayingSound != null) _buildMiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    final isPrePrayerTab = _selectedTab == 2;
    final vol = isPrePrayerTab
        ? _audioService.prePrayerVolume
        : _audioService.adhanVolume;
    final percent = (vol * 100).round();
    final title = isPrePrayerTab
        ? 'مستوى صوت منبه قبل الصلاة'
        : 'مستوى صوت الأذان';
    final subtitle = isPrePrayerTab
        ? 'يتم رفع صوت المنبه تلقائياً إلى هذا المستوى عند التنبيه ويعود كما كان بعده'
        : 'يتم رفع صوت المنبه تلقائياً إلى هذا المستوى عند الأذان ويعود كما كان بعده';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    vol > 0.6
                        ? Icons.volume_up_rounded
                        : (vol > 0.2
                              ? Icons.volume_down_rounded
                              : Icons.volume_mute_rounded),
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.black.withAlpha(150),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.volume_mute_rounded,
                size: 20.sp,
                color: AppColors.primary.withAlpha(130),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.h,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primary.withAlpha(35),
                    thumbColor: AppColors.primary,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                  ),
                  child: Slider.adaptive(
                    value: vol,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    onChanged: (val) {
                      if (isPrePrayerTab) {
                        _audioService.setPrePrayerVolume(val);
                      } else {
                        _audioService.setAdhanVolume(val);
                      }
                    },
                  ),
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: 20.sp,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? AppColors.background : AppColors.primary,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.background : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundsList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: AdhanData.availableSounds.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final sound = AdhanData.availableSounds[index];
        final isSelectedDefault = _audioService.selectedSound.id == sound.id;
        final isCurrentlyPlaying =
            _audioService.currentPlayingSound?.id == sound.id &&
            _audioService.isPlaying;
        final isNasserQatami = sound.id == 'qatami';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelectedDefault
                ? AppColors.primary.withAlpha(25)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelectedDefault
                  ? AppColors.primary
                  : AppColors.primary.withAlpha(35),
              width: isSelectedDefault ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Radio / Select Default Adhan
              IconButton(
                icon: Icon(
                  isSelectedDefault
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelectedDefault
                      ? AppColors.primary
                      : AppColors.primary.withAlpha(120),
                  size: 24.sp,
                ),
                tooltip: 'تعيين كأذان افتراضي',
                onPressed: () {
                  _audioService.setSelectedAdhan(sound);
                },
              ),

              SizedBox(width: 6.w),

              // Title and Muadhin info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sound.title,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: isSelectedDefault
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (isNasserQatami) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'مميز ⭐',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      sound.muadhin,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.black.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),

              // Duration tag
              if (sound.durationText.isNotEmpty)
                Text(
                  sound.durationText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary.withAlpha(160),
                  ),
                ),

              SizedBox(width: 6.w),

              // Play / Pause preview button
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: isCurrentlyPlaying
                        ? AppColors.primary
                        : AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCurrentlyPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: isCurrentlyPlaying
                        ? AppColors.background
                        : AppColors.primary,
                    size: 20.sp,
                  ),
                ),
                tooltip: isCurrentlyPlaying ? 'إيقاف مؤقت' : 'استماع',
                onPressed: () => _audioService.toggle(sound),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsList() {
    const prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildBatteryOptimizationBanner(),
        // Persistent Prayer Notification Card
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.primary.withAlpha(70)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الإشعار الدائم لمواقيت الصلاة',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'إشعار ثابت في شريط الإشعارات وشاشة القفل بالصلاة القادمة والعداد بالسالب',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: AppColors.black.withAlpha(160),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _audioService.isPersistentNotificationEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) async {
                      if (val) {
                        await NotificationServices.requestNotificationPermission();
                      }
                      await _audioService.togglePersistentNotification(val);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
              if (_audioService.isPersistentNotificationEnabled) ...[
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withAlpha(100)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    icon: Icon(Icons.refresh_rounded, size: 18.sp),
                    label: Text(
                      'تحديث وعرض الإشعار الدائم الآن',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      await NotificationServices.requestNotificationPermission();
                      await PrayerSchedulerService()
                          .updatePersistentPrayerNotification();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'تم تحديث الإشعار الدائم في شريط الإشعارات بنجاح!',
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.volume_down_rounded,
                color: AppColors.primary,
                size: 22.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إيقاف الأذان السريع (في الاجتماعات والأماكن الهادئة)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'يمكنك إيقاف أو كتم صوت الأذان فوراً عند رنينه بالضغط على أزرار خفض أو رفع الصوت في الهاتف، أو عبر زر "إيقاف الأذان" المباشر في الإشعار.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.black.withAlpha(180),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'يمكنك تشغيل أو إيقاف صوت الأذان لكل صلاة بشكل مستقل.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        ...prayers.map((prayer) {
          final isEnabled = _audioService.isPrayerAlertEnabled(prayer);

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isEnabled
                    ? AppColors.primary.withAlpha(80)
                    : AppColors.black.withAlpha(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: isEnabled
                          ? AppColors.primary
                          : AppColors.black.withAlpha(100),
                      size: 22.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'أذان صلاة $prayer',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? AppColors.primary
                            : AppColors.black.withAlpha(120),
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: isEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    _audioService.togglePrayerAlert(prayer, val);
                    if (!val) {
                      final id = PrayerSchedulerService.prayerNameToId[prayer];
                      if (id != null) {
                        PrayerSchedulerService().cancelPrayerAlarm(id);
                      }
                    } else {
                      PrayerSchedulerService().scheduleUpcomingPrayers(null);
                    }
                  },
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 14.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            icon: const Icon(Icons.notifications_active_rounded),
            label: Text(
              'تجربة إشعار وصوت الأذان الآن',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final isGranted =
                  await NotificationServices.requestNotificationPermission();
              if (!isGranted && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        '⚠️ تنبيه: إذن الإشعارات معطل في الهاتف! يرجى السماح بالإشعارات من إعدادات التطبيق ليظهر الإشعار.',
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              await _audioService.play(
                _audioService.selectedSound,
                prayerName: 'تجربة الأذان',
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'جاري تشغيل صوت ${_audioService.selectedSound.title} (يمكنك إيقافه من زر الإشعار أو أزرار الصوت)',
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(
              'تجربة تنبيه الأذان بعد 10 ثوانٍ (مع قفل الهاتف)',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final isGranted =
                  await NotificationServices.requestNotificationPermission();
              if (!isGranted && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        '⚠️ تنبيه: إذن الإشعارات معطل في الهاتف! يرجى السماح بالإشعارات من إعدادات التطبيق ليظهر الإشعار.',
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              const channel = MethodChannel('com.example.alhuda/adhan');
              final rawRes = _audioService.selectedSound.source
                  .split('/')
                  .last
                  .replaceAll('.mp3', '');
              await channel.invokeMethod('scheduleNativeTestAlarm', {
                'delaySeconds': 10,
                'prayerName': 'الظهر',
                'soundId': _audioService.selectedSound.id,
                'rawRes': rawRes,
                'title': _audioService.selectedSound.title,
                'muadhin': _audioService.selectedSound.muadhin,
                'volume': _audioService.adhanVolume,
                'isAlarmMode': _audioService.isAlarmMode,
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'تمت جدولة تنبيه الأذان بدقة بعد 10 ثوانٍ.. اقفل شاشة هاتفك الآن لتجربة ظهور المنبه وإيقافه بأزرار الصوت!',
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildPrePrayerAlertsTab() {
    const prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    final isGloballyEnabled = _audioService.isPrePrayerAlertEnabled;
    final minutes = _audioService.prePrayerMinutes;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildBatteryOptimizationBanner(),
        SizedBox(height: 8.h),
        // 1. Info & Master Toggle Card
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.primary.withAlpha(70)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'صوت منبه اقتراب الصلاة (صوت فقط)',
                                style: TextStyle(
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'منبه صوتي ينطق "اقتربت صلاة كذا" قبل كل صلاة بربع ساعة (صوت ناطق فقط بدون أي إشعار)',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: AppColors.black.withAlpha(160),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isGloballyEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) async {
                      await _audioService.togglePrePrayerAlert(val);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Alert Timing Selection Card
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'وقت التنبيه قبل دخول وقت الصلاة:',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [5, 10, 15, 20, 30].map((m) {
                  final isSelected = minutes == m;
                  final label = m == 15 ? '$m دقيقة (الافتراضي)' : '$m دقائق';
                  return ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.background
                            : AppColors.primary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withAlpha(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(40),
                      ),
                    ),
                    onSelected: (selected) async {
                      if (selected) {
                        await _audioService.setPrePrayerMinutes(m);
                        if (mounted) setState(() {});
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // 3. Test Voice Button
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(
                    'تجربة صوت المنبه ("اقتربت صلاة الظهر")',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    await _audioService.testPrePrayerAlert(prayerName: 'الظهر');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'جاري تشغيل الصوت: "اقتربت صلاة الظهر"..',
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                  icon: const Icon(Icons.screen_lock_portrait_rounded),
                  label: Text(
                    'تجربة منبه اقتراب الصلاة بعد 10 ثوانٍ (مع قفل الشاشة - صوت فقط)',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    const channel = MethodChannel('com.example.alhuda/adhan');
                    await channel.invokeMethod('scheduleNativeTestPrePrayerAlarm', {
                      'delaySeconds': 10,
                      'prayerName': 'الظهر',
                      'rawRes': 'pre_prayer_dhuhr',
                      'volume': _audioService.prePrayerVolume,
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'تمت جدولة منبه صلاة الظهر بدقة بعد 10 ثوانٍ.. يمكنك قفل هاتفك الآن لسماع الصوت بدقة!',
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // 4. Per-Prayer Switch List
        Container(
          padding: EdgeInsets.all(12.r),
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'تخصيص المنبه لكل صلاة بشكل مستقل:',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...prayers.map((prayer) {
          final isPrayerEnabled = _audioService.isPrePrayerAlertEnabledFor(
            prayer,
          );

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isPrayerEnabled
                    ? AppColors.primary.withAlpha(80)
                    : AppColors.black.withAlpha(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPrayerEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: isPrayerEnabled
                          ? AppColors.primary
                          : AppColors.black.withAlpha(100),
                      size: 22.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'منبه اقتراب صلاة $prayer',
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isPrayerEnabled
                            ? AppColors.primary
                            : AppColors.black.withAlpha(120),
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: isPrayerEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: isGloballyEnabled
                      ? (val) async {
                          await _audioService.togglePrayerPreAlert(prayer, val);
                          if (mounted) setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 14.h),
      ],
    );
  }

  Widget _buildMiniPlayer() {
    final sound = _audioService.currentPlayingSound!;
    final pos = _audioService.position;
    final dur = _audioService.duration;
    final maxMs = dur.inMilliseconds.toDouble();
    final curMs = pos.inMilliseconds.toDouble().clamp(
      0.0,
      maxMs > 0 ? maxMs : 1.0,
    );

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SizedBox(width: 6.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 250.w,
                    child: Text(
                      sound.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                  Text(
                    sound.muadhin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.background.withAlpha(200),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _audioService.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: AppColors.background,
                      size: 32.sp,
                    ),
                    onPressed: () => _audioService.toggle(sound),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.stop_rounded,
                      color: AppColors.background,
                      size: 28.sp,
                    ),
                    onPressed: () => _audioService.stop(),
                  ),
                ],
              ),
            ],
          ),

          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              trackHeight: 3.h,
              activeTrackColor: AppColors.background,
              inactiveTrackColor: AppColors.background.withAlpha(80),
              thumbColor: AppColors.background,
            ),
            child: Slider(
              value: curMs,
              max: maxMs > 0 ? maxMs : 1.0,
              onChanged: (val) {
                _audioService.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),

          // Time labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(pos),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.background.withAlpha(220),
                  ),
                ),
                Text(
                  _formatDuration(dur),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.background.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
