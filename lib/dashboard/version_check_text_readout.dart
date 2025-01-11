import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/themes/theme_manager.dart';

import '../mod_manager/version_checker.dart';

class VersionCheckTextReadout extends ConsumerStatefulWidget {
  final int? versionCheckComparison;
  final VersionCheckerInfo? localVersionCheck;
  final RemoteVersionCheckResult? remoteVersionCheck;
  final bool showClickToDownloadIfPossible;

  const VersionCheckTextReadout(
      this.versionCheckComparison,
      this.localVersionCheck,
      this.remoteVersionCheck,
      this.showClickToDownloadIfPossible,
      {super.key});

  @override
  ConsumerState createState() => _VersionCheckTextReadoutState();
}

class _VersionCheckTextReadoutState
    extends ConsumerState<VersionCheckTextReadout> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionCheckComparison = widget.versionCheckComparison;
    final localVersionCheck = widget.localVersionCheck;
    final remoteVersionCheck = widget.remoteVersionCheck;
    final bool hasUpdate = versionCheckComparison == -1;
    final hasDirectDownload =
        remoteVersionCheck?.remoteVersion?.directDownloadURL != null;

    return Container(
      child: switch (versionCheckComparison) {
        -1 => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showClickToDownloadIfPossible && hasUpdate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          hasDirectDownload
                              ? "Click to download"
                              : "Click to open in browser",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text("Right-click to expand this tooltip.",
                            style: theme.textTheme.labelLarge),
                      ),
                    ],
                  ),
                ),
              Text(
                  "New version:      ${remoteVersionCheck?.remoteVersion?.modVersion}",
                  style: theme.textTheme.labelLarge),
              Text("Current version: ${localVersionCheck?.modVersion}",
                  style: theme.textTheme.labelLarge),
              if (hasDirectDownload)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      "File: ${remoteVersionCheck?.remoteVersion?.directDownloadURL}",
                      style: theme.textTheme.labelLarge),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Version Checker url:\n${remoteVersionCheck?.uri}",
                    style: theme.textTheme.labelLarge?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()])),
              ),
              Text(
                  "\nUpdate information is provided by the mod author, not TriOS, and cannot be guaranteed.",
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontStyle: FontStyle.italic)),
              if (!hasDirectDownload)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      "This mod does not support direct download and should be downloaded manually.",
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (localVersionCheck != null &&
                  remoteVersionCheck != null &&
                  remoteVersionCheck.error == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("You are up to date.",
                        style: theme.textTheme.labelLarge),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                          "Current version: ${localVersionCheck.modVersion}",
                          style: theme.textTheme.labelLarge),
                    ),
                    Text(
                        "Remote version: ${remoteVersionCheck.remoteVersion?.modVersion}",
                        style: theme.textTheme.labelLarge),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                          "Version Checker url:\n${remoteVersionCheck.uri}",
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ])),
                    ),
                  ],
                ),
              // Remote error.
              if (localVersionCheck != null &&
                  remoteVersionCheck?.error != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Error checking for updates.",
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: ThemeManager.vanillaErrorColor,
                            fontWeight: FontWeight.bold)),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                          "This is usually caused by the mod author. Please visit the mod page to manually find updates.",
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: ThemeManager.vanillaErrorColor)),
                    ),
                    Text(
                        "If the in-game Version Checker is working for this specific mod, please report a TriOS bug.",
                        style: theme.textTheme.labelLarge),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                          "Version Checker url:\n${remoteVersionCheck?.uri}",
                          style: theme.textTheme.labelLarge?.copyWith(
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ])),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("Message",
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: ThemeManager.vanillaErrorColor,
                              fontWeight: FontWeight.bold)),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: Text("${remoteVersionCheck?.error}",
                          overflow: TextOverflow.fade,
                          style: theme.textTheme.labelLarge?.copyWith(
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ])),
                    ),
                  ],
                ),
              if (localVersionCheck == null)
                Text(
                    "This mod may not support Version Checker.\nPlease visit the mod page to manually find updates.",
                    style: theme.textTheme.labelLarge),
            ],
          )
      },
    );
  }
}
