import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/view/pages/section_detail_widget.dart';
import 'package:alhuda/features/app_guide/data/models/app_feature_info.dart';
import 'package:alhuda/features/app_guide/data/repositories/app_guide_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تبويب استعراض مميزات التطبيق
class AppFeaturesTab extends StatefulWidget {
  const AppFeaturesTab({super.key});

  @override
  State<AppFeaturesTab> createState() => _AppFeaturesTabState();
}

class _AppFeaturesTabState extends State<AppFeaturesTab> {
  List<AppFeatureInfo> _features = [];

  @override
  void initState() {
    super.initState();
    _features = AppGuideData.getFeatures();
  }

  void _navigateToFeature(AppFeatureInfo feature) {
    if (feature.navigationBuilder == null) return;
    HapticFeedback.lightImpact();
    final widget = feature.navigationBuilder!(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SectionDetailWidget(title: feature.title, child: widget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        // بطاقة ملخص الميزات
        Container(
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: AppColors.primary.withAlpha(35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'موسوعة إسلامية شاملة ومتكاملة',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'جميع أقسام التطبيق تعمل بدون إنترنت لحفظ وقتك وراحتك',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 10.5.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // قائمة بطاقات المميزات
        ..._features.map((feature) => _buildFeatureCard(feature)),
      ],
    );
  }

  Widget _buildFeatureCard(AppFeatureInfo feature) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.primary.withAlpha(30), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          leading: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(35),
                  AppColors.primary.withAlpha(12),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primary.withAlpha(45),
                width: 1,
              ),
            ),
            child: Icon(feature.icon, color: AppColors.primary, size: 22.sp),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  feature.title,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  feature.badge,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              feature.subtitle,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 11.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          children: [
            const Divider(height: 1),
            SizedBox(height: 10.h),
            // الوصف الكامل
            Text(
              feature.description,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 11.5.sp,
                color: AppColors.textPrimary.withAlpha(220),
                height: 1.5,
              ),
            ),
            SizedBox(height: 12.h),

            // أبرز النقاط
            ...feature.highlights.map(
              (point) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 14.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // زر الانتقال المباشر وتجربة القسم
            if (feature.navigationBuilder != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToFeature(feature),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 19.sp,
                    color: AppColors.onPrimary,
                  ),
                  label: Text(
                    'فتح قسم ${feature.title}',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
