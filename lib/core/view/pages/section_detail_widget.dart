import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/core/view/widgets/font_size_bottom_sheet.dart';
import 'package:alhuda/services/font_size_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable section wrapper page providing a consistent AppBar,
/// back navigation, centered title, and per-feature font scaling for every feature.
class SectionDetailWidget extends StatefulWidget {
  final String title;
  final Widget child;
  final AppFeature? feature;

  const SectionDetailWidget({
    super.key,
    required this.title,
    required this.child,
    this.feature,
  });

  @override
  State<SectionDetailWidget> createState() => _SectionDetailWidgetState();
}

class _SectionDetailWidgetState extends State<SectionDetailWidget> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature ??
        AppFeature.fromTitle(widget.title) ??
        AppFeature.quran;

    return FeatureFontScope(
      feature: feature,
      child: Directionality(
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
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.format_size_rounded,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                tooltip: 'تعديل حجم خط ${feature.title}',
                onPressed: () => FontSizeBottomSheet.show(
                  context,
                  initialFeature: feature,
                ),
              ),
            ],
          ),
          body: KeyedSubtree(
            key: ValueKey(ThemeService.instance.isDarkMode),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
