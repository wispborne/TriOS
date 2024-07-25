import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/mod_dependencies_widget.dart';
import '../dashboard/mod_list_basic.dart';
import '../dashboard/version_check_icon.dart';
import '../dashboard/version_check_text_readout.dart';
import '../datatable3/data_table_3.dart';
import '../models/mod.dart';
import '../trios/constants.dart';
import '../trios/download_manager/download_manager.dart';
import '../widgets/mod_type_icon.dart';
import '../widgets/moving_tooltip.dart';
import '../widgets/tooltip_frame.dart';

class Smol2 extends ConsumerStatefulWidget {
  const Smol2({super.key});

  @override
  ConsumerState createState() => _Smol2State();
}

class _Smol2State extends ConsumerState<Smol2> {
  bool _sortAscending = true;
  int? _sortColumnIndex;
  Mod? selectedMod;

  /// Gets set to a different function when sorting changes.
  /// TODO save this in shared preferences
  List<Mod> Function(List<Mod>) sortFunction = (mods) => mods.sortedBy(
      (mod) => mod.findFirstEnabledOrHighestVersion?.modInfo.name ?? "");

  List<Mod> _sortModsBy<T extends Comparable<T>>(
      List<Mod> mods, T Function(Mod) comparableGetter) {
    return _sortAscending
        ? mods.sortedBy<T>((mod) => comparableGetter(mod))
        : mods.sortedByDescending<T>((mod) => comparableGetter(mod));
  }

  _onSort<T extends Comparable<T>>(
      int columnIndex, T Function(Mod) comparableGetter) {
    setState(() {
      final isSameColumn = columnIndex == _sortColumnIndex;
      _sortColumnIndex = columnIndex;
      _sortAscending = isSameColumn ? !_sortAscending : true;
      sortFunction = (List<Mod> mods) => _sortModsBy(mods, comparableGetter);
    });
  }

  tooltippy(Widget child, ModVariant modVariant) {
    final compatWithGame = ref
        .read(AppState.modCompatibility)[modVariant.smolId]
        ?.gameCompatibility;

    return MovingTooltipWidget(
      tooltipWidget: SizedBox(
        width: 400,
        child: TooltipFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModDependenciesWidget(
                modVariant: modVariant,
                compatWithGame: compatWithGame,
                compatTextColor: compatWithGame?.getGameCompatibilityColor(),
              ),
            ],
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modsToDisplay = sortFunction(ref.watch(AppState.mods));
    const alternateRowColor = true;
    // final enabledMods =
    //     ref.watch(AppState.enabledModsFile).value?.enabledMods ?? {};
    const double versionSelectorWidth = 130;
    final theme = Theme.of(context);
    const lightTextOpacity = 0.8;
    final lightTextColor =
        theme.colorScheme.onSurface.withOpacity(lightTextOpacity);
    var versionCheck = ref.watch(AppState.versionCheckResults).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Theme(
        data: theme.copyWith(
          //disable ripple
          splashFactory: NoSplash.splashFactory,
        ),
        child: Stack(
          children: [
            // Opacity(
            //   opacity: 0.6,
            //   child: Text("Under construction: search, mod info, and more.",
            //       style: theme.textTheme.labelLarge
            //           ?.copyWith(color: ThemeManager.vanillaWarningColor)),
            // ),
            DataTable3(
              columnSpacing: 12,
              horizontalMargin: 12,
              bottomMargin: 16,
              minWidth: 600,
              showCheckboxColumn: false,
              dividerThickness: 0,
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              sortArrowBuilder: (ascending, sorted) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: !sorted
                    ? Container()
                    : ascending
                        ? const Icon(Icons.arrow_upward, size: 14)
                        : const Icon(Icons.arrow_downward, size: 14),
              ),
              // onSelectAll: (selected) {},
              columns: [
                const DataColumn3(
                  label: Text(''), // Version selector
                  fixedWidth: versionSelectorWidth,
                ),
                const DataColumn3(
                  label: Text(''), // Utility/Total Conversion icon
                  fixedWidth: 35,
                ),
                const DataColumn3(
                  label: Text(''), // Mod icon
                  fixedWidth: 38,
                ),
                DataColumn3(
                  label: const Text('Name'),
                  onSort: (columnIndex, ascending) => _onSort(
                      columnIndex,
                      (mod) =>
                          mod.findFirstEnabledOrHighestVersion?.modInfo.name ??
                          ""),
                ),
                DataColumn3(
                  label: const Text('Author'),
                  onSort: (columnIndex, ascending) => _onSort(
                      columnIndex,
                      (mod) =>
                          mod.findFirstEnabledOrHighestVersion?.modInfo
                              .author ??
                          ""),
                ),
                DataColumn3(
                  label: const Text('Version(s)'),
                  onSort: (columnIndex, ascending) => _onSort(
                      columnIndex,
                      (mod) => mod.modVariants
                          .map((e) => e.modInfo.version)
                          .join(", ")),
                ),
                const DataColumn3(
                  label: Text('VRAM Est.'),
                ),
                DataColumn3(
                  label: const Text('Req. Game Version'),
                  onSort: (columnIndex, ascending) => _onSort(
                      columnIndex,
                      (mod) =>
                          mod.findFirstEnabledOrHighestVersion?.modInfo
                              .gameVersion ??
                          ""),
                ),
              ],
              rows: modsToDisplay
                  .mapIndexed((index, mod) {
                    final bestVersion = mod.findFirstEnabledOrHighestVersion;
                    final enabledVersion = mod.findFirstEnabled;
                    if (bestVersion == null) return null;
                    final gameVersion = ref.watch(appSettings
                        .select((value) => value.lastStarsectorVersion));
                    final dependencies = ref
                        .watch(AppState.modCompatibility)[bestVersion.smolId];
                    final areDependenciesMet = dependencies?.dependencyChecks
                                .every((e) =>
                                    e.satisfiedAmount is Satisfied ||
                                    e.satisfiedAmount is VersionWarning ||
                                    e.satisfiedAmount is Disabled) !=
                            false &&
                        dependencies?.gameCompatibility !=
                            GameCompatibility.incompatible;

                    final localVersionCheck =
                        mod.findHighestVersion?.versionCheckerInfo;
                    final remoteVersionCheck =
                        versionCheck?[bestVersion.smolId];
                    final versionCheckComparison =
                        compareLocalAndRemoteVersions(
                            localVersionCheck, remoteVersionCheck);

                    const rowHeight = kMinInteractiveDimension;
                    final extraRowHeight = !areDependenciesMet ? 16.0 : 0.0;

                    Widget affixToTop({required Widget child}) => Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: rowHeight,
                            child: Center(child: child),
                          ),
                        );

                    return DataRow3(
                      onSelectChanged: (selected) {
                        if (selected != null) {}
                      },
                      specificRowHeight: rowHeight + extraRowHeight,
                      color: (alternateRowColor && index.isEven
                          ? WidgetStateProperty.all(
                              theme.colorScheme.surface.withOpacity(0.4))
                          : null),
                      onTap: () {
                        setState(() {
                          if (selectedMod == mod) {
                            selectedMod = null;
                          } else {
                            selectedMod = mod;
                          }
                        });
                      },
                      cells: [
                        // Enable/Disable
                        DataCell3(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              affixToTop(
                                child: ModVersionSelectionDropdown(
                                  mod: mod,
                                  width: versionSelectorWidth,
                                  showTooltip: true,
                                ),
                              ),
                              if (!areDependenciesMet)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 0),
                                  child: Builder(builder: (context) {
                                    return Text(
                                      dependencies?.gameCompatibility ==
                                              GameCompatibility.incompatible
                                          ? "Incompatible with ${gameVersion ?? "game version"}."
                                          : dependencies?.dependencyChecks
                                                  .where((e) =>
                                                      e.satisfiedAmount
                                                          is! Satisfied)
                                                  .map((e) => switch (
                                                          e.satisfiedAmount) {
                                                        Satisfied _ => null,
                                                        Missing _ =>
                                                          "${e.dependency.formattedNameVersion} is missing.",
                                                        Disabled _ => null,
                                                        VersionInvalid _ =>
                                                          "Missing version ${e.dependency.version} of ${e.dependency.nameOrId}.",
                                                        VersionWarning
                                                          version =>
                                                          "${e.dependency.nameOrId} version ${e.dependency.version} is wanted but ${version.modVariant!.bestVersion} may work.",
                                                      })
                                                  .join(" • ") ??
                                              "",
                                      style: theme.textTheme.labelMedium?.copyWith(
                                          color: dependencies
                                                      ?.gameCompatibility ==
                                                  GameCompatibility.incompatible
                                              ? ThemeManager.vanillaErrorColor
                                              : getTopDependencySeverity(
                                                      dependencies
                                                              ?.dependencyStates ??
                                                          [],
                                                      gameVersion,
                                                      sortLeastSevere: false)
                                                  .getDependencySatisfiedColor()),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                    );
                                  }),
                                ),
                            ],
                          ),
                          builder: (context, child) =>
                              tooltippy(child, bestVersion),
                        ),
                        // Utility/Total Conversion icon
                        DataCell3(
                          affixToTop(
                              child: ModTypeIcon(modVariant: bestVersion)),
                          builder: (context, child) => ContextMenuRegion(
                              contextMenu: ModListMini.buildContextMenu(
                                  mod, ref, context),
                              child: child),
                        ),
                        // Icon
                        DataCell3(
                          affixToTop(
                            child: SizedBox(
                              width: 30,
                              child: bestVersion.iconFilePath == null
                                  ? Container()
                                  : Image.file(
                                      bestVersion.iconFilePath!.toFile()),
                            ),
                          ),
                          builder: (context, child) => ContextMenuRegion(
                              contextMenu: ModListMini.buildContextMenu(
                                  mod, ref, context),
                              child: child),
                        ),
                        // Name
                        DataCell3(
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 600,
                            ),
                            child: Text(
                              bestVersion.modInfo.name ?? "(no name)",
                              style: GoogleFonts.roboto(
                                textStyle: theme.textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          builder: (context, child) => ContextMenuRegion(
                              contextMenu: ModListMini.buildContextMenu(
                                  mod, ref, context),
                              child: tooltippy(
                                  affixToTop(child: child), bestVersion)),
                        ),
                        DataCell3(
                          Text(bestVersion.modInfo.author ?? "(no author)",
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: lightTextColor)),
                          builder: (context, child) => ContextMenuRegion(
                              contextMenu: ModListMini.buildContextMenu(
                                  mod, ref, context),
                              child: affixToTop(child: child)),
                        ),
                        DataCell3(affixToTop(
                          child: mod.modVariants.isEmpty
                              ? const Text("")
                              : Row(
                                  children: [
                                    MovingTooltipWidget(
                                      tooltipWidget: SizedBox(
                                        width: 500,
                                        child: TooltipFrame(
                                            child: VersionCheckTextReadout(
                                                versionCheckComparison,
                                                localVersionCheck,
                                                remoteVersionCheck,
                                                true)),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          if (remoteVersionCheck
                                                      ?.remoteVersion !=
                                                  null &&
                                              compareLocalAndRemoteVersions(
                                                      localVersionCheck,
                                                      remoteVersionCheck) ==
                                                  -1) {
                                            ref.read(downloadManager.notifier).downloadUpdateViaBrowser(
                                                remoteVersionCheck!
                                                    .remoteVersion!,
                                                context,
                                                activateVariantOnComplete: true,
                                                modInfo: bestVersion.modInfo);
                                          } else {
                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                        content: SelectionArea(
                                                      child: VersionCheckTextReadout(
                                                          versionCheckComparison,
                                                          localVersionCheck,
                                                          remoteVersionCheck,
                                                          true),
                                                    )));
                                          }
                                        },
                                        onSecondaryTap: () => showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                    content: SelectionArea(
                                                  child: VersionCheckTextReadout(
                                                      versionCheckComparison,
                                                      localVersionCheck,
                                                      remoteVersionCheck,
                                                      true),
                                                ))),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          child: VersionCheckIcon(
                                              localVersionCheck:
                                                  localVersionCheck,
                                              remoteVersionCheck:
                                                  remoteVersionCheck,
                                              versionCheckComparison:
                                                  versionCheckComparison,
                                              theme: theme),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          children: [
                                            for (var i = 0;
                                                i < mod.modVariants.length;
                                                i++) ...[
                                              if (i > 0)
                                                TextSpan(
                                                  text: ', ',
                                                  style: theme
                                                      .textTheme.labelLarge
                                                      ?.copyWith(
                                                          color:
                                                              lightTextColor), // Style for the comma
                                                ),
                                              TextSpan(
                                                text: mod.modVariants[i].modInfo
                                                    .version
                                                    .toString(),
                                                style: theme
                                                    .textTheme.labelLarge
                                                    ?.copyWith(
                                                        color: enabledVersion ==
                                                                mod.modVariants[
                                                                    i]
                                                            ? null
                                                            : lightTextColor), // Style for the remaining items
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        )),
                        DataCell3(
                          Text("todo",
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: lightTextColor)),
                          builder: (context, child) => ContextMenuRegion(
                              contextMenu: ModListMini.buildContextMenu(
                                  mod, ref, context),
                              child: affixToTop(child: child)),
                        ),
                        DataCell3(
                          Opacity(
                            opacity: lightTextOpacity,
                            child: Text(
                                bestVersion.modInfo.gameVersion ??
                                    "(no game version)",
                                style: compareGameVersions(
                                            bestVersion.modInfo.gameVersion,
                                            ref
                                                .watch(appSettings)
                                                .lastStarsectorVersion) ==
                                        GameCompatibility.perfectMatch
                                    ? theme.textTheme.labelLarge
                                    : theme.textTheme.labelLarge
                                        ?.copyWith(color: ThemeManager.vanillaErrorColor)),
                          ),
                          builder: (context, child) => ContextMenuRegion(
                              contextMenu: ModListMini.buildContextMenu(
                                  mod, ref, context),
                              child: affixToTop(child: child)),
                        ),
                      ],
                    );
                  })
                  .whereNotNull()
                  .toList(),
              empty: Center(
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                            angle: .50,
                            child: SvgImageIcon(
                                "assets/images/icon-ice-cream.svg",
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 150),
                          ),
                          const Text("mmm, vanilla")
                        ],
                      ))),
            ),
            if (selectedMod != null)
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 400,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      boxShadow: [
                        ThemeManager.boxShadow,
                      ],
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          width: 1,
                        ),
                        left: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Builder(builder: (context) {
                      final variant = selectedMod!.findHighestVersion;
                      final versionCheck = ref
                          .watch(AppState.versionCheckResults)
                          .valueOrNull?[variant?.smolId];
                      if (variant == null) return const SizedBox();
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: SelectionArea(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (variant.iconFilePath != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 16),
                                            child: Image.file(
                                                variant.iconFilePath!.toFile(),
                                                width: 48,
                                                height: 48),
                                          )
                                        else
                                          const SizedBox(width: 0, height: 48),
                                        Text(
                                            variant.modInfo.name ?? "(no name)",
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                    fontFamily: "Orbitron",
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        "${variant.modInfo.id} ${variant.modInfo.version}",
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                fontFamily:
                                                    GoogleFonts.sourceCodePro()
                                                        .fontFamily)),
                                    const SizedBox(height: 4),
                                    Text(
                                        "Starsector ${variant.modInfo.gameVersion}",
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                fontFamily:
                                                    GoogleFonts.sourceCodePro()
                                                        .fontFamily)),
                                    if (variant.modInfo.isUtility ||
                                        variant.modInfo.isTotalConversion)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Tooltip(
                                            message: ModTypeIcon.getTooltipText(
                                                variant),
                                            child: Row(
                                              children: [
                                                ModTypeIcon(
                                                    modVariant: variant),
                                                const SizedBox(width: 8),
                                                Text(
                                                  variant.modInfo
                                                          .isTotalConversion
                                                      ? "Total Conversion"
                                                      : variant
                                                              .modInfo.isUtility
                                                          ? "Utility Mod"
                                                          : "",
                                                ),
                                              ],
                                            ),
                                          )),
                                    if (variant.modInfo.author
                                        .isNotNullOrEmpty())
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          const Text("Author",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(variant.modInfo.author ??
                                              "(no author)"),
                                        ],
                                      ),
                                    if (variant.modInfo.description
                                        .isNotNullOrEmpty())
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          const Text("Description",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(variant.modInfo.description ??
                                              "(no description)"),
                                        ],
                                      ),
                                    if (versionCheck?.remoteVersion?.modThreadId
                                            .isNotNullOrEmpty() ??
                                        false)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          TextButton(
                                              child: const Text(
                                                "Forum Thread",
                                              ),
                                              onPressed: () {
                                                launchUrl(Uri.parse(
                                                    "${Constants.forumModPageUrl}${versionCheck?.remoteVersion?.modThreadId}"));
                                              }),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    selectedMod = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
