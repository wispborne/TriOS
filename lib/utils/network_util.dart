import 'dart:convert';

import 'package:trios/utils/logging.dart';
import 'package:http/http.dart' as http;

class NetworkUtils {
  static Future<Release?> getLatestRelease(Uri githubLatestReleaseUrl) async {
    try {
      final response = await http.get(
        githubLatestReleaseUrl,
        headers: {
          'Accept': 'application/vnd.github+json',
        },
      );

      var message =
          'Request: ${response.request}. Headers: ${response.request?.headers}.\nRequest Status: ${response.statusCode}. Body: ${response.body}';

      if (response.statusCode == 200) {
        // Fimber.v(message);
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
          final release = Release.fromJson(jsonData);

          return release;
        }
      } else {
        Fimber.w(message);
      }
    } catch (error, st) {
      Fimber.w('Error fetching release data: $error', ex: error, stacktrace: st);
    }

    return null;
  }
}

class Release {
  final String url;
  final String assetsUrl;
  final String uploadUrl;
  final String htmlUrl;
  final int id;

  // final Author author;
  // final String nodeId;
  final String tagName;
  // final String targetCommitish;
  final String name;
  final bool draft;
  final bool prerelease;
  final DateTime createdAt;
  final DateTime publishedAt;
  final List<Asset> assets;
  // final String tarballUrl;
  // final String zipballUrl;
  final String body;

  Release({
    required this.url,
    required this.assetsUrl,
    required this.uploadUrl,
    required this.htmlUrl,
    required this.id,
    // required this.nodeId,
    required this.tagName,
    // required this.targetCommitish,
    required this.name,
    required this.draft,
    required this.prerelease,
    required this.createdAt,
    required this.publishedAt,
    required this.assets,
    // required this.tarballUrl,
    // required this.zipballUrl,
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
      // nodeId: json['node_id'],
      tagName: json['tag_name'],
      // targetCommitish: json['target_commitish'],
      name: json['name'],
      draft: json['draft'],
      prerelease: json['prerelease'],
      createdAt: DateTime.parse(json['created_at']),
      publishedAt: DateTime.parse(json['published_at']),
      assets: (json['assets'] as List).map((e) => Asset.fromJson(e)).toList(),
      // tarballUrl: json['tarball_url'],
      // zipballUrl: json['zipball_url'],
      body: json['body'],
    );
  }
}

class Asset {
  final String url;
  final int id;
  // final String nodeId;
  final String name;
  // final String label;
  final String contentType;
  // final String state;
  final int size;
  // final int downloadCount;
  // final DateTime createdAt;
  // final DateTime updatedAt;
  final String browserDownloadUrl;

  Asset({
    required this.url,
    required this.id,
    // required this.nodeId,
    required this.name,
    // required this.label,
    required this.contentType,
    // required this.state,
    required this.size,
    // required this.downloadCount,
    // required this.createdAt,
    // required this.updatedAt,
    required this.browserDownloadUrl,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      url: json['url'],
      id: json['id'],
      // nodeId: json['node_id'],
      name: json['name'],
      // label: json['label'],
      // uploader: Uploader.fromJson(json['uploader']),
      contentType: json['content_type'],
      // state: json['state'],
      size: json['size'],
      // downloadCount: json['download_count'],
      // createdAt: DateTime.parse(json['created_at']),
      // updatedAt: DateTime.parse(json['updated_at']),
      browserDownloadUrl: json['browser_download_url'],
    );
  }
}

// Placeholder class (Need more data to model fully)
class Uploader {
  // Update when you provide the structure of "uploader"
  Uploader.fromJson(Map<String, dynamic> json);
}
