import 'dart:io';
import 'package:alhuda/features/quran/data/mushaf_edition.dart';
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
  final Map<String, Future<File?>> _inFlightDownloads = {};

  bool _isBatchDownloading = false;
  bool _cancelBatchRequested = false;

  final ValueNotifier<TajweedDownloadProgress> downloadProgressNotifier =
      ValueNotifier<TajweedDownloadProgress>(const TajweedDownloadProgress());

  bool get isBatchDownloading => _isBatchDownloading;

  /// 60 Hizbs start pages in standard Madinah 15-line Mushaf
  static const List<int> kHizbStartPages = [
    1, 11, 22, 32, 42, 51, 62, 72, 82, 92,
    102, 112, 121, 132, 142, 151, 162, 173, 182, 192,
    201, 212, 222, 231, 242, 252, 262, 272, 282, 292,
    302, 312, 322, 332, 342, 352, 362, 371, 382, 392,
    402, 413, 422, 431, 442, 451, 462, 472, 482, 491,
    502, 513, 522, 531, 542, 553, 562, 572, 582, 591,
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
    final ed = targetEdition ?? _currentEdition;

    // 1. If edition is already 100% complete, DO NOT download again!
    if (isEditionComplete(ed)) {
      refreshDownloadStatus(ed);
      return;
    }

    if (_isBatchDownloading) return;

    _isBatchDownloading = true;
    _cancelBatchRequested = false;

    // 2. Collect all missing pages (never re-download cached pages)
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
      refreshDownloadStatus(ed);
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

        // Skip if somehow already cached
        if (!isPageCached(page, ed)) {
          await getPageFile(page, ed);
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
    refreshDownloadStatus(ed);
  }

  /// Cancel batch download
  void cancelBatchDownload() {
    _cancelBatchRequested = true;
    _isBatchDownloading = false;
    refreshDownloadStatus();
  }

  /// Fetch page file: returns cached File if present, otherwise downloads and saves it once
  Future<File?> getPageFile(int page, [MushafEdition? edition]) async {
    await init();
    final ed = edition ?? _currentEdition;
    final file = getLocalFile(page, ed);
    if (file != null && await file.exists() && await file.length() > 1000) {
      return file;
    }

    final downloadKey = '${ed.id}_$page';
    if (_inFlightDownloads.containsKey(downloadKey)) {
      return await _inFlightDownloads[downloadKey];
    }

    final downloadFuture = _downloadPageInternal(page, ed, file);
    _inFlightDownloads[downloadKey] = downloadFuture;
    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _inFlightDownloads.remove(downloadKey);
    }
  }

  Future<File?> _downloadPageInternal(int page, MushafEdition ed, File? file) async {
    if (file == null) return null;
    if (await file.exists() && await file.length() > 1000) {
      return file;
    }

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
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading page $page (${ed.id}): $e');
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

  /// Returns the Hizb number (1 to 60) if [page] marks the start of a Hizb, otherwise null.
  static int? getHizbStartingOnPage(int page) {
    final index = kHizbStartPages.indexOf(page);
    if (index >= 0) {
      return index + 1;
    }
    return null;
  }

  /// Calculates the exact Juz number (1 to 30) for a given Hizb (1 to 60)
  static int getJuzForHizb(int hizb) {
    return ((hizb.clamp(1, 60) - 1) ~/ 2) + 1;
  }
}
