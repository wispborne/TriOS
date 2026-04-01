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
  final bool showVersionChips;

  const Changelogs(
    this.mod,
    this.localVersionCheck,
    this.remoteVersionCheck, {
    super.key,
    this.withTitle = true,
    this.showVersionChips = true,
  });

  @override
  ConsumerState createState() => _ChangelogsState();
}

class _ChangelogsState extends ConsumerState<Changelogs> {
  ModChangelog? modChangelog;
  bool isLoading = false;
  String? _selectedVersion;

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
        if (!isLoading && widget.showVersionChips) _buildVersionChips(context),
        Expanded(
          child: !isLoading
              ? Builder(
                  builder: (context) {
                    List<TextSpan> textSpans = [];

                    if (modChangelog?.parsedVersions.isNotNullOrEmpty() ==
                        true) {
                      var versions = modChangelog!.parsedVersions!;
                      if (_selectedVersion != null) {
                        final idx = versions.indexWhere(
                          (v) => v.version.toString() == _selectedVersion,
                        );
                        if (idx >= 0) versions = versions.sublist(idx);
                      }
                      for (final version in versions) {
                        textSpans.add(
                          buildVersionText(version.version.toString(), context),
                        );
                        textSpans.add(
                          buildChangelogText(version.changelog, context),
                        );
                      }
                    } else {
                      var lines = modChangelog?.changelog.split('\n') ?? [];
                      if (_selectedVersion != null) {
                        final idx = lines.indexWhere(
                          (line) =>
                              line.trimLeft().toLowerCase().startsWith(
                                'version',
                              ) &&
                              line.contains(_selectedVersion!),
                        );
                        if (idx >= 0) lines = lines.sublist(idx);
                      }
                      textSpans = lines.map((line) {
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

  Widget _buildVersionChips(BuildContext context) {
    final List<String> versionLabels;

    if (modChangelog?.parsedVersions.isNotNullOrEmpty() == true) {
      versionLabels =
          modChangelog!.parsedVersions!
              .map((v) => v.version.toString())
              .toList();
    } else {
      final lines = modChangelog?.changelog.split('\n') ?? [];
      versionLabels =
          lines
              .where(
                (line) => line.trimLeft().toLowerCase().startsWith('version'),
              )
              .map((line) => line.trim())
              .toList();
    }

    if (versionLabels.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (final version in versionLabels)
              ActionChip(
                label: Text(version),
                backgroundColor: _selectedVersion == version
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                onPressed: () {
                  setState(() {
                    _selectedVersion =
                        _selectedVersion == version ? null : version;
                  });
                },
              ),
          ],
        ),
      ),
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
