import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/theme_service.dart';
import 'package:alhuda/view/pages/mushaf_page_view.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/view/widgets/tafsir_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_kit/audio.dart';

class SurahReaderPage extends StatefulWidget {
  final int surahNumber;
  final int? initialAyahNumber;
  final double? initialFontSize;

  const SurahReaderPage({
    super.key,
    required this.surahNumber,
    this.initialAyahNumber,
    this.initialFontSize,
  });

  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  late int _currentSurah;
  late List<AyahData> _ayahs;
  final ScrollController _scrollController = ScrollController();
  late double _fontSize;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.surahNumber;
    _fontSize = (widget.initialFontSize ?? 26.0).sp;
    _loadSurahData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSurahData() {
    final surah = QuranService.instance.getSurah(_currentSurah);
    _ayahs = QuranService.instance.getAyahsForSurah(_currentSurah);

    if (surah != null) {
      QuranService.instance.setLastRead(
        surahNumber: _currentSurah,
        surahName: surah.arabicName,
        ayahNumber: widget.initialAyahNumber ?? 1,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (widget.initialAyahNumber != null && widget.initialAyahNumber! > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAyah(widget.initialAyahNumber!);
      });
    }
  }

  void _scrollToAyah(int ayahNum) {
    if (!_scrollController.hasClients) return;
    // Estimated average item height ~ 130
    final targetOffset = (ayahNum - 1) * 130.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _changeSurah(int newSurah) {
    if (newSurah < 1 || newSurah > 114) return;
    setState(() {
      _currentSurah = newSurah;
      _isLoading = true;
    });
    _loadSurahData();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10.w),
                const Expanded(
                  child: Text(
                    'يتطلب الاستماع لتلاوة القارئ اتصالاً بالإنترنت',
                    style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.brown.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  void _showReciterPicker() {
    final reciters = QuranService.instance.reciters;
    final currentReciterIndex = QuranService.instance.audioService.reciterIndex;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر القارئ المفضل',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Almarai',
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = reciters[index];
                    final isSelected = index == currentReciterIndex;
                    return ListTile(
                      title: Text(
                        reciter.nameAr,
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        reciter.nameEn,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppColors.primary)
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
        );
      },
    );
  }

  void _showSurahJumpDialog() {
    final surahs = QuranService.instance.getAllSurahs();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  'انتقل إلى سورة أخرى',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Almarai',
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final s = surahs[index];
                    final isSelected = s.number == _currentSurah;
                    return ListTile(
                      leading: Container(
                        width: 34.r,
                        height: 34.r,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${s.number}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      title: Text(
                        'سورة ${s.arabicName}',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15.sp,
                        ),
                      ),
                      subtitle: Text(
                        '${s.revelationType} • ${s.totalAyahs} آية • صفحة ${s.startPage}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _changeSurah(s.number);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surah = QuranService.instance.getSurah(_currentSurah);
    final surahName = surah?.arabicName ?? 'سورة $_currentSurah';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: InkWell(
          onTap: _showSurahJumpDialog,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20.r),
                SizedBox(width: 4.w),
                Text(
                  'سورة $surahName',
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            color: AppColors.primary,
            tooltip: 'عرض صفحات المصحف الشريف',
            onPressed: () {
              final surah = QuranService.instance.getSurah(_currentSurah);
              final page = surah?.startPage ?? 1;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MushafPageView(
                    initialPage: page,
                    initialFontSize: _fontSize / 1.sp,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over_outlined),
            color: AppColors.primary,
            tooltip: 'تغيير القارئ',
            onPressed: _showReciterPicker,
          ),
          PopupMenuButton<double>(
            icon: Icon(Icons.format_size_rounded, color: AppColors.primary),
            tooltip: 'حجم الخط',
            onSelected: (size) {
              setState(() {
                _fontSize = size.sp;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 18, child: Text('خط صغير (18)')),
              const PopupMenuItem(value: 22, child: Text('خط عادي (22)')),
              const PopupMenuItem(value: 26, child: Text('خط قياسي (26)')),
              const PopupMenuItem(value: 30, child: Text('خط كبير (30)')),
              const PopupMenuItem(value: 34, child: Text('خط كبير جداً (34)')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
                    itemCount: _ayahs.length + 1, // 0 is Header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSurahHeader(surah);
                      }
                      final ayah = _ayahs[index - 1];
                      return _buildAyahCard(ayah, surahName);
                    },
                  ),
                ),

                // Audio Player Bottom Sheet (Active Recitation)
                _buildAudioPlayerBar(),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSurahHeader(SurahData? surah) {
    if (surah == null) return const SizedBox.shrink();
    final bool showBasmalah = _currentSurah != 1 && _currentSurah != 9;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صفحة ${surah.startPage}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontFamily: 'Almarai',
                ),
              ),
              Text(
                'سورة ${surah.arabicName}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              Text(
                '${surah.revelationType} • ${surah.totalAyahs} آية',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontFamily: 'Almarai',
                ),
              ),
            ],
          ),
          if (showBasmalah) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAyahCard(AyahData ayah, String surahName) {
    final isBookmarked = QuranService.instance.isBookmarked(_currentSurah, ayah.ayahNumber);

    return ValueListenableBuilder<QuranAudioState>(
      valueListenable: QuranService.instance.audioService.state,
      builder: (context, audioState, _) {
        final isPlayingThisAyah = audioState.isActive &&
            audioState.surah == _currentSurah &&
            audioState.ayah == ayah.ayahNumber;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: isPlayingThisAyah
                ? (ThemeService.instance.isDarkMode
                    ? const Color(0xFF382F26)
                    : const Color(0xFFF3EDE2))
                : AppColors.card,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isPlayingThisAyah
                  ? AppColors.primary
                  : Colors.grey.withAlpha(30),
              width: isPlayingThisAyah ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ayah Number Badge
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${ayah.ayahNumber}',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // Actions
                  Row(
                    children: [
                      // Play Audio
                      IconButton(
                        icon: Icon(
                          isPlayingThisAyah
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 24.r,
                          color: AppColors.primary,
                        ),
                        tooltip: 'استماع للآية',
                        onPressed: () async {
                          if (isPlayingThisAyah) {
                            QuranService.instance.audioService.togglePlayPause();
                          } else {
                            final canPlay = await _verifyAudioPlayable(_currentSurah);
                            if (!canPlay) return;
                            QuranService.instance.audioService.playAyah(
                              _currentSurah,
                              ayah.ayahNumber,
                            );
                          }
                        },
                      ),

                      // Tafsir Button
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary.withAlpha(15),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 16),
                        label: Text(
                          'التفسير',
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          TafsirBottomSheet.show(
                            context,
                            surahNumber: _currentSurah,
                            surahName: surahName,
                            ayahNumber: ayah.ayahNumber,
                            ayahText: ayah.uthmaniText,
                          );
                        },
                      ),

                      // Bookmark
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 22.r,
                          color: isBookmarked ? Colors.amber.shade800 : Colors.grey.shade600,
                        ),
                        tooltip: isBookmarked ? 'إزالة العلامة' : 'حفظ كعلامة',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await QuranService.instance.toggleBookmark(
                            surah: _currentSurah,
                            surahName: surahName,
                            ayah: ayah.ayahNumber,
                            snippet: ayah.uthmaniText,
                          );
                          if (!mounted) return;
                          setState(() {});
                          messenger.showSnackBar(
                            SnackBar(
                              content: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  isBookmarked ? 'تمت إزالة العلامة المرجعية' : 'تم حفظ العلامة المرجعية بنجاح',
                                  style: const TextStyle(fontFamily: 'Almarai'),
                                ),
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),

                      // Copy
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 18.r, color: Colors.grey.shade600),
                        tooltip: 'نسخ الآية',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: '﴿${ayah.uthmaniText}﴾ [$surahName: ${ayah.ayahNumber}]',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text('تم نسخ نص الآية', style: TextStyle(fontFamily: 'Almarai')),
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // Ayah Uthmani Text
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  ayah.uthmaniText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: _fontSize,
                    height: 2.0,
                    wordSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioPlayerBar() {
    return ValueListenableBuilder<QuranAudioState>(
      valueListenable: QuranService.instance.audioService.state,
      builder: (context, state, _) {
        if (!state.isActive) return const SizedBox.shrink();

        final reciter = QuranService.instance.reciters[state.reciterIndex];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
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
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (state.isLoading)
                      LinearProgressIndicator(
                        minHeight: 2.h,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.skip_previous_rounded, color: AppColors.primary),
                onPressed: () async {
                  final canPlay = await _verifyAudioPlayable(state.surah);
                  if (!canPlay) return;
                  QuranService.instance.audioService.skipPrevious();
                },
              ),
              IconButton(
                icon: Icon(
                  state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppColors.primary,
                  size: 32.r,
                ),
                onPressed: () async {
                  if (!state.isPlaying) {
                    final canPlay = await _verifyAudioPlayable(state.surah);
                    if (!canPlay) return;
                  }
                  QuranService.instance.audioService.togglePlayPause();
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next_rounded, color: AppColors.primary),
                onPressed: () async {
                  final canPlay = await _verifyAudioPlayable(state.surah);
                  if (!canPlay) return;
                  QuranService.instance.audioService.skipNext();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: AppColors.card,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentSurah > 1 ? () => _changeSurah(_currentSurah - 1) : null,
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
            label: const Text('السورة السابقة', style: TextStyle(fontFamily: 'Almarai')),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          Text(
            '$_currentSurah / 114',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              fontFamily: 'Almarai',
            ),
          ),
          TextButton.icon(
            onPressed: _currentSurah < 114 ? () => _changeSurah(_currentSurah + 1) : null,
            icon: const Text('السورة التالية', style: TextStyle(fontFamily: 'Almarai')),
            label: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
