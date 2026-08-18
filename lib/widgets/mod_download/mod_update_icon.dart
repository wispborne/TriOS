import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/dashboard/mod_list_basic_entry.dart';
import 'package:trios/dashboard/version_check_icon.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/mod_download/mod_download_status.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// The update marker shown next to a mod: a spinner while that mod's update is
/// downloading or installing, and the version-check icon the rest of the time.
///
/// Left-click starts the update when there is one; otherwise it opens the
/// changelog and version details, which right-click always opens. Hovering
/// shows the version-check readout.
///
/// Used by the Dashboard's mod list and the Mods grid, which is why it lives
/// here rather than in either of them.
class ModUpdateIcon extends ConsumerWidget {
  final Mod mod;

  /// The variant this row is about — the one whose version is compared.
  final ModInfo modInfo;

  final VersionCheckComparison? comparison;

  /// Where to read the mod's changelog, for the details dialog.
  final String? changelogUrl;

  /// Whether the hover readout includes the changelog. The Mods grid has its
  /// own changelog button beside this icon, so it leaves it out.
  final bool showChangelogInTooltip;

  /// False greys the icon out and ignores clicks.
  final bool isEnabled;

  final double spinnerSize;
  final EdgeInsetsGeometry spinnerPadding;
  final TooltipPosition tooltipPosition;

  const ModUpdateIcon({
    super.key,
    required this.mod,
    required this.modInfo,
    required this.comparison,
    required this.changelogUrl,
    required this.isEnabled,
    this.showChangelogInTooltip = false,
    this.spinnerSize = 22,
    this.spinnerPadding = const EdgeInsets.only(left: 4, right: 10),
    this.tooltipPosition = TooltipPosition.bottomRight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localVersionCheck = comparison?.variant.versionCheckerInfo;
    final remoteVersionCheck = comparison?.remoteVersionCheck;
    final remoteVersion = remoteVersionCheck?.remoteVersion;

    final target = DownloadTarget(
      modId: mod.id,
      url: remoteVersion?.directDownloadURL,
      displayName: modInfo.nameOrId,
    );

    return ModDownloadStatusBuilder(
      target: target,
      builder: (context, downloadStatus) {
        if (downloadStatus.isBusy) {
          return MovingTooltipWidget.text(
            message: downloadStatus.message!,
            child: Padding(
              padding: spinnerPadding,
              child: SizedBox(
                width: spinnerSize,
                height: spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: downloadStatus.progress,
                ),
              ),
            ),
          );
        }

        void showDetails() => ModListBasicEntry.showVersionCheckDialog(
          context,
          mod,
          changelogUrl,
          localVersionCheck,
          remoteVersionCheck,
          comparison?.comparisonInt,
        );

        return MovingTooltipWidget(
          position: tooltipPosition,
          tooltipWidget:
              ModListBasicEntry.buildVersionCheckTextReadoutForTooltip(
                mod,
                showChangelogInTooltip ? changelogUrl : null,
                comparison?.comparisonInt,
                localVersionCheck,
                remoteVersionCheck,
              ),
          child: Disable(
            isEnabled: isEnabled,
            child: InkWell(
              onTap: () {
                if (remoteVersion != null && comparison?.comparisonInt == -1) {
                  ModListBasicEntry.startUpdateDownload(
                    ref,
                    target,
                    remoteVersion,
                    modInfo,
                  );
                } else {
                  showDetails();
                }
              },
              onSecondaryTap: showDetails,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: VersionCheckIcon.fromComparison(
                  comparison: comparison,
                  modId: mod.id,
                  theme: theme,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
