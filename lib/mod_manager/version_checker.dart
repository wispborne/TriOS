import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';

import '../models/mod_variant.dart';
import '../models/version_checker_info.dart';
import '../trios/app_state.dart';
import '../trios/providers.dart';
import '../utils/dart_mappable_utils.dart';
import 'mod_manager_logic.dart';

part 'version_checker.mapper.dart';

class VersionCheckerManager
    extends GenericAsyncSettingsManager<VersionCheckerState> {
  @override
  VersionCheckerState Function() get createDefaultState =>
      () => VersionCheckerState({});

  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => "trios_version_checker_cache.${fileFormat.name}";

  @override
  VersionCheckerState Function(Map<String, dynamic> map) get fromMap =>
      (map) => VersionCheckerStateMapper.fromMap(map);

  @override
  Map<String, dynamic> Function(VersionCheckerState obj) get toMap =>
      (obj) => obj.toMap();
}

class VersionCheckerAsyncProvider
    extends GenericSettingsAsyncNotifier<VersionCheckerState> {
  /// Time before the next version check can be done. Tracked per mod.
  static const versionCheckCooldown = Duration(minutes: 5);

  /// Actual source of truth for the state, persists between rebuilds.
  final Map<String, RemoteVersionCheckResult> _versionCheckResultsCache = {};
  final cacheLock = Mutex();

  @override
  GenericAsyncSettingsManager<VersionCheckerState> createSettingsManager() =>
      VersionCheckerManager();

  @override
  Future<VersionCheckerState> build() async {
    await super.build();
    // IMPORTANT: Automatically refreshes whenever mods change.
    final modsRef = ref.watch(AppState.mods);
    await refresh(skipCache: false);
    return VersionCheckerState(_versionCheckResultsCache);
  }

  // Executes async, updates state every time a Version Check http request is completed.
  Future<void> refresh({required bool skipCache}) async {
    final skippingCache = AppState.skipCacheOnNextVersionCheck || skipCache;
    final httpClient = ref.watch(triOSHttpClient);

    if (skippingCache) {
      await cacheLock.protect(() async {
        _versionCheckResultsCache.clear();
        update((s) => _mutateOrCreateState(_versionCheckResultsCache));
        AppState.skipCacheOnNextVersionCheck = false;
      });
    } else if (_versionCheckResultsCache.isEmpty) {
      // Load from file cache if not already loaded and not skipping the cache.
      await settingsManager.readSettingsFromDisk();
    }

    var currentTime = DateTime.now();

    final modsRef = ref.read(AppState.mods);
    // Doesn't check every variant. Only looks up the highest version that has a .version file.
    final variantsToCheck = modsRef
        .map((mod) => mod.modVariants.sortedDescending().firstWhereOrNull(
            (variant) => variant.versionCheckerInfo?.seemsLegit == true))
        .whereNotNull()
        .toList();

    final versionCheckFutures = variantsToCheck.map((mod) {
      // Always check if never checked before.
      if (_versionCheckResultsCache[mod.smolId] != null) {
        final lastCheck = _versionCheckResultsCache[mod.smolId]!.timestamp;
        if (skipCache ||
            currentTime.difference(lastCheck) > versionCheckCooldown) {
          // If enough time has passed since the last check (or we're ignoring the cache), check again.
          return (mod, checkRemoteVersion(mod, httpClient), wasCached: false);
        } else {
          // Otherwise, return the cached result.
          return (
            mod,
            Future.value(_versionCheckResultsCache[mod.smolId]!),
            wasCached: true
          );
        }
      } else {
        return (mod, checkRemoteVersion(mod, httpClient), wasCached: false);
      }
    }).toList();

    // Set up handlers for the futures.
    for (var futResult in versionCheckFutures) {
      final (mod, future, wasCached: wasCached) = futResult;
      if (wasCached) {
        continue; // No need to do anything if the data was already there.
      }

      future.then((result) async {
        Fimber.v(
            () => "Caching remote version info for ${mod.modInfo.id}: $result");
        await cacheLock.protect(() async {
          _versionCheckResultsCache[mod.smolId] = result;
          update((s) => _mutateOrCreateState(_versionCheckResultsCache));
        });
      }).catchError((e, st) async {
        Fimber.e("Error fetching remote version info. Storing error. $e\n$st");
        final errResult = RemoteVersionCheckResult(null, null)
          ..smolId = mod.smolId
          ..error = e;
        await cacheLock.protect(() async {
          _versionCheckResultsCache[mod.smolId] = errResult;
          update((s) => _mutateOrCreateState(_versionCheckResultsCache));
        });
      });
    }
  }

  VersionCheckerState _mutateOrCreateState(
      Map<String, RemoteVersionCheckResult> versionCheckResultsCache) {
    return state.valueOrNull?.copyWith(
          versionCheckResultsBySmolId: versionCheckResultsCache,
        ) ??
        VersionCheckerState(versionCheckResultsCache);
  }

  final versionCheckerCacheFile =
      File(p.join("cache", "TriOS-VersionCheckerCache.json")).normalize;
}

/// Result of looking up a remote version checker file.
/// Cached in TriOS, rather than doing a network request every time.
@MappableClass()
class RemoteVersionCheckResult with RemoteVersionCheckResultMappable {
  String? smolId;
  Object? error;
  @MappableField(hook: VersionHook())
  final VersionCheckerInfo? remoteVersion;
  final String? uri;
  final DateTime timestamp;

  RemoteVersionCheckResult(this.remoteVersion, this.uri, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'VersionCheckResult{smolId: $smolId, remoteVersion: $remoteVersion, error: $error, uri: $uri, timestamp: $timestamp}';

  VersionCheckComparison? compareToLocal(ModVariant modVariant) {
    return VersionCheckComparison.specific(modVariant, this);
  }
}

@MappableClass()
class VersionCheckerState with VersionCheckerStateMappable {
  final Map<String, RemoteVersionCheckResult> versionCheckResultsBySmolId;

  VersionCheckerState(this.versionCheckResultsBySmolId);
}

Future<RemoteVersionCheckResult> checkRemoteVersion(
  ModVariant modVariant,
  TriOSHttpClient httpClient,
) async {
  var remoteVersionUrl = modVariant.versionCheckerInfo?.masterVersionFile;
  if (remoteVersionUrl == null) {
    return RemoteVersionCheckResult(null, null)
      ..smolId = modVariant.smolId
      ..error = Exception("No remote version url for ${modVariant.modInfo.id}");
  }
  final fixedUrl = fixUrl(remoteVersionUrl);

  try {
    final response = await httpClient.get(
      fixedUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      allowSelfSignedCertificates: true,
    );

    var data = response.data;

    if (data is List<int>) {
      data = String.fromCharCodes(data);
    }

    final String body = data;
    if (response.statusCode == 200) {
      return RemoteVersionCheckResult(
          VersionCheckerInfoMapper.fromJson(body.fixJson()), remoteVersionUrl)
        ..smolId = modVariant.smolId;
    } else {
      throw Exception(
          "Failed to fetch remote version info for ${modVariant.modInfo.id}: ${response.statusCode} - $body");
    }
  } catch (e, st) {
    Fimber.w(
        "Error fetching remote version info for ${modVariant.modInfo.id}: $e\n$st");
    return RemoteVersionCheckResult(null, remoteVersionUrl)
      ..smolId = modVariant.smolId
      ..error = e;
  }
}

/// User linked to the page for their version file on github instead of to the raw file.
final _githubFilePageRegex = RegExp(
    r"https://github.com/.+/blob/.+/assets/.+.version",
    caseSensitive: false);

/// User set dl=0 instead of dl=1 when hosted on dropbox.
final _dropboxDlPageRegex = RegExp(
    """https://www.dropbox.com/s/.+/.+.version?dl=0""",
    caseSensitive: false);

String fixUrl(String urlString) {
  if (_githubFilePageRegex.hasMatch(urlString)) {
    return urlString
        .replaceAll("github.com", "raw.githubusercontent.com")
        .replaceAll("blob/", "");
  } else if (_dropboxDlPageRegex.hasMatch(urlString)) {
    return urlString.replaceAll("dl=0", "dl=1");
  } else {
    return urlString;
  }
}

extension VersionCheckerStringExt on String {
  String fixModDownloadUrl() {
    return fixUrl(this);
  }
}
