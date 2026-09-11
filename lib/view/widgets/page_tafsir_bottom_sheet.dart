import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/tafsir_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Interactive modal sheet displaying complete exegesis for all verses on a Quran page
class PageTafsirBottomSheet extends StatefulWidget {
  final int initialPageNumber;
  final TafsirSource? initialSource;

  const PageTafsirBottomSheet({
    super.key,
    required this.initialPageNumber,
    this.initialSource,
  });

  static void show(
    BuildContext context, {
    required int pageNumber,
    TafsirSource? initialSource,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PageTafsirBottomSheet(
        initialPageNumber: pageNumber,
        initialSource: initialSource,
      ),
    );
  }

  @override
  State<PageTafsirBottomSheet> createState() => _PageTafsirBottomSheetState();
}

class _PageTafsirBottomSheetState extends State<PageTafsirBottomSheet> {
  late int _currentPage;
  late TafsirSource _selectedSource;
  List<AyahPageTafsir> _ayahTafsirs = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 16.sp;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPageNumber.clamp(1, 604);
    _selectedSource = widget.initialSource ?? TafsirService.availableTafsirs.first;
    _loadPageTafsir();
  }

  Future<void> _loadPageTafsir() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await TafsirService.instance.getPageTafsir(
        source: _selectedSource,
        pageNumber: _currentPage,
      );
      if (mounted) {
        setState(() {
          _ayahTafsirs = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل تفسير الصفحة، يرجى التحقق من الاتصال بالإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  void _copyAyahTafsir(AyahPageTafsir item) {
    final text = '﴿${item.ayahText}﴾\n[${item.surahName}: ${item.ayahNumber}]\n\n'
        '■ ${_selectedSource.name}:\n'
        '${item.tafsirText}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ الآية وتفسيرها بنجاح',
          style: TextStyle(fontFamily: 'Almarai'),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAllPageTafsir() {
    final buffer = StringBuffer();
    final surahName = QuranService.instance.getPageSurahName(_currentPage);
    buffer.writeln('■ تفسير صفحة $_currentPage ($surahName) - ${_selectedSource.name}');
    buffer.writeln('----------------------------------------\n');

    for (final item in _ayahTafsirs) {
      buffer.writeln('﴿ ${item.ayahText} ﴾');
      buffer.writeln('[${item.surahName}: ${item.ayahNumber}]');
      buffer.writeln(item.tafsirText);
      buffer.writeln('\n----------------------------------------\n');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ تفسير الصفحة كاملة إلى الحافظة',
          style: TextStyle(fontFamily: 'Almarai'),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    final surahName = QuranService.instance.getPageSurahName(_currentPage);
    final juzName = QuranService.instance.getPageJuzName(_currentPage);
    final offlinePkg = TafsirService.getOfflinePackage(_selectedSource.id);
    final isOfflineReady = TafsirService.instance.isOfflineDownloaded(_selectedSource.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          SizedBox(height: 10.h),
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // Header Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right controls: Font scaling & Copy Page
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_all_rounded, size: 22),
                      color: AppColors.primary,
                      tooltip: 'نسخ تفسير الصفحة كاملة',
                      onPressed: _ayahTafsirs.isNotEmpty ? _copyAllPageTafsir : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_increase_rounded, size: 22),
                      color: AppColors.primary,
                      tooltip: 'تكبير الخط',
                      onPressed: () {
                        setState(() {
                          if (_fontSize < 24.sp) _fontSize += 2.sp;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_decrease_rounded, size: 22),
                      color: AppColors.primary,
                      tooltip: 'تصغير الخط',
                      onPressed: () {
                        setState(() {
                          if (_fontSize > 12.sp) _fontSize -= 2.sp;
                        });
                      },
                    ),
                  ],
                ),

                // Center Title & Page Navigation
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تفسير صفحة $_currentPage',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                          Text(
                            'سورة $surahName • $juzName',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24),
                  color: Colors.grey.shade600,
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          SizedBox(height: 4.h),

          // Offline Status / Download Banner
          if (offlinePkg != null)
            _buildOfflineStatusBanner(offlinePkg, isOfflineReady, isDark),
          SizedBox(height: 4.h),
          // Source Switcher Chips
          SizedBox(
            height: 48.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              itemCount: TafsirService.availableTafsirs.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final source = TafsirService.availableTafsirs[index];
                final isSelected = source.id == _selectedSource.id;
                final isDownloaded = TafsirService.instance.isOfflineDownloaded(source.id);

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        source.name,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      if (isDownloaded) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.offline_pin_rounded,
                          size: 14.r,
                          color: isSelected ? Colors.white : Colors.green.shade700,
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withAlpha(20),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected && source.id != _selectedSource.id) {
                      setState(() {
                        _selectedSource = source;
                      });
                      _loadPageTafsir();
                    }
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Main Content: List of Ayahs with their exegesis
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'جارٍ تحميل تفسير آيات صفحة $_currentPage...',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 48.r, color: Colors.grey.shade400),
                              SizedBox(height: 10.h),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Almarai')),
                                onPressed: _loadPageTafsir,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        itemCount: _ayahTafsirs.length,
                        separatorBuilder: (_, __) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Divider(
                            color: AppColors.primary.withAlpha(30),
                            thickness: 1,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final item = _ayahTafsirs[index];
                          return _buildAyahTafsirItem(item, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatusBanner(
    OfflineTafsirPackage pkg,
    bool isOfflineReady,
    bool isDark,
  ) {
    if (isOfflineReady) {
      return Container(
        margin: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 2.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 18.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'هذا التفسير (${pkg.name}) متاح بالكامل أوفلاين بدون إنترنت.',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Not downloaded yet: Show download banner with live progress
    return ValueListenableBuilder<Map<String, TafsirDownloadProgress>>(
      valueListenable: TafsirService.instance.downloadProgressNotifier,
      builder: (context, progressMap, _) {
        final progress = progressMap[pkg.id];
        final isDownloading = progress?.isDownloading ?? false;

        return Container(
          margin: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 2.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.amber.shade400, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isDownloading ? Icons.downloading_rounded : Icons.cloud_download_rounded,
                    color: Colors.amber.shade900,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDownloading
                              ? 'جارٍ تنزيل ${pkg.name} (${progress?.percentInt ?? 0}%)...'
                              : 'حمّل ${pkg.name} مرة واحدة ليعمل بدون نت (${pkg.approximateSize})',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.brown.shade900,
                          ),
                        ),
                        if (isDownloading && progress != null && progress.totalBytes > 0) ...[
                          SizedBox(height: 2.h),
                          Text(
                            progress.sizeText,
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 10.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isDownloading)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      onPressed: () async {
                        final success = await TafsirService.instance.downloadOfflineTafsir(pkg.id);
                        if (success && mounted) {
                          setState(() {});
                          _loadPageTafsir();
                        }
                      },
                      child: const Text(
                        'تحميل الآن',
                        style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              if (isDownloading) ...[
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress?.progress ?? 0.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 5.h,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAyahTafsirItem(AyahPageTafsir item, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ayah Header with Badge and Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 14.r, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text(
                    '${item.surahName} • آية ${item.ayahNumber}',
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
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 18.r, color: Colors.grey.shade600),
              tooltip: 'نسخ الآية وتفسيرها',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _copyAyahTafsir(item),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // Uthmani Ayah Box
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : const Color(0xFFFAF6F0),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              '﴿ ${item.ayahText} ﴾',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.8,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),

        // Tafsir Text Box
        Directionality(
          textDirection: TextDirection.rtl,
          child: SelectableText(
            item.tafsirText,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: _fontSize,
              color: AppColors.textPrimary,
              height: 1.75,
            ),
          ),
        ),
      ],
    );
  }
}
