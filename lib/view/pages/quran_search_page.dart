import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/view/pages/mushaf_page_view.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:alhuda/view/widgets/tafsir_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<QuranSearchResult> _results = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    final list = QuranService.instance.search(query);
    setState(() {
      _results = list;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'البحث في القرآن الكريم',
          style: TextStyle(
            fontSize: 20.sp,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Almarai',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: TextStyle(fontFamily: 'NotoNaskhArabic', color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ابحث عن كلمة، آية، أو جملة...',
                  hintStyle: TextStyle(
                    fontFamily: 'Almarai',
                    color: Colors.grey.shade500,
                    fontSize: 14.sp,
                  ),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: _onSearch,
              ),
            ),
          ),

          // Result Count Banner
          if (_hasSearched)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نتائج البحث: ${_results.length} آية',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (_results.length >= 100)
                    Text(
                      '(أول 100 نتيجة)',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

          // Results List / Empty State
          Expanded(
            child: !_hasSearched
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 64.r,
                            color: AppColors.primary.withAlpha(80),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'اكتب كلمة أو جزءاً من آية للبحث السريع في كامل آيات وسور المصحف الشريف.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 56.r, color: Colors.grey.shade400),
                              SizedBox(height: 14.h),
                              Text(
                                'لم يتم العثور على نتائج مطابقة',
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'تأكد من كتابة الكلمات بشكل صحيح دون همزات إضافية.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Almarai',
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                          ),
                                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                                          label: const Text('التفسير', style: TextStyle(fontFamily: 'Almarai')),
                                          onPressed: () {
                                            TafsirBottomSheet.show(
                                              context,
                                              surahNumber: item.surahNumber,
                                              surahName: item.surahName,
                                              ayahNumber: item.ayahNumber,
                                              ayahText: item.uthmaniText,
                                            );
                                          },
                                        ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.primary,
                                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                            ),
                                            icon: const Icon(Icons.menu_book_rounded, size: 16),
                                            label: const Text('المصحف', style: TextStyle(fontFamily: 'Almarai')),
                                            onPressed: () {
                                              final page = QuranService.instance.getPageNumber(item.surahNumber, item.ayahNumber);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MushafPageView(
                                                    initialPage: page,
                                                    highlightedSurah: item.surahNumber,
                                                    highlightedAyah: item.ayahNumber,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        'سورة ${item.surahName} • آية ${item.ayahNumber}',
                                        style: TextStyle(
                                          fontFamily: 'Almarai',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    item.uthmaniText,
                                    style: TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 16.sp,
                                      height: 1.9,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
