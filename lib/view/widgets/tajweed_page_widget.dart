import 'dart:ui' as ui;
import 'package:alhuda/core/constants/app_colors.dart';
import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/tajweed_page_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



/// A hardware-accelerated painter that crops the outer publisher borders of Dar Al-Ma'rifah
/// Tajweed pages (645x1000) to show only the pure, pristine 15 lines of Quranic text.
class _TajweedCropPainter extends CustomPainter {
  final ui.Image image;
  _TajweedCropPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // Exact inner Quran text bounding box
    final double sx1 = (18.0 / 645.0) * image.width;
    final double sy1 = (25.0 / 1000.0) * image.height;
    final double sx2 = (627.0 / 645.0) * image.width;
    final double sy2 = (930.0 / 1000.0) * image.height;

    final srcRect = Rect.fromLTRB(sx1, sy1, sx2, sy2);
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _TajweedCropPainter oldDelegate) => oldDelegate.image != image;
}

/// Authentic Tajweed Mushaf Page Widget matching the Dar Al-Ma'rifah 15-line layout exactly
class TajweedPageWidget extends StatefulWidget {
  final int pageNumber;
  final VoidCallback? onPageTapped;
  final VoidCallback? onBookmarkToggled;
  final VoidCallback? onSurahTap;
  final VoidCallback? onPageTap;
  final VoidCallback? onJuzTap;

  const TajweedPageWidget({
    super.key,
    required this.pageNumber,
    this.onPageTapped,
    this.onBookmarkToggled,
    this.onSurahTap,
    this.onPageTap,
    this.onJuzTap,
  });

  @override
  State<TajweedPageWidget> createState() => _TajweedPageWidgetState();
}

class _TajweedPageWidgetState extends State<TajweedPageWidget> {
  ui.Image? _decodedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(TajweedPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _decodedImage = null;
      _isLoading = true;
      _loadImage();
    }
  }

  @override
  void dispose() {
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
    final surahName = QuranService.instance.getPageSurahName(widget.pageNumber);
    final juzNumber = QuranService.instance.getPageJuzNumber(widget.pageNumber);
    final hizbNumber = TajweedPageCacheService.getHizbForPage(widget.pageNumber);
    return Container(
      color: const Color(0xFFFAF7EE), // Creamy authentic Mushaf parchment background
      child: Column(
        children: [
          // Center Page Body: Full Display Quran Text
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
              child: GestureDetector(
                onTap: widget.onPageTapped,
                behavior: HitTestBehavior.opaque,
                child: _buildPageContent(),
              ),
            ),
          ),

          // Authentic Page Footer Line (سورة [الاسم] - [رقم الصفحة] - جزء [رقم الجزء] • الحزب [رقم الحزب])
          Container(
            height: 30.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7EE),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withAlpha(15),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right (in RTL direction): Surah Name
                InkWell(
                  onTap: widget.onSurahTap,
                  borderRadius: BorderRadius.circular(4.r),
                  child: Text(
                    'سورة $surahName',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary.withAlpha(200),
                    ),
                  ),
                ),

                // Center: Page Number
                InkWell(
                  onTap: widget.onPageTap,
                  borderRadius: BorderRadius.circular(4.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    child: Text(
                      '${widget.pageNumber}',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E1B18),
                      ),
                    ),
                  ),
                ),

                // Left: Juz and Hizb Number (e.g. جزء 24 • الحزب 47)
                InkWell(
                  onTap: widget.onJuzTap,
                  borderRadius: BorderRadius.circular(4.r),
                  child: Text(
                    'جزء $juzNumber • الحزب $hizbNumber',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary.withAlpha(200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    if (_decodedImage != null) {
      return CustomPaint(
        painter: _TajweedCropPainter(_decodedImage!),
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
