import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/features/app_guide/data/models/app_guide_step.dart';
import 'package:alhuda/features/app_guide/data/repositories/app_guide_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تبويب طريقة استخدام التطبيق والإرشادات العملية
class AppGuideStepsTab extends StatefulWidget {
  const AppGuideStepsTab({super.key});

  @override
  State<AppGuideStepsTab> createState() => _AppGuideStepsTabState();
}

class _AppGuideStepsTabState extends State<AppGuideStepsTab> {
  String _selectedCategory = 'الكل';
  final List<AppGuideStep> _allSteps = AppGuideData.getGuideSteps();

  List<String> get _categories {
    final cats = {'الكل'};
    for (final s in _allSteps) {
      cats.add(s.category);
    }
    return cats.toList();
  }

  List<AppGuideStep> get _filteredSteps {
    if (_selectedCategory == 'الكل') return _allSteps;
    return _allSteps.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSteps;
    final categories = _categories;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        // شريط تصفية الفئات (Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              final isSelected = cat == _selectedCategory;
              return Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat);
                  },
                  backgroundColor: AppColors.card,
                  selectedColor: AppColors.primary,
                  checkmarkColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withAlpha(30),
                    ),
                  ),
                  labelStyle: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 11.5.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 14.h),

        // بطاقات خطوات الاستخدام
        ...filtered.map((step) => _buildStepCard(step)),
      ],
    );
  }

  Widget _buildStepCard(AppGuideStep guide) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.primary.withAlpha(30),
          width: 1.2,
        ),
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
            child: Icon(
              guide.icon,
              color: AppColors.primary,
              size: 22.sp,
            ),
          ),
          title: Text(
            guide.title,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              guide.subtitle,
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

            // خطوات الاستخدام بالتسلسل
            ...List.generate(guide.steps.length, (idx) {
              final stepText = guide.steps[idx];
              final stepNumber = idx + 1;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22.w,
                      height: 22.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        stepText,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // صندوق النصيحة الذهبية
            if (guide.tip != null) ...[
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.amber.shade700.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.amber.shade800,
                      size: 17.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        guide.tip!,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                          height: 1.4,
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
    );
  }
}
