import 'dart:convert';

import 'package:fimber/fimber.dart';
import 'package:http/http.dart' as http;

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
}

class SelfUpdater {
  static const String githubBase = "https://api.github.com";
  static const String githubLatestRelease =
      "$githubBase/repos/wispborne/smol/releases/latest";

  static Future<Map<String, dynamic>?> checkForUpdate() async {
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
        final jsonData = jsonDecode(response.body) as List<dynamic>;
        if (jsonData.isNotEmpty) {
          final latestRelease = jsonData as Map<String, dynamic>;

          return latestRelease;
        }
      } else {
        Fimber.w(message);
      }
    } catch (error) {
      Fimber.w('Error fetching release data: $error');
    }

    return null;
  }
}
