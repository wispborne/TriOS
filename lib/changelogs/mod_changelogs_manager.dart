import 'dart:async';
import 'dart:convert';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/providers.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';

part 'mod_changelogs_manager.mapper.dart';

/// String is mod id.
class ModChangelogsManager extends AsyncNotifier<Map<String, ModChangelog>> {
  @override
  FutureOr<Map<String, ModChangelog>> build() async {
    final mods = ref.watch(AppState.mods);
    final httpClient = ref.watch(triOSHttpClient);
    final cachedVersionChecks = ref
        .watch(AppState.versionCheckResults)
        .valueOrNull;

    // Show a spinner only the first time.
    if (!state.hasValue && !state.isLoading && !state.hasError) {
      state = const AsyncValue.loading();
    }

    // Start with whatever we already have.
    final Map<String, ModChangelog> results = Map.of(
      state.valueOrNull ?? <String, ModChangelog>{},
    );

    for (final mod in mods) {
      // Only fetch changelogs once per mod...
      if (results.containsKey(mod.id)) continue;

      // and only if there is Version Checker...
      final modVariant = mod.findFirstEnabledOrHighestVersion;
      if (modVariant == null || modVariant.versionCheckerInfo == null) continue;

      final versionCheckComparisonResult = mod.updateCheck(cachedVersionChecks);

      final changelogUrl = getChangelogUrl(
        versionCheckComparisonResult?.variant.versionCheckerInfo,
        versionCheckComparisonResult?.remoteVersionCheck,
      );

      // and only if there is a changelog url.
      if (changelogUrl.isNullOrEmpty()) continue;

      final raw = await fetchChangelog(httpClient, changelogUrl!, mod.id);
      if (raw.isNullOrEmpty()) continue;

      results[mod.id] = processChangelog(
        raw!,
        changelogUrl,
        mod.id,
        modVariant.smolId,
      );
      // Add just-fetched changelog to state.
      state = AsyncValue.data(Map<String, ModChangelog>.from(results));
    }

    state = AsyncValue.data(results);
    return results;
  }

  /// Returns the changelog URL for a mod.
  ///
  /// This function checks the `remoteVersionCheck` for a changelog URL first.
  /// If it is not available, it falls back to the `localVersionCheckerInfo`.
  ///
  /// Returns `null` if neither contains a changelog URL.
  String? getChangelogUrl(
    VersionCheckerInfo? localVersionCheckerInfo,
    RemoteVersionCheckResult? remoteVersionCheck,
  ) {
    return [
      remoteVersionCheck?.remoteVersion?.changelogURL,
      localVersionCheckerInfo?.changelogURL,
    ].firstWhere(
      (url) => url != null && Uri.tryParse(url) != null,
      orElse: () => null,
    );
  }

  /// Downloads a changelog. Any network error is swallowed and logged.
  Future<String?> fetchChangelog(
    TriOSHttpClient httpClient,
    String changelogUrl,
    String modId,
  ) async {
    try {
      final response = await httpClient.get(changelogUrl);
      var data = response.data;
      if (data is List<int>) data = utf8.decode(data);
      return data.toString().trim();
    } catch (ex, st) {
      Fimber.w(
        'Failed to fetch changelog for mod "$modId" ($changelogUrl)',
        ex: ex,
        stacktrace: st,
      );
      return ex.toString();
    }
  }

  /// Processes the changelog by removing the first line if it contains "Changelog".
  ModChangelog processChangelog(
    String changelog,
    String url,
    String modId,
    String smolId,
  ) {
    var lines = changelog.split("\n");

    // Remove the first line if it contains "Changelog"
    if (lines.firstOrNull?.containsIgnoreCase("Changelog") == true) {
      lines = lines.skip(1).toList();
    }

    // If there's a blank line after a version line, remove it
    List<String> cleanedLines = [];

    for (int i = 0; i < lines.length; i++) {
      cleanedLines.add(lines[i]);
      final lowercaseLine = lines[i].trim().toLowerCase();
      if (i < lines.length - 1 &&
          lowercaseLine.startsWith('version') &&
          lines[i + 1].trim().isEmpty) {
        i++;
      }
    }

    // Parse versions from cleanedLines
    List<ChangelogVersion>? parsedVersions = <ChangelogVersion>[];
    Version? currentVersion;
    final buffer = StringBuffer();

    for (final line in cleanedLines) {
      try {
        final versionStr = parseVersionFromChangelog(line.trim());
        if (versionStr != null) {
          // Flush previous version's changelog
          if (currentVersion != null) {
            parsedVersions.add(
              ChangelogVersion(currentVersion, buffer.toString().trim()),
            );
            buffer.clear();
          }
          try {
            currentVersion = Version.parse(versionStr);
          } catch (ex, st) {
            Fimber.d(
              "Failed to parse version '$versionStr' in smolId $smolId",
              ex: ex,
              stacktrace: st,
            );
          }
        } else if (currentVersion != null) {
          buffer.writeln(line);
        }
      } catch (ex, st) {
        Fimber.d("Error parsing changelog.", ex: ex, stacktrace: st);
      }
    }

    // Add the last collected version
    if (currentVersion != null) {
      parsedVersions.add(
        ChangelogVersion(currentVersion, buffer.toString().trim()),
      );
    }

    if (parsedVersions.isEmpty) {
      parsedVersions = null;
    }

    return ModChangelog(
      modId: modId,
      smolId: smolId,
      changelog: cleanedLines.join("\n"),
      url: url,
      parsedVersions: parsedVersions,
    );
  }
}

/// Thanks Gemini.
///
/// Parses the latest version number from a changelog text.
///
/// It iterates through the lines of the [changelogContent] and uses a
/// regular expression to find the first line that likely indicates a
/// version number based on common patterns (e.g., "Version X.Y.Z", "vX.Y.Z",
/// "X.Y.Z (Date)", "## Version X.Y").
///
/// Args:
///   changelogContent: The full text content of the changelog file.
///
/// Returns:
///   The first potential version string found (e.g., "2.1.0", "1.0.g", "0.18"),
///   or null if no likely version number is found near the top according
///   to the patterns.
String? parseVersionFromChangelog(String changelogContent) {
  final versionRegex = RegExp(
    //  ^\s*                              anchor + leading whitespace
    //  (?:(?:##\s*)?version|>>>)?       optional "Version"/"## Version" or ">>>"
    //  \s*(?:[vV])?                     optional "v" or "V"
    //  \s*([0-9]+(?:\.[0-9A-Za-z]+)*)   capture 1+ segments of digits/alphanum
    //  (?=\s*(?:[:(]|$))                lookahead for ":" or "(" or end
    r'^\s*(?:(?:##\s*)?version|>>>)?\s*(?:[vV])?\s*([0-9]+(?:\.[0-9A-Za-z]+)*)(?=\s*(?:[:\(]|$))',
    caseSensitive: false,
  );

  for (final rawLine in LineSplitter.split(changelogContent)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final match = versionRegex.firstMatch(line);
    if (match != null) {
      final version = match.group(1);
      if (version != null && version.isNotEmpty) {
        return version;
      }
    }
  }

  return null;
}

@MappableClass()
class ModChangelog with ModChangelogMappable {
  final String modId;
  final String smolId;
  final String changelog;
  final String url;
  final List<ChangelogVersion>? parsedVersions;

  ModChangelog({
    required this.modId,
    required this.smolId,
    required this.changelog,
    required this.url,
    this.parsedVersions,
  });

  @override
  String toString() => changelog;
}

@MappableClass()
class ChangelogVersion with ChangelogVersionMappable {
  final Version version;
  final String changelog;

  ChangelogVersion(this.version, this.changelog);
}
