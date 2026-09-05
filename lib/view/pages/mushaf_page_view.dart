import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/view/pages/surah_reader_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/view/widgets/mushaf_page_widget.dart';
import 'package:alhuda/view/widgets/tafsir_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_kit/audio.dart';
import 'package:quran_kit/core.dart';
import 'package:quran_kit/rendering.dart';

/// Full Madinah Mushaf Page View (604 pages)
class MushafPageView extends StatefulWidget {
  final int initialPage;
  final int? highlightedSurah;
  final int? highlightedAyah;

  const MushafPageView({
    super.key,
    this.initialPage = 1,
    this.highlightedSurah,
    this.highlightedAyah,
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
  bool _showTajweed = true;
  QpcV4AssetsStore? _store;
  MushafThemeMode _themeMode = MushafThemeMode.parchment;
  double _fontSize = 26.0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _selectedSurah = widget.highlightedSurah;
    _selectedAyah = widget.highlightedAyah;
    if (_selectedSurah != null && _selectedAyah != null) {
      _selectedAyahText = QuranService.instance.getVerseUthmani(_selectedSurah!, _selectedAyah!);
    }
    _pageController = PageController(initialPage: _currentPage - 1);
    _updateLastRead(_currentPage);

    // Initialize QPC v4 store and prefetch fonts for current page
    _store = QuranService.instance.qpcStore;
    if (_store == null) {
      QuranService.instance.ensureQpcStore().then((store) {
        if (mounted) setState(() => _store = store);
      });
    }
    FontDownloader.instance.prefetch(_currentPage, radius: 5);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    FontDownloader.instance.prefetch(clamped, radius: 5);
  }

  void _onAyahTapped(int surahNumber, int verseNumber, String verseText) {
    setState(() {
      _selectedSurah = surahNumber;
      _selectedAyah = verseNumber;
      _selectedAyahText = verseText;
      _showOverlay = true;
    });
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
          length: 3,
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
                  labelStyle: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 13.sp),
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'رقم الصفحة'),
                    Tab(text: 'فهرس السور'),
                    Tab(text: 'فهرس الأجزاء'),
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
                              style: TextStyle(fontFamily: 'Almarai', fontSize: 15.sp),
                            ),
                            SizedBox(height: 16.h),
                            TextField(
                              controller: pageInputController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'مثال: 77',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                              ),
                              onPressed: () {
                                final p = int.tryParse(pageInputController.text.trim());
                                if (p != null && p >= 1 && p <= 604) {
                                  Navigator.pop(context);
                                  _jumpToPage(p);
                                }
                              },
                              child: Text('انتقال للصفحة', style: TextStyle(fontFamily: 'Almarai', fontSize: 14.sp)),
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
                                border: Border.all(color: AppColors.primary.withAlpha(50)),
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
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: isMeccan ? const Color(0xFFFFF8E1) : const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(4.r),
                                    border: Border.all(
                                      color: isMeccan ? const Color(0xFFFFB300) : const Color(0xFF26A69A),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    s.revelationType,
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isMeccan ? const Color(0xFF8D6E63) : const Color(0xFF00695C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'آياتها ${QuranService.toArabicDigits(s.totalAyahs)} • ${s.englishName}',
                              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
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
                              child: Text('${j.number}', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text('الجزء ${j.number}', style: const TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
                            subtitle: Text('يبدأ من سورة ${j.startSurahName} (آية ${j.startAyahNumber})', style: TextStyle(fontSize: 11.sp)),
                            trailing: Text('صفحة ${j.startPage}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12.sp)),
                            onTap: () {
                              Navigator.pop(context);
                              _jumpToPage(j.startPage);
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
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined, color: AppColors.primary),
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
              SizedBox(height: 6.h),
              Text(
                'ألوان المصحف الشريف المعتمدة برواية حفص عن عاصم (مجمع الملك فهد):',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 10.h),
              ...tajweedRules.map((rule) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Row(
                    children: [
                      Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          color: Color(rule.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Color(rule.color).withAlpha(90),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          rule.arabicName,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                      Text(
                        rule.englishName,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.all(20.r),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'خيارات العرض والقراءة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.primary),
                    ),
                    SizedBox(height: 16.h),

                    // Theme Selection
                    Text('مظهر ورقة المصحف:', style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildThemeChip('مصحفي كريمي', MushafThemeMode.parchment, const Color(0xFFFAF7EE), setSheetState),
                        SizedBox(width: 8.w),
                        _buildThemeChip('أبيض ناصع', MushafThemeMode.white, Colors.white, setSheetState),
                        SizedBox(width: 8.w),
                        _buildThemeChip('ليلي داكن', MushafThemeMode.dark, const Color(0xFF181818), setSheetState),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    SizedBox(height: 16.h),

                    // Font Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('حجم الخط القرآني:', style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        Text('${_fontSize.toInt()}', style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: _fontSize.clamp(22.0, 32.0),
                      min: 22.0,
                      max: 32.0,
                      divisions: 10,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setSheetState(() => _fontSize = val);
                        setState(() => _fontSize = val);
                      },
                    ),

                    SizedBox(height: 10.h),

                    // Tajweed Color Toggle
                    SwitchListTile(
                      title: Text(
                        'ألوان أحكام التجويد (QFC4)',
                        style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                      subtitle: Text(
                        'تلوين المدود، الغنن، القلقلة، والتفخيم',
                        style: TextStyle(fontFamily: 'Almarai', fontSize: 11.sp, color: Colors.grey.shade600),
                      ),
                      value: _showTajweed,
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setSheetState(() => _showTajweed = val);
                        setState(() => _showTajweed = val);
                      },
                    ),

                    // Tajweed Color Guide Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.palette_outlined, size: 18),
                        label: const Text(
                          'عرض دليل ألوان أحكام التجويد',
                          style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showTajweedRulesDialog();
                        },
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Switch View Button (Card View)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      icon: const Icon(Icons.view_agenda_outlined),
                      label: const Text('التبديل إلى عرض بطاقات الآيات المنفصلة', style: TextStyle(fontFamily: 'Almarai')),
                      onPressed: () {
                        Navigator.pop(context);
                        final pageData = QuranService.instance.getPageData(_currentPage);
                        final surahNum = pageData.isNotEmpty ? (pageData.first['surah'] ?? 1) : 1;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurahReaderPage(surahNumber: surahNum),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeChip(String label, MushafThemeMode mode, Color color, StateSetter setSheetState) {
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
              color: mode == MushafThemeMode.dark ? Colors.white : Colors.black87,
            ),
          ),
        ),
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
    final sPlace = surahDataForInfo?.revelationType ??
        QuranService.instance.getPlaceOfRevelationArabic(surahNumForInfo);
    final sCountAr = QuranService.toArabicDigits(
      surahDataForInfo?.totalAyahs ?? QuranService.instance.getVerseCount(surahNumForInfo),
    );

    return Scaffold(
      backgroundColor: _themeMode == MushafThemeMode.dark ? const Color(0xFF121212) : const Color(0xFFFAF7EE),
      body: SafeArea(
        child: Stack(
          children: [
            // 604-page Madinah PageView (RTL Swiping)
            Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                reverse: true, // Right-to-Left swiping
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index + 1;
                    _selectedSurah = null;
                    _selectedAyah = null;
                    _selectedAyahText = null;
                  });
                  _updateLastRead(_currentPage);
                  FontDownloader.instance.prefetch(_currentPage, radius: 5);
                },
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  return MushafPageWidget(
                    pageNumber: pageNum,
                    store: _store,
                    showTajweed: _showTajweed,
                    selectedSurah: _selectedSurah,
                    selectedAyah: _selectedAyah,
                    fontSize: _fontSize,
                    themeMode: _themeMode,
                    onAyahTapped: _onAyahTapped,
                    onPageBackgroundTapped: _onPageBackgroundTapped,
                  );
                },
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
                    color: Colors.white.withAlpha(240),
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _showJumpDialog,
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'سورة $surahName',
                                      style: TextStyle(
                                        fontFamily: 'NotoNaskhArabic',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
                                  ],
                                ),
                                Text(
                                  '$juzName • صفحة $_currentPage من 604 • $sPlace • آياتها $sCountAr',
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
                        icon: const Icon(Icons.palette_outlined, color: AppColors.primary),
                        tooltip: 'دليل ألوان التجويد',
                        onPressed: _showTajweedRulesDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
                        tooltip: 'خيارات العرض',
                        onPressed: _showSettingsSheet,
                      ),
                    ],
                  ),
                ),
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
                bottom: 8.h,
                left: 16.w,
                right: 16.w,
                child: _buildPageScrubber(),
              ),

            // Audio Player Floating Bar (if active)
            Positioned(
              bottom: (_selectedSurah != null && _selectedAyah != null) ? 110.h : (_showOverlay ? 80.h : 12.h),
              left: 16.w,
              right: 16.w,
              child: _buildAudioPlayerBar(),
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
    final surahName = surah?.arabicName ?? QuranService.instance.getSurahNameArabic(surahNum);
    final ayahText = _selectedAyahText ?? QuranService.instance.getVerseUthmani(surahNum, ayahNum);
    final isBookmarked = QuranService.instance.isBookmarked(surahNum, ayahNum);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
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
                  const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 16),
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
                onTap: () {
                  QuranService.instance.audioService.playAyah(
                    surahNum,
                    ayahNum,
                  );
                },
              ),

              // 3. Bookmark Button
              _buildActionButton(
                icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: isBookmarked ? 'محفوظة' : 'حفظ علامة',
                color: isBookmarked ? Colors.amber.shade800 : Colors.grey.shade700,
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
                        content: Text(
                          isBookmarked ? 'تمت إزالة العلامة المرجعية' : 'تم حفظ العلامة المرجعية بنجاح',
                          style: const TextStyle(fontFamily: 'Almarai'),
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
                  Clipboard.setData(ClipboardData(
                    text: '﴿ $ayahText ﴾ [سورة $surahName: $ayahNum]',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ الآية الكريمة إلى الحافظة', style: TextStyle(fontFamily: 'Almarai')),
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

  /// Fast page scrubber when controls are visible
  Widget _buildPageScrubber() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(245),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Page Button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            tooltip: 'الصفحة السابقة',
            onPressed: _currentPage > 1 ? () => _jumpToPage(_currentPage - 1) : null,
          ),

          // Slider across 604 pages
          Expanded(
            child: Slider(
              value: _currentPage.toDouble(),
              min: 1.0,
              max: 604.0,
              divisions: 603,
              activeColor: AppColors.primary,
              onChanged: (val) {
                _jumpToPage(val.round());
              },
            ),
          ),

          // Next Page Button
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
            tooltip: 'الصفحة التالية',
            onPressed: _currentPage < 604 ? () => _jumpToPage(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  /// Floating mini Audio bar if recitation is currently playing
  Widget _buildAudioPlayerBar() {
    return ValueListenableBuilder<QuranAudioState>(
      valueListenable: QuranService.instance.audioService.state,
      builder: (context, state, _) {
        if (!state.isActive) {
          return const SizedBox.shrink();
        }

        final reciter = QuranService.instance.reciters[state.reciterIndex];

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () => QuranService.instance.audioService.stop(),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تلاوة الآية ${state.ayah} • ${reciter.nameAr}',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (state.isLoading)
                      LinearProgressIndicator(minHeight: 2.h, color: AppColors.primary),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, color: AppColors.primary, size: 20),
                onPressed: () => QuranService.instance.audioService.skipPrevious(),
              ),
              IconButton(
                icon: Icon(
                  state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppColors.primary,
                  size: 28.r,
                ),
                onPressed: () => QuranService.instance.audioService.togglePlayPause(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: AppColors.primary, size: 20),
                onPressed: () => QuranService.instance.audioService.skipNext(),
              ),
            ],
          ),
        );
      },
    );
  }
}
