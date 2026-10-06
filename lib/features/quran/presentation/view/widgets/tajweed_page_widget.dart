import 'dart:ui' as ui;
import 'package:alhuda/services/tajweed_page_cache_service.dart';
import 'package:alhuda/features/quran/presentation/view/widgets/mushaf_page_widget.dart'
    show MushafThemeMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A hardware-accelerated painter that crops the outer publisher borders of Dar Al-Ma'rifah
/// Tajweed pages (645x1000) to show only the pure, pristine 15 lines of Quranic text.
class _TajweedCropPainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  _TajweedCropPainter(this.image, {this.fit = BoxFit.contain});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Exact inner Quran text bounding box for Dar Al-Ma'rifah
    final double sx1 = (18.0 / 645.0) * image.width;
    final double sy1 = (25.0 / 1000.0) * image.height;
    final double sx2 = (627.0 / 645.0) * image.width;
    final double sy2 = (930.0 / 1000.0) * image.height;

    final srcRect = Rect.fromLTRB(sx1, sy1, sx2, sy2);
    final fittedSizes = applyBoxFit(fit, srcRect.size, size);
    final destinationSize = fittedSizes.destination;
    final double dx = (size.width - destinationSize.width) / 2.0;
    final double dy = (size.height - destinationSize.height) / 2.0;
    final dstRect = Rect.fromLTWH(dx, dy, destinationSize.width, destinationSize.height);

    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _TajweedCropPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.fit != fit;
}

/// A painter that preserves the full authentic Medina Mushaf frame and border
class _FullPagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  _FullPagePainter(this.image, {this.fit = BoxFit.contain});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final fittedSizes = applyBoxFit(fit, srcRect.size, size);
    final destinationSize = fittedSizes.destination;
    final double dx = (size.width - destinationSize.width) / 2.0;
    final double dy = (size.height - destinationSize.height) / 2.0;
    final dstRect = Rect.fromLTWH(dx, dy, destinationSize.width, destinationSize.height);

    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _FullPagePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.fit != fit;
}

/// Authentic Tajweed Mushaf Page Widget matching the Dar Al-Ma'rifah 15-line layout exactly
class TajweedPageWidget extends StatefulWidget {
  final int pageNumber;
  final VoidCallback? onPageTapped;
  final VoidCallback? onBookmarkToggled;
  final VoidCallback? onSurahTap;
  final VoidCallback? onPageTap;
  final VoidCallback? onJuzTap;
  final bool fitWidthInLandscape;
  final MushafThemeMode themeMode;
  final bool showOverlay;

  const TajweedPageWidget({
    super.key,
    required this.pageNumber,
    this.onPageTapped,
    this.onBookmarkToggled,
    this.onSurahTap,
    this.onPageTap,
    this.onJuzTap,
    this.fitWidthInLandscape = false,
    this.themeMode = MushafThemeMode.parchment,
    this.showOverlay = false,
  });

  @override
  State<TajweedPageWidget> createState() => _TajweedPageWidgetState();
}

class _TajweedPageWidgetState extends State<TajweedPageWidget> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    TajweedPageCacheService.instance.editionNotifier.addListener(_onEditionChanged);
    _loadImage();
  }

  void _onEditionChanged() {
    if (mounted) {
      setState(() {
        _decodedImage = null;
        _isLoading = true;
      });
      _loadImage();
    }
  }

  @override
  void didUpdateWidget(TajweedPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _decodedImage = null;
      _isLoading = true;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _loadImage();
    }
  }

  @override
  void dispose() {
    TajweedPageCacheService.instance.editionNotifier.removeListener(_onEditionChanged);
    _scrollController.dispose();
    _decodedImage = null;
    super.dispose();
  }

  Future<void> _loadImage() async {
    // 1. Check local cache or download in background
    try {
      final file = await TajweedPageCacheService.instance.getPageFile(widget.pageNumber);
      if (!mounted) return;

      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _decodedImage = frame.image;
            _isLoading = false;
          });
        }
      } else {
        // Try direct network load if file wasn't saved
        final url = TajweedPageCacheService.instance.getPageUrl(widget.pageNumber);
        final imageProvider = NetworkImage(url);
        final stream = imageProvider.resolve(const ImageConfiguration());
        stream.addListener(ImageStreamListener(
          (ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                _decodedImage = info.image;
                _isLoading = false;
              });
            }
          },
          onError: (dynamic _, StackTrace? __) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final edition = TajweedPageCacheService.instance.currentEdition;
    final isWhiteEdition = !edition.cropPublisherBorders;
    final isDark = widget.themeMode == MushafThemeMode.dark;
    final isWhite = widget.themeMode == MushafThemeMode.white;
    final bgColor = isDark
        ? const Color(0xFF121212)
        : (isWhite || isWhiteEdition ? Colors.white : const Color(0xFFFAF7EE));
    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Center Page Body: Full Display Quran Text
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isLandscape ? 8.0 : 4.w,
                (isLandscape && widget.showOverlay && !widget.fitWidthInLandscape)
                    ? 42.h
                    : (isLandscape ? 2.0 : 4.h),
                isLandscape ? 8.0 : 4.w,
                (isLandscape && widget.showOverlay && !widget.fitWidthInLandscape)
                    ? 46.h
                    : 8.h,
              ),
              child: GestureDetector(
                onTap: widget.onPageTapped,
                behavior: HitTestBehavior.opaque,
                child: _buildPageContent(isLandscape),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(bool isLandscape) {
    if (_decodedImage != null) {
      // Pages 1 and 2 (Al-Fatiha and Al-Baqarah start) are authentic full illuminations and must never be cropped
      final isCrop = TajweedPageCacheService
              .instance.currentEdition.cropPublisherBorders &&
          widget.pageNumber > 2;

      // In landscape, if fitWidth is enabled, render scrollable full-width page
      if (isLandscape && widget.fitWidthInLandscape) {
        final double srcW = isCrop
            ? (627.0 - 18.0) / 645.0 * _decodedImage!.width
            : _decodedImage!.width.toDouble();
        final double srcH = isCrop
            ? (930.0 - 25.0) / 1000.0 * _decodedImage!.height
            : _decodedImage!.height.toDouble();
        final double aspectRatio = (srcH > 0) ? (srcW / srcH) : 0.65;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double pageWidth = constraints.maxWidth;
            final double pageHeight = pageWidth / aspectRatio;

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: pageWidth,
                height: pageHeight,
                child: CustomPaint(
                  painter: isCrop
                      ? _TajweedCropPainter(_decodedImage!, fit: BoxFit.fill)
                      : _FullPagePainter(_decodedImage!, fit: BoxFit.fill),
                  size: Size(pageWidth, pageHeight),
                ),
              ),
            );
          },
        );
      }

      // Default (Portrait or Landscape Fit-Screen): strictly maintain authentic aspect ratio
      return CustomPaint(
        painter: isCrop
            ? _TajweedCropPainter(_decodedImage!, fit: BoxFit.contain)
            : _FullPagePainter(_decodedImage!, fit: BoxFit.fill),
        size: Size.infinite,
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32.r,
              height: 32.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF8B6B38),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'جاري تحميل صفحة ${widget.pageNumber}...',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 12.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // Error / Offline retry view
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40.sp, color: Colors.grey.shade500),
            SizedBox(height: 10.h),
            Text(
              'تعذر تحميل الصفحة، يرجى التأكد من الاتصال بالإنترنت للمرة الأولى',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 12.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6B38),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadImage();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Almarai')),
            ),
          ],
        ),
      ),
    );
  }
}
