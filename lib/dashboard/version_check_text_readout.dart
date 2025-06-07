import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_with_icon.dart';

import '../mod_manager/version_checker.dart';

class VersionCheckTextReadout extends ConsumerStatefulWidget {
  final int? versionCheckComparison;
  final VersionCheckerInfo? localVersionCheck;
  final RemoteVersionCheckResult? remoteVersionCheck;
  final bool showClickToDownloadIfPossible;
  final bool showRightClickToExpand;

  const VersionCheckTextReadout(
    this.versionCheckComparison,
    this.localVersionCheck,
    this.remoteVersionCheck,
    this.showClickToDownloadIfPossible,
    this.showRightClickToExpand, {
    super.key,
  });

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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showClickToDownloadIfPossible && hasUpdate)
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasDirectDownload
                          ? "Download & Install Update"
                          : "Click to Open Download Page",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                TextWithIcon(
                  leading: const Icon(Icons.upcoming, size: 20),
                  text: '',
                ),
                TextWithIcon(
                  text: '${remoteVersionCheck?.remoteVersion?.modVersion}',
                  style: GoogleFonts.robotoMono().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextWithIcon(
                  leading: SvgImageIcon(
                    "assets/images/icon-not-upcoming.svg",
                    height: 20,
                  ),
                  text: '',
                ),
                TextWithIcon(
                  text: '${localVersionCheck?.modVersion}',
                  style: GoogleFonts.robotoMono().copyWith(fontSize: 13),
                ),
              ],
            ),
            if (hasDirectDownload)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: TextWithIcon(
                  text:
                      "${remoteVersionCheck?.remoteVersion?.directDownloadURL}",
                  leading: const Icon(Icons.file_download_outlined, size: 20),
                  style: theme.textTheme.labelLarge,
                ),
              ),
            if (!hasDirectDownload)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "This mod requires a manual download."
                  "${widget.showRightClickToExpand ? "\nClick to open the download page." : ""}",
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(),
            ),

            Text(
              "Source: ${remoteVersionCheck?.uri}",
              style: theme.textTheme.labelLarge,
            ),

            const SizedBox(height: 16),

            if (widget.showRightClickToExpand)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "Right-click to expand this tooltip.",
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Text(
              "Update information is provided by the mod author, not ${Constants.appName}.",
              style: theme.textTheme.labelLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
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
                  Text(
                    "You are up to date.",
                    style: theme.textTheme.labelLarge,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Current version: ${localVersionCheck.modVersion}",
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    "Remote version: ${remoteVersionCheck.remoteVersion?.modVersion}",
                    style: theme.textTheme.labelLarge,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Version Checker url:\n${remoteVersionCheck.uri}",
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            // Remote error.
            if (localVersionCheck != null && remoteVersionCheck?.error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Error checking for updates.",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ThemeManager.vanillaErrorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "This is usually caused by the mod author or a network error. Please visit the mod page to manually find updates.",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: ThemeManager.vanillaErrorColor,
                      ),
                    ),
                  ),
                  Text(
                    "If the in-game Version Checker is working for this specific mod, please report a TriOS bug.",
                    style: theme.textTheme.labelLarge,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Version Checker url:\n${remoteVersionCheck?.uri}",
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Message",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: ThemeManager.vanillaErrorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Text(
                      "${remoteVersionCheck?.error}",
                      overflow: TextOverflow.fade,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            if (localVersionCheck == null)
              Text(
                "This mod may not support Version Checker.\nPlease visit the mod page to manually find updates.",
                style: theme.textTheme.labelLarge,
              ),
          ],
        ),
      },
    );
  }
}
