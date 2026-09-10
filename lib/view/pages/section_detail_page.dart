import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable section wrapper page providing a consistent AppBar,
/// back navigation, and centered title for every feature.
class SectionDetailPage extends StatefulWidget {
  final String title;
  final Widget child;

  const SectionDetailPage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  State<SectionDetailPage> createState() => _SectionDetailPageState();
}

class _SectionDetailPageState extends State<SectionDetailPage> {
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
            widget.title,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          actions: [
            SizedBox(width: 48.w),
          ],
        ),
        body: KeyedSubtree(
          key: ValueKey(ThemeService.instance.isDarkMode),
          child: widget.child,
        ),
      ),
    );
  }
}
