import 'dart:io';
import 'package:alhuda/model/mushaf_edition.dart';
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
  final String? editionId;
  final String approximateSize;
  final double approximateSizeMB;

  const TajweedDownloadProgress({
    this.downloaded = 0,
    this.total = 604,
    this.isDownloading = false,
    this.isComplete = false,
    this.error,
    this.editionId,
    this.approximateSize = '85 ميجابايت',
    this.approximateSizeMB = 85.0,
  });

  double get percentage => total > 0 ? (downloaded / total).clamp(0.0, 1.0) : 0.0;
  int get percentInt => (percentage * 100).toInt();
  double get downloadedMB => percentage * approximateSizeMB;
}

/// Central cache and image management service for Quran pages (604 pages)
/// Supporting multiple authentic editions:
/// - Hafs Tajweed (Dar Al-Ma'rifah)
/// - Madinah Hafs (King Fahd Complex)
/// - Madinah Warsh (King Fahd Complex)
/// - Madinah Shu'bah (King Fahd Complex)
class TajweedPageCacheService {
  TajweedPageCacheService._();
  static final TajweedPageCacheService instance = TajweedPageCacheService._();

  MushafEdition _currentEdition = MushafEdition.hafsTajweed;
  final ValueNotifier<MushafEdition> editionNotifier =
      ValueNotifier<MushafEdition>(MushafEdition.hafsTajweed);

  MushafEdition get currentEdition => _currentEdition;

  Directory? _baseDocDir;
  final Map<String, Directory> _editionDirs = {};
  final Set<String> _activeDownloads = {};

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

  /// Initialize local cache directory and saved preferences
  Future<void> init() async {
    if (_baseDocDir != null) return;
    try {
      _baseDocDir = await getApplicationDocumentsDirectory();

      // Read saved edition preference
      final configFile = File('${_baseDocDir!.path}/alhuda_mushaf_edition.json');
      if (await configFile.exists()) {
        final savedId = (await configFile.readAsString()).trim();
        _currentEdition = MushafEdition.fromId(savedId);
        editionNotifier.value = _currentEdition;
      }

      // Initialize folders for each edition
      for (final ed in MushafEdition.availableEditions) {
        final dir = Directory('${_baseDocDir!.path}/${ed.folderName}');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _editionDirs[ed.id] = dir;
      }

      refreshDownloadStatus();
    } catch (e) {
      debugPrint('TajweedPageCacheService init error: $e');
    }
  }

  /// Switch active Mushaf edition and persist choice
  Future<void> switchEdition(MushafEdition edition) async {
    if (_currentEdition.id == edition.id) return;
    if (_isBatchDownloading) {
      cancelBatchDownload();
    }
    _currentEdition = edition;
    editionNotifier.value = edition;

    try {
      if (_baseDocDir != null) {
        final configFile =
            File('${_baseDocDir!.path}/alhuda_mushaf_edition.json');
        await configFile.writeAsString(edition.id);
      }
    } catch (e) {
      debugPrint('Error saving mushaf edition: $e');
    }

    refreshDownloadStatus();
  }

  Directory? _getDirForEdition(MushafEdition? edition) {
    final ed = edition ?? _currentEdition;
    if (_editionDirs.containsKey(ed.id)) {
      return _editionDirs[ed.id];
    }
    if (_baseDocDir != null) {
      return Directory('${_baseDocDir!.path}/${ed.folderName}');
    }
    return null;
  }

  /// Get direct remote URL for a page in the specified (or active) edition
  String getPageUrl(int page, [MushafEdition? edition]) {
    final ed = edition ?? _currentEdition;
    return '${ed.baseUrl}/$page.jpg';
  }

  /// Get fallback remote URL for a page if configured
  String? getFallbackPageUrl(int page, [MushafEdition? edition]) {
    final ed = edition ?? _currentEdition;
    if (ed.fallbackBaseUrl == null) return null;
    return '${ed.fallbackBaseUrl}/$page.jpg';
  }

  /// Get local file path for a page
  File? getLocalFile(int page, [MushafEdition? edition]) {
    final dir = _getDirForEdition(edition);
    if (dir == null) return null;
    return File('${dir.path}/$page.jpg');
  }

  /// Check whether a page image is already cached locally
  bool isPageCached(int page, [MushafEdition? edition]) {
    final file = getLocalFile(page, edition);
    return file != null && file.existsSync() && file.lengthSync() > 1000;
  }

  /// Count how many pages are cached locally for an edition
  int getCachedPagesCount([MushafEdition? edition]) {
    final ed = edition ?? _currentEdition;
    int count = 0;
    for (int p = 1; p <= ed.totalPages; p++) {
      if (isPageCached(p, ed)) count++;
    }
    return count;
  }

  /// Check if an edition is 100% downloaded
  bool isEditionComplete(MushafEdition edition) {
    return getCachedPagesCount(edition) >= edition.totalPages;
  }

  /// Refresh download progress state from current local cache
  void refreshDownloadStatus([MushafEdition? edition]) {
    final ed = edition ?? _currentEdition;
    final cached = getCachedPagesCount(ed);
    downloadProgressNotifier.value = TajweedDownloadProgress(
      downloaded: cached,
      total: ed.totalPages,
      isDownloading: _isBatchDownloading,
      isComplete: cached >= ed.totalPages,
      editionId: ed.id,
      approximateSize: ed.approximateSize,
      approximateSizeMB: ed.approximateSizeMB,
    );
  }

  /// Download all 604 pages in parallel using a worker pool for the active edition
  Future<void> startBatchDownload({
    int concurrency = 6,
    MushafEdition? targetEdition,
  }) async {
    await init();
    if (_isBatchDownloading) return;

    final ed = targetEdition ?? _currentEdition;
    _isBatchDownloading = true;
    _cancelBatchRequested = false;

    // Collect all missing pages
    final missingPages = <int>[];
    for (int p = 1; p <= ed.totalPages; p++) {
      if (!isPageCached(p, ed)) {
        missingPages.add(p);
      }
    }

    int currentCached = ed.totalPages - missingPages.length;
    downloadProgressNotifier.value = TajweedDownloadProgress(
      downloaded: currentCached,
      total: ed.totalPages,
      isDownloading: true,
      isComplete: missingPages.isEmpty,
      editionId: ed.id,
      approximateSize: ed.approximateSize,
      approximateSizeMB: ed.approximateSizeMB,
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
          final file = getLocalFile(page, ed);
          if (file != null && (!file.existsSync() || file.lengthSync() <= 1000)) {
            http.Response? response;
            try {
              response = await http
                  .get(Uri.parse(getPageUrl(page, ed)))
                  .timeout(const Duration(seconds: 25));
            } catch (_) {
              // Primary URL failed
            }

            if ((response == null ||
                    response.statusCode != 200 ||
                    response.bodyBytes.length <= 1000) &&
                ed.fallbackBaseUrl != null) {
              try {
                final fallbackUrl = getFallbackPageUrl(page, ed);
                if (fallbackUrl != null) {
                  response = await http
                      .get(Uri.parse(fallbackUrl))
                      .timeout(const Duration(seconds: 25));
                }
              } catch (_) {
                // Fallback failed
              }
            }

            if (response != null &&
                response.statusCode == 200 &&
                response.bodyBytes.length > 1000) {
              await file.writeAsBytes(response.bodyBytes, flush: true);
            }
          }
        } catch (e) {
          debugPrint('Batch download error for page $page (${ed.id}): $e');
        }

        if (isPageCached(page, ed)) {
          currentCached++;
        }

        downloadProgressNotifier.value = TajweedDownloadProgress(
          downloaded: currentCached,
          total: ed.totalPages,
          isDownloading: !_cancelBatchRequested && currentCached < ed.totalPages,
          isComplete: currentCached >= ed.totalPages,
          editionId: ed.id,
          approximateSize: ed.approximateSize,
          approximateSizeMB: ed.approximateSizeMB,
        );
      }
    }

    final workerCount = concurrency.clamp(1, missingPages.length);
    final workers = List.generate(workerCount, (_) => worker());
    await Future.wait(workers);

    _isBatchDownloading = false;
    final finalCount = getCachedPagesCount(ed);
    downloadProgressNotifier.value = TajweedDownloadProgress(
      downloaded: finalCount,
      total: ed.totalPages,
      isDownloading: false,
      isComplete: finalCount >= ed.totalPages,
      editionId: ed.id,
      approximateSize: ed.approximateSize,
      approximateSizeMB: ed.approximateSizeMB,
    );
  }

  /// Cancel batch download
  void cancelBatchDownload() {
    _cancelBatchRequested = true;
    _isBatchDownloading = false;
    refreshDownloadStatus();
  }

  /// Fetch page file: returns cached File if present, otherwise downloads and saves it
  Future<File?> getPageFile(int page, [MushafEdition? edition]) async {
    await init();
    final ed = edition ?? _currentEdition;
    final file = getLocalFile(page, ed);
    if (file != null && await file.exists() && await file.length() > 1000) {
      return file;
    }

    final downloadKey = '${ed.id}_$page';
    if (_activeDownloads.contains(downloadKey)) {
      // Wait for ongoing download to finish
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (file != null && await file.exists() && await file.length() > 1000) {
          return file;
        }
      }
    }

    _activeDownloads.add(downloadKey);
    try {
      http.Response? response;
      try {
        response = await http
            .get(Uri.parse(getPageUrl(page, ed)))
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        // Primary URL failed
      }

      if ((response == null ||
              response.statusCode != 200 ||
              response.bodyBytes.length <= 1000) &&
          ed.fallbackBaseUrl != null) {
        try {
          final fallbackUrl = getFallbackPageUrl(page, ed);
          if (fallbackUrl != null) {
            response = await http
                .get(Uri.parse(fallbackUrl))
                .timeout(const Duration(seconds: 15));
          }
        } catch (_) {
          // Fallback failed
        }
      }

      if (response != null &&
          response.statusCode == 200 &&
          response.bodyBytes.length > 1000) {
        if (file != null) {
          await file.writeAsBytes(response.bodyBytes, flush: true);
          return file;
        }
      }
    } catch (e) {
      debugPrint('Error downloading page $page (${ed.id}): $e');
    } finally {
      _activeDownloads.remove(downloadKey);
    }
    return null;
  }

  /// Prefetch adjacent pages in background (ahead and behind)
  void prefetchPages(int currentPage, {int radius = 5, MushafEdition? edition}) {
    final ed = edition ?? _currentEdition;
    for (int offset = 1; offset <= radius; offset++) {
      final nextPage = currentPage + offset;
      final prevPage = currentPage - offset;

      if (nextPage <= ed.totalPages &&
          !isPageCached(nextPage, ed) &&
          !_activeDownloads.contains('${ed.id}_$nextPage')) {
        getPageFile(nextPage, ed);
      }
      if (prevPage >= 1 &&
          !isPageCached(prevPage, ed) &&
          !_activeDownloads.contains('${ed.id}_$prevPage')) {
        getPageFile(prevPage, ed);
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
