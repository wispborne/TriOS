import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:stringr/stringr.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/network_util.dart';
import 'package:trios/utils/util.dart';

import '../../models/download_progress.dart';

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

class SelfUpdater extends AsyncNotifier<DownloadProgress?> {
  static const String githubBase = "https://api.github.com";
  static const String githubLatestRelease =
      "$githubBase/repos/wispborne/trios/releases";
  static const String oldFileSuffix = ".delete-me";

  @override
  Future<DownloadProgress?> build() async {
    return null;
  }

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

  Future<void> updateSelf(Release release, {bool exitSelfAfter = true}) async {
    final updateWorkingDir =
        Directory.systemTemp.createTempSync('trios_update').absolute.normalize;

    // Download the release asset.
    final downloadFile = await downloadRelease(
      release,
      updateWorkingDir,
    );

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
      // If there's a subfolder, use the contents of the subfolder as the files to update (added in 0.0.48).
      final directoryWithNewVersionFiles =
          updateWorkingDir.listSync().length == 1
              ? updateWorkingDir.listSync()[0].toDirectory()
              : updateWorkingDir;

      try {
        await replaceSelf(directoryWithNewVersionFiles);
      } catch (error) {
        Fimber.w('Error self-updating something. YOLOing.', ex: error);
      }
      if (currentPlatform == TargetPlatform.windows) {
        await Process.start(
          'cmd',
          ['/c', "start", "", Platform.resolvedExecutable],
          runInShell: true,
          mode: ProcessStartMode.detached,
        );
      } else if (currentPlatform == TargetPlatform.linux) {
        await Process.start(
          'nohup',
          [Platform.resolvedExecutable],
          runInShell: true,
          mode: ProcessStartMode.detached,
        );
      } else if (currentPlatform == TargetPlatform.macOS) {
        // Doesn't work!
        await Process.start(
          'open',
          ['-n', currentMacOSAppPath.path],
          runInShell: true,
          mode: ProcessStartMode.detached,
        );
      }
      if (exitSelfAfter) {
        await Future.delayed(const Duration(milliseconds: 500));
        Fimber.i(
            'Exiting old version of self, new should have already started.');
        exit(0);
      }
    }
  }

  /// Replaces all files in the current working directory with files that have the same relative path
  /// in the given source directory.
  Future<void> replaceSelf(Directory sourceDirectory) async {
    final allNewFiles =
        sourceDirectory.listSync(recursive: true, followLinks: true);
    final currentDir = currentPlatform != TargetPlatform.macOS
        ? currentDirectory
        : currentMacOSAppPath;
    final jobs = <Future<void>>[];

    for (final newFile in allNewFiles) {
      if (newFile.isFile()) {
        final newFileRelative =
            newFile.toFile().relativeTo(sourceDirectory).toFile();
        final fileToReplace =
            File(p.join(currentDir.path, newFileRelative.path));
        jobs.add(updateLockedFileInPlace(
            newFile.toFile(), fileToReplace, oldFileSuffix));
      }
    }

    await Future.wait(jobs);
  }

  /// Updates or replaces a locked file in place.
  ///
  /// Depending on the destination file's existence and type:
  /// - If the file doesn't exist, it copies the source file to the destination.
  /// - If it's a `.so` file, it replaces the destination's contents with the source's contents.
  /// - Otherwise, it renames the destination file by appending the given suffix and then copies the source file to the destination.
  ///
  /// Parameters:
  /// - [sourceFile]: The file to copy or use for content replacement.
  /// - [destFile]: The target file to update or replace.
  /// - [oldFileSuffix]: Suffix for renaming the existing file.
  ///
  /// Returns:
  /// - A [Future] that completes when the operation is done.
  Future<void> updateLockedFileInPlace(
    File sourceFile,
    File destFile,
    String oldFileSuffix,
  ) async {
    final sourceExt = sourceFile.extension;
    final doesDestExist = destFile.existsSync();

    // Create parent directories if they don't exist.
    if (!doesDestExist && !destFile.parent.existsSync()) {
      destFile.parent.createSync(recursive: true);
    }

    if (!doesDestExist) {
      // Nothing to replace, just copy the file.
      Fimber.d("Copying new file: ${sourceFile.path} to ${destFile.path}");
      await sourceFile.copy(destFile.path);
    } else if (currentPlatform == TargetPlatform.windows &&
        sourceExt == ".so") {
      // Can't rename .so files on Windows, but we can replace their content.
      Fimber.d(
          "Replacing contents of .so file: ${destFile.path} with that of ${sourceFile.path}");
      await destFile.writeAsBytes(await sourceFile.readAsBytes());
    } else {
      // Can't replace content of other locked files, but can rename them.
      // Can always rename on Linux.
      var oldFile = File(destFile.path + oldFileSuffix);
      Fimber.d("Renaming locked file: ${destFile.path} to ${oldFile.path}, "
          "and copying new file: ${sourceFile.path} to ${destFile.path}");
      if (oldFile.existsSync()) {
        if (await oldFile.isWritable()) {
          Fimber.d("Old file already exists, deleting: ${oldFile.path}");
          oldFile.deleteSync();
        }
      }

      await destFile.rename(oldFile.path);
      await sourceFile.copy(destFile.path);
    }
  }

  static Future<void> cleanUpOldUpdateFiles() async {
    final filesInCurrentDir = currentDirectory
        .listSync(recursive: true)
        .where((element) => element.path.endsWith(oldFileSuffix))
        .toList();
    for (final file in filesInCurrentDir) {
      if (file is File) {
        try {
          await file.delete();
        } catch (error) {
          Fimber.w('Error deleting old file: ${file.path}', ex: error);
        }
      }
    }

    Fimber.i('Cleaned up ${filesInCurrentDir.length} old update files.');
  }

  Future<void> runSelfUpdateScript(File updateScriptFile) async {
    // Run the update script.
    // Do NOT wait for it. We want to exit immediately after starting the update script.
    runZonedGuarded(() async {
      if (currentPlatform == TargetPlatform.linux) {
        Fimber.i("Making ${updateScriptFile.path} executable first.");
        Process.runSync(
            'chmod', ['+x', updateScriptFile.absolute.normalize.path],
            runInShell: true);
        Fimber.i(
            'Running update script: ${updateScriptFile.absolute.path} (exists? ${updateScriptFile.existsSync()})');
        await OpenFilex.open(updateScriptFile.parent.path,
            linuxDesktopName: getLinuxDesktopEnvironment().lowerCase());
        await Process.start(updateScriptFile.absolute.normalize.path, ["&"],
            runInShell: true, mode: ProcessStartMode.detached);
      } else {
        Fimber.i(
            'Running update script: ${updateScriptFile.absolute.path} (exists? ${updateScriptFile.existsSync()})');
        await Process.start('', [updateScriptFile.absolute.normalize.path, "&"],
            runInShell: true, mode: ProcessStartMode.detached);
      }
    }, (error, stackTrace) {
      Fimber.w('Error running update script.',
          ex: error, stacktrace: stackTrace);
    });
  }

  String getLinuxDesktopEnvironment() {
    final env = Platform.environment;
    if (env.containsKey("XDG_CURRENT_DESKTOP")) {
      return env["XDG_CURRENT_DESKTOP"] ?? "Unknown";
    } else if (env.containsKey("DESKTOP_SESSION")) {
      return env["DESKTOP_SESSION"] ?? "Unknown";
    } else if (env.containsKey("GENOME_DESKTOP_SESSION_ID")) {
      return "GNOME";
    } else if (env.containsKey("KDE_FULL_SESSION")) {
      return "KDE";
    } else {
      return "UNKNOWN";
    }
  }

  /// Fetches the latest release from the GitHub API.
  /// If [includePrereleases] is true, it will include prereleases. If null, uses the user's setting.
  Future<Release?> getLatestRelease({bool? includePrereleases}) async {
    final includePrereleasesToUse = includePrereleases ??
        ref.read(appSettings.select((s) => s.updateToPrereleases)) ??
        false;
    return await NetworkUtils.getRelease(Uri.parse(githubLatestRelease),
        includePrereleases: includePrereleasesToUse);
  }

  /// Downloads the release asset for the given platform.
  /// If [platform] is not provided, it will use the current platform.
  /// Returns the path of the downloaded file.
  Future<File> downloadRelease(Release release, Directory destDir,
      {String? platform}) async {
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

    final downloadResult = await downloadFile(downloadLink, destDir, null,
        onProgress: (bytesReceived, contentLength) {
      Fimber.v(() =>
          "Downloaded: ${bytesReceived.bytesAsReadableMB()} / ${contentLength.bytesAsReadableMB()}");
      state = AsyncData(DownloadProgress(bytesReceived, contentLength,
          isIndeterminate: false));
    });

    return downloadResult;
  }
}
