import 'package:alhuda/features/quran/data/mushaf_edition.dart';
import 'package:alhuda/services/tajweed_page_cache_service.dart';
import 'package:alhuda/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MushafEdition Tests', () {
    test('Supported editions include Hafs Tajweed, Madinah Hafs, Madinah Warsh, and Madinah Shubah', () {
      expect(MushafEdition.availableEditions.length, 4);
      expect(MushafEdition.hafsTajweed.id, 'hafs_tajweed');
      expect(MushafEdition.madinahHafs.id, 'madinah_hafs');
      expect(MushafEdition.madinahWarsh.id, 'madinah_warsh');
      expect(MushafEdition.madinahShubah.id, 'madinah_shubah');
    });

    test('Each edition has accurate download size labels and metadata', () {
      expect(MushafEdition.hafsTajweed.approximateSize, '85 ميجابايت');
      expect(MushafEdition.madinahHafs.approximateSize, '180 ميجابايت');
      expect(MushafEdition.madinahWarsh.approximateSize, '180 ميجابايت');
      expect(MushafEdition.madinahShubah.approximateSize, '180 ميجابايت');
      expect(MushafEdition.hafsTajweed.approximateSizeMB, 85.0);
      expect(MushafEdition.madinahHafs.approximateSizeMB, 180.0);
      expect(MushafEdition.madinahShubah.approximateSizeMB, 180.0);
      expect(MushafEdition.hafsTajweed.totalPages, 604);
      expect(MushafEdition.madinahShubah.totalPages, 604);
      expect(MushafEdition.hafsTajweed.hasTajweedColors, isTrue);
      expect(MushafEdition.madinahHafs.hasTajweedColors, isFalse);
      expect(MushafEdition.madinahShubah.hasTajweedColors, isFalse);
      expect(MushafEdition.madinahShubah.riwayah, 'شعبة عن عاصم');
      expect(MushafEdition.madinahShubah.publisher, 'مجمع الملك فهد');
    });

    test('fromId retrieves edition or falls back to default', () {
      expect(MushafEdition.fromId('madinah_shubah'), MushafEdition.madinahShubah);
      expect(MushafEdition.fromId('madinah_warsh'), MushafEdition.madinahWarsh);
      expect(MushafEdition.fromId('madinah_hafs'), MushafEdition.madinahHafs);
      expect(MushafEdition.fromId('non_existent'), MushafEdition.hafsTajweed);
    });
  });

  group('AppSnackBar & RTL Tests', () {
    testWidgets('AppSnackBar wraps content with RTL Directionality', (tester) async {
      const testKey = Key('test_snack_text');
      final snackBar = AppSnackBar.create(
        content: const Text('رسالة تجريبية', key: testKey),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Find the Directionality wrapping the SnackBar content
      final directionalityWidgets = tester.widgetList<Directionality>(find.byType(Directionality));
      final rtlDirectionalities = directionalityWidgets.where((d) => d.textDirection == TextDirection.rtl);
      expect(rtlDirectionalities.isNotEmpty, isTrue);

      // Verify the text is inside
      expect(find.byKey(testKey), findsOneWidget);
    });
  });

  group('Hizb & Juz Detection Tests', () {
    test('Hizb start pages list has exactly 60 entries', () {
      expect(TajweedPageCacheService.kHizbStartPages.length, 60);
      expect(TajweedPageCacheService.kHizbStartPages[0], 1); // Hizb 1
      expect(TajweedPageCacheService.kHizbStartPages[1], 11); // Hizb 2 (page 11 in user screenshot)
      expect(TajweedPageCacheService.kHizbStartPages[2], 22); // Hizb 3
      expect(TajweedPageCacheService.kHizbStartPages[3], 32); // Hizb 4
    });

    test('getHizbStartingOnPage identifies Hizb start pages and rejects non-start pages', () {
      // Page 11 starts Hizb 2 (Al-Baqarah 75)
      expect(TajweedPageCacheService.getHizbStartingOnPage(11), 2);
      expect(TajweedPageCacheService.getHizbStartingOnPage(1), 1);
      expect(TajweedPageCacheService.getHizbStartingOnPage(22), 3);
      expect(TajweedPageCacheService.getHizbStartingOnPage(32), 4);

      // Pages 10 and 12 do not start any Hizb
      expect(TajweedPageCacheService.getHizbStartingOnPage(10), isNull);
      expect(TajweedPageCacheService.getHizbStartingOnPage(12), isNull);
      expect(TajweedPageCacheService.getHizbStartingOnPage(21), isNull);
    });

    test('getJuzForHizb calculates accurate Juz for any Hizb', () {
      // Hizb 1 and 2 are in Juz 1
      expect(TajweedPageCacheService.getJuzForHizb(1), 1);
      expect(TajweedPageCacheService.getJuzForHizb(2), 1);

      // Hizb 3 and 4 are in Juz 2
      expect(TajweedPageCacheService.getJuzForHizb(3), 2);
      expect(TajweedPageCacheService.getJuzForHizb(4), 2);

      // Hizb 59 and 60 are in Juz 30
      expect(TajweedPageCacheService.getJuzForHizb(59), 30);
      expect(TajweedPageCacheService.getJuzForHizb(60), 30);
    });

    test('getHizbForPage correctly resolves current Hizb on page 11', () {
      expect(TajweedPageCacheService.getHizbForPage(11), 2);
      expect(TajweedPageCacheService.getHizbText(11), 'الحزب 2');
    });
  });
}
