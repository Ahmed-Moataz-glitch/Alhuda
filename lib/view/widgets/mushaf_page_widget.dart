import 'dart:async';
import 'package:alhuda/services/quran_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quran_kit/core.dart';
import 'package:quran_kit/rendering_ui.dart';

enum MushafThemeMode {
  parchment,
  white,
  dark,
}

class MushafThemeConfig {
  final Color backgroundColor;
  final Color frameColor;
  final Color innerFrameColor;
  final Color textColor;
  final Color bannerBackground;
  final Color bannerBorderColor;
  final Color bannerTextColor;
  final Color highlightColor;
  final Color verseSymbolColor;

  const MushafThemeConfig({
    required this.backgroundColor,
    required this.frameColor,
    required this.innerFrameColor,
    required this.textColor,
    required this.bannerBackground,
    required this.bannerBorderColor,
    required this.bannerTextColor,
    required this.highlightColor,
    required this.verseSymbolColor,
  });

  static const MushafThemeConfig parchment = MushafThemeConfig(
    backgroundColor: Color(0xFFFAF7EE),
    frameColor: Color(0xFF8B6B38),
    innerFrameColor: Color(0xFFC5A059),
    textColor: Color(0xFF1E1D1B),
    bannerBackground: Color(0xFFF0EAE1),
    bannerBorderColor: Color(0xFF8B6B38),
    bannerTextColor: Color(0xFF5D4037),
    highlightColor: Color(0x66E5C07B),
    verseSymbolColor: Color(0xFF8B6B38),
  );

  static const MushafThemeConfig white = MushafThemeConfig(
    backgroundColor: Color(0xFFFFFFFF),
    frameColor: Color(0xFF8D6E63),
    innerFrameColor: Color(0xFFBCAAA4),
    textColor: Color(0xFF212121),
    bannerBackground: Color(0xFFF5F5F5),
    bannerBorderColor: Color(0xFF8D6E63),
    bannerTextColor: Color(0xFF3E2723),
    highlightColor: Color(0x55BCAAA4),
    verseSymbolColor: Color(0xFF8D6E63),
  );

  static const MushafThemeConfig dark = MushafThemeConfig(
    backgroundColor: Color(0xFF181818),
    frameColor: Color(0xFFD4AF37),
    innerFrameColor: Color(0xFF8C7322),
    textColor: Color(0xFFECEFF1),
    bannerBackground: Color(0xFF24221E),
    bannerBorderColor: Color(0xFFD4AF37),
    bannerTextColor: Color(0xFFFFD54F),
    highlightColor: Color(0x55D4AF37),
    verseSymbolColor: Color(0xFFFFD54F),
  );
}

/// Gesture recognizer supporting both quick tap and long press on an InlineSpan
class TapLongPressRecognizer extends TapGestureRecognizer {
  TapLongPressRecognizer({
    this.longPressDuration = const Duration(milliseconds: 500),
  }) {
    onTapDown = _handleTapDown;
    onTapUp = _handleTapUp;
    onTapCancel = _handleTapCancel;
  }

  final Duration longPressDuration;
  VoidCallback? onQuickTap;
  void Function(LongPressStartDetails details)? onLongPress;

  Timer? _longTimer;
  bool _didLongPress = false;
  TapDownDetails? _lastTapDown;

  void _handleTapDown(TapDownDetails details) {
    _lastTapDown = details;
    _didLongPress = false;
    _longTimer?.cancel();
    _longTimer = Timer(longPressDuration, () {
      _didLongPress = true;
      final d = _lastTapDown;
      if (d == null) return;
      onLongPress?.call(
        LongPressStartDetails(
          globalPosition: d.globalPosition,
          localPosition: d.localPosition,
        ),
      );
    });
  }

  void _handleTapCancel() {
    _longTimer?.cancel();
    _longTimer = null;
    _lastTapDown = null;
    _didLongPress = false;
  }

  void _handleTapUp(TapUpDetails details) {
    _longTimer?.cancel();
    _longTimer = null;
    if (!_didLongPress) {
      onQuickTap?.call();
    }
    _lastTapDown = null;
    _didLongPress = false;
  }

  @override
  void dispose() {
    _longTimer?.cancel();
    super.dispose();
  }
}

class MushafPageWidget extends StatefulWidget {
  final int pageNumber;
  final QpcV4AssetsStore? store;
  final bool showTajweed;
  final int? selectedSurah;
  final int? selectedAyah;
  final int? playingSurah;
  final int? playingAyah;
  final double? fontSize;
  final MushafThemeMode themeMode;
  final Function(int surahNumber, int verseNumber, String verseText) onAyahTapped;
  final VoidCallback? onPageBackgroundTapped;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.store,
    this.showTajweed = true,
    this.selectedSurah,
    this.selectedAyah,
    this.playingSurah,
    this.playingAyah,
    this.fontSize,
    this.themeMode = MushafThemeMode.parchment,
    required this.onAyahTapped,
    this.onPageBackgroundTapped,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  bool _fontReady = false;
  bool _fontFailed = false;
  List<QpcV4RenderBlock>? _blocks;

  QpcV4AssetsStore? get effectiveStore => widget.store ?? QuranService.instance.qpcStore;

  MushafThemeConfig get config {
    switch (widget.themeMode) {
      case MushafThemeMode.parchment:
        return MushafThemeConfig.parchment;
      case MushafThemeMode.white:
        return MushafThemeConfig.white;
      case MushafThemeMode.dark:
        return MushafThemeConfig.dark;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFontAndBlocks();
  }

  @override
  void didUpdateWidget(MushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber || oldWidget.store != widget.store) {
      _loadFontAndBlocks();
    }
  }

  void _loadFontAndBlocks() async {
    final store = effectiveStore;
    if (store == null) return;

    if (FontLoader.instance.isPageReady(widget.pageNumber)) {
      _blocks = PageRenderer(store: store).buildPage(pageNumber: widget.pageNumber);
      setState(() {
        _fontReady = true;
        _fontFailed = false;
      });
      return;
    }

    try {
      await FontLoader.instance
          .ensurePagesLoaded(widget.pageNumber, radius: 3)
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        final curStore = effectiveStore;
        if (curStore != null) {
          _blocks = PageRenderer(store: curStore).buildPage(pageNumber: widget.pageNumber);
        }
        setState(() {
          _fontReady = true;
          _fontFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final curStore = effectiveStore;
        if (curStore != null) {
          _blocks = PageRenderer(store: curStore).buildPage(pageNumber: widget.pageNumber);
        }
        setState(() {
          _fontFailed = true;
          _fontReady = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final juzName = QuranService.instance.getPageJuzName(widget.pageNumber);
    final surahName = QuranService.instance.getPageSurahName(widget.pageNumber);

    return GestureDetector(
      onTap: widget.onPageBackgroundTapped,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: config.backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Container(
          // Outer Decorative Border Frame
          decoration: BoxDecoration(
            border: Border.all(color: config.frameColor, width: 2.0),
            borderRadius: BorderRadius.circular(6.r),
          ),
          padding: EdgeInsets.all(3.r),
          child: Container(
            // Inner Fine Border Frame
            decoration: BoxDecoration(
              border: Border.all(color: config.innerFrameColor, width: 1.0),
              borderRadius: BorderRadius.circular(4.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                // Top Header Line (الجزء - الزخرفة - السورة)
                _buildPageHeader(juzName, surahName),

                SizedBox(height: 4.h),

                // Center Page Body: QFC4 Hafs text & Authentic Surah Banners
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (effectiveStore == null || (!_fontReady && !_fontFailed)) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: QuranLoadingPlaceholder(
                              isDark: widget.themeMode == MushafThemeMode.dark,
                            ),
                          ),
                        );
                      }

                      if (_blocks == null || _blocks!.isEmpty) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: QuranLoadingPlaceholder(
                              isDark: widget.themeMode == MushafThemeMode.dark,
                            ),
                          ),
                        );
                      }

                      final textColor = config.textColor;
                      final ayahColor = config.verseSymbolColor;
                      final baseFontSize = widget.fontSize ?? 26.0;

                      // Identify Surah Start Pages vs Regular Continuation Pages
                      final bool hasSurahHeader = _blocks!.any((b) => b is QpcV4SurahHeaderBlock);
                      final bool isSurahStartPage = hasSurahHeader || QuranService.kSurahStartPages.contains(widget.pageNumber);
                      final int ayahLineCount = _blocks!.whereType<QpcV4AyahLineBlock>().length;

                      // Enlarge font ONLY on Surah start pages, keep standard font on regular pages
                      final double effectiveFontSize;
                      if (isSurahStartPage) {
                        if (ayahLineCount <= 6) {
                          // e.g. Page 1 (Fatihah), Page 2 (Baqarah start - 5 lines)
                          effectiveFontSize = 40.0;
                        } else if (ayahLineCount <= 9) {
                          // e.g. Page 50 (Aal-Imran start - 9 lines)
                          effectiveFontSize = 34.0;
                        } else if (ayahLineCount <= 12) {
                          // e.g. Page 77 (An-Nisa start - 10 lines)
                          effectiveFontSize = 30.0;
                        } else {
                          effectiveFontSize = 28.0;
                        }
                      } else {
                        // Regular 15-line pages: standard crisp font matching the Madinah Mushaf
                        effectiveFontSize = baseFontSize.clamp(24.0, 28.0);
                      }
                      final double effectiveBannerWidth = size.width * 1.3;

                      final fontFamily = FontLoader.instance.getFontFamilyForPage(
                        widget.pageNumber,
                        isDark: widget.themeMode == MushafThemeMode.dark,
                        tajweed: widget.showTajweed,
                      );

                      final playingAyah = (widget.playingSurah != null && widget.playingAyah != null)
                          ? (surah: widget.playingSurah!, ayah: widget.playingAyah!)
                          : null;

                      final selectedAyah = (widget.selectedSurah != null && widget.selectedAyah != null)
                          ? (surah: widget.selectedSurah!, ayah: widget.selectedAyah!)
                          : null;

                      return SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _blocks!.map((block) {
                              if (block is QpcV4SurahHeaderBlock) {
                                return _buildSurahBanner(
                                  block.surahNumber,
                                  config,
                                  widget.themeMode == MushafThemeMode.dark,
                                  bannerWidth: effectiveBannerWidth,
                                );
                              }

                              if (block is QpcV4BasmallahBlock) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 3.h),
                                  child: QuranBasmallah(
                                    surahNumber: block.surahNumber,
                                    color: config.textColor,
                                  ),
                                );
                              }

                              if (block is QpcV4AyahLineBlock) {
                                return _buildAyahLine(
                                  block,
                                  fontFamily: fontFamily,
                                  fontSize: effectiveFontSize,
                                  textColor: textColor,
                                  ayahColor: ayahColor,
                                  playingAyah: playingAyah,
                                  selectedAyah: selectedAyah,
                                  highlightColor: config.highlightColor,
                                  onAyahTapped: widget.onAyahTapped,
                                );
                              }

                              return const SizedBox.shrink();
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 2.h),

                // Bottom Footer Line (رقم الصفحة)
                _buildPageFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Classical Madinah Mushaf Surah Header Banner
  /// Right: Revelation place (مكية / مدنية)
  /// Center: Calligraphic Surah Name in ornamental SVG banner
  /// Left: Verse count (آياتها ...)
  Widget _buildSurahBanner(
    int surahNumber,
    MushafThemeConfig config,
    bool isDark, {
    double bannerWidth = 360.0,
  }) {
    final revPlace = QuranService.instance.getPlaceOfRevelationArabic(surahNumber);
    final verseCount = QuranService.instance.getVerseCount(surahNumber);
    final verseCountAr = QuranService.toArabicDigits(verseCount);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Container(
        width: bannerWidth,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: config.bannerBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: config.bannerBorderColor.withAlpha(150),
            width: 1.2,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Right side (in RTL): Revelation place badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: config.backgroundColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: config.innerFrameColor.withAlpha(140),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  revPlace,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: config.bannerTextColor,
                  ),
                ),
              ),

              // Center: Decorative SVG Banner with Calligraphy
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          isDark
                              ? 'packages/quran_kit/assets/data/surahSvgBannerDark.svg'
                              : 'packages/quran_kit/assets/data/surahSvgBanner.svg',
                          width: 190.w,
                          height: 38.h,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            config.frameColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        Text(
                          ' surah${surahNumber.toString().padLeft(3, '0')} ',
                          style: TextStyle(
                            fontFamily: 'surahName',
                            package: 'quran_kit',
                            fontSize: 32.sp,
                            height: 1.2,
                            color: config.bannerTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Left side (in RTL): Ayah count badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: config.backgroundColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: config.innerFrameColor.withAlpha(140),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'آياتها $verseCountAr',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: config.bannerTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ayah line renderer using QPC v4 ligature fonts & Tajweed colors
  Widget _buildAyahLine(
    QpcV4AyahLineBlock block, {
    required String fontFamily,
    required double fontSize,
    required Color textColor,
    required Color ayahColor,
    required ({int surah, int ayah})? playingAyah,
    required ({int surah, int ayah})? selectedAyah,
    required Color highlightColor,
    required void Function(int surahNumber, int verseNumber, String verseText) onAyahTapped,
  }) {
    final spans = <InlineSpan>[];

    for (final seg in block.segments) {
      final isPlaying = playingAyah != null &&
          seg.surahNumber == playingAyah.surah &&
          seg.ayahNumber == playingAyah.ayah;

      final isSelected = selectedAyah != null &&
          seg.surahNumber == selectedAyah.surah &&
          seg.ayahNumber == selectedAyah.ayah;

      final isHighlighted = isPlaying || isSelected;

      // When playing, use full highlight color. If manually selected at the same time, give selected a soft tint.
      final Color? bgColor = isPlaying
          ? highlightColor
          : (isSelected
              ? (playingAyah != null ? highlightColor.withAlpha(100) : highlightColor)
              : null);

      spans.add(TextSpan(
        text: seg.glyphs,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: 1.95,
          wordSpacing: -1.0,
          color: isHighlighted ? ayahColor : textColor,
          backgroundColor: bgColor,
        ),
        recognizer: TapLongPressRecognizer()
          ..onQuickTap = () {
            final text = QuranService.instance.getVerseUthmani(
              seg.surahNumber,
              seg.ayahNumber,
            );
            onAyahTapped(seg.surahNumber, seg.ayahNumber, text);
          }
          ..onLongPress = (details) {
            final text = QuranService.instance.getVerseUthmani(
              seg.surahNumber,
              seg.ayahNumber,
            );
            onAyahTapped(seg.surahNumber, seg.ayahNumber, text);
          },
      ));

      if (seg.isAyahEnd) {
        spans.add(TextSpan(
          text: '${QuranService.toArabicDigits(seg.ayahNumber)}\u202F\u202F',
          style: TextStyle(
            fontFamily: 'ayahNumber',
            package: 'quran_kit',
            fontSize: fontSize + 4,
            height: 1.5,
            color: ayahColor,
          ),
          recognizer: TapLongPressRecognizer()
            ..onQuickTap = () {
              final text = QuranService.instance.getVerseUthmani(
                seg.surahNumber,
                seg.ayahNumber,
              );
              onAyahTapped(seg.surahNumber, seg.ayahNumber, text);
            }
            ..onLongPress = (details) {
              final text = QuranService.instance.getVerseUthmani(
                seg.surahNumber,
                seg.ayahNumber,
              );
              onAyahTapped(seg.surahNumber, seg.ayahNumber, text);
            },
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      softWrap: false,
      overflow: TextOverflow.visible,
    );
  }

  /// Top header inside the Islamic frame
  Widget _buildPageHeader(String juzName, String surahName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Juz Name on the Right (in RTL)
            Flexible(
              child: Text(
                juzName,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: config.frameColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Center Islamic Flourish
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                '۞',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: config.innerFrameColor,
                ),
              ),
            ),
            // Surah Name on the Left
            Flexible(
              child: Text(
                'سورة $surahName',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: config.frameColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        // Thin Ornamental Line
        Row(
          children: [
            Expanded(child: Divider(color: config.innerFrameColor.withAlpha(120), height: 1, thickness: 0.8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Icon(Icons.diamond_outlined, size: 16.sp, color: config.frameColor),
            ),
            Expanded(child: Divider(color: config.innerFrameColor.withAlpha(120), height: 1, thickness: 0.8)),
          ],
        ),
      ],
    );
  }

  /// Bottom footer: Centered page number
  Widget _buildPageFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thin bottom divider
        Row(
          children: [
            Expanded(child: Divider(color: config.innerFrameColor.withAlpha(120), height: 1, thickness: 0.8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Icon(Icons.diamond_outlined, size: 16.sp, color: config.frameColor),
            ),
            Expanded(child: Divider(color: config.innerFrameColor.withAlpha(120), height: 1, thickness: 0.8)),
          ],
        ),
        SizedBox(height: 4.h),
        // Ornate Page Number Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: config.frameColor.withAlpha(15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: config.innerFrameColor.withAlpha(90)),
          ),
          child: Text(
            '— ${QuranService.toArabicDigits(widget.pageNumber)} —',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: config.frameColor,
            ),
          ),
        ),
      ],
    );
  }
}
