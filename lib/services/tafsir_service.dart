import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Represents a Tafsir book source with its metadata
class TafsirSource {
  final String id;
  final String key;
  final String name;
  final String author;
  final String language;
  final String apiType; // 'qurancdn' or 'alquran_cloud'

  const TafsirSource({
    required this.id,
    required this.key,
    required this.name,
    required this.author,
    this.language = 'ar',
    required this.apiType,
  });
}

/// Comprehensive service for fetching and caching Quran Tafsirs
class TafsirService {
  TafsirService._();
  static final TafsirService instance = TafsirService._();

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
  Directory? _cacheDir;
  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDoc.path}/alhuda_tafsir_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      _isInit = true;
    } catch (e) {
      debugPrint('TafsirService initialization warning: $e');
    }
  }

  /// Get Tafsir for a specific verse from cache or API
  Future<String> getTafsir({
    required TafsirSource source,
    required int surah,
    required int ayah,
  }) async {
    final cacheKey = '${source.id}_${surah}_$ayah';

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. Check disk cache
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

    // 3. Fetch from network
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

    // 4. Save to cache
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
