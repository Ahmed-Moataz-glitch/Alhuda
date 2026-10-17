import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/services/font_size_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// نافذة سفلية تفاعلية لتعديل حجم الخط لكل ميزة على حدة بشكل منفصل
class FontSizeBottomSheet extends StatefulWidget {
  final AppFeature? initialFeature;

  const FontSizeBottomSheet({
    super.key,
    this.initialFeature,
  });

  /// فتح النافذة السفلية بسهولة وتحديد الميزة المطلوبة
  static Future<void> show(
    BuildContext context, {
    AppFeature? initialFeature,
  }) {
    HapticFeedback.lightImpact();
    final resolvedFeature = initialFeature ??
        FeatureFontScope.of(context) ??
        FontSizeService.instance.activeFeature;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FontSizeBottomSheet(
        initialFeature: resolvedFeature,
      ),
    );
  }

  @override
  State<FontSizeBottomSheet> createState() => _FontSizeBottomSheetState();
}

class _FontSizeBottomSheetState extends State<FontSizeBottomSheet> {
  late AppFeature _selectedFeature;

  @override
  void initState() {
    super.initState();
    _selectedFeature = widget.initialFeature ?? AppFeature.home;
  }

  @override
  Widget build(BuildContext context) {
    final service = FontSizeService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final currentScale = service.getScale(_selectedFeature);
          final isFeatureDefault = service.isFeatureDefault(_selectedFeature);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 30),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شريط المقبض العلوي
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withAlpha(60),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // الترويسة الرئيسية
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedFeature.icon,
                            color: AppColors.primary,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'حجم خط ${_selectedFeature.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'تعديل حجم النصوص لميزة ${_selectedFeature.title} بشكل منفصل',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isFeatureDefault)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 4.h,
                              ),
                            ),
                            onPressed: () =>
                                service.resetScale(_selectedFeature),
                            icon: Icon(Icons.restart_alt_rounded, size: 16.sp),
                            label: Text(
                              'إعادة ضبط',
                              style: TextStyle(
                                fontFamily: 'Almarai',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 20.sp,
                          ),
                          tooltip: 'إغلاق',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // شريط اختيار الميزة
                    _buildFeatureSelector(service),

                    SizedBox(height: 14.h),

                    // صندوق المعاينة الحية للميزة المحددة
                    _buildPreviewCard(service, isDark, currentScale),

                    SizedBox(height: 16.h),

                    // شريط التكبير والتصغير الدقيق (Slider + Steppers)
                    _buildSliderControls(service, currentScale),

                    SizedBox(height: 14.h),

                    // الخيارات السريعة الجاهزة (Presets)
                    _buildPresetButtons(service, currentScale),

                    SizedBox(height: 16.h),

                    // زر التأكيد والإغلاق
                    SizedBox(
                      height: 46.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'تَمّ الاعتماد لـ ${_selectedFeature.title} (${service.percentageText(_selectedFeature)})',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// شريط اختيار الميزة المراد تعديل خطها
  Widget _buildFeatureSelector(FontSizeService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'اختر الميزة لتعديل خطها:',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (!service.areAllDefault)
              InkWell(
                onTap: () => service.resetAllScales(),
                borderRadius: BorderRadius.circular(6.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Text(
                    'إعادة ضبط الجميع',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 10.5.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 38.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: AppFeature.values.length,
            separatorBuilder: (_, __) => SizedBox(width: 6.w),
            itemBuilder: (context, index) {
              final feature = AppFeature.values[index];
              final isSelected = feature == _selectedFeature;
              final scale = service.getScale(feature);
              final isDefault = (scale - FontSizeService.defaultScale).abs() < 0.01;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFeature = feature);
                  service.setActiveFeature(feature);
                },
                borderRadius: BorderRadius.circular(10.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withAlpha(30),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        feature.icon,
                        size: 15.sp,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (!isDefault) ...[
                        SizedBox(width: 5.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withAlpha(45)
                                : AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${(scale * 100).round()}%',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// صندوق المعاينة الحية للميزة المحددة بحجم خطها الحالي
  Widget _buildPreviewCard(
    FontSizeService service,
    bool isDark,
    double currentScale,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_red_eye_rounded,
                      size: 15.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'معاينة حية لـ ${_selectedFeature.title}:',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${service.percentageText(_selectedFeature)} • ${service.scaleLabel(_selectedFeature)}',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // نموذج النص الأساسي متأثر بحجم خط الميزة
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(currentScale),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.primary.withAlpha(20),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedFeature.previewTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _selectedFeature.previewFontFamily,
                      fontSize: _selectedFeature == AppFeature.quran ||
                              _selectedFeature == AppFeature.hadith ||
                              _selectedFeature == AppFeature.tasbeeh ||
                              _selectedFeature == AppFeature.azkar ||
                              _selectedFeature == AppFeature.allahNames
                          ? 17.sp
                          : 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _selectedFeature.previewSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (_selectedFeature == AppFeature.home) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(30),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.primary,
                              size: 17.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المصحف الشريف',
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'تلاوة، تفسير، وبحث الآيات',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 9.5.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '١١٤ سورة',
                              style: TextStyle(
                                fontFamily: 'Almarai',
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// أدوات التحكم بالمؤشر (Slider وأزرار الزيادة/النقصان)
  Widget _buildSliderControls(FontSizeService service, double currentScale) {
    final canDecrease = currentScale > FontSizeService.minScale + 0.001;
    final canIncrease = currentScale < FontSizeService.maxScale - 0.001;

    return Row(
      children: [
        // زر تصغير
        _buildCircleButton(
          icon: Icons.remove_rounded,
          tooltip: 'تصغير خط ${_selectedFeature.title}',
          enabled: canDecrease,
          onTap: () => service.decreaseScale(_selectedFeature),
        ),
        SizedBox(width: 8.w),

        // شريط التمرير
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withAlpha(35),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(30),
              trackHeight: 4.h,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
            ),
            child: Slider(
              value: currentScale,
              min: FontSizeService.minScale,
              max: FontSizeService.maxScale,
              divisions: 12, // خطوات 0.05
              label: service.percentageText(_selectedFeature),
              onChanged: (val) {
                service.setScale(_selectedFeature, val);
              },
            ),
          ),
        ),
        SizedBox(width: 8.w),

        // زر تكبير
        _buildCircleButton(
          icon: Icons.add_rounded,
          tooltip: 'تكبير خط ${_selectedFeature.title}',
          enabled: canIncrease,
          onTap: () => service.increaseScale(_selectedFeature),
        ),
      ],
    );
  }

  /// أزرار الأحجام السريعة الجاهزة (Presets)
  Widget _buildPresetButtons(FontSizeService service, double currentScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أحجام مقترحة سريعة:',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 11.5.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: FontSizeService.presets.map((preset) {
            final isSelected = (currentScale - preset).abs() < 0.03;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    service.setScale(_selectedFeature, preset);
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(35),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            FontSizeService.presetName(preset),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${(preset * 100).round()}%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 9.sp,
                              color: isSelected
                                  ? Colors.white.withAlpha(220)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? AppColors.primary.withAlpha(25)
                  : AppColors.background,
              border: Border.all(
                color: enabled
                    ? AppColors.primary.withAlpha(60)
                    : AppColors.textSecondary.withAlpha(30),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: enabled
                  ? AppColors.primary
                  : AppColors.textSecondary.withAlpha(60),
            ),
          ),
        ),
      ),
    );
  }
}
