import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trios/utils/extensions.dart';

import '../models/mod_variant.dart';
import '../models/version_checker_info.dart';
import '../trios/app_state.dart';

/// String is the smolId
final versionCheckResults = FutureProvider<Map<String, VersionCheckerInfo>>((ref) async {
  final mods = ref.read(AppState.modVariants);
  if (mods.value.isNullOrEmpty()) return {};

  var entries = mods.value!.map((mod) async => MapEntry(mod.smolId, (await checkRemoteVersion(mod))!));
  return Map.fromEntries(await Future.wait(entries));
});

Future<VersionCheckerInfo?> checkRemoteVersion(ModVariant modVariant) async {
  var remoteVersionUrl = modVariant.versionCheckerInfo?.masterVersionFile;
  if (remoteVersionUrl == null) return null;
  final fixedUrl = fixUrl(remoteVersionUrl);

  try {
    final response = await http.get(Uri.parse(fixedUrl));
    final body = response.body;
    if (response.statusCode == 200) {
      return VersionCheckerInfo.fromJson(body.fixJsonToMap());
    }
  } catch (e, st) {
    Fimber.d("Error fetching remote version info for ${modVariant.modInfo.id}: $e\n$st");
  }

  return null;
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
