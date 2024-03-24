import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trios/utils/extensions.dart';

import '../models/mod_variant.dart';
import '../models/version_checker_info.dart';
import '../trios/app_state.dart';

/// String is the smolId
final versionCheckResults =
    AsyncNotifierProvider<_VersionCheckerNotifier, Map<String, VersionCheckResult>>(_VersionCheckerNotifier.new);

class _VersionCheckerNotifier extends AsyncNotifier<Map<String, VersionCheckResult>> {
  @override
  Map<String, VersionCheckResult> build() {
    refresh();
    return {};
  }

  // Executes async, updates state every time a Version Check http request is completed.
  void refresh() {
    state = AsyncValue.data({});
    final _versionCheckResultsCache = state.value ?? {}; // TODO change to just state

    final mods = ref.watch(AppState.modVariants);
    if (mods.value.isNullOrEmpty()) return;

    // TODO refresh cache button
    try {
      final entries = mods.value!.map((mod) {
        if (_versionCheckResultsCache[mod.smolId] != null) {
          return Future.value(_versionCheckResultsCache[mod.smolId]!);
        } else {
          return checkRemoteVersion(mod);
        }
      }).forEach((futResult) => futResult.then((result) {
            state = AsyncValue.data(state.value!..update(result.smolId, (value) => result, ifAbsent: () => result));
          }));
    } catch (e, st) {
      Fimber.e("Error fetching remote version info: $e\n$st");
    }
  }
}

// Map<String, VersionCheckResult> _versionCheckResultsCache = {};

class VersionCheckResult {
  final String smolId;
  final VersionCheckerInfo? remoteVersion;
  final Object? error;

  VersionCheckResult(this.smolId, this.remoteVersion, this.error);
}

int? compareLocalAndRemoteVersions(VersionCheckerInfo? local, VersionCheckResult? remote) {
  if (local == null || remote == null) return 0;
  return local.modVersion?.compareTo(remote.remoteVersion?.modVersion);
}

Future<VersionCheckResult> checkRemoteVersion(ModVariant modVariant) async {
  var remoteVersionUrl = modVariant.versionCheckerInfo?.masterVersionFile;
  if (remoteVersionUrl == null) {
    return VersionCheckResult(modVariant.smolId, null, Exception("No remote version url for ${modVariant.modInfo.id}"));
  }
  final fixedUrl = fixUrl(remoteVersionUrl);

  try {
    final response = await http.get(
      Uri.parse(fixedUrl),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    final body = response.body;
    if (response.statusCode == 200) {
      return VersionCheckResult(modVariant.smolId, VersionCheckerInfo.fromJson(body.fixJsonToMap()), null);
    } else {
      throw Exception(
          "Failed to fetch remote version info for ${modVariant.modInfo.id}: ${response.statusCode} - $body");
    }
  } catch (e, st) {
    Fimber.d("Error fetching remote version info for ${modVariant.modInfo.id}: $e\n$st");
    return VersionCheckResult(modVariant.smolId, null, e);
  }
}

/// User linked to the page for their version file on github instead of to the raw file.
final _githubFilePageRegex = RegExp(r"https://github.com/.+/blob/.+/assets/.+.version", caseSensitive: false);

/// User set dl=0 instead of dl=1 when hosted on dropbox.
final _dropboxDlPageRegex = RegExp("""https://www.dropbox.com/s/.+/.+.version\?dl=0""", caseSensitive: false);

//     private fun fixUrl(urlString: String): String {
//         return when {
//             urlString.matches(githubFilePageRegex) -> {
//                 urlString
//                     .replace("github.com", "raw.githubusercontent.com", ignoreCase = true)
//                     .replace("blob/", "", ignoreCase = true)
//             }
//
//             urlString.matches(dropboxDlPageRegex) -> {
//                 urlString
//                     .replace("dl=0", "dl=1", ignoreCase = true)
//             }
//
//             else -> urlString
//         }
//             .also {
//                 if (urlString != it) {
//                     Timber.i { "Fixed Version Checker url from '$urlString' to '$it'." }
//                 }
//             }
//     }

String fixUrl(String urlString) {
  if (_githubFilePageRegex.hasMatch(urlString)) {
    return urlString.replaceAll("github.com", "raw.githubusercontent.com").replaceAll("blob/", "");
  } else if (_dropboxDlPageRegex.hasMatch(urlString)) {
    return urlString.replaceAll("dl=0", "dl=1");
  } else {
    return urlString;
  }
}
