import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:trios/utils/logging.dart';

class NetworkUtils {
  /// Fetch a single release (the latest that meets [includePrereleases] criteria).
  /// This returns only the **first** matching release from the response.
  static Future<Release?> getRelease(
    Uri githubReleasesUrl, {
    required bool includePrereleases,
  }) async {
    return (await getAllReleases(
      githubReleasesUrl,
      includePrereleases: includePrereleases,
      limit: 1,
    ))?.firstOrNull;
  }

  /// Fetch **all** TriOS releases from GitHub's Releases API (with optional limit).
  ///
  /// - [includePrereleases]: Whether to include prerelease versions or not.
  /// - [limit]: If provided, returns at most this many releases (starting from newest).
  ///
  /// Example usage:
  /// ```dart
  ///   final releases = await NetworkUtils.getAllReleases(
  ///     Uri.parse('https://api.github.com/repos/wispborne/TriOS/releases'),
  ///     includePrereleases: true,
  ///     limit: 5,
  ///   );
  ///   releases.forEach((r) => print(r.tagName));
  /// ```
  static Future<List<Release>?> getAllReleases(
    Uri githubReleasesUrl, {
    bool includePrereleases = false,
    int? limit,
  }) async {
    try {
      final response = await http.get(
        githubReleasesUrl,
        headers: {'Accept': 'application/vnd.github+json'},
      );

      var message =
          'Request: ${response.request}. Headers: ${response.request?.headers}.\n'
          'Request Status: ${response.statusCode}. Body: ${response.body}';

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData.isNotEmpty) {
          // Parse all releases
          final allReleases = <Release>[];
          for (var releaseJson in jsonData) {
            var release = Release.fromJson(releaseJson);
            // Skip prerelease if not requested
            if (includePrereleases || !release.prerelease) {
              allReleases.add(release);
            }
          }

          // Sort by published date descending, just to be safe (GitHub usually returns newest first).
          allReleases.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

          // If a limit is specified, return only that many
          if (limit != null && limit > 0 && allReleases.length > limit) {
            return allReleases.take(limit).toList();
          }

          return allReleases;
        }
      } else {
        Fimber.w(message);
      }
    } catch (error, st) {
      Fimber.w('Error fetching releases: $error', ex: error, stacktrace: st);
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

  final String tagName;
  final String name;
  final bool draft;
  final bool prerelease;
  final DateTime createdAt;
  final DateTime publishedAt;
  final List<Asset> assets;
  final String body;

  Release({
    required this.url,
    required this.assetsUrl,
    required this.uploadUrl,
    required this.htmlUrl,
    required this.id,
    required this.tagName,
    required this.name,
    required this.draft,
    required this.prerelease,
    required this.createdAt,
    required this.publishedAt,
    required this.assets,
    required this.body,
  });

  factory Release.fromJson(Map<String, dynamic> json) {
    return Release(
      url: json['url'],
      assetsUrl: json['assets_url'],
      uploadUrl: json['upload_url'],
      htmlUrl: json['html_url'],
      id: json['id'],
      tagName: json['tag_name'],
      name: json['name'],
      draft: json['draft'],
      prerelease: json['prerelease'],
      createdAt: DateTime.parse(json['created_at']),
      publishedAt: DateTime.parse(json['published_at']),
      assets:
          (json['assets'] as List)
              .map((e) => Asset.fromJson(e as Map<String, dynamic>))
              .toList(),
      body: json['body'],
    );
  }
}

class Asset {
  final String url;
  final int id;
  final String name;
  final String contentType;
  final int size;
  final String browserDownloadUrl;

  Asset({
    required this.url,
    required this.id,
    required this.name,
    required this.contentType,
    required this.size,
    required this.browserDownloadUrl,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      url: json['url'],
      id: json['id'],
      name: json['name'],
      contentType: json['content_type'],
      size: json['size'],
      browserDownloadUrl: json['browser_download_url'],
    );
  }
}

// Placeholder class (Need more data to model fully)
class Uploader {
  // Update when you provide the structure of "uploader"
  Uploader.fromJson(Map<String, dynamic> json);
}
