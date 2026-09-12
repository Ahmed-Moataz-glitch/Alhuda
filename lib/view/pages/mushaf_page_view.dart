import 'package:alhuda/model/mushaf_edition.dart';
import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/tajweed_page_cache_service.dart';
import 'package:alhuda/services/tajweed_span_builder.dart';
import 'package:alhuda/view/pages/surah_reader_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/services/tafsir_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/view/widgets/mushaf_page_widget.dart'
    show MushafThemeMode;
import 'package:alhuda/view/widgets/page_tafsir_bottom_sheet.dart';
import 'package:alhuda/view/widgets/tajweed_page_widget.dart';
import 'package:alhuda/view/widgets/tafsir_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_kit/audio.dart';

/// Full Madinah Mushaf Page View (604 pages)
class MushafPageView extends StatefulWidget {
  final int initialPage;
  final int? highlightedSurah;
  final int? highlightedAyah;
  final double? initialFontSize;

  const MushafPageView({
    super.key,
    this.initialPage = 1,
    this.highlightedSurah,
    this.highlightedAyah,
    this.initialFontSize,
  });

  @override
  State<MushafPageView> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPageView> {
  late PageController _pageController;
  late int _currentPage;
  int? _selectedSurah;
  int? _selectedAyah;
  String? _selectedAyahText;
  bool _showOverlay = true;
  bool _autoAdvancePages = true;
  MushafThemeMode _themeMode = MushafThemeMode.parchment;

  int? _lastPlayingSurah;
  int? _lastPlayingAyah;
  bool _lastIsActive = false;

  @override
  void initState() {
    super.initState();
    if (ThemeService.instance.isDarkMode) {
      _themeMode = MushafThemeMode.dark;
    }
    _currentPage = widget.initialPage.clamp(1, 604);
    _selectedSurah = widget.highlightedSurah;
    _selectedAyah = widget.highlightedAyah;
    if (_selectedSurah != null && _selectedAyah != null) {
      _selectedAyahText = QuranService.instance.getVerseUthmani(
        _selectedSurah!,
        _selectedAyah!,
      );
    }
    _pageController = PageController(initialPage: _currentPage - 1);
    _updateLastRead(_currentPage);

    // Track active audio recitation
    final currentAudio = QuranService.instance.audioService.state.value;
    if (currentAudio.isActive) {
      _lastIsActive = true;
      _lastPlayingSurah = currentAudio.surah;
      _lastPlayingAyah = currentAudio.ayah;
    }
    QuranService.instance.audioService.state.addListener(_onAudioStateChanged);

    _safePrefetch(_currentPage);

    // Initialize Tajweed Page Cache Service and refresh download count
    TajweedPageCacheService.instance.editionNotifier.addListener(
      _onEditionChanged,
    );
    TajweedPageCacheService.instance.init().then((_) {
      if (mounted) {
        TajweedPageCacheService.instance.refreshDownloadStatus();
      }
    });
  }

  void _onEditionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    TajweedPageCacheService.instance.editionNotifier.removeListener(
      _onEditionChanged,
    );
    QuranService.instance.audioService.state.removeListener(
      _onAudioStateChanged,
    );
    _pageController.dispose();
    super.dispose();
  }

  void _onAudioStateChanged() {
    final s = QuranService.instance.audioService.state.value;
    final isActive = s.isActive;
    final surah = isActive ? s.surah : null;
    final ayah = isActive ? s.ayah : null;

    if (isActive != _lastIsActive ||
        surah != _lastPlayingSurah ||
        ayah != _lastPlayingAyah) {
      _lastIsActive = isActive;
      _lastPlayingSurah = surah;
      _lastPlayingAyah = ayah;

      if (mounted) {
        // Auto-navigate to page if the currently playing ayah belongs to a different page
        if (isActive && surah != null && ayah != null) {
          final targetPage = QuranService.instance.getPageNumber(surah, ayah);
          if (targetPage != _currentPage) {
            if (_autoAdvancePages) {
              if ((targetPage - _currentPage).abs() == 1) {
                _pageController.animateToPage(
                  targetPage - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _jumpToPage(targetPage);
              }
            } else {
              // User opted not to auto-advance past the current page
              QuranService.instance.audioService.stop();
            }
          }
        }
        setState(() {});
      }
    }
  }

  /// Play the entire page from its first Ayah
  Future<void> _playCurrentPage() async {
    final pageData = QuranService.instance.getPageData(_currentPage);
    if (pageData.isEmpty) return;
    final first = pageData.first;
    final startSurah = first['surah'] ?? 1;
    final startAyah = first['start'] ?? 1;

    final canPlay = await _verifyAudioPlayable(startSurah);
    if (!canPlay) return;

    try {
      await QuranService.instance.audioService.playAyah(startSurah, startAyah);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'تعذر تشغيل التلاوة، يرجى التأكد من الاتصال بالإنترنت',
              ),
            ),
          ),
        );
      }
    }
  }

  /// Toggle play/pause for the current page
  void _togglePageAudio() async {
    final audio = QuranService.instance.audioService;
    final s = audio.state.value;
    if (s.isActive) {
      final playingPage = QuranService.instance.getPageNumber(s.surah, s.ayah);
      if (playingPage == _currentPage) {
        audio.togglePlayPause();
      } else {
        await _playCurrentPage();
      }
    } else {
      await _playCurrentPage();
    }
  }

  /// Show reciter picker bottom sheet
  void _showReciterPicker() {
    final reciters = QuranService.instance.reciters;
    final currentReciterIndex = QuranService.instance.audioService.reciterIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'اختيار القارئ المفضل',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: reciters.length,
                    itemBuilder: (context, index) {
                      final reciter = reciters[index];
                      final isSelected = index == currentReciterIndex;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withAlpha(20),
                          child: Icon(
                            Icons.person_rounded,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            size: 20.r,
                          ),
                        ),
                        title: Text(
                          reciter.nameAr,
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontSize: 14.sp,
                          ),
                        ),
                        subtitle: Text(
                          reciter.nameEn,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          QuranService.instance.audioService.setReciter(index);
                          Navigator.pop(context);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _safePrefetch(int page) {
    TajweedPageCacheService.instance.prefetchPages(page, radius: 5);
  }

  Future<bool> _verifyAudioPlayable(int surahNumber) async {
    final canPlay = await QuranService.instance.canPlayAudio(surahNumber);
    if (!canPlay && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10.w),
                const Expanded(
                  child: Text(
                    'يتطلب الاستماع لتلاوة القارئ اتصالاً بالإنترنت',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.brown.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  void _updateLastRead(int page) {
    final pageData = QuranService.instance.getPageData(page);
    if (pageData.isNotEmpty) {
      final first = pageData.first;
      final surahNum = first['surah'] ?? 1;
      final ayahNum = first['start'] ?? 1;
      final surahName = QuranService.instance.getPageSurahName(page);
      QuranService.instance.setLastRead(
        surahNumber: surahNum,
        surahName: surahName,
        ayahNumber: ayahNum,
        pageNumber: page,
      );
    }
  }

  void _jumpToPage(int page) {
    final clamped = page.clamp(1, 604);
    _pageController.jumpToPage(clamped - 1);
    setState(() {
      _currentPage = clamped;
      _selectedSurah = null;
      _selectedAyah = null;
      _selectedAyahText = null;
    });
    _updateLastRead(clamped);
    _safePrefetch(clamped);
  }

  void _onPageBackgroundTapped() {
    setState(() {
      if (_selectedSurah != null) {
        // Clear Ayah selection first
        _selectedSurah = null;
        _selectedAyah = null;
        _selectedAyahText = null;
      } else {
        // Toggle fullscreen overlay
        _showOverlay = !_showOverlay;
      }
    });
  }

  Future<void> _toggleCurrentPageBookmark() async {
    HapticFeedback.mediumImpact();
    final isNowBookmarked =
        await QuranService.instance.togglePageBookmark(_currentPage);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(
                isNowBookmarked
                    ? Icons.bookmark_added_rounded
                    : Icons.bookmark_remove_rounded,
                color: Colors.white,
                size: 20.r,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  isNowBookmarked
                      ? 'تم حفظ صفحة $_currentPage في العلامات المرجعية'
                      : 'تمت إزالة علامة صفحة $_currentPage',
                  style: const TextStyle(
                    fontFamily: 'Almarai',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor:
            isNowBookmarked ? AppColors.primary : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBookmarkRibbon() {
    return Tooltip(
      message: 'فاصل الصفحة المحفوظة (اضغط للإزالة)',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 28.w,
        height: 52.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFD4AF37), // Rich gold
              Color(0xFF8B6B18),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(4.r),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 6.h,
              child: Icon(
                Icons.bookmark_rounded,
                color: Colors.white.withAlpha(240),
                size: 16.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJumpDialog() {
    final pageInputController = TextEditingController();
    final surahs = QuranService.instance.getAllSurahs();
    final juzs = QuranService.instance.getAllJuzs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 4,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الانتقال في المصحف الشريف',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'رقم الصفحة'),
                      Tab(text: 'فهرس السور'),
                      Tab(text: 'فهرس الأجزاء'),
                      Tab(text: 'العلامات'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 1. Direct Page Number Input
                        Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'أدخل رقم الصفحة (1 - 604):',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 15.sp,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              TextField(
                                controller: pageInputController,
                                onTapOutside: (_) =>
                                    FocusScope.of(context).unfocus(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'مثال: 77',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.h,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 40.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                onPressed: () {
                                  final p = int.tryParse(
                                    pageInputController.text.trim(),
                                  );
                                  if (p != null && p >= 1 && p <= 604) {
                                    Navigator.pop(context);
                                    _jumpToPage(p);
                                  }
                                },
                                child: Text(
                                  'انتقال للصفحة',
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final saved = QuranService.instance.getLastSavedPageBookmark();
                                  if (saved == null) return const SizedBox.shrink();
                                  return Padding(
                                    padding: EdgeInsets.only(top: 16.h),
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.amber.shade900,
                                        side: BorderSide(
                                          color: Colors.amber.shade700.withAlpha(120),
                                        ),
                                        backgroundColor: Colors.amber.withAlpha(20),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 10.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.bookmark_rounded,
                                        color: Colors.amber.shade800,
                                        size: 18.r,
                                      ),
                                      label: Text(
                                        'الصفحة المحفوظة: ص ${saved.pageNumber} (سورة ${saved.surahName})',
                                        style: TextStyle(
                                          fontFamily: 'Almarai',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _jumpToPage(saved.pageNumber);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // 2. Surah Index
                        ListView.builder(
                          itemCount: surahs.length,
                          itemBuilder: (context, i) {
                            final s = surahs[i];
                            final isMeccan = s.revelationType == 'مكية';
                            return ListTile(
                              leading: Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: AppColors.primary.withAlpha(50),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${s.number}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    'سورة ${s.arabicName}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: 'Rubik',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 1.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMeccan
                                          ? const Color(0xFFFFF8E1)
                                          : const Color(0xFFE0F2F1),
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(
                                        color: isMeccan
                                            ? const Color(0xFFFFB300)
                                            : const Color(0xFF26A69A),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      s.revelationType,
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isMeccan
                                            ? const Color(0xFF8D6E63)
                                            : const Color(0xFF00695C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'آياتها ${QuranService.toArabicDigits(s.totalAyahs)} • ${s.englishName}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                'صفحة ${s.startPage}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _jumpToPage(s.startPage);
                              },
                            );
                          },
                        ),

                        // 3. Juz Index
                        ListView.builder(
                          itemCount: juzs.length,
                          itemBuilder: (context, i) {
                            final j = juzs[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  '${j.number}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                'الجزء ${j.number}',
                                style: const TextStyle(
                                  fontFamily: 'Almarai',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'يبدأ من سورة ${j.startSurahName} (آية ${j.startAyahNumber})',
                                style: TextStyle(fontSize: 11.sp),
                              ),
                              trailing: Text(
                                'صفحة ${j.startPage}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _jumpToPage(j.startPage);
                              },
                            );
                          },
                        ),

                        // 4. Bookmarks Index
                        StatefulBuilder(
                          builder: (context, setModalState) {
                            final bookmarks = QuranService.instance.getBookmarks();
                            if (bookmarks.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.r),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bookmark_border_rounded,
                                        size: 48.r,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'لا توجد علامات مرجعية محفوظة بعد',
                                        style: TextStyle(
                                          fontFamily: 'Almarai',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        'يمكنك حفظ الصفحة الحالية في أي وقت بالضغط على أيقونة الفاصل في الشريط العلوي.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Almarai',
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: bookmarks.length,
                              itemBuilder: (context, i) {
                                final b = bookmarks[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade50,
                                    child: Icon(
                                      Icons.bookmark_rounded,
                                      color: Colors.amber.shade800,
                                      size: 20.r,
                                    ),
                                  ),
                                  title: Text(
                                    'سورة ${b.surahName} • آية ${b.ayahNumber}',
                                    style: TextStyle(
                                      fontFamily: 'Almarai',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    b.snippet.isNotEmpty
                                        ? b.snippet
                                        : 'صفحة ${b.pageNumber}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(20),
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          'ص ${b.pageNumber}',
                                          style: TextStyle(
                                            fontFamily: 'Almarai',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        onPressed: () async {
                                          await QuranService.instance
                                              .removeBookmarkByPage(
                                                  b.pageNumber);
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _jumpToPage(b.pageNumber);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTajweedRulesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        Text(
                          'دليل ألوان أحكام التجويد',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                SizedBox(height: 4.h),
                Text(
                  'اصطلاحات ألوان مصحف التجويد الملون (دار المعرفة) برواية حفص عن عاصم',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 11.5.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: ListView(
                    children: [
                      ...[
                        (
                          name: 'تفخيم الحروف',
                          hakam: 'أزرق داكن (كحلي)',
                          desc:
                              'حروف الاستعلاء (خ، ص، ض، غ، ط، ق، ظ)، والراء المفخمة، ولام لفظ الجلالة المفخمة',
                          example:
                              'يُبْصِرُونَ، خَلَقَكُمْ، الصَّوَٰعِقِ، رِزْقًا، قَبْلِكُمْ',
                          color: TajweedPalette.tafkheemLight,
                        ),
                        (
                          name: 'القلقلة',
                          hakam: 'أزرق سماوي (فاتح)',
                          desc:
                              'حروف (ق، ط، ب، ج، د) عند سكونها أو الوقف عليها',
                          example:
                              'يَجْعَلُونَ، أَصَٰبِعَهُم، قَبْلِكُمْ، وَادْعُواْ',
                          color: TajweedPalette.qalqalaLight,
                        ),
                        (
                          name: 'الغنة والإخفاء والإدغام بغنة',
                          hakam: 'أخضر (حركتان)',
                          desc:
                              'النون والميم المشددتان، الإخفاء الحقيقي والشفوي، الإدغام بغنة، والقلب',
                          example:
                              'أَنَّ، ثُمَّ، مِّمَّا، عِندَ، مَّعْدُودَةً، أَندَادًا، كُنتُمْ',
                          color: TajweedPalette.ghunnaLight,
                        ),
                        (
                          name: 'المد اللازم',
                          hakam: 'أحمر داكن (6 حركات)',
                          desc: 'المد اللازم الكلمي والحرفي المثقل والمخفف',
                          example: 'الضَّالِّينَ، دَابَّة، الحَاقَّة، الٓمٓ',
                          color: TajweedPalette.maddLazimLight,
                        ),
                        (
                          name: 'المد الواجب المتصل',
                          hakam: 'أحمر فاقع (4 أو 5 حركات)',
                          desc: 'أن يأتي حرف المد وبعده همزة في نفس الكلمة',
                          example:
                              'السَّمَاءِ، جَاءَ، سُوءَ، إِسْرَائِيلَ، بِنَاءً',
                          color: TajweedPalette.maddMuttasilLight,
                        ),
                        (
                          name: 'المد المنفصل والصلة الكبرى',
                          hakam: 'وردي / فوشيا (2-4-5 حركات)',
                          desc:
                              'أن يأتي حرف المد في كلمة وهمزة القطع في الكلمة التي تليها',
                          example:
                              'فِي آذَانِهِمْ، بِمَا أُنزِلَ، قَالُوا إِنَّا، عَهْدَهُۥٓ أَمْ',
                          color: TajweedPalette.maddMunfasilLight,
                        ),
                        (
                          name: 'المد العارض واللين والبدل والطبيعي',
                          hakam: 'برتقالي / كموني (2 أو 4 أو 6 حركات)',
                          desc:
                              'المد العارض للسكون عند الوقف، مد اللين، ومد الصلة الصغرى والألف الخنجرية',
                          example:
                              'يَرْجِعُونَ، تَتَّقُونَ، تَعْلَمُونَ، صَادِقِينَ، خَوْفٍ',
                          color: TajweedPalette.maddTabiiLight,
                        ),
                        (
                          name: 'الحروف التي لا تلفظ',
                          hakam: 'رمادي',
                          desc:
                              'همزة الوصل، اللام الشمسية، الألف الفارقة، والإدغام الكامل بغير غنة',
                          example:
                              'وَٱلَّذِينَ، قَالُواْ، أُوْلَٰئِكَ، مِن رَّبِّهِم',
                          color: TajweedPalette.sakinLight,
                        ),
                        (
                          name: 'علامات الوقف وضبط المصحف',
                          hakam: 'ذهبي / برونزي',
                          desc:
                              'م (لازم)، لا (ممنوع)، ج (جائز)، قلى (الوقف أولى)، صلى (الوصل أولى)، ۛ (تعانق)',
                          example: 'ۚ ، ۗ ، ۖ ، ۘ ، ۛ ، ۜ',
                          color: TajweedPalette.waqfLight,
                        ),
                      ].map((rule) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: rule.color.withAlpha(12),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: rule.color.withAlpha(40)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 2.h),
                                width: 22.r,
                                height: 22.r,
                                decoration: BoxDecoration(
                                  color: rule.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            rule.name,
                                            style: TextStyle(
                                              fontFamily: 'Almarai',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 1.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: rule.color.withAlpha(30),
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Text(
                                            rule.hakam,
                                            style: TextStyle(
                                              fontFamily: 'Almarai',
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                              color: rule.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      rule.desc,
                                      style: TextStyle(
                                        fontFamily: 'Almarai',
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'أمثلة: ${rule.example}',
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary.withAlpha(200),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final reciters = QuranService.instance.reciters;
            final reciterIndex =
                QuranService.instance.audioService.reciterIndex;
            final currentReciter =
                (reciterIndex >= 0 && reciterIndex < reciters.length)
                ? reciters[reciterIndex]
                : reciters.first;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            color: AppColors.primary,
                          ),
                          Text(
                            'إعدادات المصحف الشريف',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      SizedBox(height: 6.h),

                      // 1. Audio & Reciter Settings Section (تلاوة واستماع الصفحة)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(10),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(40),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: AppColors.primary,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'تلاوة واستماع القرآن الكريم',
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),

                            // Reciter Selector Tile
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _showReciterPicker();
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16.r,
                                      backgroundColor: AppColors.primary
                                          .withAlpha(25),
                                      child: Icon(
                                        Icons.record_voice_over_rounded,
                                        color: AppColors.primary,
                                        size: 16.r,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'القارئ الحالي',
                                            style: TextStyle(
                                              fontFamily: 'Almarai',
                                              fontSize: 10.sp,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            currentReciter.nameAr,
                                            style: TextStyle(
                                              fontFamily: 'Almarai',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5.sp,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(15),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Text(
                                        'تغيير القارئ',
                                        style: TextStyle(
                                          fontFamily: 'Almarai',
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 10.h),

                            // Listen to Current Page Action
                            ValueListenableBuilder<QuranAudioState>(
                              valueListenable:
                                  QuranService.instance.audioService.state,
                              builder: (context, audioState, _) {
                                final isThisPage =
                                    audioState.isActive &&
                                    QuranService.instance.getPageNumber(
                                          audioState.surah,
                                          audioState.ayah,
                                        ) ==
                                        _currentPage;
                                final isPlaying =
                                    isThisPage && audioState.isPlaying;

                                return ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPlaying
                                        ? Colors.amber.shade800
                                        : AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 9.h,
                                    ),
                                  ),
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.headphones_rounded,
                                    size: 18.r,
                                  ),
                                  label: Text(
                                    isPlaying
                                        ? 'إيقاف مؤقت لتلاوة الصفحة $_currentPage'
                                        : 'استماع للصفحة الحالية كاملة (صفحة $_currentPage)',
                                    style: TextStyle(
                                      fontFamily: 'Almarai',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _togglePageAudio();
                                  },
                                );
                              },
                            ),

                            SizedBox(height: 6.h),

                            // Auto-advance toggle
                            SwitchListTile(
                              title: Text(
                                'الانتقال التلقائي للصفحة التالية',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                              subtitle: Text(
                                'متابعة التلاوة تلقائياً عند انتهاء الصفحة الحالية',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 10.5.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              value: _autoAdvancePages,
                              activeThumbColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setSheetState(() => _autoAdvancePages = val);
                                setState(() => _autoAdvancePages = val);
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 14.h),

                      // 2. Tajweed Guide Card (only for editions with Tajweed colors)
                      if (TajweedPageCacheService
                          .instance
                          .currentEdition
                          .hasTajweedColors) ...[
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.amber.withAlpha(20)
                                : Colors.amber.shade50.withAlpha(120),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.amber.withAlpha(70)
                                  : Colors.amber.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.palette_outlined,
                                        color: isDark
                                            ? Colors.amber.shade300
                                            : Colors.amber.shade900,
                                        size: 20.r,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'دليل ألوان أحكام التجويد',
                                        style: TextStyle(
                                          fontFamily: 'Almarai',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.sp,
                                          color: isDark
                                              ? Colors.amber.shade200
                                              : Colors.brown.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showTajweedRulesDialog();
                                    },
                                    child: Text(
                                      'عرض الكل',
                                      style: TextStyle(
                                        fontFamily: 'Almarai',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.sp,
                                        color: isDark
                                            ? Colors.amber.shade300
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'دلالة ألوان مصحف التجويد الملون برواية حفص عن عاصم (دار المعرفة)',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 10.5.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildTajweedMiniDot(
                                    TajweedPalette.tafkheemLight,
                                    'تفخيم',
                                  ),
                                  _buildTajweedMiniDot(
                                    TajweedPalette.qalqalaLight,
                                    'قلقلة',
                                  ),
                                  _buildTajweedMiniDot(
                                    TajweedPalette.ghunnaLight,
                                    'غنة',
                                  ),
                                  _buildTajweedMiniDot(
                                    TajweedPalette.maddLazimLight,
                                    'مد لازم',
                                  ),
                                  _buildTajweedMiniDot(
                                    TajweedPalette.maddMuttasilLight,
                                    'مد متصل',
                                  ),
                                  _buildTajweedMiniDot(
                                    TajweedPalette.sakinLight,
                                    'لا يلفظ',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                      ],

                      // Theme Selection
                      Text(
                        'مظهر ورقة المصحف:',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          _buildThemeChip(
                            'مصحفي كريمي',
                            MushafThemeMode.parchment,
                            const Color(0xFFFAF7EE),
                            setSheetState,
                          ),
                          SizedBox(width: 8.w),
                          _buildThemeChip(
                            'أبيض ناصع',
                            MushafThemeMode.white,
                            Colors.white,
                            setSheetState,
                          ),
                          SizedBox(width: 8.w),
                          _buildThemeChip(
                            'ليلي داكن',
                            MushafThemeMode.dark,
                            const Color(0xFF181818),
                            setSheetState,
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      // Mushaf Editions Selection
                      _buildEditionSelector(setSheetState),

                      SizedBox(height: 14.h),

                      // Full Quran Offline Download Card
                      _buildFullDownloadCard(setSheetState),

                      SizedBox(height: 14.h),

                      // Offline Tafsir Downloads Card
                      _buildOfflineTafsirSettingsCard(setSheetState),

                      SizedBox(height: 14.h),

                      // Switch View Button (Card View)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        icon: const Icon(Icons.view_agenda_outlined),
                        label: const Text(
                          'التبديل إلى عرض بطاقات الآيات المنفصلة',
                          style: TextStyle(fontFamily: 'Almarai'),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          final pageData = QuranService.instance.getPageData(
                            _currentPage,
                          );
                          final surahNum = pageData.isNotEmpty
                              ? (pageData.first['surah'] ?? 1)
                              : 1;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurahReaderPage(
                                surahNumber: surahNum,
                                initialFontSize: widget.initialFontSize ?? 26.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTajweedMiniDot(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.r,
          height: 14.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(80),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeChip(
    String label,
    MushafThemeMode mode,
    Color color,
    StateSetter setSheetState,
  ) {
    final isSelected = _themeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setSheetState(() => _themeMode = mode);
          setState(() => _themeMode = mode);
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: mode == MushafThemeMode.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditionSelector(StateSetter setSheetState) {
    final currentEd = TajweedPageCacheService.instance.currentEdition;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طبعة المصحف الشريف:',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        ...MushafEdition.availableEditions.map((ed) {
          final isSelected = ed.id == currentEd.id;
          final isDownloaded = TajweedPageCacheService.instance
              .isEditionComplete(ed);
          final cachedCount = TajweedPageCacheService.instance
              .getCachedPagesCount(ed);

          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: InkWell(
              onTap: () async {
                await TajweedPageCacheService.instance.switchEdition(ed);
                setSheetState(() {});
                if (mounted) setState(() {});
              },
              borderRadius: BorderRadius.circular(12.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(isDark ? 40 : 18)
                      : (isDark ? AppColors.surface : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.border : Colors.grey.shade300),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade500,
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ed.name,
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 12.5.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isSelected
                                              ? AppColors.primary
                                              : Colors.grey)
                                          .withAlpha(20),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  ed.approximateSize,
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Text(
                                '${ed.riwayah} • ${ed.publisher}',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 10.5.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              if (isDownloaded)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 13.r,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'محمل بالكامل',
                                      style: TextStyle(
                                        fontFamily: 'Almarai',
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                )
                              else if (cachedCount > 0)
                                Text(
                                  '$cachedCount / 604 صفحة',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 10.sp,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFullDownloadCard(StateSetter setSheetState) {
    return ValueListenableBuilder<TajweedDownloadProgress>(
      valueListenable:
          TajweedPageCacheService.instance.downloadProgressNotifier,
      builder: (context, progress, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currentEdition = TajweedPageCacheService.instance.currentEdition;
        final isComplete =
            progress.isComplete ||
            progress.downloaded >= currentEdition.totalPages;
        final isDownloading = progress.isDownloading;

        return Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isComplete
                ? (isDark
                      ? Colors.green.withAlpha(25)
                      : const Color(0xFFE8F5E9))
                : (isDownloading
                      ? (isDark
                            ? Colors.blue.withAlpha(25)
                            : const Color(0xFFE3F2FD))
                      : (isDark ? AppColors.surface : Colors.grey.shade50)),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isComplete
                  ? (isDark
                        ? Colors.green.withAlpha(70)
                        : const Color(0xFF81C784))
                  : (isDownloading
                        ? (isDark
                              ? Colors.blue.withAlpha(70)
                              : const Color(0xFF64B5F6))
                        : (isDark ? AppColors.border : Colors.grey.shade300)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : (isDownloading
                              ? Icons.downloading_rounded
                              : Icons.cloud_download_rounded),
                    color: isComplete
                        ? (isDark
                              ? Colors.green.shade300
                              : const Color(0xFF2E7D32))
                        : (isDownloading
                              ? (isDark
                                    ? Colors.blue.shade300
                                    : const Color(0xFF1976D2))
                              : AppColors.primary),
                    size: 24.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'تحميل صفحات ${currentEdition.shortName}',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: isComplete
                                      ? (isDark
                                            ? Colors.green.shade300
                                            : const Color(0xFF1B5E20))
                                      : (isDownloading
                                            ? (isDark
                                                  ? Colors.blue.shade300
                                                  : const Color(0xFF0D47A1))
                                            : AppColors.textPrimary),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isComplete
                                            ? Colors.green
                                            : AppColors.primary)
                                        .withAlpha(25),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                currentEdition.approximateSize,
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isComplete
                                      ? Colors.green.shade800
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          isComplete
                              ? 'تم تحميل جميع الصفحات (604 صفحة • ${currentEdition.approximateSize}) • جاهز للقراءة أوفلاين'
                              : (isDownloading
                                    ? 'جارٍ التحميل في الخلفية: ${progress.downloaded} من 604 صفحة (${progress.percentInt}%)'
                                    : 'تم حفظ ${progress.downloaded} من 604 صفحة أوفلاين (${currentEdition.approximateSize})'),
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isDownloading) ...[
                SizedBox(height: 10.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: progress.percentage,
                    minHeight: 6.h,
                    backgroundColor: isDark ? AppColors.surface : Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1976D2),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text(
                      'إلغاء التحميل',
                      style: TextStyle(fontFamily: 'Almarai', fontSize: 11),
                    ),
                    onPressed: () {
                      TajweedPageCacheService.instance.cancelBatchDownload();
                      setSheetState(() {});
                    },
                  ),
                ),
              ] else if (!isComplete) ...[
                SizedBox(height: 10.h),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 10.w),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    'تحميل ${currentEdition.shortName} للقراءة بدون إنترنت (${currentEdition.approximateSize})',
                    style: const TextStyle(
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    TajweedPageCacheService.instance.startBatchDownload();
                    setSheetState(() {});
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showPageTafsir() {
    PageTafsirBottomSheet.show(context, pageNumber: _currentPage);
  }

  Widget _buildOfflineTafsirSettingsCard(StateSetter setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.withAlpha(20)
            : const Color(0xFFE8F5E9).withAlpha(140),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.green.withAlpha(60) : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                size: 22.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحميل التفاسير بدون إنترنت',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green.shade900,
                      ),
                    ),
                    Text(
                      'حمّل التفسير مرة واحدة ليعمل لجميع صفحات المصحف أوفلاين',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 10.5.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Offline packages: Al-Muyassar and Ibn Kathir
          ...TafsirService.offlinePackages.map((pkg) {
            final isDownloaded = TafsirService.instance.isOfflineDownloaded(
              pkg.id,
            );
            return ValueListenableBuilder<Map<String, TafsirDownloadProgress>>(
              valueListenable: TafsirService.instance.downloadProgressNotifier,
              builder: (context, progressMap, _) {
                final progress = progressMap[pkg.id];
                final isDownloading = progress?.isDownloading ?? false;

                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark ? AppColors.border : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDownloaded
                                ? Icons.check_circle_rounded
                                : Icons.cloud_download_outlined,
                            color: isDownloaded
                                ? (isDark
                                      ? Colors.green.shade300
                                      : Colors.green.shade700)
                                : AppColors.primary,
                            size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkg.name,
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${pkg.approximateSize} • ${isDownloaded ? "جاهز للاستخدام بدون نت" : pkg.author}',
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 10.sp,
                                    color: isDownloaded
                                        ? (isDark
                                              ? Colors.green.shade300
                                              : Colors.green.shade800)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isDownloading)
                            Text(
                              '${progress?.percentInt ?? 0}%',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          else if (isDownloaded)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: 'حذف التفسير لتوفير المساحة',
                              onPressed: () async {
                                await TafsirService.instance
                                    .deleteOfflineTafsir(pkg.id);
                                setSheetState(() {});
                                if (mounted) setState(() {});
                              },
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                              onPressed: () async {
                                setSheetState(() {});
                                await TafsirService.instance
                                    .downloadOfflineTafsir(pkg.id);
                                setSheetState(() {});
                                if (mounted) setState(() {});
                              },
                              child: const Text(
                                'تحميل',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 11,
                                ),
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
                            minHeight: 4.h,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahName = QuranService.instance.getPageSurahName(_currentPage);
    final juzName = QuranService.instance.getPageJuzName(_currentPage);
    final pageData = QuranService.instance.getPageData(_currentPage);
    final startEntry = pageData.firstWhere(
      (e) => (e['start'] ?? 0) == 1,
      orElse: () => {},
    );
    final isSurahStart = startEntry.isNotEmpty;
    final surahNumForInfo = isSurahStart
        ? (startEntry['surah'] ?? 1)
        : (pageData.isNotEmpty ? (pageData.first['surah'] ?? 1) : 1);
    final surahDataForInfo = QuranService.instance.getSurah(surahNumForInfo);
    final sPlace =
        surahDataForInfo?.revelationType ??
        QuranService.instance.getPlaceOfRevelationArabic(surahNumForInfo);
    final sCountAr = QuranService.toArabicDigits(
      surahDataForInfo?.totalAyahs ??
          QuranService.instance.getVerseCount(surahNumForInfo),
    );

    return Scaffold(
      backgroundColor: _themeMode == MushafThemeMode.dark
          ? const Color(0xFF121212)
          : const Color(0xFFFAF7EE),
      body: SafeArea(
        child: Stack(
          children: [
            // 604-page Madinah PageView (RTL Swiping matching paper Mushaf)
            Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                reverse:
                    false, // In RTL: flips forward matching physical Mushaf
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index + 1;
                    _selectedSurah = null;
                    _selectedAyah = null;
                    _selectedAyahText = null;
                  });
                  _updateLastRead(_currentPage);
                  _safePrefetch(_currentPage);
                },
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  return TajweedPageWidget(
                    key: ValueKey('tajweed_p$pageNum'),
                    pageNumber: pageNum,
                    onPageTapped: _onPageBackgroundTapped,
                    onBookmarkToggled: () => setState(() {}),
                    onSurahTap: _showJumpDialog,
                    onPageTap: _showJumpDialog,
                    onJuzTap: _showJumpDialog,
                  );
                },
              ),
            ),

            // Visual Bookmark Ribbon (فاصل المصحف المرجعي)
            if (QuranService.instance.isPageBookmarked(_currentPage))
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: _showOverlay ? 56.h : 0,
                right: 32.w,
                child: GestureDetector(
                  onTap: _toggleCurrentPageBookmark,
                  child: _buildBookmarkRibbon(),
                ),
              ),

            // Top Overlay Bar (Animated)
            if (_showOverlay)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.card.withAlpha(240),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _showJumpDialog,
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'سورة $surahName',
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                Text(
                                  textAlign: TextAlign.center,
                                  '$juzName • ${TajweedPageCacheService.getHizbText(_currentPage)} • صفحة $_currentPage من 604 • $sPlace • آياتها $sCountAr',
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          QuranService.instance.isPageBookmarked(_currentPage)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: QuranService.instance.isPageBookmarked(_currentPage)
                              ? Colors.amber.shade800
                              : AppColors.primary,
                        ),
                        tooltip: QuranService.instance.isPageBookmarked(_currentPage)
                            ? 'إزالة حفظ الصفحة'
                            : 'حفظ الصفحة كعلامة مرجعية',
                        onPressed: _toggleCurrentPageBookmark,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.palette_outlined,
                          color: AppColors.primary,
                        ),
                        tooltip: 'دليل ألوان التجويد',
                        onPressed: _showTajweedRulesDialog,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: AppColors.primary,
                        ),
                        tooltip: 'خيارات العرض',
                        onPressed: _showSettingsSheet,
                      ),
                    ],
                  ),
                ),
              ),

            // Floating active batch download notification
            ValueListenableBuilder<TajweedDownloadProgress>(
              valueListenable:
                  TajweedPageCacheService.instance.downloadProgressNotifier,
              builder: (context, progress, _) {
                if (!progress.isDownloading) return const SizedBox.shrink();
                return Positioned(
                  top: _showOverlay ? 60.h : 10.h,
                  left: 16.w,
                  right: 16.w,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12.r),
                      color: AppColors.primary,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'جارٍ تحميل ${TajweedPageCacheService.instance.currentEdition.shortName}... (${TajweedPageCacheService.instance.currentEdition.approximateSize})',
                                    style: TextStyle(
                                      fontFamily: 'Almarai',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'تم تحميل ${progress.downloaded} من 604 صفحة (${progress.percentInt}%)',
                                    style: TextStyle(
                                      fontFamily: 'Almarai',
                                      fontSize: 11.sp,
                                      color: Colors.white.withAlpha(220),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'إلغاء التحميل',
                              onPressed: () {
                                TajweedPageCacheService.instance
                                    .cancelBatchDownload();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Bottom Selected Ayah Action Bar
            if (_selectedSurah != null && _selectedAyah != null)
              Positioned(
                bottom: 12.h,
                left: 16.w,
                right: 16.w,
                child: _buildAyahActionBar(),
              )
            // Bottom Page Scrubber (when overlay is active and no ayah is selected)
            else if (_showOverlay)
              Positioned(
                bottom: 24.h,
                left: 16.w,
                right: 16.w,
                child: _buildPageScrubber(),
              ),

            // Floating Audio Player Bar (when audio recitation is active and no ayah is selected)
            if (_selectedSurah == null)
              ValueListenableBuilder<QuranAudioState>(
                valueListenable: QuranService.instance.audioService.state,
                builder: (context, audioState, _) {
                  if (!audioState.isActive) return const SizedBox.shrink();
                  return Positioned(
                    bottom: _showOverlay ? 116.h : 20.h,
                    left: 16.w,
                    right: 16.w,
                    child: _buildAudioPlayerBar(audioState),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Action bar shown when an Ayah is tapped: [التفسير, استماع, حفظ, نسخ]
  Widget _buildAyahActionBar() {
    final surahNum = _selectedSurah!;
    final ayahNum = _selectedAyah!;
    final surah = QuranService.instance.getSurah(surahNum);
    final surahName =
        surah?.arabicName ?? QuranService.instance.getSurahNameArabic(surahNum);
    final ayahText =
        _selectedAyahText ??
        QuranService.instance.getVerseUthmani(surahNum, ayahNum);
    final isBookmarked = QuranService.instance.isBookmarked(surahNum, ayahNum);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.border : Colors.black.withAlpha(15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ayah Title & Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedSurah = null;
                    _selectedAyah = null;
                    _selectedAyahText = null;
                  });
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'سورة $surahName • آية $ayahNum',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.touch_app_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Action Buttons: [التفسير, استماع, حفظ, نسخ]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Tafsir Button (Opens 10 Tafsir books)
              _buildActionButton(
                icon: Icons.menu_book_rounded,
                label: 'التفسير',
                color: AppColors.primary,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => TafsirBottomSheet(
                      surahNumber: surahNum,
                      ayahNumber: ayahNum,
                      surahName: surahName,
                      ayahText: ayahText,
                    ),
                  );
                },
              ),

              // 2. Audio Listen Button
              _buildActionButton(
                icon: Icons.volume_up_rounded,
                label: 'استماع',
                color: Colors.teal.shade700,
                onTap: () async {
                  final targetSurah = surahNum;
                  final targetAyah = ayahNum;
                  setState(() {
                    _selectedSurah = null;
                    _selectedAyah = null;
                    _selectedAyahText = null;
                  });
                  final canPlay = await _verifyAudioPlayable(targetSurah);
                  if (!canPlay) return;

                  try {
                    await QuranService.instance.audioService.playAyah(
                      targetSurah,
                      targetAyah,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'تعذر تشغيل التلاوة، يرجى التأكد من الاتصال بالإنترنت',
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),

              // 3. Bookmark Button
              _buildActionButton(
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: isBookmarked ? 'محفوظة' : 'حفظ علامة',
                color: isBookmarked
                    ? Colors.amber.shade800
                    : Colors.grey.shade700,
                onTap: () async {
                  await QuranService.instance.toggleBookmark(
                    surah: surahNum,
                    surahName: surahName,
                    ayah: ayahNum,
                    snippet: ayahText,
                    pageNumber: _currentPage,
                  );
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            isBookmarked
                                ? 'تمت إزالة العلامة المرجعية'
                                : 'تم حفظ العلامة المرجعية بنجاح',
                            style: const TextStyle(fontFamily: 'Almarai'),
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              // 4. Copy Button
              _buildActionButton(
                icon: Icons.copy_rounded,
                label: 'نسخ',
                color: Colors.blueGrey.shade700,
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: '﴿ $ayahText ﴾ [سورة $surahName: $ayahNum]',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'تم نسخ الآية الكريمة إلى الحافظة',
                          style: TextStyle(fontFamily: 'Almarai'),
                        ),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22.r),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fast page scrubber and quick audio actions when controls are visible
  Widget _buildPageScrubber() {
    final reciters = QuranService.instance.reciters;
    final reciterIndex = QuranService.instance.audioService.reciterIndex;
    final reciter = (reciterIndex >= 0 && reciterIndex < reciters.length)
        ? reciters[reciterIndex]
        : reciters.first;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.card.withAlpha(245),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row with Listen to Page Button + Current Reciter Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Listen to Page button
                    ValueListenableBuilder<QuranAudioState>(
                      valueListenable: QuranService.instance.audioService.state,
                      builder: (context, audioState, _) {
                        final isThisPage =
                            audioState.isActive &&
                            QuranService.instance.getPageNumber(
                                  audioState.surah,
                                  audioState.ayah,
                                ) ==
                                _currentPage;
                        final isPlaying = isThisPage && audioState.isPlaying;
      
                        return InkWell(
                          onTap: _togglePageAudio,
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: isPlaying
                                  ? Colors.amber.shade800
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.headphones_rounded,
                                  color: Colors.white,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  isPlaying ? 'إيقاف مؤقت' : 'استماع',
                                  style: TextStyle(
                                    fontFamily: 'Almarai',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 6.w),
      
                    // Page Tafsir button
                    InkWell(
                      onTap: _showPageTafsir,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.primary,
                              size: 14.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'تفسير الصفحة',
                              style: TextStyle(
                                fontFamily: 'Almarai',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      
                // Reciter Selector Button
                InkWell(
                  onTap: _showReciterPicker,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.record_voice_over_rounded,
                          size: 14.r,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          reciter.nameAr,
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16.r,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
      
            // Slider across 604 pages
            Row(
              children: [
                // Next Page Button
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                  tooltip: 'الصفحة التالية',
                  onPressed: _currentPage < 604
                      ? () => _jumpToPage(_currentPage + 1)
                      : null,
                ),
      
                // Slider across 604 pages (Page 1 on the Left, Page 604 on the Right)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Expanded(
                    child: Slider(
                      value: _currentPage.toDouble(),
                      min: 1.0,
                      max: 604.0,
                      divisions: 603,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withAlpha(80),
                      onChanged: (val) {
                        _jumpToPage(val.round());
                      },
                    ),
                  ),
                ),
      
                // Previous Page Button
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: 'الصفحة السابقة',
                  onPressed: _currentPage > 1
                      ? () => _jumpToPage(_currentPage - 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Floating Audio Player Bar when audio is active
  Widget _buildAudioPlayerBar(QuranAudioState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reciters = QuranService.instance.reciters;
    final reciter =
        (state.reciterIndex >= 0 && state.reciterIndex < reciters.length)
        ? reciters[state.reciterIndex]
        : reciters.first;
    final surahData = QuranService.instance.getSurah(state.surah);
    final surahName =
        surahData?.arabicName ??
        QuranService.instance.getSurahNameArabic(state.surah);
    final playingPage = QuranService.instance.getPageNumber(
      state.surah,
      state.ayah,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.primary.withAlpha(35),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info Row: Reciter & Current Ayah Info + Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                tooltip: 'إيقاف التلاوة',
                onPressed: () => QuranService.instance.audioService.stop(),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تلاوة صفحة $playingPage • سورة $surahName (آية ${state.ayah})',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      InkWell(
                        onTap: _showReciterPicker,
                        borderRadius: BorderRadius.circular(4.r),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.record_voice_over_rounded,
                              size: 12.r,
                              color: Colors.teal.shade700,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              reciter.nameAr,
                              style: TextStyle(
                                fontFamily: 'Almarai',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.teal.shade300
                                    : Colors.teal.shade800,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 14.r,
                              color: isDark
                                  ? Colors.teal.shade300
                                  : Colors.teal.shade800,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.person_pin_rounded,
                  color: AppColors.primary,
                  size: 20.r,
                ),
                tooltip: 'تغيير القارئ',
                onPressed: _showReciterPicker,
              ),
            ],
          ),

          // Buffering progress
          if (state.isLoading) ...[
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                minHeight: 2.5.h,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withAlpha(20),
              ),
            ),
          ],

          SizedBox(height: 6.h),

          // Controls Row: Next Ayah (Right in RTL), Play/Pause (Center), Prev Ayah (Left in RTL)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Next Ayah
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: AppColors.primary,
                  size: 26.r,
                ),
                tooltip: 'الآية التالية',
                onPressed: () async {
                  final canPlay = await _verifyAudioPlayable(state.surah);
                  if (!canPlay) return;
                  QuranService.instance.audioService.skipNext();
                },
              ),
              SizedBox(width: 14.w),

              // Play / Pause
              GestureDetector(
                onTap: () async {
                  if (!state.isPlaying) {
                    final canPlay = await _verifyAudioPlayable(state.surah);
                    if (!canPlay) return;
                  }
                  QuranService.instance.audioService.togglePlayPause();
                },
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(70),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24.r,
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // Previous Ayah
              IconButton(
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: AppColors.primary,
                  size: 26.r,
                ),
                tooltip: 'الآية السابقة',
                onPressed: () async {
                  final canPlay = await _verifyAudioPlayable(state.surah);
                  if (!canPlay) return;
                  QuranService.instance.audioService.skipPrevious();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
