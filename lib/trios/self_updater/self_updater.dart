import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:trios/trios/self_updater/script_generator.dart';
import 'package:trios/utils/extensions.dart';

import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/main.dart';
import 'package:trios/utils/util.dart';

class SelfUpdateInfo {
  final String version;
  final String url;
  final String releaseNote;

  SelfUpdateInfo({required this.version, required this.url, required this.releaseNote});

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
  static const String githubLatestRelease = "$githubBase/repos/wispborne/trios/releases/latest";

  static bool hasNewVersion(Release latestRelease, {String currentVersion = version}) {
    try {
      final latestVersion = Version.parse(latestRelease.tagName);
      return Version.parse(currentVersion).compareTo(latestVersion) < 0;
    } catch (error) {
      Fimber.w('Error parsing version: $error');
    }

    return false;
  }

  static Future<void> update(Release release,
      {bool exitSelfAfter = true, void Function(int, int)? downloadProgress}) async {
    final updateWorkingDir = Directory.systemTemp.createTempSync('trios_update').absolute.normalize;

    // Download the release asset.
    final downloadFile = await downloadRelease(release, updateWorkingDir, onProgress: (bytesReceived, contentLength) {
      Fimber.v('Downloaded: ${bytesReceived.bytesAsReadableMB()} / ${contentLength.bytesAsReadableMB()}');
      downloadProgress?.call(bytesReceived, contentLength);
    });

    Fimber.i('Downloaded update file: ${downloadFile.path}');
    final extractedDir = updateWorkingDir;
    // Extract the downloaded update archive.
    final extractedFiles = await LibArchive().extractEntriesInArchive(downloadFile, extractedDir.path);

    if (extractedFiles.isNotEmpty) {
      downloadFile.deleteSync(); // Clean up the .zip file, we don't want to end up moving it in as part of the update.
      Fimber.i('Extracted ${extractedFiles.length} files in the ${release.tagName} release to ${extractedDir.path}');

      // Generate the update script and write it to a file.
      final scriptDest = kDebugMode ? Directory(p.join(Directory.current.path, "update-test")) : Directory.current;
      final updateScriptFile = await ScriptGenerator.writeUpdateScriptToFileSimple(updateWorkingDir, scriptDest);
      Fimber.i("Wrote update script to: ${updateScriptFile.path}");

      Fimber.i('Running update script: ${updateScriptFile.path}');

      // Run the update script.
      // Do NOT wait for it. We want to exit immediately after starting the update script.
      if (Platform.isWindows) {
        await Process.start("start", ["", updateScriptFile.absolute.normalize.path],
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
    try {
      final response = await http.get(
        Uri.parse(githubLatestRelease),
        headers: {
          'Accept': 'application/vnd.github+json',
        },
      );

      var message =
          'Request: ${response.request}. Headers: ${response.request?.headers}.\nRequest Status: ${response.statusCode}. Body: ${response.body}';

      if (response.statusCode == 200) {
        Fimber.i(message);
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        /*
        * "url" -> "https://api.github.com/repos/wispborne/TriOS/releases/142440421"
        * "assets_url" -> "https://api.github.com/repos/wispborne/TriOS/releases/142440421/assets"
        * "upload_url" -> "https://uploads.github.com/repos/wispborne/TriOS/releases/142440421/assets{?name,label}"
        * "html_url" -> "https://github.com/wispborne/TriOS/releases/tag/9"
        * "id" -> 142440421
        * "author" -> [_Map]
        * "node_id" -> "RE_kwDOLQl5mM4IfXfl"
        * "tag_name" -> "9"
        * "target_commitish" -> "4f6880c6c0c5cc50f02b5fcee3276b55fb8a8c92"
        * "name" -> "Build 9"
        * "draft" -> false
        * "prerelease" -> false
        * "created_at" -> "2024-02-17T08:08:42Z"
        * "published_at" -> "2024-02-17T08:14:43Z"
        * "assets" -> [_GrowableList]
        * "tarball_url" -> "https://api.github.com/repos/wispborne/TriOS/tarball/9"
        * "zipball_url" -> "https://api.github.com/repos/wispborne/TriOS/zipball/9"
        * "body" -> "setting as a non-prerelease to test self-update"
         */
        if (jsonData.isNotEmpty) {
          final latestRelease = jsonData['tag_name'] as String;
          final release = Release.fromJson(jsonData);

          return release;
        }
      } else {
        Fimber.w(message);
      }
    } catch (error) {
      Fimber.w('Error fetching release data: $error');
    }

    return null;
  }

  /// Downloads the release asset for the given platform.
  /// If [platform] is not provided, it will use the current platform.
  /// Returns the path of the downloaded file.
  static Future<File> downloadRelease(Release release, Directory destDir,
      {String? platform, ProgressCallback? onProgress}) async {
    final platformToUse = platform ?? Platform.operatingSystem;
    final assetNameForPlatform = switch (platformToUse) {
      "windows" => "windows",
      "linux" => "linux",
      "macos" => "macos",
      _ => throw UnsupportedError("Unsupported platform: $platformToUse"),
    };

    final downloadLink = release.assets
        .firstWhereOrNull((element) => element.name.toLowerCase().contains(assetNameForPlatform))
        ?.browserDownloadUrl;

    if (downloadLink == null) {
      throw Exception("No download link found for platform: $assetNameForPlatform");
    }

    Fimber.i("Download link: $downloadLink");

    final downloadResult = await downloadFile(downloadLink, destDir.absolute.path, onProgress: onProgress);
    return downloadResult;
  }
}

class Release {
  final String url;
  final String assetsUrl;
  final String uploadUrl;
  final String htmlUrl;
  final int id;

  // final Author author;
  final String nodeId;
  final String tagName;
  final String targetCommitish;
  final String name;
  final bool draft;
  final bool prerelease;
  final DateTime createdAt;
  final DateTime publishedAt;
  final List<Asset> assets;
  final String tarballUrl;
  final String zipballUrl;
  final String body;

  Release({
    required this.url,
    required this.assetsUrl,
    required this.uploadUrl,
    required this.htmlUrl,
    required this.id,
    required this.nodeId,
    required this.tagName,
    required this.targetCommitish,
    required this.name,
    required this.draft,
    required this.prerelease,
    required this.createdAt,
    required this.publishedAt,
    required this.assets,
    required this.tarballUrl,
    required this.zipballUrl,
    required this.body,
  });

  // To convert json into the data class
  factory Release.fromJson(Map<String, dynamic> json) {
    return Release(
      url: json['url'],
      assetsUrl: json['assets_url'],
      uploadUrl: json['upload_url'],
      htmlUrl: json['html_url'],
      id: json['id'],
      nodeId: json['node_id'],
      tagName: json['tag_name'],
      targetCommitish: json['target_commitish'],
      name: json['name'],
      draft: json['draft'],
      prerelease: json['prerelease'],
      createdAt: DateTime.parse(json['created_at']),
      publishedAt: DateTime.parse(json['published_at']),
      assets: (json['assets'] as List).map((e) => Asset.fromJson(e)).toList(),
      tarballUrl: json['tarball_url'],
      zipballUrl: json['zipball_url'],
      body: json['body'],
    );
  }
}

class Asset {
  final String url;
  final int id;
  final String nodeId;
  final String name;
  final String label;
  final Uploader uploader;
  final String contentType;
  final String state;
  final int size;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String browserDownloadUrl;

  Asset({
    required this.url,
    required this.id,
    required this.nodeId,
    required this.name,
    required this.label,
    required this.uploader,
    required this.contentType,
    required this.state,
    required this.size,
    required this.downloadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.browserDownloadUrl,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      url: json['url'],
      id: json['id'],
      nodeId: json['node_id'],
      name: json['name'],
      label: json['label'],
      uploader: Uploader.fromJson(json['uploader']),
      contentType: json['content_type'],
      state: json['state'],
      size: json['size'],
      downloadCount: json['download_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      browserDownloadUrl: json['browser_download_url'],
    );
  }
}

// Placeholder class (Need more data to model fully)
class Uploader {
  // Update when you provide the structure of "uploader"
  Uploader.fromJson(Map<String, dynamic> json);
}
