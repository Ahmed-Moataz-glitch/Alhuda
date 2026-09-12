import 'dart:convert';
import 'dart:io';
import 'package:alhuda/features/quran/domain/entities/tafsir_entities.dart';
import 'package:alhuda/services/quran_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
export 'package:alhuda/features/quran/domain/entities/tafsir_entities.dart';
export 'package:alhuda/features/quran/domain/repositories/tafsir_repository.dart';
export 'package:alhuda/features/quran/data/repositories/tafsir_repository_impl.dart';

/// Progress and state of an offline Tafsir package download
class TafsirDownloadProgress {
  final String tafsirId;
  final bool isDownloading;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final String? error;

  const TafsirDownloadProgress({
    required this.tafsirId,
    this.isDownloading = false,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  String get sizeText {
    if (totalBytes <= 0) return '';
    final mb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$recMb / $mb ميجابايت';
  }

  int get percentInt => (progress * 100).clamp(0, 100).round();
}

/// Metadata configuration for bulk downloadable offline Tafsir packages
class OfflineTafsirPackage {
  final String id;
  final String name;
  final String author;
  final String approximateSize;
  final int approximateSizeBytes;
  final String cdnUrl;
  final String fallbackUrl;

  const OfflineTafsirPackage({
    required this.id,
    required this.name,
    required this.author,
    required this.approximateSize,
    required this.approximateSizeBytes,
    required this.cdnUrl,
    required this.fallbackUrl,
  });
}

/// Represents an Ayah and its Tafsir on a Quran page
class AyahPageTafsir {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final String tafsirText;
  final bool isOffline;

  const AyahPageTafsir({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.tafsirText,
    this.isOffline = false,
  });
}

/// Comprehensive service for fetching, caching, and offline-storing Quran Tafsirs
class TafsirService {
  TafsirService._();
  static final TafsirService instance = TafsirService._();

  static const List<OfflineTafsirPackage> offlinePackages = [
    OfflineTafsirPackage(
      id: 'muyassar',
      name: 'التفسير الميسر',
      author: 'مجمع الملك فهد لطباعة المصحف الشريف',
      approximateSize: '2.9 ميجابايت',
      approximateSizeBytes: 3072000,
      cdnUrl: 'https://cdn.jsdelivr.net/gh/abdalrhmanreda/islamic-data-assets@main/tafser/muyassar.json',
      fallbackUrl: 'https://raw.githubusercontent.com/abdalrhmanreda/islamic-data-assets/main/tafser/muyassar.json',
    ),
    OfflineTafsirPackage(
      id: 'ibn_kathir',
      name: 'تفسير ابن كثير',
      author: 'الحافظ إسماعيل بن كثير الدمشقي',
      approximateSize: '15.9 ميجابايت',
      approximateSizeBytes: 16662000,
      cdnUrl: 'https://cdn.jsdelivr.net/gh/abdalrhmanreda/islamic-data-assets@main/tafser/katheer.json',
      fallbackUrl: 'https://raw.githubusercontent.com/abdalrhmanreda/islamic-data-assets/main/tafser/katheer.json',
    ),
  ];

  static OfflineTafsirPackage? getOfflinePackage(String id) {
    try {
      return offlinePackages.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static bool hasOfflinePackage(String id) =>
      offlinePackages.any((p) => p.id == id);

  static const List<TafsirSource> availableTafsirs = [
    TafsirSource(
      id: 'muyassar',
      key: '16',
      name: 'التفسير الميسر',
      author: 'مجمع الملك فهد لطباعة المصحف',
      apiType: 'qurancdn',
    ),
    TafsirSource(
      id: 'saadi',
      key: '91',
      name: 'تفسير السعدي',
      author: 'الشيخ عبد الرحمن بن ناصر السعدي',
      apiType: 'qurancdn',
    ),
    TafsirSource(
      id: 'ibn_kathir',
      key: '14',
      name: 'تفسير ابن كثير',
      author: 'الحافظ إسماعيل بن كثير الدمشقي',
      apiType: 'qurancdn',
    ),
    TafsirSource(
      id: 'qurtubi',
      key: '90',
      name: 'تفسير القرطبي',
      author: 'الإمام محمد بن أحمد القرطبي',
      apiType: 'qurancdn',
    ),
    TafsirSource(
      id: 'tabari',
      key: '15',
      name: 'تفسير الطبري',
      author: 'الإمام محمد بن جرير الطبري',
      apiType: 'qurancdn',
    ),
    TafsirSource(
      id: 'baghawi',
      key: '94',
      name: 'تفسير البغوي',
      author: 'الإمام الحسين بن مسعود البغوي',
      apiType: 'qurancdn',
    ),
    TafsirSource(
      id: 'wasit',
      key: '93',
      name: 'التفسير الوسيط',
      author: 'د. محمد سيد طنطاوي',
      apiType: 'qurancdn',
    ),
    TafsirSource(
      id: 'jalalayn',
      key: 'ar.jalalayn',
      name: 'تفسير الجلالين',
      author: 'جلال الدين المحلي والسيوطي',
      apiType: 'alquran_cloud',
    ),
    TafsirSource(
      id: 'miqbas',
      key: 'ar.miqbas',
      name: 'تنوير المقباس',
      author: 'ابن عباس رضي الله عنهما',
      apiType: 'alquran_cloud',
    ),
    TafsirSource(
      id: 'en_sahih',
      key: 'en.sahih',
      name: 'Sahih International',
      author: 'Sahih International (English)',
      language: 'en',
      apiType: 'alquran_cloud',
    ),
  ];

  final Map<String, String> _memoryCache = {};
  final Map<String, Map<String, String>> _offlineTafsirStore = {};
  final Set<String> _activeDownloads = {};
  Directory? _cacheDir;
  Directory? _offlineDir;
  bool _isInit = false;

  final ValueNotifier<Map<String, TafsirDownloadProgress>> downloadProgressNotifier =
      ValueNotifier<Map<String, TafsirDownloadProgress>>({});

  Future<void> init() async {
    if (_isInit) return;
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDoc.path}/alhuda_tafsir_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      _offlineDir = Directory('${appDoc.path}/alhuda_tafsir_offline');
      if (!await _offlineDir!.exists()) {
        await _offlineDir!.create(recursive: true);
      }
      _isInit = true;
    } catch (e) {
      debugPrint('TafsirService initialization warning: $e');
    }
  }

  /// Check if an offline Tafsir package is downloaded and ready for use
  bool isOfflineDownloaded(String tafsirId) {
    if (_offlineTafsirStore.containsKey(tafsirId) &&
        _offlineTafsirStore[tafsirId]!.isNotEmpty) {
      return true;
    }
    if (_offlineDir != null) {
      final file = File('${_offlineDir!.path}/$tafsirId.json');
      if (file.existsSync() && file.lengthSync() > 1000) {
        return true;
      }
    }
    return false;
  }

  /// Ensure offline JSON dataset is parsed into the in-memory lookup map
  Future<bool> ensureOfflineLoaded(String tafsirId) async {
    if (_offlineTafsirStore.containsKey(tafsirId) &&
        _offlineTafsirStore[tafsirId]!.isNotEmpty) {
      return true;
    }
    await init();
    if (_offlineDir == null) return false;
    final file = File('${_offlineDir!.path}/$tafsirId.json');
    if (!await file.exists() || await file.length() < 1000) return false;

    try {
      final content = await file.readAsString();
      Map<String, String> map;
      if (kIsWeb) {
        map = _parseTafsirJson(content);
      } else {
        map = await compute(_parseTafsirJson, content);
      }
      if (map.isNotEmpty) {
        _offlineTafsirStore[tafsirId] = map;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to load offline tafsir $tafsirId: $e');
      return false;
    }
  }

  static Map<String, String> _parseTafsirJson(String jsonString) {
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      final map = <String, String>{};
      for (final raw in list) {
        if (raw is Map) {
          final sura = raw['sura'] ?? raw['surah'] ?? raw['sura_number'] ?? raw['surah_number'];
          final aya = raw['aya'] ?? raw['ayah'] ?? raw['aya_number'] ?? raw['ayah_number'];
          final text = raw['text'] ?? raw['tafseer'] ?? raw['tafsir'];
          if (sura != null && aya != null && text != null) {
            map['$sura:$aya'] = text.toString().trim();
          }
        }
      }
      return map;
    } catch (e) {
      debugPrint('Error parsing tafsir json: $e');
      return {};
    }
  }

  /// Download a full offline Tafsir dataset with streaming progress tracking
  Future<bool> downloadOfflineTafsir(
    String tafsirId, {
    void Function(double progress)? onProgress,
  }) async {
    final pkg = getOfflinePackage(tafsirId);
    if (pkg == null) return false;

    if (_activeDownloads.contains(tafsirId)) return false;
    _activeDownloads.add(tafsirId);

    await init();
    final targetDir = _offlineDir;
    if (targetDir == null) {
      _activeDownloads.remove(tafsirId);
      return false;
    }

    final tempFile = File('${targetDir.path}/$tafsirId.json.tmp');
    final finalFile = File('${targetDir.path}/$tafsirId.json');

    _updateProgress(TafsirDownloadProgress(
      tafsirId: tafsirId,
      isDownloading: true,
      progress: 0.0,
      totalBytes: pkg.approximateSizeBytes,
    ));

    http.Client? client;
    try {
      client = http.Client();
      final urls = [pkg.cdnUrl, pkg.fallbackUrl];
      http.StreamedResponse? response;

      for (final url in urls) {
        try {
          final request = http.Request('GET', Uri.parse(url));
          final res = await client.send(request).timeout(const Duration(seconds: 25));
          if (res.statusCode == 200) {
            response = res;
            break;
          }
        } catch (e) {
          debugPrint('Failed to connect to tafsir url $url: $e');
        }
      }

      if (response == null) {
        throw Exception('تعذر الاتصال بخوادم تحميل التفسير');
      }

      final totalBytes = (response.contentLength != null && response.contentLength! > 0)
          ? response.contentLength!
          : pkg.approximateSizeBytes;
      int receivedBytes = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

        _updateProgress(TafsirDownloadProgress(
          tafsirId: tafsirId,
          isDownloading: true,
          progress: progress,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        ));
        onProgress?.call(progress);
      }

      await sink.flush();
      await sink.close();

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);

      // Parse and load into offline store
      await ensureOfflineLoaded(tafsirId);

      _updateProgress(TafsirDownloadProgress(
        tafsirId: tafsirId,
        isDownloading: false,
        progress: 1.0,
        receivedBytes: totalBytes,
        totalBytes: totalBytes,
      ));
      return true;
    } catch (e) {
      debugPrint('Tafsir download error ($tafsirId): $e');
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      _updateProgress(TafsirDownloadProgress(
        tafsirId: tafsirId,
        isDownloading: false,
        progress: 0.0,
        error: e.toString(),
      ));
      return false;
    } finally {
      client?.close();
      _activeDownloads.remove(tafsirId);
    }
  }

  /// Delete an offline Tafsir file from local storage
  Future<void> deleteOfflineTafsir(String tafsirId) async {
    await init();
    if (_offlineDir != null) {
      final file = File('${_offlineDir!.path}/$tafsirId.json');
      if (await file.exists()) {
        await file.delete();
      }
    }
    _offlineTafsirStore.remove(tafsirId);
    final updated = Map<String, TafsirDownloadProgress>.from(downloadProgressNotifier.value);
    updated.remove(tafsirId);
    downloadProgressNotifier.value = updated;
  }

  void _updateProgress(TafsirDownloadProgress progress) {
    final updated = Map<String, TafsirDownloadProgress>.from(downloadProgressNotifier.value);
    updated[progress.tafsirId] = progress;
    downloadProgressNotifier.value = updated;
  }

  @visibleForTesting
  void setMockOfflineTafsir(String tafsirId, Map<String, String> map) {
    _offlineTafsirStore[tafsirId] = map;
  }

  /// Get Tafsir for a specific verse from offline store, cache or API
  Future<String> getTafsir({
    required TafsirSource source,
    required int surah,
    required int ayah,
  }) async {
    final offlineKey = '$surah:$ayah';

    // 1. Check offline store first (zero latency O(1) without network)
    if (_offlineTafsirStore.containsKey(source.id)) {
      final offlineMap = _offlineTafsirStore[source.id]!;
      if (offlineMap.containsKey(offlineKey)) {
        return offlineMap[offlineKey]!;
      }
    } else if (isOfflineDownloaded(source.id)) {
      final loaded = await ensureOfflineLoaded(source.id);
      if (loaded && _offlineTafsirStore[source.id]?.containsKey(offlineKey) == true) {
        return _offlineTafsirStore[source.id]![offlineKey]!;
      }
    }

    // 2. Check in-memory cache
    final cacheKey = '${source.id}_${surah}_$ayah';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 3. Check disk cache
    await init();
    if (_cacheDir != null) {
      final cachedFile = File('${_cacheDir!.path}/$cacheKey.txt');
      if (await cachedFile.exists()) {
        final text = await cachedFile.readAsString();
        if (text.trim().isNotEmpty) {
          _memoryCache[cacheKey] = text;
          return text;
        }
      }
    }

    // 4. Fetch from network
    String text = '';
    if (source.apiType == 'qurancdn') {
      text = await _fetchFromQuranCdn(source.key, surah, ayah);
    } else {
      text = await _fetchFromAlquranCloud(source.key, surah, ayah);
    }

    // Fallback to Alquran Cloud if empty
    if (text.trim().isEmpty) {
      text = await _fetchFromAlquranCloud('ar.muyassar', surah, ayah);
    }

    final sanitized = _cleanText(text);

    // 5. Save to cache
    if (sanitized.isNotEmpty) {
      _memoryCache[cacheKey] = sanitized;
      if (_cacheDir != null) {
        try {
          final cachedFile = File('${_cacheDir!.path}/$cacheKey.txt');
          await cachedFile.writeAsString(sanitized, flush: true);
        } catch (e) {
          debugPrint('Failed to write tafsir cache to disk: $e');
        }
      }
    }

    return sanitized.isEmpty ? 'لا يتوفر تفسير لهذه الآية حالياً.' : sanitized;
  }

  /// Get the complete commentary for all Ayahs on a given page (1-604)
  Future<List<AyahPageTafsir>> getPageTafsir({
    required TafsirSource source,
    required int pageNumber,
  }) async {
    await init();
    if (isOfflineDownloaded(source.id) && !_offlineTafsirStore.containsKey(source.id)) {
      await ensureOfflineLoaded(source.id);
    }

    final isOffline = isOfflineDownloaded(source.id);
    final pageData = QuranService.instance.getPageData(pageNumber);
    final results = <AyahPageTafsir>[];

    for (final segment in pageData) {
      final surahNum = segment['surah'] ?? 1;
      final startAyah = segment['start'] ?? 1;
      final endAyah = segment['end'] ?? 1;
      final surahData = QuranService.instance.getSurah(surahNum);
      final surahName = surahData?.arabicName ?? QuranService.instance.getSurahNameArabic(surahNum);

      for (int ayahNum = startAyah; ayahNum <= endAyah; ayahNum++) {
        final ayahText = QuranService.instance.getVerseUthmani(surahNum, ayahNum);
        final tafsirText = await getTafsir(source: source, surah: surahNum, ayah: ayahNum);

        results.add(AyahPageTafsir(
          surahNumber: surahNum,
          surahName: surahName,
          ayahNumber: ayahNum,
          ayahText: ayahText,
          tafsirText: tafsirText,
          isOffline: isOffline,
        ));
      }
    }

    return results;
  }

  Future<String> _fetchFromQuranCdn(String resourceId, int surah, int ayah) async {
    try {
      final url = 'https://api.qurancdn.com/api/v4/tafsirs/$resourceId/by_ayah/$surah:$ayah';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final tafsir = data['tafsir'] as Map<String, dynamic>?;
        if (tafsir != null && tafsir['text'] != null) {
          return tafsir['text'].toString();
        }
      }
    } catch (e) {
      debugPrint('QuranCdn tafsir fetch error for $resourceId ($surah:$ayah): $e');
    }
    return '';
  }

  Future<String> _fetchFromAlquranCloud(String identifier, int surah, int ayah) async {
    try {
      final url = 'https://api.alquran.cloud/v1/ayah/$surah:$ayah/$identifier';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final ayahData = data['data'] as Map<String, dynamic>?;
        if (ayahData != null && ayahData['text'] != null) {
          return ayahData['text'].toString();
        }
      }
    } catch (e) {
      debugPrint('AlquranCloud tafsir fetch error for $identifier ($surah:$ayah): $e');
    }
    return '';
  }

  /// Clean HTML markup, multiple spaces, and span tags returned by web endpoints
  String _cleanText(String html) {
    if (html.isEmpty) return '';
    String result = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return result;
  }
}
