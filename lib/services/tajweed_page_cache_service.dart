import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Progress state of batch downloading
class TajweedDownloadProgress {
  final int downloaded;
  final int total;
  final bool isDownloading;
  final bool isComplete;
  final String? error;

  const TajweedDownloadProgress({
    this.downloaded = 0,
    this.total = 604,
    this.isDownloading = false,
    this.isComplete = false,
    this.error,
  });

  double get percentage => total > 0 ? (downloaded / total).clamp(0.0, 1.0) : 0.0;
  int get percentInt => (percentage * 100).toInt();
}

/// Central cache and image management service for Dar Al-Ma'rifah Tajweed Quran pages (604 pages)
class TajweedPageCacheService {
  TajweedPageCacheService._();
  static final TajweedPageCacheService instance = TajweedPageCacheService._();

  static const String _baseUrl =
      'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/easyquran.com/hafs-tajweed';

  Directory? _cacheDir;
  final Set<int> _activeDownloads = {};

  bool _isBatchDownloading = false;
  bool _cancelBatchRequested = false;

  final ValueNotifier<TajweedDownloadProgress> downloadProgressNotifier =
      ValueNotifier<TajweedDownloadProgress>(const TajweedDownloadProgress());

  bool get isBatchDownloading => _isBatchDownloading;

  /// 60 Hizbs start pages in standard Madinah 15-line Mushaf
  static const List<int> kHizbStartPages = [
    1, 12, 22, 31, 42, 50, 59, 68, 79, 89,
    99, 109, 119, 128, 138, 148, 156, 167, 177, 187,
    196, 206, 217, 227, 235, 247, 255, 267, 278, 288,
    298, 308, 317, 322, 332, 342, 352, 361, 373, 385,
    395, 404, 413, 422, 431, 442, 453, 463, 472, 483,
    492, 502, 512, 522, 531, 542, 551, 560, 569, 582,
  ];

  /// Initialize local cache directory
  Future<void> init() async {
    if (_cacheDir != null) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docDir.path}/quran_tajweed_pages');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      refreshDownloadStatus();
    } catch (e) {
      debugPrint('TajweedPageCacheService init error: $e');
    }
  }

  /// Get direct remote URL for a page
  String getPageUrl(int page) => '$_baseUrl/$page.jpg';

  /// Get local file path for a page
  File? getLocalFile(int page) {
    if (_cacheDir == null) return null;
    return File('${_cacheDir!.path}/$page.jpg');
  }

  /// Check whether a page image is already cached locally
  bool isPageCached(int page) {
    final file = getLocalFile(page);
    return file != null && file.existsSync() && file.lengthSync() > 1000;
  }

  /// Count how many pages are cached locally
  int getCachedPagesCount() {
    if (_cacheDir == null) return 0;
    int count = 0;
    for (int p = 1; p <= 604; p++) {
      if (isPageCached(p)) count++;
    }
    return count;
  }

  /// Refresh download progress state from current local cache
  void refreshDownloadStatus() {
    final cached = getCachedPagesCount();
    downloadProgressNotifier.value = TajweedDownloadProgress(
      downloaded: cached,
      total: 604,
      isDownloading: _isBatchDownloading,
      isComplete: cached >= 604,
    );
  }

  /// Download all 604 pages in parallel using a worker pool
  Future<void> startBatchDownload({int concurrency = 6}) async {
    await init();
    if (_isBatchDownloading) return;

    _isBatchDownloading = true;
    _cancelBatchRequested = false;

    // Collect all missing pages
    final missingPages = <int>[];
    for (int p = 1; p <= 604; p++) {
      if (!isPageCached(p)) {
        missingPages.add(p);
      }
    }

    int currentCached = 604 - missingPages.length;
    downloadProgressNotifier.value = TajweedDownloadProgress(
      downloaded: currentCached,
      total: 604,
      isDownloading: true,
      isComplete: missingPages.isEmpty,
    );

    if (missingPages.isEmpty) {
      _isBatchDownloading = false;
      return;
    }

    int nextIndex = 0;

    Future<void> worker() async {
      while (!_cancelBatchRequested) {
        int page;
        if (nextIndex >= missingPages.length) {
          break;
        }
        page = missingPages[nextIndex++];

        try {
          final file = getLocalFile(page);
          if (file != null && (!file.existsSync() || file.lengthSync() <= 1000)) {
            final response = await http
                .get(Uri.parse(getPageUrl(page)))
                .timeout(const Duration(seconds: 25));
            if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
              await file.writeAsBytes(response.bodyBytes, flush: true);
            }
          }
        } catch (e) {
          debugPrint('Batch download error for page $page: $e');
        }

        if (isPageCached(page)) {
          currentCached++;
        }

        downloadProgressNotifier.value = TajweedDownloadProgress(
          downloaded: currentCached,
          total: 604,
          isDownloading: !_cancelBatchRequested && currentCached < 604,
          isComplete: currentCached >= 604,
        );
      }
    }

    final workerCount = concurrency.clamp(1, missingPages.length);
    final workers = List.generate(workerCount, (_) => worker());
    await Future.wait(workers);

    _isBatchDownloading = false;
    final finalCount = getCachedPagesCount();
    downloadProgressNotifier.value = TajweedDownloadProgress(
      downloaded: finalCount,
      total: 604,
      isDownloading: false,
      isComplete: finalCount >= 604,
    );
  }

  /// Cancel batch download
  void cancelBatchDownload() {
    _cancelBatchRequested = true;
    _isBatchDownloading = false;
    refreshDownloadStatus();
  }

  /// Fetch page file: returns cached File if present, otherwise downloads and saves it
  Future<File?> getPageFile(int page) async {
    await init();
    final file = getLocalFile(page);
    if (file != null && await file.exists() && await file.length() > 1000) {
      return file;
    }

    if (_activeDownloads.contains(page)) {
      // Wait for ongoing download to finish
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (file != null && await file.exists() && await file.length() > 1000) {
          return file;
        }
      }
    }

    _activeDownloads.add(page);
    try {
      final response = await http.get(Uri.parse(getPageUrl(page))).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
        if (file != null) {
          await file.writeAsBytes(response.bodyBytes, flush: true);
          return file;
        }
      }
    } catch (e) {
      debugPrint('Error downloading Tajweed page $page: $e');
    } finally {
      _activeDownloads.remove(page);
    }
    return null;
  }

  /// Prefetch adjacent pages in background (ahead and behind)
  void prefetchPages(int currentPage, {int radius = 5}) {
    for (int offset = 1; offset <= radius; offset++) {
      final nextPage = currentPage + offset;
      final prevPage = currentPage - offset;

      if (nextPage <= 604 && !isPageCached(nextPage) && !_activeDownloads.contains(nextPage)) {
        getPageFile(nextPage);
      }
      if (prevPage >= 1 && !isPageCached(prevPage) && !_activeDownloads.contains(prevPage)) {
        getPageFile(prevPage);
      }
    }
  }

  /// Calculates the exact Hizb number (1 to 60) for a given page
  static int getHizbForPage(int page) {
    final p = page.clamp(1, 604);
    for (int i = kHizbStartPages.length - 1; i >= 0; i--) {
      if (p >= kHizbStartPages[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Formatted text for the Hizb number (e.g. 'الحزب 47')
  static String getHizbText(int page) {
    final hizbNum = getHizbForPage(page);
    return 'الحزب $hizbNum';
  }
}
