import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/dashboard/changelogs.dart';
import 'package:trios/dashboard/mod_dependencies_widget.dart';
import 'package:trios/dashboard/mod_list_basic_entry.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/hoverable_widget.dart';
import 'package:trios/widgets/mod_type_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_with_icon.dart';
import 'package:trios/widgets/tooltip_frame.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dashboard/version_check_icon.dart';
import '../../trios/download_manager/download_manager.dart';
import '../../widgets/svg_image_icon.dart';

class WispGridModRowView extends ConsumerStatefulWidget {
  final Mod mod;
  final Function(Mod? mod) onModRowSelected;

  const WispGridModRowView(
      {super.key, required this.mod, required this.onModRowSelected});

  @override
  ConsumerState createState() => _WispGridModRowViewState();
}

class _WispGridModRowViewState extends ConsumerState<WispGridModRowView> {
  static const _dependencyAddedRowHeight = 0.0;
  static const _standardRowHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(modGridStateProvider);
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;
    final mod = widget.mod;
    final allMods = ref.watch(AppState.mods);
    final height = _standardRowHeight;
    final bestVersion = mod.findFirstEnabledOrHighestVersion!;

    return SizedBox(
      child: Column(
        children: [
          ContextMenuRegion(
            contextMenu:
                buildModContextMenu(mod, ref, context, showSwapToVersion: true),
            child: HoverableWidget(
                onTap: () => {
                      widget.onModRowSelected(mod),
                    },
                builder: (context, isHovering) {
                  return Container(
                    color:
                        isHovering ? Colors.black.withValues(alpha: 0.2) : null,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: WispGrid.gridRowSpacing,
                          children: (gridState.columnSettings.entries
                              .map((columnSetting) {
                            return Builder(builder: (context) {
                              final header = columnSetting.key;
                              final state = columnSetting.value;

                              return switch (header) {
                                ModGridHeader.favorites => _RowItemContainer(
                                    height: height,
                                    width: state.width,
                                    child: Expanded(
                                      child: FavoriteButton(
                                        favoritesWidth: state.width,
                                        mod: mod,
                                        isRowHighlighted: isHovering,
                                      ),
                                    ),
                                  ),
                                ModGridHeader.changeVariantButton =>
                                  Builder(builder: (context) {
                                    return ContextMenuRegion(
                                        contextMenu: buildModContextMenu(
                                            mod, ref, context,
                                            showSwapToVersion: true),
                                        child: _RowItemContainer(
                                          height: height,
                                          width: state.width,
                                          child: Disable(
                                            isEnabled: !isGameRunning,
                                            child: ModVersionSelectionDropdown(
                                              mod: mod,
                                              width:
                                                  WispGrid.versionSelectorWidth,
                                              showTooltip: false,
                                            ),
                                          ),
                                        ));
                                  }),
                                ModGridHeader.modIcon =>
                                  Builder(builder: (context) {
                                    String? iconPath = bestVersion.iconFilePath;
                                    return _RowItemContainer(
                                      height: height,
                                      width: state.width,
                                      child: iconPath != null
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Image.file(
                                                  iconPath.toFile(),
                                                  width: 32,
                                                  height: 32,
                                                ),
                                              ],
                                            )
                                          : const SizedBox(
                                              width: 32, height: 32),
                                    );
                                  }),
                                ModGridHeader.icons => _RowItemContainer(
                                    height: height,
                                    width: state.width,
                                    child: ModTypeIcon(modVariant: bestVersion),
                                  ),
                                ModGridHeader.name => buildNameCell(
                                    mod, bestVersion, allMods, state),
                                ModGridHeader.author =>
                                  Builder(builder: (context) {
                                    final theme = Theme.of(context);
                                    final lightTextColor = theme
                                        .colorScheme.onSurface
                                        .withOpacity(WispGrid.lightTextOpacity);
                                    return ContextMenuRegion(
                                        contextMenu: buildModContextMenu(
                                            mod, ref, context,
                                            showSwapToVersion: true),
                                        child: _RowItemContainer(
                                          height: height,
                                          width: state.width,
                                          child: Text(
                                            bestVersion.modInfo.author
                                                    ?.toString()
                                                    .replaceAll("\n", "   ") ??
                                                "(no author)",
                                            maxLines: 1,
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                    color: lightTextColor),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ));
                                  }),
                                ModGridHeader.version => _buildVersionCell(
                                    WispGrid.lightTextOpacity,
                                    mod,
                                    height,
                                    isGameRunning,
                                    bestVersion,
                                    state),
                                ModGridHeader.vramImpact => buildVramCell(
                                    WispGrid.lightTextOpacity,
                                    mod,
                                    height,
                                    state),
                                ModGridHeader.gameVersion =>
                                  Builder(builder: (context) {
                                    final theme = Theme.of(context);

                                    return ContextMenuRegion(
                                        contextMenu: buildModContextMenu(
                                            mod, ref, context,
                                            showSwapToVersion: true),
                                        child: _RowItemContainer(
                                          height: height,
                                          width: state.width,
                                          child: Opacity(
                                            opacity: WispGrid.lightTextOpacity,
                                            child: Text(
                                                bestVersion
                                                        .modInfo.gameVersion ??
                                                    "(no game version)",
                                                style: compareGameVersions(
                                                            bestVersion.modInfo
                                                                .gameVersion,
                                                            ref
                                                                .watch(
                                                                    appSettings)
                                                                .lastStarsectorVersion) ==
                                                        GameCompatibility
                                                            .perfectMatch
                                                    ? theme.textTheme.labelLarge
                                                    : theme.textTheme.labelLarge
                                                        ?.copyWith(
                                                            color: ThemeManager
                                                                .vanillaErrorColor)),
                                          ),
                                        ));
                                  }),
                              };
                            });
                          }).toList()),
                        ),
                        buildMissingDependencyButton(
                            mod.findFirstEnabled, allMods)
                      ],
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }

  Builder buildVramCell(double lightTextOpacity, Mod mod, double height,
      ModGridColumnSetting state) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final lightTextColor =
          theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
      final bestVersion = mod.findFirstEnabledOrHighestVersion;
      final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
      if (bestVersion == null) return const SizedBox();

      return ContextMenuRegion(
          contextMenu:
              buildModContextMenu(mod, ref, context, showSwapToVersion: true),
          child: _RowItemContainer(
            height: height,
            width: state.width,
            child: Expanded(
              child: Builder(builder: (context) {
                final vramEstimatorState =
                    ref.watch(AppState.vramEstimatorProvider);
                final vramMap = vramEstimatorState.modVramInfo;
                final biggestFish = vramMap
                    .maxBy((e) =>
                        e.value.bytesUsingGraphicsLibConfig(graphicsLibConfig))
                    ?.value
                    .bytesUsingGraphicsLibConfig(graphicsLibConfig);
                final ratio = biggestFish == null
                    ? 0.00
                    : (vramMap[bestVersion.smolId]
                                ?.bytesUsingGraphicsLibConfig(graphicsLibConfig)
                                .toDouble() ??
                            0) /
                        biggestFish.toDouble();
                final vramEstimate = vramMap[bestVersion.smolId];
                final withoutGraphicsLib = vramEstimate?.images
                    .where((e) => e.graphicsLibType == null)
                    .map((e) => e.bytesUsed)
                    .toList();
                final fromGraphicsLib = vramEstimate?.images
                    .where((e) => e.graphicsLibType != null)
                    .map((e) => e.bytesUsed)
                    .toList();

                return MovingTooltipWidget.text(
                  message: vramEstimate == null
                      ? ""
                      : "Version ${vramEstimate.info.version}"
                          "\n"
                          "\n${withoutGraphicsLib?.sum().bytesAsReadableMB()} from mod (${withoutGraphicsLib?.length} images)"
                          "\n${fromGraphicsLib?.sum().bytesAsReadableMB()} added by your GraphicsLib settings (${fromGraphicsLib?.length} images)"
                          "\n---"
                          "\n${vramEstimate.bytesUsingGraphicsLibConfig(graphicsLibConfig).bytesAsReadableMB()} total",
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: vramEstimate?.bytesUsingGraphicsLibConfig(
                                        graphicsLibConfig) !=
                                    null
                                ? Text(
                                    vramEstimate!
                                        .bytesUsingGraphicsLibConfig(
                                            graphicsLibConfig)
                                        .bytesAsReadableMB(),
                                    style: theme.textTheme.labelLarge
                                        ?.copyWith(color: lightTextColor))
                                : Align(
                                    alignment: Alignment.centerRight,
                                    child: Opacity(
                                        opacity: 0.5,
                                        child: Disable(
                                          isEnabled:
                                              !vramEstimatorState.isScanning,
                                          child: MovingTooltipWidget.text(
                                            message: "Estimate VRAM usage",
                                            child: IconButton(
                                              icon: const Icon(Icons.memory),
                                              iconSize: 24,
                                              onPressed: () {
                                                ref
                                                    .read(AppState
                                                        .vramEstimatorProvider
                                                        .notifier)
                                                    .startEstimating(
                                                        variantsToCheck: [
                                                      mod.findFirstEnabledOrHighestVersion!
                                                    ]);
                                              },
                                            ),
                                          ),
                                        )),
                                  )),
                      ),
                      if (vramEstimate != null)
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ));
    });
  }

  Builder _buildVersionCell(double lightTextOpacity, Mod mod, double height,
      bool isGameRunning, ModVariant bestVersion, ModGridColumnSetting state) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final lightTextColor =
          theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
      final disabledVersionTextColor = lightTextColor.withOpacity(0.5);
      final enabledVersion = mod.findFirstEnabled;
      final versionCheckResultsNew =
          ref.watch(AppState.versionCheckResults).valueOrNull;
      //
      final versionCheckComparison = mod.updateCheck(versionCheckResultsNew);
      final localVersionCheck =
          versionCheckComparison?.variant.versionCheckerInfo;
      final remoteVersionCheck = versionCheckComparison?.remoteVersionCheck;
      final changelogUrl = Changelogs.getChangelogUrl(
          versionCheckComparison?.variant.versionCheckerInfo,
          versionCheckComparison?.remoteVersionCheck);
      return mod.modVariants.isEmpty
          ? const Text("")
          : _RowItemContainer(
              height: height,
              width: state.width,
              child: Row(
                children: [
                  if (changelogUrl.isNotNullOrEmpty())
                    MovingTooltipWidget(
                      tooltipWidget: SizedBox(
                        width: 400,
                        height: 400,
                        child: TooltipFrame(
                          child: Stack(
                            children: [
                              Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 4, top: 0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 4),
                                          child: SvgImageIcon(
                                            "assets/images/icon-bullhorn-variant.svg",
                                            color: theme.colorScheme.primary,
                                            width: 20,
                                            height: 20,
                                          ),
                                        ),
                                        Text("Click horn to see full changelog",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            )),
                                      ],
                                    ),
                                  )),
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Changelogs(
                                  localVersionCheck,
                                  remoteVersionCheck,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                  content: Changelogs(
                                      localVersionCheck, remoteVersionCheck)));
                        },
                        child: SvgImageIcon(
                          "assets/images/icon-bullhorn-variant.svg",
                          color: theme.iconTheme.color?.withOpacity(0.7),
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  MovingTooltipWidget(
                    tooltipWidget:
                        ModListBasicEntry.buildVersionCheckTextReadout(
                            null,
                            versionCheckComparison?.comparisonInt,
                            localVersionCheck,
                            remoteVersionCheck),
                    child: Disable(
                      isEnabled: !isGameRunning,
                      child: InkWell(
                        onTap: () {
                          if (remoteVersionCheck?.remoteVersion != null &&
                              versionCheckComparison?.comparisonInt == -1) {
                            ref
                                .read(downloadManager.notifier)
                                .downloadUpdateViaBrowser(
                                    remoteVersionCheck!.remoteVersion!,
                                    activateVariantOnComplete: false,
                                    modInfo: bestVersion.modInfo);
                          } else {
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                    content: ModListBasicEntry
                                        .changeAndVersionCheckAlertDialogContent(
                                            changelogUrl,
                                            localVersionCheck,
                                            remoteVersionCheck,
                                            versionCheckComparison
                                                ?.comparisonInt)));
                          }
                        },
                        onSecondaryTap: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                content: ModListBasicEntry
                                    .changeAndVersionCheckAlertDialogContent(
                                        changelogUrl,
                                        localVersionCheck,
                                        remoteVersionCheck,
                                        versionCheckComparison
                                            ?.comparisonInt))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: VersionCheckIcon.fromComparison(
                              comparison: versionCheckComparison, theme: theme),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Builder(builder: (context) {
                      final variantsWithEnabledFirst = mod.modVariants.sorted(
                        (a, b) => a.isModInfoEnabled != b.isModInfoEnabled
                            ? (a.isModInfoEnabled ? -1 : 1)
                            : a.compareTo(b),
                      );

                      final text = RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            for (var i = 0;
                                i < variantsWithEnabledFirst.length;
                                i++) ...[
                              if (i > 0)
                                TextSpan(
                                    text: ', ',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                        color: disabledVersionTextColor)),
                              TextSpan(
                                text: variantsWithEnabledFirst[i]
                                    .modInfo
                                    .version
                                    .toString(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: enabledVersion ==
                                          variantsWithEnabledFirst[i]
                                      ? null
                                      : disabledVersionTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );

                      return MovingTooltipWidget.framed(
                          tooltipWidget: text, child: text);
                    }),
                  ),
                ],
                // ),
              ),
            );
    });
  }

  Builder buildNameCell(Mod mod, ModVariant bestVersion, List<Mod> allMods,
      ModGridColumnSetting state) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final enabledVersion = mod.findFirstEnabled;

      return ContextMenuRegion(
          contextMenu: buildModContextMenu(
            mod,
            ref,
            context,
            showSwapToVersion: true,
          ),
          child: _RowItemContainer(
            height: _standardRowHeight,
            width: state.width,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 600,
              ),
              child: Text(
                bestVersion.modInfo.name ?? "(no name)",
                style: GoogleFonts.roboto(
                  textStyle: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // )
            ),
          ));
    });
  }

  Widget buildMissingDependencyButton(
      ModVariant? enabledVersion, List<Mod> allMods) {
    final modCompatibility =
        ref.watch(AppState.modCompatibility)[enabledVersion?.smolId];
    final unmetDependencies = modCompatibility?.dependencyChecks
            .where((e) => !e.isCurrentlySatisfied)
            .toList() ??
        [];

    if (unmetDependencies.isEmpty) return Container();

    final gridState = ref.watch(modGridStateProvider);
    final cellWidthBeforeNameColumn = gridState.columnSettings.entries
        .sortedBy<num>((entry) => entry.value.position)
        .takeWhile((element) => element.key != ModGridHeader.name)
        .map((e) => e.value.width + WispGrid.gridRowSpacing)
        .sum;

    return Padding(
      padding: EdgeInsets.only(left: cellWidthBeforeNameColumn, bottom: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...unmetDependencies.map((checkResult) {
            final buttonStyle = OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(60, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    ThemeManager.cornerRadius), // Rounded corners
              ),
            );

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: MovingTooltipWidget.text(
                message:
                    "${enabledVersion?.modInfo.nameOrId} requires ${checkResult.dependency.formattedNameVersion}",
                child: Row(
                  children: [
                    // if (checkResult.satisfiedAmount is Disabled)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Builder(builder: (context) {
                        if (checkResult.satisfiedAmount is Disabled) {
                          final disabledVariant =
                              (checkResult.satisfiedAmount as Disabled)
                                  .modVariant;
                          return OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(AppState.modVariants.notifier)
                                    .changeActiveModVariant(
                                        disabledVariant!.mod(allMods)!,
                                        disabledVariant);
                              },
                              style: buttonStyle,
                              child: TextWithIcon(
                                text:
                                    "Enable ${disabledVariant?.modInfo.formattedNameVersion}",
                                leading: disabledVariant?.iconFilePath == null
                                    ? null
                                    : Image.file(
                                        (disabledVariant?.iconFilePath ?? "")
                                            .toFile(),
                                        height: 20,
                                        isAntiAlias: true,
                                      ),
                                leadingPadding: const EdgeInsets.only(right: 4),
                              ));
                        } else {
                          final missingDependency = checkResult.dependency;

                          return OutlinedButton(
                              onPressed: () async {
                                final modName =
                                    missingDependency.formattedNameVersionId;
                                // Advanced search
                                final url = Uri.parse(
                                    'https://www.google.com/search?q=starsector+$modName+download');

                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  showSnackBar(
                                      context: context,
                                      content: const Text(
                                          "Couldn't open browser. Google recommends Chrome for a faster experience!"));
                                }
                              },
                              style: buttonStyle,
                              child: TextWithIcon(
                                text:
                                    "Search ${missingDependency.formattedNameVersionId}",
                                leading: const SvgImageIcon(
                                  "assets/images/icon-search.svg",
                                  width: 20,
                                  height: 20,
                                ),
                                leadingPadding: const EdgeInsets.only(right: 4),
                              ));
                        }
                      }),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _RowItemContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final double width;

  const _RowItemContainer(
      {required this.child, required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
            ],
          ),
        ),
      ],
    );
  }
}

_buildModGridTooltip(
    {required Widget child,
    required List<ModVariant> modVariants,
    required WidgetRef ref}) {
  final modCompat = ref.read(AppState.modCompatibility);
  final gameVersion =
      ref.read(appSettings.select((value) => value.lastStarsectorVersion));
  final compatWithGame = modVariants
      .map((e) => modCompat[e.smolId])
      .toList()
      .leastSevereCompatibility;
  final highestCompatibleGameVersion =
      modVariants.preferHighestVersionForGameVersion(gameVersion)!;

  return MovingTooltipWidget(
    tooltipWidget: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400, minHeight: 200),
      child: TooltipFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModDependenciesWidget(
              modVariant: highestCompatibleGameVersion,
              compatWithGame: compatWithGame,
              compatTextColor: compatWithGame.getGameCompatibilityColor(),
            ),
          ],
        ),
      ),
    ),
    child: child,
  );
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    Key? key,
    required this.favoritesWidth,
    required this.mod,
    required this.isRowHighlighted,
  }) : super(key: key);

  final double favoritesWidth;
  final Mod mod;
  final bool isRowHighlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // todo: implement favorites
    // final profile = ref.watch(userProfileProvider);
    final isFavorited = false; //profile.favoriteMods.contains(mod.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isFavorited || isRowHighlighted)
          Padding(
            padding: const EdgeInsets.only(right: 0.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  // setModFavorited(ref, mod.id, !isFavorited);
                },
                child: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.6)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
