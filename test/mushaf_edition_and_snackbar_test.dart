import 'package:alhuda/model/mushaf_edition.dart';
import 'package:alhuda/view/widgets/app_snackbar.dart';
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
}
