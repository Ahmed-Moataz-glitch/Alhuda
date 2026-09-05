import 'package:alhuda/services/tafsir_service.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Interactive bottom sheet presenting multiple Islamic Tafsirs for any Ayah
class TafsirBottomSheet extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;

  const TafsirBottomSheet({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
  });

  static void show(
    BuildContext context, {
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required String ayahText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TafsirBottomSheet(
        surahNumber: surahNumber,
        surahName: surahName,
        ayahNumber: ayahNumber,
        ayahText: ayahText,
      ),
    );
  }

  @override
  State<TafsirBottomSheet> createState() => _TafsirBottomSheetState();
}

class _TafsirBottomSheetState extends State<TafsirBottomSheet> {
  late TafsirSource _selectedSource;
  String _tafsirContent = '';
  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 17.sp;

  @override
  void initState() {
    super.initState();
    _selectedSource = TafsirService.availableTafsirs.first;
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await TafsirService.instance.getTafsir(
        source: _selectedSource,
        surah: widget.surahNumber,
        ayah: widget.ayahNumber,
      );
      if (mounted) {
        setState(() {
          _tafsirContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل التفسير حالياً، يرجى التحقق من الاتصال بالإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    final text = '﴿${widget.ayahText}﴾\n[${widget.surahName}: ${widget.ayahNumber}]\n\n'
        '■ ${_selectedSource.name} (${_selectedSource.author}):\n'
        '$_tafsirContent';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ الآية مع التفسير بنجاح',
          style: TextStyle(fontFamily: 'Almarai'),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = _selectedSource.language == 'ar';

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 22),
                      color: AppColors.primary,
                      tooltip: 'نسخ',
                      onPressed: _tafsirContent.isNotEmpty ? _copyToClipboard : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_increase_rounded, size: 22),
                      color: AppColors.primary,
                      tooltip: 'تكبير الخط',
                      onPressed: () {
                        setState(() {
                          if (_fontSize < 26.sp) _fontSize += 2.sp;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_decrease_rounded, size: 22),
                      color: AppColors.primary,
                      tooltip: 'تصغير الخط',
                      onPressed: () {
                        setState(() {
                          if (_fontSize > 13.sp) _fontSize -= 2.sp;
                        });
                      },
                    ),
                  ],
                ),
                Text(
                  '${widget.surahName}  •  الآية ${widget.ayahNumber}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Almarai',
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Ayah Preview Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary.withAlpha(50)),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                '﴿ ${widget.ayahText} ﴾',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: 'NotoNaskhArabic',
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2523),
                  height: 1.8,
                ),
              ),
            ),
          ),

          // Tafsir Switcher Chips
          SizedBox(
            height: 44.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              itemCount: TafsirService.availableTafsirs.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final source = TafsirService.availableTafsirs[index];
                final isSelected = source.id == _selectedSource.id;
                return ChoiceChip(
                  label: Text(
                    source.name,
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
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
                    if (selected && _selectedSource.id != source.id) {
                      setState(() {
                        _selectedSource = source;
                      });
                      _loadTafsir();
                    }
                  },
                );
              },
            ),
          ),

          // Author / Book Subtitle
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedSource.language == 'ar' ? 'اللغة: العربية' : 'اللغة: English',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                    fontFamily: 'Almarai',
                  ),
                ),
                Text(
                  _selectedSource.author,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withAlpha(200),
                    fontFamily: 'Almarai',
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tafsir Content Area
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
                          'جاري استرجاع ${_selectedSource.name}...',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                            fontFamily: 'Almarai',
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
                              SizedBox(height: 12.h),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'Almarai',
                                ),
                              ),
                              SizedBox(height: 14.h),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Almarai')),
                                onPressed: _loadTafsir,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Scrollbar(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                          child: Directionality(
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                            child: SelectableText(
                              _tafsirContent,
                              textAlign: isRtl ? TextAlign.justify : TextAlign.left,
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: 2.0,
                                color: const Color(0xFF222222),
                                fontFamily: isRtl ? 'NotoNaskhArabic' : null,
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
