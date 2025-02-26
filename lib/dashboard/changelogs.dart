import 'dart:convert';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/providers.dart';
import 'package:trios/utils/logging.dart';

import '../mod_manager/version_checker.dart';
import '../models/version_checker_info.dart';

class Changelogs extends ConsumerStatefulWidget {
  final VersionCheckerInfo? localVersionCheck;
  final RemoteVersionCheckResult? remoteVersionCheck;
  final bool withTitle;

  const Changelogs(
    this.localVersionCheck,
    this.remoteVersionCheck, {
    super.key,
    this.withTitle = true,
  });

  @override
  ConsumerState createState() => _ChangelogsState();

  static String? getChangelogUrl(
    VersionCheckerInfo? localVersionCheckerInfo,
    RemoteVersionCheckResult? remoteVersionCheck,
  ) {
    return remoteVersionCheck?.remoteVersion?.changelogURL ??
        localVersionCheckerInfo?.changelogURL;
  }
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
    changelogUrl =
        Changelogs.getChangelogUrl(
          widget.localVersionCheck,
          widget.remoteVersionCheck,
        ) ??
        "";
    if (changelogUrl.isNotEmpty) {
      if (_changelogCache.containsKey(changelogUrl)) {
        changelog = _changelogCache[changelogUrl]!;
        return;
      }

      final httpClient = ref.read(triOSHttpClient);
      isLoading = true;
      httpClient
          .get(changelogUrl)
          .then((response) {
            var data = response.data;

            if (data is List<int>) {
              data = utf8.decode(data);
            } else {
              data = data.toString();
            }

            changelog = data.toString().trim();
            var lines = changelog.split("\n");

            // Remove the first line if it contains "Changelog"
            if (lines.firstOrNull?.containsIgnoreCase("Changelog") == true) {
              lines = lines.skip(1).toList();
            }

            // If there's a blank line after a version line, remove it
            List<String> cleanedLines = [];

            for (int i = 0; i < lines.length; i++) {
              cleanedLines.add(lines[i]);
              if (i < lines.length - 1 &&
                  lines[i].trim().toLowerCase().startsWith('version') &&
                  lines[i + 1].trim().isEmpty) {
                i++;
              }
            }

            changelog = cleanedLines.join("\n");

            _changelogCache[changelogUrl] = changelog;
            isLoading = false;
            if (mounted) setState(() {});
          })
          .onError((error, stackTrace) {
            changelog = "Failed to load changelog: $error";
            isLoading = false;
            Fimber.e(
              "Failed to load changelog from $changelogUrl for mod ${widget.localVersionCheck?.modName} v${widget.localVersionCheck?.modVersion}",
              ex: error,
            );
            if (mounted) setState(() {});
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (changelogUrl.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.withTitle)
          Text(
            "Changelog",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              decoration: TextDecoration.underline,
            ),
          ),
        Expanded(
          child:
              !isLoading
                  ? Builder(
                    builder: (context) {
                      final lines = changelog.split('\n');
                      List<TextSpan> textSpans =
                          lines.map((line) {
                            if (line.trimLeft().toLowerCase().startsWith(
                              'version',
                            )) {
                              return TextSpan(
                                text: '$line\n',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            } else {
                              return TextSpan(
                                text: '$line\n',
                                style: Theme.of(context).textTheme.labelLarge,
                              );
                            }
                          }).toList();

                      return SelectableText.rich(TextSpan(children: textSpans));
                    },
                  )
                  : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
