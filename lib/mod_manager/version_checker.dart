import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';

import '../models/mod_variant.dart';
import '../models/version_checker_info.dart';
import '../trios/app_state.dart';
import '../trios/constants.dart';
import 'mod_manager_logic.dart';

part 'version_checker.mapper.dart';

class VersionCheckerManager
    extends GenericAsyncSettingsManager<VersionCheckerState> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => "trios_version_checker_cache.${fileFormat.name}";

  @override
  Future<Directory> getConfigDataFolderPath() =>
      Future.value(Constants.cacheDirPath);

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
  static const versionCheckCooldown = Duration(minutes: 60);

  /// Actual source of truth for the state, persists between rebuilds.
  final Map<String, RemoteVersionCheckResult> _versionCheckResultsCache = {};
  final _cacheLock = Mutex();

  @override
  GenericAsyncSettingsManager<VersionCheckerState> createSettingsManager() =>
      VersionCheckerManager();

  @override
  VersionCheckerState createDefaultState() => VersionCheckerState({});

  @override
  Future<VersionCheckerState> build() async {
    await super.build();
    // Automatically refreshes whenever mods change.
    ref.watch(AppState.mods);
    await refresh(skipCache: false);
    // Need to do `toMap` to avoid the state being the same object as the cache.
    // This resulted in `updateState` having the same old state as new state, since the cache was mutated before `updateState`
    // was called, resulting in the state object also being mutated.
    return VersionCheckerState(_versionCheckResultsCache.toMap());
  }

  /// Refreshes the version check results, updating the state accordingly.
  Future<void> refresh({
    required bool skipCache,
    List<ModVariant>? specificVariantsToCheck,
    bool evenIfMuted = false,
  }) async {
    if (specificVariantsToCheck == null) {
      await _initializeCache(skipCache);
    }

    final List<ModVariant> variantsToCheck =
        (specificVariantsToCheck ?? _getVariantsToCheck()).toList();
    final metadata = ref.read(AppState.modsMetadata).value;

    if (metadata != null && !evenIfMuted) {
      final mutedIds = variantsToCheck
          .where(
            (v) =>
                metadata.getMergedModMetadata(v.modInfo.id)?.areUpdatesMuted ==
                true,
          )
          .map((v) => v.smolId)
          .toSet();
      variantsToCheck.removeWhere((v) => mutedIds.contains(v.smolId));
    }

    final versionCheckTasks = _createVersionCheckTasks(
      variantsToCheck,
      skipCache,
    );

    await _executeVersionCheckTasks(versionCheckTasks);
  }

  /// Initializes the cache by clearing it or loading from disk based on skipCache.
  Future<void> _initializeCache(bool skipCache) async {
    final shouldSkipCache = AppState.skipCacheOnNextVersionCheck || skipCache;

    if (shouldSkipCache) {
      await _cacheLock.protect(() async {
        _versionCheckResultsCache.clear();
        updateState((s) => _updateStateWithCache(_versionCheckResultsCache));
        AppState.skipCacheOnNextVersionCheck = false;
      });
    } else if (_versionCheckResultsCache.isEmpty) {
      final versionResultsOnDisk = await settingsManager.read(
        createDefaultState(),
      );
      _versionCheckResultsCache.addAll(
        versionResultsOnDisk.versionCheckResultsBySmolId,
      );
    }
  }

  /// Retrieves the list of mod variants that need version checking.
  List<ModVariant> _getVariantsToCheck() {
    final modsRef = ref.read(AppState.mods);
    return modsRef
        .map(
          (mod) => mod.modVariants.sortedDescending().firstWhereOrNull(
            (variant) => variant.versionCheckerInfo?.seemsLegit == true,
          ),
        )
        .nonNulls
        .toList();
  }

  /// Creates tasks for version checking each mod variant.
  List<VersionCheckTask> _createVersionCheckTasks(
    List<ModVariant> variantsToCheck,
    bool skipCache,
  ) {
    final httpClient = ref.watch(triOSHttpClient);
    final currentTime = DateTime.now();

    return variantsToCheck.map((modVariant) {
      final cachedResult = _versionCheckResultsCache[modVariant.smolId];
      final needsUpdate =
          skipCache ||
          cachedResult == null ||
          currentTime.difference(cachedResult.timestamp) > versionCheckCooldown;

      if (needsUpdate) {
        final future = checkRemoteVersion(modVariant, httpClient);
        return VersionCheckTask(
          modVariant,
          modVariant.versionCheckerInfo,
          future,
          wasCached: false,
        );
      } else {
        return VersionCheckTask(
          modVariant,
          modVariant.versionCheckerInfo,
          Future.value(cachedResult),
          wasCached: true,
        );
      }
    }).toList();
  }

  /// Executes the version check tasks, updating the cache and state.
  Future<void> _executeVersionCheckTasks(List<VersionCheckTask> tasks) async {
    final futures = tasks.where((task) => !task.wasCached).map((task) async {
      try {
        final result = await task.future;
        Fimber.v(
          () =>
              "Caching remote version info for ${task.modVariant.modInfo.id}: $result",
        );
        _updateCache(result);
      } catch (e, st) {
        Fimber.e(
          "Error fetching remote version info for ${task.modVariant.modInfo.id}: $e\n$st",
        );
        final errorResult =
            RemoteVersionCheckResult(task.localVersion, null, null)
              ..smolId = task.modVariant.smolId
              ..error = e;
        _updateCache(errorResult);
      }
    }).toList();

    await Future.wait(futures);
  }

  /// Updates the cache and state with the provided result.
  Future<void> _updateCache(RemoteVersionCheckResult result) async {
    if (result.smolId == null) {
      Fimber.e("No smolId for $result");
      return;
    }
    await _cacheLock.protect(() async {
      _versionCheckResultsCache[result.smolId!] = result;
      await updateState(
        (s) => _updateStateWithCache(_versionCheckResultsCache),
      );
    });
  }

  VersionCheckerState _updateStateWithCache(
    Map<String, RemoteVersionCheckResult> versionCheckResultsCache,
  ) =>
      state.value?.copyWith(
        versionCheckResultsBySmolId: versionCheckResultsCache,
      ) ??
      VersionCheckerState(versionCheckResultsCache);

  final versionCheckerCacheFile = File(
    p.join("cache", "TriOS-VersionCheckerCache.json"),
  ).normalize;
}

/// Represents a task for checking the version of a mod variant.
class VersionCheckTask {
  final ModVariant modVariant;
  final VersionCheckerInfo? localVersion;
  final Future<RemoteVersionCheckResult> future;
  final bool wasCached;

  VersionCheckTask(
    this.modVariant,
    this.localVersion,
    this.future, {
    required this.wasCached,
  });
}

/// Result of looking up a remote version checker file.
/// Cached in TriOS, rather than doing a network request every time.
@MappableClass()
class RemoteVersionCheckResult with RemoteVersionCheckResultMappable {
  String? smolId;
  Object? error;
  final VersionCheckerInfo? remoteVersion;
  final VersionCheckerInfo? localVersion;

  /// Simply returns remote if available, otherwise returns local.
  final VersionCheckerInfo? remoteVersionWithFallback;
  final String? uri;
  final DateTime timestamp;

  RemoteVersionCheckResult(
    this.localVersion,
    this.remoteVersion,
    this.uri, {
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       remoteVersionWithFallback = remoteVersion ?? localVersion;

  @override
  String toString() =>
      'VersionCheckResult{smolId: $smolId, remoteVersion: $remoteVersion, error: $error, uri: $uri, timestamp: $timestamp}';

  VersionCheckComparison? compareToLocal(ModVariant modVariant) =>
      VersionCheckComparison.specific(modVariant, this);
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
    return RemoteVersionCheckResult(modVariant.versionCheckerInfo, null, null)
      ..smolId = modVariant.smolId
      ..error = Exception("No remote version URL for ${modVariant.modInfo.id}");
  }
  final fixedUrl = fixUrl(remoteVersionUrl);

  try {
    // TODO https://bitbucket.org/niatahl/trailer-moments/downloads/trailermoments.version doesn't work
    final response = await httpClient.get(
      fixedUrl,
      // Having this header causes Version Checker to fail for Bitbucket repos. Didn't see any issues with any of my 0.97a mods.
      // headers: {'Content-Type': 'application/json'},
      allowSelfSignedCertificates: true,
    );

    var data = response.data;

    if (data is List<int>) {
      data = utf8.decode(data);
    }

    final String body = data;
    if (response.statusCode == 200) {
      return RemoteVersionCheckResult(
        modVariant.versionCheckerInfo,
        VersionCheckerInfoMapper.fromJson(body.fixJson()),
        remoteVersionUrl,
      )..smolId = modVariant.smolId;
    } else {
      throw Exception(
        "Failed to fetch remote version info for ${modVariant.modInfo.id}: ${response.statusCode} - $body",
      );
    }
  } catch (e, st) {
    Fimber.w("Error fetching remote version info for ${modVariant.modInfo.id}");
    Fimber.v(() => '', ex: e, stacktrace: st);
    return RemoteVersionCheckResult(
        modVariant.versionCheckerInfo,
        null,
        remoteVersionUrl,
      )
      ..smolId = modVariant.smolId
      ..error = e;
  }
}

/// User linked to the page for their version file on GitHub instead of to the raw file.
final _githubFilePageRegex = RegExp(
  r"https://github.com/.+/blob/.+/assets/.+.version",
  caseSensitive: false,
);

/// User set dl=0 instead of dl=1 when hosted on Dropbox.
final _dropboxDlPageRegex = RegExp(
  r"https://www.dropbox.com/s/.+/.+.version\?dl=0",
  caseSensitive: false,
);

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
