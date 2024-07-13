import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';

import '../mod_manager/version_checker.dart';
import '../models/version_checker_info.dart';

class Changelogs extends ConsumerStatefulWidget {
  final VersionCheckerInfo? localVersionCheck;
  final VersionCheckResult? remoteVersionCheck;

  const Changelogs(this.localVersionCheck, this.remoteVersionCheck,
      {super.key});

  @override
  ConsumerState createState() => _ChangelogsState();
}

class _ChangelogsState extends ConsumerState<Changelogs> {
  String changelogUrl = "";
  String changelog = "";
  bool isLoading = false;
  static final Map<String, String> _changelogCache = {};

  @override
  void initState() {
    super.initState();

    //  val changelogUrl = onlineVersionInfo?.changelogUrl?.nullIfBlank()  ?: mod.findHighestVersion?.versionCheckerInfo?.changelogUrl?.nullIfBlank()
    changelogUrl = widget.remoteVersionCheck?.remoteVersion?.changelogURL ??
        widget.localVersionCheck?.changelogURL ??
        "";
    if (changelogUrl.isNotEmpty) {
      if (_changelogCache.containsKey(changelogUrl)) {
        changelog = _changelogCache[changelogUrl]!;
        return;
      }

      isLoading = true;
      Dio().get(changelogUrl).then((value) {
        changelog = value.data.toString();
        _changelogCache[changelogUrl] = changelog;
        isLoading = false;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (changelogUrl.isEmpty) {
      return Container();
    }

    return !isLoading
        ? MarkdownBody(data: changelog)
        : const Row(
            children: [
              Text("Loading..."),
              CircularProgressIndicator(),
            ],
          );
  }
}
