import 'package:alhuda/services/quran_service.dart';
import 'package:alhuda/services/tafsir_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  group('QuranService Tests', () {
    setUpAll(() async {
      await QuranService.instance.init();
    });

    test('Loads exactly 114 surahs with complete metadata', () {
      final surahs = QuranService.instance.getAllSurahs();
      expect(surahs.length, 114);

      final fatiha = surahs.first;
      expect(fatiha.number, 1);
      expect(fatiha.arabicName, 'الفاتحة');
      expect(fatiha.totalAyahs, 7);
      expect(fatiha.revelationType, 'مكية');
      expect(fatiha.startPage, 1);

      final baqarah = surahs[1];
      expect(baqarah.number, 2);
      expect(baqarah.arabicName, 'البقرة');
      expect(baqarah.revelationType, 'مدنية');

      final nas = surahs.last;
      expect(nas.number, 114);
      expect(nas.arabicName, 'الناس');
      expect(nas.totalAyahs, 6);
      expect(nas.revelationType, 'مكية');
      expect(nas.startPage, 604);

      for (final s in surahs) {
        expect(s.revelationType == 'مكية' || s.revelationType == 'مدنية', isTrue);
      }
    });

    test('Returns correct ayahs in Uthmani script for Surah Al-Fatiha', () {
      final ayahs = QuranService.instance.getAyahsForSurah(1);
      expect(ayahs.length, 7);

      expect(ayahs[0].ayahNumber, 1);
      expect(ayahs[0].uthmaniText.isNotEmpty, isTrue);

      final lastAyah = ayahs.last;
      expect(lastAyah.ayahNumber, 7);
      expect(lastAyah.uthmaniText.isNotEmpty, isTrue);
    });

    test('Provides all 30 canonical Quran Juzs', () {
      final juzs = QuranService.instance.getAllJuzs();
      expect(juzs.length, 30);
      expect(juzs[0].number, 1);
      expect(juzs[0].startSurahName, 'الفاتحة');
      expect(juzs[29].number, 30);
      expect(juzs[29].startSurahName, 'النبأ');
    });

    test('Searches ayahs with Arabic diacritic normalization', () {
      final results = QuranService.instance.search('الحمد لله');
      expect(results.isNotEmpty, isTrue);

      final firstMatch = results.first;
      expect(firstMatch.surahNumber, 1);
      expect(firstMatch.ayahNumber, 2);
    });

    test('Bookmarks management works correctly', () async {
      await QuranService.instance.toggleBookmark(
        surah: 2,
        surahName: 'البقرة',
        ayah: 255,
        snippet: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
      );

      expect(QuranService.instance.isBookmarked(2, 255), isTrue);

      await QuranService.instance.removeBookmark(2, 255);
      expect(QuranService.instance.isBookmarked(2, 255), isFalse);
    });

    test('Page bookmarks management works correctly', () async {
      // Toggle bookmark for page 42
      final added = await QuranService.instance.togglePageBookmark(42);
      expect(added, isTrue);
      expect(QuranService.instance.isPageBookmarked(42), isTrue);

      final lastSaved = QuranService.instance.getLastSavedPageBookmark();
      expect(lastSaved, isNotNull);
      expect(lastSaved?.pageNumber, 42);

      // Remove page bookmark
      final removed = await QuranService.instance.togglePageBookmark(42);
      expect(removed, isFalse);
      expect(QuranService.instance.isPageBookmarked(42), isFalse);

      // Add again and test removeBookmarkByPage
      await QuranService.instance.togglePageBookmark(77);
      expect(QuranService.instance.isPageBookmarked(77), isTrue);
      await QuranService.instance.removeBookmarkByPage(77);
      expect(QuranService.instance.isPageBookmarked(77), isFalse);
    });

    test('Last read tracking updates correctly', () async {
      await QuranService.instance.setLastRead(
        surahNumber: 18,
        surahName: 'الكهف',
        ayahNumber: 1,
      );

      final lastRead = QuranService.instance.lastRead;
      expect(lastRead, isNotNull);
      expect(lastRead?.surahNumber, 18);
      expect(lastRead?.surahName, 'الكهف');
      expect(lastRead?.ayahNumber, 1);
    });
  });

  group('TafsirService Tests', () {
    test('Contains all 10 curated Tafsir sources including 9 Arabic exegeses', () {
      final tafsirs = TafsirService.availableTafsirs;
      expect(tafsirs.length, 10);

      final ids = tafsirs.map((t) => t.id).toList();
      expect(ids.contains('muyassar'), isTrue);
      expect(ids.contains('saadi'), isTrue);
      expect(ids.contains('ibn_kathir'), isTrue);
      expect(ids.contains('qurtubi'), isTrue);
      expect(ids.contains('tabari'), isTrue);
      expect(ids.contains('baghawi'), isTrue);
      expect(ids.contains('wasit'), isTrue);
      expect(ids.contains('jalalayn'), isTrue);
      expect(ids.contains('miqbas'), isTrue);
      expect(ids.contains('en_sahih'), isTrue);
    });

    test('Offline packages configure Al-Muyassar and Ibn Kathir with valid endpoints', () {
      final packages = TafsirService.offlinePackages;
      expect(packages.length, 2);

      final muyassar = packages.firstWhere((p) => p.id == 'muyassar');
      expect(muyassar.name, 'التفسير الميسر');
      expect(muyassar.cdnUrl.contains('muyassar.json'), isTrue);
      expect(muyassar.fallbackUrl.contains('muyassar.json'), isTrue);
      expect(muyassar.approximateSizeBytes, greaterThan(1000000));

      final ibnKathir = packages.firstWhere((p) => p.id == 'ibn_kathir');
      expect(ibnKathir.name, 'تفسير ابن كثير');
      expect(ibnKathir.cdnUrl.contains('katheer.json'), isTrue);
      expect(ibnKathir.fallbackUrl.contains('katheer.json'), isTrue);
      expect(ibnKathir.approximateSizeBytes, greaterThan(10000000));
    });

    test('TafsirDownloadProgress accurately calculates percentages and sizeText', () {
      const progress = TafsirDownloadProgress(
        tafsirId: 'muyassar',
        isDownloading: true,
        progress: 0.654,
        receivedBytes: 2000000,
        totalBytes: 3072000,
      );

      expect(progress.percentInt, 65);
      expect(progress.sizeText.contains('ميجابايت'), isTrue);
      expect(progress.isDownloading, isTrue);
    });

    test('Offline indexed Tafsir returns instant O(1) commentary for verses and pages', () async {
      final service = TafsirService.instance;
      service.setMockOfflineTafsir('muyassar', {
        '1:1': 'تفسير بسم الله الرحمن الرحيم الميسر أوفلاين',
        '1:2': 'تفسير الحمد لله رب العالمين الميسر أوفلاين',
        '1:3': 'تفسير الرحمن الرحيم الميسر أوفلاين',
        '1:4': 'تفسير مالك يوم الدين الميسر أوفلاين',
        '1:5': 'تفسير إياك نعبد وإياك نستعين الميسر أوفلاين',
        '1:6': 'تفسير اهدنا الصراط المستقيم الميسر أوفلاين',
        '1:7': 'تفسير صراط الذين أنعمت عليهم الميسر أوفلاين',
      });

      expect(service.isOfflineDownloaded('muyassar'), isTrue);

      final source = TafsirService.availableTafsirs.firstWhere((t) => t.id == 'muyassar');
      final singleAyah = await service.getTafsir(source: source, surah: 1, ayah: 1);
      expect(singleAyah, 'تفسير بسم الله الرحمن الرحيم الميسر أوفلاين');

      final page1Tafsir = await service.getPageTafsir(source: source, pageNumber: 1);
      expect(page1Tafsir.length, 7);
      expect(page1Tafsir.first.surahNumber, 1);
      expect(page1Tafsir.first.ayahNumber, 1);
      expect(page1Tafsir.first.tafsirText, 'تفسير بسم الله الرحمن الرحيم الميسر أوفلاين');
      expect(page1Tafsir.first.isOffline, isTrue);
      expect(page1Tafsir.last.ayahNumber, 7);
    });
  });
}
