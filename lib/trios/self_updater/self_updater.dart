import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/trios/self_updater/script_generator.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/network_util.dart';
import 'package:trios/utils/util.dart';

import '../constants.dart';

class SelfUpdateInfo {
  final String version;
  final String url;
  final String releaseNote;

  SelfUpdateInfo(
      {required this.version, required this.url, required this.releaseNote});

  factory SelfUpdateInfo.fromJson(Map<String, dynamic> json) {
    return SelfUpdateInfo(
      version: json['version'],
      url: json['url'],
      releaseNote: json['releaseNote'],
    );
  }

  @override
  String toString() {
    return 'SelfUpdateInfo{version: $version, url: $url, releaseNote: $releaseNote}';
  }
}

class SelfUpdater {
  static const String githubBase = "https://api.github.com";
  static const String githubLatestRelease =
      "$githubBase/repos/wispborne/trios/releases/latest";

  static bool hasNewVersion(Release latestRelease,
      {String currentVersion = Constants.version}) {
    try {
      final latestVersion = Version.parse(latestRelease.tagName);
      return Version.parse(currentVersion).compareTo(latestVersion) < 0;
    } catch (error) {
      Fimber.w('Error parsing version: $error');
    }

    return false;
  }

  static Future<void> update(Release release,
      {bool exitSelfAfter = true,
      void Function(int, int)? downloadProgress}) async {
    final updateWorkingDir =
        Directory.systemTemp.createTempSync('trios_update').absolute.normalize;

    // Download the release asset.
    final downloadFile = await downloadRelease(release, updateWorkingDir,
        onProgress: (bytesReceived, contentLength) {
      Fimber.v(
          'Downloaded: ${bytesReceived.bytesAsReadableMB()} / ${contentLength.bytesAsReadableMB()}');
      downloadProgress?.call(bytesReceived, contentLength);
    });

    Fimber.i('Downloaded update file: ${downloadFile.path}');
    final extractedDir = updateWorkingDir;
    // Extract the downloaded update archive.
    final extractedFiles = await LibArchive()
        .extractEntriesInArchive(downloadFile, extractedDir.path);

    if (extractedFiles.isNotEmpty) {
      downloadFile
          .deleteSync(); // Clean up the .zip file, we don't want to end up moving it in as part of the update.
      Fimber.i(
          'Extracted ${extractedFiles.length} files in the ${release.tagName} release to ${extractedDir.path}');

      // Generate the update script and write it to a file.
      final scriptDest = kDebugMode
          ? Directory(p.join(Directory.current.path, "update-trios"))
          : Directory.current;
      // If there's a subfolder, use the contents of the subfolder as the files to update (added in 0.0.48).
      final filesToUpdateFromPath = updateWorkingDir.listSync().length == 1
          ? updateWorkingDir.listSync()[0].toDirectory()
          : updateWorkingDir;
      final updateScriptFile =
          await ScriptGenerator.writeUpdateScriptToFileSimple(
              filesToUpdateFromPath, scriptDest);
      Fimber.i("Wrote update script to: ${updateScriptFile.path}");

      Fimber.i('Running update script: ${updateScriptFile.path}');

      // Run the update script.
      // Do NOT wait for it. We want to exit immediately after starting the update script.
      if (Platform.isWindows) {
        await Process.start(
            "start", ["", updateScriptFile.absolute.normalize.path],
            runInShell: true, mode: ProcessStartMode.detached);
      } else {
        await Process.start('', [updateScriptFile.absolute.normalize.path, "&"],
            runInShell: true, mode: ProcessStartMode.detached);
      }

      if (exitSelfAfter) {
        Fimber.i('Exiting self while update runs to avoid locking files.');
        exit(0);
      }
    }
  }

  static Future<Release?> getLatestRelease() async {
    return await NetworkUtils.getLatestRelease(Uri.parse(githubLatestRelease));
  }

  /// Downloads the release asset for the given platform.
  /// If [platform] is not provided, it will use the current platform.
  /// Returns the path of the downloaded file.
  static Future<File> downloadRelease(Release release, Directory destDir,
      {String? platform, ProgressCallback? onProgress}) async {
    final platformToUse = platform ?? Platform.operatingSystem;

    // Uses the file with the platform name somewhere in it.
    final assetNameForPlatform = switch (platformToUse) {
      "windows" => "windows",
      "linux" => "linux",
      "macos" => "macos",
      _ => throw UnsupportedError("Unsupported platform: $platformToUse"),
    };

    final downloadLink = release.assets
        .firstWhereOrNull((element) =>
            element.name.toLowerCase().contains(assetNameForPlatform))
        ?.browserDownloadUrl;

    if (downloadLink == null) {
      throw Exception(
          "No download link found for platform: $assetNameForPlatform");
    }

    Fimber.i("Download link: $downloadLink");

    final downloadResult =
        await downloadFile(downloadLink, destDir, null, onProgress: onProgress);
    return downloadResult;
  }
}
