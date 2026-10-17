import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/view/widgets/font_size_bottom_sheet.dart';
import 'package:alhuda/features/quran/data/dua_khatm_quran_data.dart';
import 'package:alhuda/services/font_size_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DuaKhatmQuranPage extends StatefulWidget {
  const DuaKhatmQuranPage({super.key});

  @override
  State<DuaKhatmQuranPage> createState() => _DuaKhatmQuranPageState();
}

class _DuaKhatmQuranPageState extends State<DuaKhatmQuranPage> {
  bool _isSectionedView = true;

  @override
  void initState() {
    super.initState();
    FontSizeService.instance.addListener(_onChanged);
    ThemeService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    FontSizeService.instance.removeListener(_onChanged);
    ThemeService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _copyDua() {
    Clipboard.setData(ClipboardData(text: DuaKhatmQuranData.fullText));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10.w),
              const Expanded(
                child: Text(
                  'تم نسخ دعاء ختم القرآن الكريم إلى الحافظة بنجاح',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = FontSizeService.instance.getScale(AppFeature.quran);

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
              size: 20.sp,
            ),
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'دعاء ختم القرآن الكريم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 21.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
              tooltip: 'نسخ الدعاء',
              onPressed: _copyDua,
            ),
            IconButton(
              icon: Icon(
                Icons.format_size_rounded,
                color: AppColors.primary,
                size: 22.sp,
              ),
              tooltip: 'حجم خط المصحف الشريف',
              onPressed: () => FontSizeBottomSheet.show(
                context,
                initialFeature: AppFeature.quran,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            children: [
              // بطاقة فضل ختم القرآن والاستبشار بالدعاء
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withAlpha(200),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مبارك إتمام كتاب الله تعالى 🎉',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            DuaKhatmQuranData.fadlKhatm,
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 12.sp,
                              height: 1.45,
                              color: Colors.white.withAlpha(235),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // شريط التبديل بين العرض المبوّب والعرض المتصل
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isSectionedView = true),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            color: _isSectionedView
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'فقرات مبوبة بالعناوين',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 12.5.sp,
                              fontWeight: _isSectionedView
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _isSectionedView
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isSectionedView = false),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            color: !_isSectionedView
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'نص متصل كالمصحف',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 12.5.sp,
                              fontWeight: !_isSectionedView
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: !_isSectionedView
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // بطاقة البسملة
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(40),
                    width: 1,
                  ),
                ),
                child: Text(
                  DuaKhatmQuranData.basmalah,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: (22 * fontScale).sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // محتوى الدعاء حسب نوع العرض المختار
              if (_isSectionedView)
                for (int i = 0; i < DuaKhatmQuranData.sections.length; i++)
                  _buildSectionCard(
                    DuaKhatmQuranData.sections[i],
                    i + 1,
                    fontScale,
                  )
              else
                _buildContinuousView(fontScale),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    DuaKhatmSection section,
    int index,
    double fontScale,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withAlpha(25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Divider(
            color: AppColors.border,
            thickness: 0.8,
            height: 16.h,
          ),
          Text(
            section.text,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: (19 * fontScale).sp,
              height: 1.85,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousView(double fontScale) {
    final isDark = ThemeService.instance.isDarkMode;
    final frameColor =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFF8B6B38);
    final rosetteColor =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFF8B6B38);

    final spans = <InlineSpan>[];
    for (int i = 0; i < DuaKhatmQuranData.sections.length; i++) {
      spans.add(
        TextSpan(
          text: DuaKhatmQuranData.sections[i].text,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: (19.5 * fontScale).sp,
            height: 2.1,
            color: AppColors.textPrimary,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: '  ۞  ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: (19.5 * fontScale).sp,
            fontWeight: FontWeight.bold,
            color: rosetteColor,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181818) : const Color(0xFFFAF7EE),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: frameColor.withAlpha(140),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
