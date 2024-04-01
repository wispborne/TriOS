import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/trios_theme.dart';

import '../mod_manager/version_checker.dart';

class VersionCheckTextReadout extends ConsumerStatefulWidget {
  final int? versionCheckComparison;
  final VersionCheckerInfo? localVersionCheck;
  final VersionCheckResult? remoteVersionCheck;
  final bool showClickToDownloadIfPossible;

  const VersionCheckTextReadout(
      this.versionCheckComparison, this.localVersionCheck, this.remoteVersionCheck, this.showClickToDownloadIfPossible,
      {super.key});

  @override
  ConsumerState createState() => _VersionCheckTextReadoutState();
}

class _VersionCheckTextReadoutState extends ConsumerState<VersionCheckTextReadout> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionCheckComparison = widget.versionCheckComparison;
    final localVersionCheck = widget.localVersionCheck;
    final remoteVersionCheck = widget.remoteVersionCheck;
    final bool hasUpdate = versionCheckComparison == -1;
    final hasDirectDownload = remoteVersionCheck?.remoteVersion?.directDownloadURL != null;

    return Container(
      child: switch (versionCheckComparison) {
        -1 => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showClickToDownloadIfPossible && hasUpdate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("Note: full mod manager features will time some time to develop.",
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.secondary)),
                ),
              if (widget.showClickToDownloadIfPossible && hasUpdate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("Click to download.",
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              Text("New version:      ${remoteVersionCheck?.remoteVersion?.modVersion}", style: theme.textTheme.labelLarge),
              Text("Current version: ${localVersionCheck?.modVersion}",
                  style: theme.textTheme.labelLarge),
              if (hasDirectDownload)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("File: ${remoteVersionCheck?.remoteVersion?.directDownloadURL}",
                      style: theme.textTheme.labelLarge),
                ),
              Text("\nUpdate information is provided by the mod author, not TriOS, and cannot be guaranteed.",
                  style: theme.textTheme.labelLarge?.copyWith(fontStyle: FontStyle.italic)),
              if (remoteVersionCheck?.remoteVersion != null &&
                  remoteVersionCheck?.remoteVersion?.directDownloadURL == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("This mod does not support direct download and should be downloaded manually.",
                      style: theme.textTheme.labelLarge?.copyWith(fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        _ => Column(
            children: [
              if (localVersionCheck != null && remoteVersionCheck != null && remoteVersionCheck.error == null)
                Column(
                  children: [
                    Text("You are up to date.", style: theme.textTheme.labelLarge),
                    Text("Current version: ${localVersionCheck.modVersion}", style: theme.textTheme.labelLarge),
                  ],
                ),
              if (localVersionCheck != null && remoteVersionCheck?.error != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Error checking for updates. This is not caused by ${Constants.appName}.",
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: vanillaErrorColor, fontWeight: FontWeight.bold)),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text("Message:",
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: vanillaErrorColor, fontWeight: FontWeight.bold)),
                    ),
                    Text("${remoteVersionCheck?.error}",
                        style:
                            theme.textTheme.labelLarge?.copyWith(fontFeatures: [const FontFeature.tabularFigures()])),
                  ],
                ),
              if (localVersionCheck == null)
                Text("This mod does not support Version Checker.\nPlease visit the mod page to manually find updates.",
                    style: theme.textTheme.labelLarge),
            ],
          )
      },
    );
  }
}
