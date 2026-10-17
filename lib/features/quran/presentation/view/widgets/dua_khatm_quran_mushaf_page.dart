import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/features/quran/data/dua_khatm_quran_data.dart';
import 'package:alhuda/services/font_size_service.dart';
import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Authentic Medina Mushaf Frame Painter
/// Paints double golden border lines with classical Islamic corner arabesques.
class _MushafFramePainter extends CustomPainter {
  final Color outerColor;
  final Color innerColor;

  _MushafFramePainter({
    required this.outerColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final innerPaint = Paint()
      ..color = innerColor.withAlpha(190)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cornerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;

    // 1. Outer Frame Rect
    final outerRect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    canvas.drawRect(outerRect, outerPaint);

    // 2. Inner Frame Rect (with 3.5px margin)
    const margin = 3.5;
    final innerRect = Rect.fromLTWH(
      margin + 1,
      margin + 1,
      size.width - 2 * (margin + 1),
      size.height - 2 * (margin + 1),
    );
    canvas.drawRect(innerRect, innerPaint);

    // 3. Islamic Corner Rosettes (4 Corners)
    final cornerSize = 7.0;
    void drawCornerOrnament(double cx, double cy) {
      final path = Path()
        ..moveTo(cx, cy - cornerSize)
        ..lineTo(cx + cornerSize * 0.7, cy - cornerSize * 0.7)
        ..lineTo(cx + cornerSize, cy)
        ..lineTo(cx + cornerSize * 0.7, cy + cornerSize * 0.7)
        ..lineTo(cx, cy + cornerSize)
        ..lineTo(cx - cornerSize * 0.7, cy + cornerSize * 0.7)
        ..lineTo(cx - cornerSize, cy)
        ..lineTo(cx - cornerSize * 0.7, cy - cornerSize * 0.7)
        ..close();
      canvas.drawPath(path, cornerPaint);
    }

    drawCornerOrnament(innerRect.left + 5, innerRect.top + 5);
    drawCornerOrnament(innerRect.right - 5, innerRect.top + 5);
    drawCornerOrnament(innerRect.left + 5, innerRect.bottom - 5);
    drawCornerOrnament(innerRect.right - 5, innerRect.bottom - 5);
  }

  @override
  bool shouldRepaint(covariant _MushafFramePainter oldDelegate) {
    return oldDelegate.outerColor != outerColor ||
        oldDelegate.innerColor != innerColor;
  }
}

/// Authentic Mushaf Page for Dua' Khatm Al-Quran (Pages 605 and 606)
/// Modeled faithfully after the physical Medina Mushaf concluding pages:
/// - Illuminated Medina golden border and arabesque cornerpieces
/// - Classic Surah banner header with golden arabesques
/// - Continuous calligraphic Uthmani/Amiri text with full tashkeel
/// - Traditional golden Islamic rosettes (۞) between supplications
/// - Genuine page header and footer matching the Holy Quran pages
class DuaKhatmQuranMushafPage extends StatefulWidget {
  final int pageNumber;
  final VoidCallback? onPageTapped;
  final bool showOverlay;

  const DuaKhatmQuranMushafPage({
    super.key,
    this.pageNumber = 605,
    this.onPageTapped,
    this.showOverlay = false,
  });

  @override
  State<DuaKhatmQuranMushafPage> createState() =>
      _DuaKhatmQuranMushafPageState();
}

class _DuaKhatmQuranMushafPageState extends State<DuaKhatmQuranMushafPage> {
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

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    final fontScale = FontSizeService.instance.getScale(AppFeature.quran);

    // Authentic Medina Mushaf palette
    final outerFrameColor =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFF8B6B38);
    final innerFrameColor =
        isDark ? const Color(0xFFC5A059) : const Color(0xFFA67C52);
    final pageBgColor =
        isDark ? const Color(0xFF181818) : const Color(0xFFFAF7EE);
    final textColor =
        isDark ? const Color(0xFFECEFF1) : const Color(0xFF1E1D1B);
    final rosetteColor =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFF8B6B38);
    final bannerTextColor =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFF5D4037);

    final isFirstPage = widget.pageNumber <= 605;
    final sectionsToDisplay = isFirstPage
        ? DuaKhatmQuranData.page605Sections
        : DuaKhatmQuranData.page606Sections;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPageTapped,
        child: Container(
          color: AppColors.background,
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
          child: Container(
            decoration: BoxDecoration(
              color: pageBgColor,
              borderRadius: BorderRadius.circular(4.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _MushafFramePainter(
                outerColor: outerFrameColor,
                innerColor: innerFrameColor,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Column(
                  children: [
                    // 1. Top Header Line inside frame (الجزء - ۞ - السورة)
                    _buildPageHeader(outerFrameColor, innerFrameColor),

                    SizedBox(height: 6.h),

                    // 2. Center Sacred Mushaf Body
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (isFirstPage) ...[
                                    // Classic Surah Banner Cartouche
                                    _buildSurahBanner(
                                      isDark,
                                      outerFrameColor,
                                      bannerTextColor,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Basmalah in authentic Arabic calligraphy
                                    Text(
                                      DuaKhatmQuranData.basmalah,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: (19 * fontScale).sp,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                  ] else ...[
                                    // Top ornamental flourish for Page 606
                                    _buildContinuationFlourish(
                                      outerFrameColor,
                                      innerFrameColor,
                                    ),
                                    SizedBox(height: 8.h),
                                  ],

                                  // Continuous flowing text (as in the authentic Mushaf, NO cards)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                    ),
                                    child: _buildContinuousText(
                                      sectionsToDisplay,
                                      textColor,
                                      rosetteColor,
                                      fontScale,
                                    ),
                                  ),

                                  if (!isFirstPage) ...[
                                    SizedBox(height: 8.h),
                                    // Authentic Islamic Concluding Seal
                                    _buildConcludingSeal(
                                      isDark,
                                      outerFrameColor,
                                      innerFrameColor,
                                      textColor,
                                      fontScale,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // 3. Bottom Footer Line (خاتمة المصحف - رقم الصفحة - تقبل الله)
                    _buildPageFooter(
                      outerFrameColor,
                      innerFrameColor,
                      isFirstPage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Classical Madinah Mushaf Top Header inside frame
  Widget _buildPageHeader(Color frameColor, Color innerFrameColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Juz Name on the Right (in RTL)
            Flexible(
              child: Text(
                'الجُزْءُ الثَّلَاثُونَ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: frameColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Dua Title on the Left
            Flexible(
              child: Text(
                'دُعَاءُ خَتْمِ القُرْآنِ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: frameColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        // Thin Ornamental Line with Center Diamond
        Row(
          children: [
            Expanded(
              child: Divider(
                color: innerFrameColor.withAlpha(120),
                height: 1,
                thickness: 0.8,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Icon(
                Icons.diamond_outlined,
                size: 14.sp,
                color: frameColor,
              ),
            ),
            Expanded(
              child: Divider(
                color: innerFrameColor.withAlpha(120),
                height: 1,
                thickness: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Classical Golden Surah Banner for Dua' Khatm Al-Quran
  Widget _buildSurahBanner(
    bool isDark,
    Color frameColor,
    Color bannerTextColor,
  ) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            isDark
                ? 'packages/quran_kit/assets/data/surahSvgBannerDark.svg'
                : 'packages/quran_kit/assets/data/surahSvgBanner.svg',
            width: 220.w,
            height: 40.h,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              frameColor,
              BlendMode.srcIn,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Text(
              DuaKhatmQuranData.title,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16.5.sp,
                fontWeight: FontWeight.bold,
                color: bannerTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Continuation ornamental flourish for Page 606
  Widget _buildContinuationFlourish(
    Color frameColor,
    Color innerFrameColor,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: innerFrameColor.withAlpha(140),
              width: 0.8,
            ),
            color: frameColor.withAlpha(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '۞',
                style: TextStyle(fontSize: 12.sp, color: innerFrameColor),
              ),
              SizedBox(width: 6.w),
              Text(
                'تَتِمَّةُ دُعَاءِ خَتْمِ القُرْآنِ العَظِيمِ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: frameColor,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                '۞',
                style: TextStyle(fontSize: 12.sp, color: innerFrameColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Continuous flowing text with authentic Islamic golden rosettes
  Widget _buildContinuousText(
    List<DuaKhatmSection> sections,
    Color textColor,
    Color rosetteColor,
    double fontScale,
  ) {
    final spans = <InlineSpan>[];

    for (int i = 0; i < sections.length; i++) {
      // The section invocation
      spans.add(
        TextSpan(
          text: sections[i].text,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: (18.5 * fontScale).sp,
            height: 2.1,
            color: textColor,
          ),
        ),
      );

      // Traditional Islamic Rosette Symbol (وردة فاصل الدعاء كفواصل الآيات القرآنية)
      spans.add(
        TextSpan(
          text: '  ۞  ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: (18.5 * fontScale).sp,
            fontWeight: FontWeight.bold,
            color: rosetteColor,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }

  /// Concluding seal at the end of the Mushaf
  Widget _buildConcludingSeal(
    bool isDark,
    Color frameColor,
    Color innerFrameColor,
    Color textColor,
    double fontScale,
  ) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: frameColor.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: innerFrameColor.withAlpha(160),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '۞ خَاتِمَةُ المُصْحَفِ الشَّرِيفِ ۞',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: (14 * fontScale).sp,
                fontWeight: FontWeight.bold,
                color: frameColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'تَقَبَّلَ اللهُ مِنَّا وَمِنْكُمْ صَالِحَ الأَعْمَالِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: (12.5 * fontScale).sp,
                fontWeight: FontWeight.w600,
                color: textColor.withAlpha(220),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Classical bottom footer: Page number badge and concluding margins
  Widget _buildPageFooter(
    Color frameColor,
    Color innerFrameColor,
    bool isFirstPage,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thin bottom divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: innerFrameColor.withAlpha(120),
                height: 1,
                thickness: 0.8,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Icon(
                Icons.diamond_outlined,
                size: 14.sp,
                color: frameColor,
              ),
            ),
            Expanded(
              child: Divider(
                color: innerFrameColor.withAlpha(120),
                height: 1,
                thickness: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        // Bottom Row: Marginal notes and centered Page Number
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Right: Marginal note
            Expanded(
              child: Text(
                'خَاتِمَةُ المُصْحَفِ الشَّرِيفِ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: frameColor,
                ),
              ),
            ),
            // Center: Ornate Page Number Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: frameColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: innerFrameColor.withAlpha(140),
                  width: 0.9,
                ),
              ),
              child: Text(
                QuranService.toArabicDigits(widget.pageNumber),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: frameColor,
                ),
              ),
            ),
            // Left: Status / Supplication
            Expanded(
              child: Text(
                isFirstPage ? 'يُتْبَعُ...' : 'تَقَبَّلَ اللهُ طَاعَتَكُمْ',
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: frameColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
      ],
    );
  }
}
