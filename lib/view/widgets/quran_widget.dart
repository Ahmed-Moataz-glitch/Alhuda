import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/view/pages/mushaf_page_view.dart';
import 'package:alhuda/view/pages/quran_search_page.dart';
import 'package:alhuda/view/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Main Quran tab widget displayed inside HomePage
class QuranWidget extends StatefulWidget {
  const QuranWidget({super.key});

  @override
  State<QuranWidget> createState() => _QuranWidgetState();
}

class _QuranWidgetState extends State<QuranWidget> with SingleTickerProviderStateMixin {
  late TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSurahs = QuranService.instance.getAllSurahs();
    final allJuzs = QuranService.instance.getAllJuzs();
    final bookmarks = QuranService.instance.getBookmarks();
    final lastRead = QuranService.instance.lastRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
        SizedBox(height: 10.h),

        // Quick Search Bar & Last Read Banner
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              // Search Input Button
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuranSearchPage()),
                  ).then((_) => setState(() {}));
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: AppColors.primary),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'ابحث في آيات وسور المصحف الشريف...',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Almarai',
                            fontSize: 13.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Last Read Card
              _buildLastReadCard(lastRead),
            ],
          ),
        ),

        SizedBox(height: 10.h),

        // Inner Tab Bar (السور - الأجزاء - العلامات)
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: TabBar(
            controller: _innerTabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10.r),
            ),
            labelColor: AppColors.onPrimary,
            unselectedLabelColor: isDark ? AppColors.textSecondary : Colors.grey.shade700,
            labelStyle: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              const Tab(text: 'السور'),
              const Tab(text: 'الأجزاء'),
              Tab(text: 'العلامات (${bookmarks.length})'),
            ],
          ),
        ),

        SizedBox(height: 8.h),

        // Tab Bar Views
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            children: [
              // 1. Surah List Tab
              _buildSurahsTab(allSurahs),

              // 2. Juzs List Tab
              _buildJuzsTab(allJuzs),

              // 3. Bookmarks Tab
              _buildBookmarksTab(bookmarks),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLastReadCard(LastReadPosition? lastRead) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha(210),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            ),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(
              lastRead != null ? 'متابعة' : 'ابدأ الآن',
              style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 13.sp),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MushafPageView(
                    initialPage: lastRead?.pageNumber ?? 1,
                    highlightedSurah: lastRead?.surahNumber,
                    highlightedAyah: lastRead?.ayahNumber,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_added_rounded, color: Colors.amberAccent, size: 18),
                    SizedBox(width: 6.w),
                    Text(
                      'آخر قراءة',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12.sp,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  lastRead != null
                      ? 'سورة ${lastRead.surahName} (${QuranService.instance.getPlaceOfRevelationArabic(lastRead.surahNumber)}) • آية ${lastRead.ayahNumber} (ص ${lastRead.pageNumber})'
                      : 'سورة الفاتحة (مكية) • آية 1 (ص 1)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoNaskhArabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahsTab(List<SurahData> surahs) {
    if (surahs.isEmpty) {
      return Center(
        child: Text(
          'لا توجد سورة مطابقة للبحث',
          style: TextStyle(fontFamily: 'Almarai', color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final s = surahs[index];
        final isMeccan = s.revelationType == 'مكية';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey.withAlpha(30)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            leading: Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${s.number}',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: AppColors.primary,
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    'سورة ${s.arabicName}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                // Revelation place badge: مكية / مدنية
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isMeccan
                        ? (isDark ? const Color(0x33FFA000) : const Color(0xFFFFF8E1))
                        : (isDark ? const Color(0x3300897B) : const Color(0xFFE0F2F1)),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isMeccan
                          ? (isDark ? Colors.amber.shade700.withAlpha(120) : const Color(0xFFFFB300))
                          : (isDark ? Colors.teal.shade700.withAlpha(120) : const Color(0xFF26A69A)),
                      width: 0.9,
                    ),
                  ),
                  child: Text(
                    s.revelationType,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: isMeccan
                          ? (isDark ? Colors.amber.shade200 : const Color(0xFF8D6E63))
                          : (isDark ? Colors.teal.shade200 : const Color(0xFF00695C)),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                'آياتها ${QuranService.toArabicDigits(s.totalAyahs)} • ${s.englishName}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Almarai',
                ),
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isDark ? AppColors.border : Colors.grey.shade300,
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'صفحة',
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${s.startPage}',
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MushafPageView(initialPage: s.startPage),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        );
      },
    );
  }

  Widget _buildJuzsTab(List<JuzData> juzs) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      itemCount: juzs.length,
      itemBuilder: (context, index) {
        final juz = juzs[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey.withAlpha(30)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            leading: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Text(
                '${juz.number}',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              'الجزء ${juz.number}',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
                color: AppColors.primary,
              ),
            ),
            subtitle: Text(
              'يبدأ من سورة ${juz.startSurahName} (الآية ${juz.startAyahNumber})',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontFamily: 'Almarai'),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'ص ${juz.startPage}',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MushafPageView(
                    initialPage: juz.startPage,
                    highlightedSurah: juz.startSurahNumber,
                    highlightedAyah: juz.startAyahNumber,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        );
      },
    );
  }

  Widget _buildBookmarksTab(List<QuranBookmark> bookmarks) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 56.r, color: Colors.grey.shade400),
            SizedBox(height: 12.h),
            Text(
              'لا توجد علامات مرجعية محفوظة حتى الآن',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'أثناء قراءة السورة، اضغط على أيقونة الإشارة المرجعية لأي آية لحفظها هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 12.sp,
                color: AppColors.textSecondary.withAlpha(180),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey.withAlpha(30)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(12.r),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    await QuranService.instance.removeBookmark(b.surahNumber, b.ayahNumber);
                    setState(() {});
                  },
                ),
                Text(
                  'سورة ${b.surahName} • آية ${b.ayahNumber}',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            subtitle: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                b.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MushafPageView(
                    initialPage: b.pageNumber,
                    highlightedSurah: b.surahNumber,
                    highlightedAyah: b.ayahNumber,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        );
      },
    );
  }
}
