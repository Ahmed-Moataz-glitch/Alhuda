import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A non-dismissible dialog that forces the user to update the app.
/// Uses [PopScope] with `canPop: false` so that the Android back button
/// or swipe gestures cannot close the dialog.
class ForceUpdateDialog extends StatelessWidget {
  final UpdateCheckResult result;
  final VoidCallback onUpdatePressed;
  final VoidCallback? onRecheckPressed;

  const ForceUpdateDialog({
    super.key,
    required this.result,
    required this.onUpdatePressed,
    this.onRecheckPressed,
  });

  /// Static helper to display the dialog cleanly.
  static Future<void> show({
    required BuildContext context,
    required UpdateCheckResult result,
    required VoidCallback onUpdatePressed,
    VoidCallback? onRecheckPressed,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => ForceUpdateDialog(
        result: result,
        onUpdatePressed: onUpdatePressed,
        onRecheckPressed: onRecheckPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          HapticFeedback.heavyImpact();
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          elevation: 12,
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Container(
            constraints: BoxConstraints(maxWidth: 380.w),
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: AppColors.primary.withAlpha(50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated decorative header icon
                  _buildHeaderIcon(),

                  SizedBox(height: 16.h),

                  // Brand badge
                  _buildBadge(),

                  SizedBox(height: 12.h),

                  // Main Title
                  Text(
                    'تحديث إجباري متوفر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Text(
                    'يرجى تحديث التطبيق للمتابعة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Version comparison chip
                  _buildVersionBadge(),

                  SizedBox(height: 16.h),

                  // Explanation body
                  Text(
                    'يتوفر إصدار جديد وأكثر استقراراً من تطبيق الهُدى في متجر Google Play. يتضمن هذا الإصدار تحسينات أداء مهمة وإصلاحات وإضافات ضرورية.\n\nلا يمكنك متابعة استخدام الإصدار الحالي حتى يتم التحديث.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 12.5.sp,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // Feature points card
                  _buildFeaturesCard(),

                  SizedBox(height: 22.h),

                  // Main Update Button
                  _buildUpdateButton(),

                  if (onRecheckPressed != null) ...[
                    SizedBox(height: 10.h),
                    _buildRecheckButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glowing ring
        Container(
          width: 84.w,
          height: 84.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withAlpha(20),
          ),
        ),
        // Inner ring
        Container(
          width: 66.w,
          height: 66.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withAlpha(35),
            border: Border.all(
              color: AppColors.primary.withAlpha(90),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.system_update_rounded,
            color: AppColors.primary,
            size: 34.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withAlpha(60),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 13.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 5.w),
          Text(
            'تطبيق الهُدى',
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الإصدار الحالي: v${result.currentVersion}',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 11.5.sp,
                color: AppColors.textSecondary,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 14.sp,
                color: AppColors.primary,
              ),
            ),
            Text(
              'الجديد: v${result.storeVersion}',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final items = [
      'تحسينات عامة في الأداء والسرعة',
      'إصلاحات ضرورية وتحديثات استقرار',
      'ميزات جديدة وتجربة قراءة أفضل',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((text) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 11.5.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onUpdatePressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 3,
          shadowColor: AppColors.primary.withAlpha(90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        icon: Icon(
          Icons.download_rounded,
          size: 20.sp,
        ),
        label: Text(
          'تحديث التطبيق الآن',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRecheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 40.h,
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onRecheckPressed?.call();
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Icon(
          Icons.refresh_rounded,
          size: 16.sp,
        ),
        label: Text(
          'تحققت بالفعل؟ إعادة الفحص',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
