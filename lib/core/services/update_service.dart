import 'dart:async';
import 'package:alhuda/core/constants/app_constants.dart';
import 'package:alhuda/core/view/widgets/force_update_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result data structure for version check operations.
class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final String storeVersion;
  final bool isForceUpdate;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.storeVersion,
    this.isForceUpdate = true,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'UpdateCheckResult(hasUpdate: $hasUpdate, current: $currentVersion, store: $storeVersion, force: $isForceUpdate, error: $errorMessage)';
  }
}

/// Service responsible for checking app updates against Google Play Store
/// and launching the store URL using `url_launcher`.
class UpdateService {
  UpdateService._internal();
  static final UpdateService instance = UpdateService._internal();

  /// Debug flag to simulate a force update during development & testing.
  /// Set to true to inspect the force update dialog behavior.
  static bool debugForceUpdate = false;

  /// Cached dialog display flag to prevent multiple dialogs from stacking.
  bool _isDialogOpen = false;

  /// Safely checks whether network connectivity is active.
  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 1));
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (_) {
      // If check fails or in test/headless environment, allow standard attempt
      return true;
    }
  }

  /// Returns the current installed app version using [Upgrader],
  /// falling back to [AppConstants.appVersion] on failure or timeout.
  Future<String> getCurrentVersion() async {
    try {
      final cached = Upgrader.sharedInstance.currentInstalledVersion?.trim();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      await Upgrader.sharedInstance.initialize().timeout(const Duration(seconds: 3));
      final version = Upgrader.sharedInstance.currentInstalledVersion?.trim();
      if (version != null && version.isNotEmpty) {
        return version;
      }
    } on TimeoutException {
      debugPrint('[UpdateService] Upgrader initialization timed out (normal in emulator or offline).');
    } catch (e) {
      debugPrint('[UpdateService] Note fetching app version via upgrader: $e');
    }
    return Upgrader.sharedInstance.currentInstalledVersion?.trim().isNotEmpty == true
        ? Upgrader.sharedInstance.currentInstalledVersion!.trim()
        : AppConstants.appVersion;
  }

  /// Extracts the latest version string from Google Play Store web page.
  Future<String?> fetchPlayStoreVersion({
    String packageName = AppConstants.playStorePackageName,
  }) async {
    final urls = [
      'https://play.google.com/store/apps/details?id=$packageName&hl=ar',
      'https://play.google.com/store/apps/details?id=$packageName&hl=en',
    ];

    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'ar,en-US;q=0.9,en;q=0.8',
    };

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final body = response.body;
          final version = _extractVersionFromHtml(body);
          if (version != null && version.isNotEmpty) {
            return version;
          }
        }
      } on TimeoutException {
        debugPrint('[UpdateService] Play Store request timed out for $url');
      } catch (e) {
        debugPrint('[UpdateService] Network note checking $url: $e');
      }
    }

    return null;
  }

  /// Matches Google Play HTML response against known patterns for version extraction.
  String? _extractVersionFromHtml(String html) {
    // Pattern 1: Nested array in modern Google Play payload
    final p1 = RegExp(r'\[\[\["(\d+\.\d+(?:\.[0-9a-zA-Z]+)*)"\]\]');
    final m1 = p1.firstMatch(html);
    if (m1 != null && m1.group(1) != null) {
      return m1.group(1);
    }

    // Pattern 2: Variant array structure
    final p2 = RegExp(r',\[\[\["([0-9\.]+)"\]\],');
    final m2 = p2.firstMatch(html);
    if (m2 != null && m2.group(1) != null) {
      return m2.group(1);
    }

    // Pattern 3: Schema.org softwareVersion key
    final p3 = RegExp(r'softwareVersion"\s*:\s*"([0-9\.]+)"');
    final m3 = p3.firstMatch(html);
    if (m3 != null && m3.group(1) != null) {
      return m3.group(1);
    }

    // Pattern 4: Simple standalone version pattern
    final p4 = RegExp(r'\["(\d+\.\d+\.\d+)"\]');
    final m4 = p4.firstMatch(html);
    if (m4 != null && m4.group(1) != null) {
      return m4.group(1);
    }

    return null;
  }

  /// Compares semantic versions (e.g. "1.1.0" vs "1.0.0").
  /// Returns `true` if [storeVersion] is strictly greater than [localVersion].
  bool isVersionHigher(String storeVersion, String localVersion) {
    final cleanStore =
        storeVersion.split('+').first.split('-').first.trim();
    final cleanLocal =
        localVersion.split('+').first.split('-').first.trim();

    final storeParts =
        cleanStore.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final localParts =
        cleanLocal.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = storeParts.length > localParts.length
        ? storeParts.length
        : localParts.length;

    for (int i = 0; i < maxLength; i++) {
      final s = i < storeParts.length ? storeParts[i] : 0;
      final l = i < localParts.length ? localParts[i] : 0;
      if (s > l) return true;
      if (s < l) return false;
    }

    return false;
  }

  /// Fetches the latest version published in the remote repository configuration.
  Future<String?> fetchRemoteVersion() async {
    try {
      final response = await http
          .get(Uri.parse(AppConstants.remoteVersionUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final regex = RegExp(r'version:\s*([0-9]+\.[0-9]+(?:\.[0-9]+)?)');
        final match = regex.firstMatch(response.body);
        if (match != null && match.group(1) != null) {
          return match.group(1);
        }
      }
    } on TimeoutException {
      debugPrint('[UpdateService] Remote version check timed out.');
    } catch (e) {
      debugPrint('[UpdateService] Note fetching remote version: $e');
    }
    return null;
  }

  /// Checks whether an update is available via remote repository, Google Play, or minimum version policy.
  Future<UpdateCheckResult> checkForUpdate({bool debugForce = false}) async {
    final currentVersion = await getCurrentVersion();

    if (debugForce || debugForceUpdate) {
      debugPrint('[UpdateService] Debug force update active.');
      return UpdateCheckResult(
        hasUpdate: true,
        currentVersion: currentVersion,
        storeVersion: '1.2.0',
        isForceUpdate: true,
      );
    }

    // Quick online check before triggering remote network requests
    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('[UpdateService] Device is offline. Skipping remote update check.');
      final fallbackUpdate =
          isVersionHigher(AppConstants.minRequiredVersion, currentVersion);
      return UpdateCheckResult(
        hasUpdate: fallbackUpdate,
        currentVersion: currentVersion,
        storeVersion: AppConstants.minRequiredVersion,
      );
    }

    try {
      // Run remote version check and store check concurrently to minimize wait time
      final results = await Future.wait([
        fetchRemoteVersion(),
        () async {
          try {
            final upgraderVersion = Upgrader.sharedInstance.currentAppStoreVersion;
            if (upgraderVersion != null && upgraderVersion.isNotEmpty) {
              return upgraderVersion;
            }
          } catch (e) {
            debugPrint('[UpdateService] Note reading store version from upgrader: $e');
          }
          return await fetchPlayStoreVersion();
        }(),
      ]);

      final remoteVersion = results[0];
      final playStoreVersion = results[1];

      if (remoteVersion != null) {
        debugPrint('[UpdateService] Found remote version: $remoteVersion');
      }
      if (playStoreVersion != null) {
        debugPrint('[UpdateService] Found Play Store version: $playStoreVersion');
      }

      // 3. Determine the highest target version available
      String latestVersion = AppConstants.minRequiredVersion;
      if (remoteVersion != null && isVersionHigher(remoteVersion, latestVersion)) {
        latestVersion = remoteVersion;
      }
      if (playStoreVersion != null && isVersionHigher(playStoreVersion, latestVersion)) {
        latestVersion = playStoreVersion;
      }

      final hasUpdate = isVersionHigher(latestVersion, currentVersion) ||
          isVersionHigher(AppConstants.minRequiredVersion, currentVersion);

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        storeVersion: latestVersion,
        isForceUpdate: hasUpdate,
      );
    } catch (e) {
      debugPrint('[UpdateService] Note during check: $e');
      final fallbackUpdate =
          isVersionHigher(AppConstants.minRequiredVersion, currentVersion);
      return UpdateCheckResult(
        hasUpdate: fallbackUpdate,
        currentVersion: currentVersion,
        storeVersion: AppConstants.minRequiredVersion,
        errorMessage: e.toString(),
      );
    }
  }

  /// Launches Google Play Store using upgrader or url_launcher in external application mode.
  Future<bool> launchAppStore() async {
    try {
      await Upgrader.sharedInstance.sendUserToAppStore();
      return true;
    } catch (e) {
      debugPrint('[UpdateService] Error launching store URL via upgrader: $e');
    }

    final playStoreUri = Uri.parse(AppConstants.playStoreUrl);
    final marketUri = Uri.parse(AppConstants.playStoreMarketUrl);

    try {
      // 1. Try Google Play Web URL with external application
      if (await canLaunchUrl(playStoreUri)) {
        final success = await launchUrl(
          playStoreUri,
          mode: LaunchMode.externalApplication,
        );
        if (success) return true;
      }

      // 2. Try market:// scheme
      if (await canLaunchUrl(marketUri)) {
        final success = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
        if (success) return true;
      }

      // 3. Fallback to platform default
      return await launchUrl(
        playStoreUri,
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      debugPrint('[UpdateService] Error launching store URL: $e');
      try {
        return await launchUrl(
          marketUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (_) {
        return false;
      }
    }
  }

  /// Checks for updates and displays the non-dismissible force update dialog if needed.
  Future<void> checkAndShowForceUpdateDialog(
    BuildContext context, {
    bool debugForce = false,
  }) async {
    if (_isDialogOpen) return;

    final result = await checkForUpdate(debugForce: debugForce);

    if (!context.mounted) return;

    if (result.hasUpdate) {
      _isDialogOpen = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ForceUpdateDialog(
          result: result,
          onUpdatePressed: () async {
            await launchAppStore();
          },
          onRecheckPressed: () async {
            final recheck = await checkForUpdate();
            if (!dialogContext.mounted) return;
            if (!recheck.hasUpdate) {
              Navigator.of(dialogContext).pop();
              _isDialogOpen = false;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم التحديث بنجاح! شكراً لاستخدامك تطبيق الهدى.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text(
                    'التحديث ما زال مطلوباً، يرجى تثبيت التحديث من متجر Google Play.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
          },
        ),
      );
      _isDialogOpen = false;
    }
  }
}
