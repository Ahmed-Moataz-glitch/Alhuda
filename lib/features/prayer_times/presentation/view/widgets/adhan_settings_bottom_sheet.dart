import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/core/services/prayer_scheduler_service.dart';
import 'package:alhuda/features/prayer_times/data/models/adhan_model.dart';
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
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
  bool _isIgnoringBattery = true;

  @override
  void initState() {
    super.initState();
    NotificationServices.requestNotificationPermission();
    _audioService.addListener(_onAudioStateChange);
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    final ignored = await _audioService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _isIgnoringBattery = ignored;
      });
    }
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
      child: Container(
        height: 650.h,
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

            // Tabs Selector (أصوات المؤذنين / تنبيهات الصلوات)
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
                      title: 'أصوات المؤذنين',
                      icon: Icons.record_voice_over_rounded,
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'تنبيهات الصلوات',
                      icon: Icons.alarm_on_rounded,
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),

            // Volume Control Card
            _buildVolumeControl(),

            // Content Body
            Expanded(
              child: _selectedTab == 0
                  ? _buildSoundsList()
                  : _buildAlertsList(),
            ),

            // Mini Player Controls Bar
            if (_audioService.currentPlayingSound != null) _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    final vol = _audioService.adhanVolume;
    final percent = (vol * 100).round();

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
                    'مستوى صوت الأذان',
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
            'يتم رفع صوت المنبه تلقائياً إلى هذا المستوى عند الأذان ويعود كما كان بعده',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.black.withAlpha(150),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.volume_mute_rounded,
                size: 16.sp,
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
                      _audioService.setAdhanVolume(val);
                    },
                  ),
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: 18.sp,
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
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected ? AppColors.background : AppColors.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.background : AppColors.primary,
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
        if (!_isIgnoringBattery)
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFFFEEBA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.battery_alert_rounded,
                      color: const Color(0xFF856404),
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'لضمان عمل الأذان على شاومي وسامسونج وأوبو وهواوي',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF856404),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  'تقوم بعض الهواتف بإيقاف التطبيقات في الخلفية أثناء قفل الشاشة لتوفير الطاقة. يرجى استثناء التطبيق من موفر البطارية لضمان رنين الأذان في موعده دائماً.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF856404),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF856404),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: Text(
                          'استثناء التطبيق من موفر البطارية',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          await _audioService.requestIgnoreBatteryOptimizations();
                          await Future.delayed(const Duration(seconds: 1));
                          _checkBatteryOptimization();
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'فتح معلومات التطبيق (التشغيل التلقائي)',
                      color: const Color(0xFF856404),
                      onPressed: () => _audioService.openAppSettings(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(height: 14.h),
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
              'تجربة إشعار الأذان بعد 10 ثوانٍ (مع قفل الهاتف)',
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
              await AndroidAlarmManager.oneShot(
                const Duration(seconds: 10),
                9998,
                prayerAlarmCallback,
                exact: true,
                wakeup: true,
                alarmClock: false,
                allowWhileIdle: true,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'تمت جدولة إشعار الأذان بعد 10 ثوانٍ.. يمكنك قفل شاشة هاتفك الآن للتجربة!',
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
              SizedBox(width: 4.w),
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
