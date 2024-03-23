import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/tooltip_frame.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../chipper/copy.dart';
import '../mod_manager/mod_manager_logic.dart';
import '../mod_manager/version_checker.dart';
import '../models/mod_variant.dart';
import '../trios/app_state.dart';
import '../trios/settings/settings.dart';

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();
}

class _ModListMiniState extends ConsumerState<ModListMini> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final enabledModIds = ref.watch(AppState.enabledModIds).valueOrNull;
    final modList = ref.watch(AppState.modVariants).valueOrNull;
    var versionCheck = ref.watch(versionCheckResults).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                        child: Text("Mods",
                            style: Theme.of(context).textTheme.titleLarge)),
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.copy),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () {
                            if (modList == null) return;
                            Clipboard.setData(ClipboardData(
                                text:
                                    "Mods (${modList.length})\n${modList.map((e) => false ? "${e.modInfo.id} ${e.modInfo.version}" : "${e.modInfo.name}  v${e.modInfo.version}  [${e.modInfo.id}]").join('\n')}"));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Copied mod info to clipboard."),
                            ));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
              modList != null
                  ? " ${enabledModIds?.length ?? 0} of ${modList.length} enabled"
                  : "",
              style: Theme.of(context).textTheme.labelMedium),
          Expanded(
            child: ref.watch(AppState.modVariants).when(
                  data: (modVariants) {
                    final listItems = modVariants
                        .map((e) => e as ModVariant?)
                        .filter((mod) {
                          if (mod?.versionCheckerInfo == null) return false;

                          final localVersionCheck = mod!.versionCheckerInfo;
                          final remoteVersionCheck = versionCheck?[mod.smolId];
                          return _doVersionCheck(
                                      localVersionCheck, remoteVersionCheck) ==
                                  -1 &&
                              remoteVersionCheck?.error == null;
                        })
                        .sortedBy((info) => info?.modInfo.name ?? "")
                        .toList()
                      ..add(null)
                      ..addAll(modVariants
                          // .filter((mod) => mod.versionCheckerInfo == null)
                          .sortedBy((info) => info.modInfo.name)
                          .toList());
                    return VsScrollbar(
                      controller: _scrollController,
                      isAlwaysShown: true,
                      showTrackOnHover: true,
                      child: ListView.builder(
                          shrinkWrap: true,
                          controller: _scrollController,
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final modVariant = listItems[index];
                            if (modVariant == null) {
                              return const Divider();
                            }
                            return ModListBasicEntry(
                                mod: modVariant,
                                isEnabled: enabledModIds
                                        ?.contains(modVariant.modInfo.id) ??
                                    false);
                          }),
                    );
                  },
                  loading: () => const Center(
                      child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator())),
                  error: (error, stackTrace) => Text('Error: $error'),
                ),
          ),
        ],
      ),
    );
  }
}

int? _doVersionCheck(VersionCheckerInfo? local, VersionCheckResult? remote) {
  if (local == null || remote == null) return 0;
  return local.modVersion?.compareTo(remote.remoteVersion?.modVersion);
}

/// Displays just the mods specified.
class ModListBasicEntry extends ConsumerStatefulWidget {
  final ModVariant mod;
  final bool isEnabled;

  const ModListBasicEntry(
      {super.key, required this.mod, required this.isEnabled});

  @override
  ConsumerState createState() => _ModListBasicCustomState();
}

class _ModListBasicCustomState extends ConsumerState<ModListBasicEntry> {
  @override
  Widget build(BuildContext context) {
    var versionCheck = ref.watch(versionCheckResults).valueOrNull;
    const updateIconSize = 20.0;
    final modVariant = widget.mod;

    final modInfo = modVariant.modInfo;
    final localVersionCheck = modVariant.versionCheckerInfo;
    final remoteVersionCheck = versionCheck?[modVariant.smolId];
    final compatWithGame = compareGameVersions(
        modInfo.gameVersion, ref.read(AppState.starsectorVersion).value);
    final compatTextColor = switch (compatWithGame) {
      GameCompatibility.Incompatible => TriOSTheme.vanillaErrorColor,
      GameCompatibility.Warning => TriOSTheme.vanillaWarningColor,
      GameCompatibility.Compatible => null,
    };
    final theme = Theme.of(context);
    final versionCheckComparison =
        _doVersionCheck(localVersionCheck, remoteVersionCheck);
    infoTooltip({required Widget child}) => MovingTooltipWidget(
        tooltipWidget: SizedBox(
          width: 350,
          child: TooltipFrame(
            child: ModSummaryWidget(
              modVariant: modVariant,
              compatWithGame: compatWithGame,
              compatTextColor: compatTextColor,
            ),
          ),
        ),
        child: child);
    var hasDirectDownload =
        remoteVersionCheck?.remoteVersion?.directDownloadURL != null;
    final iconColor = switch (versionCheckComparison) {
      -1 => theme.colorScheme.secondary,
      _ => theme.disabledColor.withOpacity(0.5),
    };

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: SizedBox(
            height: 26,
            child: CheckboxWithLabel(
              labelWidget: Row(
                children: [
                  Expanded(
                    child: infoTooltip(
                        child: Text("${modInfo.name} ${modInfo.version}",
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: compatTextColor))),
                  ),
                  MovingTooltipWidget(
                    tooltipWidget: SizedBox(
                      width: 500,
                      child: TooltipFrame(
                          child: VersionCheckInfo(versionCheckComparison,
                              localVersionCheck, remoteVersionCheck)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: Row(children: [
                        if (localVersionCheck?.modVersion != null &&
                            remoteVersionCheck?.remoteVersion?.modVersion !=
                                null)
                          Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ConditionalWrap(
                                  condition: versionCheckComparison == -1,
                                  wrapper: (child) => Blur(
                                      blurX: 0,
                                      blurY: 0,
                                      blurOpacity: 0.7,
                                      child: child),
                                  child: Builder(builder: (context) {
                                    if (versionCheckComparison == -1 &&
                                        hasDirectDownload) {
                                      return Icon(Icons.download,
                                          size: updateIconSize,
                                          color: iconColor);
                                    } else if (versionCheckComparison == -1 &&
                                        !hasDirectDownload) {
                                      return SvgImageIcon(
                                          "assets/images/icon-update-badge.svg",
                                          width: updateIconSize,
                                          height: updateIconSize,
                                          color: iconColor);
                                    } else {
                                      return Icon(Icons.check,
                                          size: updateIconSize,
                                          color: iconColor);
                                    }
                                  }))),
                        if (localVersionCheck?.modVersion != null &&
                            remoteVersionCheck?.error != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.error_outline,
                                size: updateIconSize,
                                color: TriOSTheme.vanillaWarningColor
                                    .withOpacity(0.5)),
                          ),
                        if (localVersionCheck?.modVersion == null)
                          Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SizedBox(
                                width: updateIconSize,
                                child: Center(
                                  child: ColorFiltered(
                                      colorFilter: greyscale,
                                      child: SvgImageIcon(
                                          "assets/images/icon-help.svg",
                                          width: updateIconSize,
                                          height: updateIconSize,
                                          color: theme.disabledColor
                                              .withOpacity(0.35))),
                                ),
                              )),
                        if (localVersionCheck != null &&
                            remoteVersionCheck == null)
                          Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ColorFiltered(
                                colorFilter: greyscale,
                                child: Text("…",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.disabledColor
                                            .withOpacity(0.35))),
                              )),
                      ]),
                    ),
                  ),
                ],
              ),
              checkWrapper: (child) => infoTooltip(child: child),
              padding: 0,
              value: widget.isEnabled,
              expand: true,
              onChanged: (_) {
                if (true) {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: const Text("Nope"),
                            content: const Text(
                                "This feature is not yet implemented."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Close"),
                              ),
                            ],
                          ));
                  return;
                }
                // if (enabledModIds == null) return;
                var isCurrentlyEnabled = widget.isEnabled;

                // TODO check mod dependencies.
                // We can disable mods without checking compatibility, but we can't enable them without checking.
                if (!isCurrentlyEnabled) {
                  final compatResult = compatWithGame;
                  if (compatResult == GameCompatibility.Incompatible) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Mod ${modInfo.name} is not compatible with your game version (${ref.read(AppState.starsectorVersion).value})"),
                    ));
                    return;
                  }
                }

                var modsFolder =
                    ref.read(appSettings.select((value) => value.modsDir));
                if (modsFolder == null) return;

                if (isCurrentlyEnabled) {
                  disableMod(modInfo.id, modsFolder, ref);
                } else {
                  enableMod(modInfo.id, modsFolder, ref);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class VersionCheckInfo extends ConsumerStatefulWidget {
  final int? versionCheckComparison;
  final VersionCheckerInfo? localVersionCheck;
  final VersionCheckResult? remoteVersionCheck;

  const VersionCheckInfo(this.versionCheckComparison, this.localVersionCheck,
      this.remoteVersionCheck,
      {super.key});

  @override
  ConsumerState createState() => _VersionCheckInfoState();
}

class _VersionCheckInfoState extends ConsumerState<VersionCheckInfo> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionCheckComparison = widget.versionCheckComparison;
    final localVersionCheck = widget.localVersionCheck;
    final remoteVersionCheck = widget.remoteVersionCheck;
    final hasDirectDownload =
        remoteVersionCheck?.remoteVersion?.directDownloadURL != null;

    return Container(
      child: switch (versionCheckComparison) {
        -1 => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("New version available: ${localVersionCheck?.modVersion}"),
              Text(
                  "Current version: ${remoteVersionCheck?.remoteVersion?.modVersion}"),
              if (hasDirectDownload)
                Text(
                    "File: ${remoteVersionCheck?.remoteVersion?.directDownloadURL}"),
              Text(
                  "\nUpdate information is provided by the mod author, not TriOS, and cannot be guaranteed.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
              if (remoteVersionCheck?.remoteVersion?.directDownloadURL == null)
                Text(
                    "This mod does not support direct download and should be downloaded manually.",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic)),
              Text("\nClick to download.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        _ => const Text(
            "This mod does not support Version Checker.\nPlease visit the mod page to manually find updates.")
      },
    );
  }
}
