import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/changelogs/mod_changelogs_manager.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';

import '../mod_manager/version_checker.dart';
import '../models/version_checker_info.dart';

class Changelogs extends ConsumerStatefulWidget {
  final Mod mod;
  final VersionCheckerInfo? localVersionCheck;
  final RemoteVersionCheckResult? remoteVersionCheck;
  final bool withTitle;

  const Changelogs(
    this.mod,
    this.localVersionCheck,
    this.remoteVersionCheck, {
    super.key,
    this.withTitle = true,
  });

  @override
  ConsumerState createState() => _ChangelogsState();
}

class _ChangelogsState extends ConsumerState<Changelogs> {
  ModChangelog? modChangelog;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //  val changelogUrl = onlineVersionInfo?.changelogUrl?.nullIfBlank()  ?: mod.findHighestVersion?.versionCheckerInfo?.changelogUrl?.nullIfBlank()
    final changelogsManager = ref.watch(AppState.changelogsProvider);
    modChangelog = changelogsManager.value?[widget.mod.id];

    if (modChangelog != null) {
      if (modChangelog!.changelog.isNotEmpty) {
        isLoading = false;
      } else if (modChangelog!.url.isNotEmpty) {
        isLoading = true;
      }
    } else {
      isLoading = true;
    }

    if (changelogsManager.isLoading) {
      isLoading = true;
    }

    if (modChangelog?.url.isEmpty == true) {
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
                      List<TextSpan> textSpans = [];

                      if (modChangelog?.parsedVersions.isNotNullOrEmpty() ==
                          true) {
                        final versions = modChangelog!.parsedVersions!;
                        for (final version in versions) {
                          textSpans.add(
                            buildVersionText(
                              version.version.toString(),
                              context,
                            ),
                          );
                          textSpans.add(
                            buildChangelogText(version.changelog, context),
                          );
                        }
                      } else {
                        final lines = modChangelog?.changelog.split('\n') ?? [];
                        textSpans =
                            lines.map((line) {
                              if (line.trimLeft().toLowerCase().startsWith(
                                'version',
                              )) {
                                return buildVersionText(line, context);
                              } else {
                                return buildChangelogText(line, context);
                              }
                            }).toList();
                      }

                      return SelectableText.rich(TextSpan(children: textSpans));
                    },
                  )
                  : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  TextSpan buildChangelogText(String line, BuildContext context) {
    return TextSpan(
      text: '$line\n',
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  TextSpan buildVersionText(String line, BuildContext context) {
    return TextSpan(
      text: '$line\n',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
