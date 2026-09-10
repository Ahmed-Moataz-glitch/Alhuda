import 'dart:async';
import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/tajweed_span_builder.dart';
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
  bool _useOfflineUthmani = false;
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
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.store != widget.store ||
        oldWidget.showTajweed != widget.showTajweed) {
      _loadFontAndBlocks();
    }
  }

  void _loadFontAndBlocks() async {
    final store = effectiveStore;
    if (store == null) return;

    // 1. If QPC font is already cached/ready in memory, use QPC blocks directly
    if (FontLoader.instance.isPageReady(widget.pageNumber)) {
      _blocks = PageRenderer(store: store).buildPage(pageNumber: widget.pageNumber);
      if (mounted) {
        setState(() {
          _useOfflineUthmani = false;
        });
      }
      return;
    }

    // 2. Immediately enable offline Uthmani mode with Tajweed colors so the user NEVER waits
    if (mounted) {
      setState(() {
        _useOfflineUthmani = true;
      });
    }

    // 3. In the background, fetch high-fidelity QPC v4 ligature fonts
    try {
      final isOnline = await QuranService.instance.hasInternetConnection();
      if (!isOnline || !mounted) return;

      await FontLoader.instance
          .ensurePagesLoaded(widget.pageNumber, radius: 2);

      if (mounted && FontLoader.instance.isPageReady(widget.pageNumber)) {
        final curStore = effectiveStore;
        if (curStore != null) {
          _blocks = PageRenderer(store: curStore).buildPage(pageNumber: widget.pageNumber);
        }
        setState(() {
          _useOfflineUthmani = false;
        });
      }
    } catch (_) {
      // Font download error, timeout, or offline - colored offline page remains seamlessly active
    }
  }

  @override
  Widget build(BuildContext context) {
    final juzName = QuranService.instance.getPageJuzName(widget.pageNumber);
    final surahName = QuranService.instance.getPageSurahName(widget.pageNumber);

    return GestureDetector(
      onTap: widget.onPageBackgroundTapped,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: config.backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
        child: Container(
          // Outer Decorative Border Frame
          decoration: BoxDecoration(
            border: Border.all(color: config.frameColor, width: 2.0),
            borderRadius: BorderRadius.circular(6.r),
          ),
          padding: EdgeInsets.all(2.r),
          child: Container(
            // Inner Fine Border Frame
            decoration: BoxDecoration(
              border: Border.all(color: config.innerFrameColor, width: 1.0),
              borderRadius: BorderRadius.circular(4.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            child: Column(
              children: [
                // Top Header Line (الجزء - الزخرفة - السورة)
                _buildPageHeader(juzName, surahName),

                SizedBox(height: 4.h),

                // Center Page Body: QFC4 Hafs text & Authentic Surah Banners
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textColor = config.textColor;
                      final ayahColor = config.verseSymbolColor;
                      final baseFontSize = widget.fontSize ?? 26.0;
                      final double effectiveBannerWidth = constraints.maxWidth;

                      final playingAyah = (widget.playingSurah != null && widget.playingAyah != null)
                          ? (surah: widget.playingSurah!, ayah: widget.playingAyah!)
                          : null;

                      final selectedAyah = (widget.selectedSurah != null && widget.selectedAyah != null)
                          ? (surah: widget.selectedSurah!, ayah: widget.selectedAyah!)
                          : null;

                      // If offline or QPC blocks not available, render authentic offline Uthmani page immediately
                      final bool shouldUseOffline = _useOfflineUthmani || _blocks == null || _blocks!.isEmpty;
                      if (shouldUseOffline) {
                        return _buildOfflinePageContent(
                          constraints,
                          config,
                          baseFontSize,
                          playingAyah,
                          selectedAyah,
                          effectiveBannerWidth,
                        );
                      }

                      // Identify Surah Start Pages vs Regular Continuation Pages
                      final bool hasSurahHeader = _blocks!.any((b) => b is QpcV4SurahHeaderBlock);
                      final bool isSurahStartPage = hasSurahHeader || QuranService.kSurahStartPages.contains(widget.pageNumber);
                      final int ayahLineCount = _blocks!.whereType<QpcV4AyahLineBlock>().length;

                      // Base font scale from slider (26.0 is standard default = 1.0)
                      final double fontScale = baseFontSize / 26.0;

                      // Enlarge font on Surah start pages, keep standard font on regular pages, scaled by user setting
                      final double effectiveFontSize;
                      if (isSurahStartPage) {
                        if (ayahLineCount <= 6) {
                          effectiveFontSize = 40.0 * fontScale;
                        } else if (ayahLineCount <= 9) {
                          effectiveFontSize = 34.0 * fontScale;
                        } else if (ayahLineCount <= 12) {
                          effectiveFontSize = 30.0 * fontScale;
                        } else {
                          effectiveFontSize = 28.0 * fontScale;
                        }
                      } else {
                        effectiveFontSize = (constraints.maxHeight / (16.0 * 1.55)).clamp(18.0, 24.0) * fontScale;
                      }

                      final fontFamily = FontLoader.instance.getFontFamilyForPage(
                        widget.pageNumber,
                        isDark: widget.themeMode == MushafThemeMode.dark,
                        tajweed: widget.showTajweed,
                      );

                      final contentColumn = Column(
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
                      );

                      if (fontScale > 1.02) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight * fontScale,
                              child: Transform.scale(
                                scale: fontScale,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    child: contentColumn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else if (fontScale < 0.98) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Center(
                            child: Transform.scale(
                              scale: fontScale,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  child: contentColumn,
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            child: contentColumn,
                          ),
                        );
                      }
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

  /// Authentic Offline Uthmani Page Renderer using embedded Quran text and NotoNaskhArabic font.
  /// Renders immediately without requiring internet or external font downloads.
  Widget _buildOfflinePageContent(
    BoxConstraints constraints,
    MushafThemeConfig config,
    double baseFontSize,
    ({int surah, int ayah})? playingAyah,
    ({int surah, int ayah})? selectedAyah,
    double bannerWidth,
  ) {
    final pageData = QuranService.instance.getPageData(widget.pageNumber);
    final isDark = widget.themeMode == MushafThemeMode.dark;
    final textColor = config.textColor;
    final ayahColor = config.verseSymbolColor;
    final highlightColor = config.highlightColor;

    // Check if this page has a surah start (start == 1)
    final bool hasSurahStart = pageData.any((e) => (e['start'] ?? 0) == 1);
    final int totalVersesOnPage = pageData.fold(
      0,
      (sum, e) => sum + ((e['end'] ?? 1) - (e['start'] ?? 1) + 1),
    );

    final double fontScale = baseFontSize / 26.0;
    final double effectiveFontSize;
    final double effectiveHeight;
    if (hasSurahStart && totalVersesOnPage <= 7) {
      effectiveFontSize = (baseFontSize * 1.08).clamp(22.0, 38.0);
      effectiveHeight = 1.95;
    } else if (hasSurahStart && totalVersesOnPage <= 12) {
      effectiveFontSize = (baseFontSize * 1.0).clamp(20.0, 34.0);
      effectiveHeight = 1.80;
    } else {
      final double availableHeight = constraints.maxHeight;
      // 15 lines standard Madinah Mushaf page layout:
      final double baselineSize = (availableHeight / 24.5).clamp(21.0, 26.5);
      effectiveFontSize = (baselineSize * fontScale).clamp(16.0, 34.0);
      effectiveHeight = (availableHeight / (15.5 * baselineSize)).clamp(1.60, 1.75);
    }

    final children = <Widget>[];

    for (final section in pageData) {
      final surahNum = section['surah'] ?? 1;
      final startAyah = section['start'] ?? 1;
      final endAyah = section['end'] ?? 1;

      // 1. If this section starts at ayah 1, render Surah Banner & Basmallah
      if (startAyah == 1) {
        children.add(_buildSurahBanner(
          surahNum,
          config,
          isDark,
          bannerWidth: bannerWidth,
        ));

        if (surahNum != 1 && surahNum != 9) {
          children.add(Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: QuranBasmallah(
              surahNumber: surahNum,
              color: config.textColor,
            ),
          ));
        }
      }

      // 2. Build Spans for all verses in this section
      final spans = <InlineSpan>[];
      for (int a = startAyah; a <= endAyah; a++) {
        final verseText = QuranService.instance.getVerseUthmani(surahNum, a);
        final cleanVerseText = verseText.trim().replaceAll(RegExp(r'\s+'), ' ');
        final isPlaying = playingAyah != null &&
            surahNum == playingAyah.surah &&
            a == playingAyah.ayah;
        final isSelected = selectedAyah != null &&
            surahNum == selectedAyah.surah &&
            a == selectedAyah.ayah;
        final isHighlighted = isPlaying || isSelected;

        final Color? bgColor = isPlaying
            ? highlightColor
            : (isSelected
                ? (playingAyah != null ? highlightColor.withAlpha(100) : highlightColor)
                : null);

        final thisSurah = surahNum;
        final thisAyah = a;

        // Verse Text with Tajweed Coloring and uniform, equal word spacing
        final verseBaseStyle = TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: effectiveFontSize,
          height: effectiveHeight,
          wordSpacing: -0.5,
          color: isHighlighted ? ayahColor : textColor,
          backgroundColor: bgColor,
          fontWeight: FontWeight.w600,
        );

        // Apply authentic Quranic Kashida (مَطّ الكلام) so words fill the line width
        // while preserving equal, natural spacing between words.
        final stretchedVerseText = TajweedSpanBuilder.applyKashida(cleanVerseText);

        if (widget.showTajweed) {
          spans.addAll(TajweedSpanBuilder.buildVerseSpans(
            verseText: stretchedVerseText,
            baseStyle: verseBaseStyle,
            isDark: isDark,
            isHighlighted: isHighlighted,
            highlightColor: ayahColor,
            onTap: () {
              widget.onAyahTapped(thisSurah, thisAyah, cleanVerseText);
            },
            onLongPress: (details) {
              widget.onAyahTapped(thisSurah, thisAyah, cleanVerseText);
            },
          ));
        } else {
          spans.add(TextSpan(
            text: stretchedVerseText,
            style: verseBaseStyle,
            recognizer: TapLongPressRecognizer()
              ..onQuickTap = () {
                widget.onAyahTapped(thisSurah, thisAyah, cleanVerseText);
              }
              ..onLongPress = (details) {
                widget.onAyahTapped(thisSurah, thisAyah, cleanVerseText);
              },
          ));
        }

        // Authentic Islamic Ayah End Symbol (زهرة نهاية الآية)
        // \u00A0 non-breaking space keeps symbol tightly attached to verse end,
        // followed by a single standard space matching the exact inter-word space.
        spans.add(TextSpan(
          text: '\u00A0${QuranService.toArabicDigits(thisAyah)}\u202F ',
          style: TextStyle(
            fontFamily: 'ayahNumber',
            package: 'quran_kit',
            fontSize: effectiveFontSize + 3,
            height: effectiveHeight,
            color: ayahColor,
          ),
          recognizer: TapLongPressRecognizer()
            ..onQuickTap = () {
              widget.onAyahTapped(thisSurah, thisAyah, cleanVerseText);
            }
            ..onLongPress = (details) {
              widget.onAyahTapped(thisSurah, thisAyah, cleanVerseText);
            },
        ));
      }

      children.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: constraints.maxWidth,
              child: RichText(
                text: TextSpan(children: spans),
                textAlign: (hasSurahStart && totalVersesOnPage <= 7)
                    ? TextAlign.center
                    : TextAlign.justify,
                textDirection: TextDirection.rtl,
                softWrap: true,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: SizedBox(
            width: constraints.maxWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
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
    double? bannerWidth,
  }) {
    final revPlace = QuranService.instance.getPlaceOfRevelationArabic(surahNumber);
    final verseCount = QuranService.instance.getVerseCount(surahNumber);
    final verseCountAr = QuranService.toArabicDigits(verseCount);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Container(
        width: bannerWidth ?? double.infinity,
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
          height: 1.55,
          wordSpacing: -1.0,
          color: isHighlighted ? ayahColor : (widget.showTajweed ? null : textColor),
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
