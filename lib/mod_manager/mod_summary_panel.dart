import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mod.dart';
import '../models/mod_variant.dart';
import '../trios/app_state.dart';
import '../trios/constants.dart';
import '../widgets/mod_type_icon.dart';
import '../widgets/moving_tooltip.dart';
import '../widgets/palette_generator_mixin.dart';

class ModSummaryPanel extends ConsumerStatefulWidget {
  final Mod? mod;
  final void Function() onClose;

  const ModSummaryPanel(this.mod, this.onClose, {super.key});

  @override
  ConsumerState createState() => _ModSummaryPanelState();
}

class _ModSummaryPanelState extends ConsumerState<ModSummaryPanel>
    with PaletteGeneratorMixin {
  @override
  String? getIconPath() =>
      widget.mod?.findFirstEnabledOrHighestVersion?.iconFilePath;

  @override
  Widget build(BuildContext context) {
    final selectedMod = widget.mod;
    final modVariants = ref.watch(AppState.modVariants).value;
    final enabledMods = ref
        .watch(AppState.enabledModsFile)
        .value
        ?.enabledMods
        .toList();
    final allMods = ref.watch(AppState.mods);
    final gameVersion = ref.watch(AppState.starsectorVersion).value;
    final dependents = selectedMod != null
        ? calculateDependents(
            selectedMod.findFirstEnabledOrHighestVersion!,
          ).getAsMods(allMods)
        : <Mod>[];
    const buttonsOpacity = 0.8;

    final paletteTheme = paletteGenerator.createPaletteTheme(context);

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            boxShadow: [ThemeManager.boxShadow],
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
          child: Builder(
            builder: (context) {
              final variant = selectedMod!.findHighestVersion;
              final versionCheck = ref
                  .watch(AppState.versionCheckResults)
                  .value
                  ?.versionCheckResultsBySmolId[variant?.smolId];
              if (variant == null) return const SizedBox();
              final iconFilePath = variant.iconFilePath;
              final modMetadata = ref
                  .watch(AppState.modsMetadata)
                  .value
                  ?.getMergedModMetadata(selectedMod.id);
              final forumThreadId = versionCheck?.remoteVersion?.modThreadId;
              final labelTextStyle = Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);
              final bodyOpacity = 0.92;
              final bodyTextStyle = Theme.of(context).textTheme.labelLarge
                  ?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(bodyOpacity),
                  );

              // if (iconFilePath != null) {
              //   PaletteGenerator.fromImageProvider(
              //           Image.file(iconFilePath.toFile(), width: 48, height: 48)
              //               .image)
              //       .then((generator) => {
              //             setState(() {
              //               paletteGenerator = generator;
              //             })
              //           });
              // } else {
              //   paletteGenerator = null;
              // }
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SingleChildScrollView(
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Theme(
                              data: paletteTheme,
                              child: Card(
                                margin: const EdgeInsets.only(),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      ThemeManager.cornerRadius,
                                    ),
                                    topRight: Radius.zero,
                                    bottomLeft: Radius.zero,
                                    bottomRight: Radius.zero,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 32,
                                    top: 16,
                                    bottom: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (iconFilePath != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 16,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Image.file(
                                                    iconFilePath.toFile(),
                                                    width: 48,
                                                    height: 48,
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            const SizedBox(
                                              width: 0,
                                              height: 48,
                                            ),
                                          Expanded(
                                            child: Text(
                                              variant.modInfo.name ??
                                                  "(no name)",
                                              style: theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontFamily: "Orbitron",
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Don't show line if no palette, otherwise it encloses the details part too much
                            Divider(
                              height: 1,
                              color: paletteGenerator != null
                                  ? paletteTheme.colorScheme.outline
                                        .withOpacity(0.4)
                                  : Theme.of(context).colorScheme.surface,
                            ),
                            // Container(
                            //   height: 12, // Adjust height for gradient fade
                            //   decoration: BoxDecoration(
                            //     gradient: LinearGradient(
                            //       stops: const [0.4, 0.85],
                            //       begin: Alignment.topCenter,
                            //       end: Alignment.bottomCenter,
                            //       colors: [
                            //         paletteTheme.cardColor, // Transparent
                            //         Theme.of(context).colorScheme.surface, // Opaque
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "${variant.modInfo.id} ${variant.modInfo.version}",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontFamily: GoogleFonts.sourceCodePro()
                                          .fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Starsector ${variant.modInfo.gameVersion}",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontFamily: GoogleFonts.sourceCodePro()
                                          .fontFamily,
                                    ),
                                  ),
                                  if (variant.modInfo.isUtility ||
                                      variant.modInfo.isTotalConversion)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Tooltip(
                                        message: ModTypeIcon.getTooltipText(
                                          variant,
                                        ),
                                        child: Row(
                                          children: [
                                            ModTypeIcon(modVariant: variant),
                                            const SizedBox(width: 8),
                                            Text(
                                              variant.modInfo.isTotalConversion
                                                  ? "Total Conversion"
                                                  : variant.modInfo.isUtility
                                                  ? "Utility Mod"
                                                  : "",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (forumThreadId.isNotNullOrEmpty() ?? false)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        Builder(
                                          builder: (context) {
                                            final uri = Uri.parse(
                                              "${Constants.forumModPageUrl}$forumThreadId",
                                            );
                                            return MovingTooltipWidget.text(
                                              message: uri.toString(),
                                              child: Opacity(
                                                opacity: buttonsOpacity,
                                                child: OutlinedButton.icon(
                                                  icon: SvgImageIcon(
                                                    "assets/images/icon-web.svg",
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  label: const Text(
                                                    "Forum Thread",
                                                  ),
                                                  onPressed: () {
                                                    launchUrl(uri);
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      Text("Version(s)", style: labelTextStyle),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedMod.modVariants
                                                .joinToString(
                                                  separator: ",  ",
                                                  transform: (variant) =>
                                                      variant.modInfo.version
                                                          ?.toString() ??
                                                      "",
                                                ),
                                            style: bodyTextStyle,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (variant.modInfo.author.isNotNullOrEmpty())
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        Text("Author", style: labelTextStyle),
                                        Text(
                                          variant.modInfo.author ??
                                              "(no author)",
                                          style: bodyTextStyle,
                                        ),
                                      ],
                                    ),
                                  if (modMetadata != null)
                                    MovingTooltipWidget.text(
                                      message: "First seen by TriOS",
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Row(
                                          children: [
                                            Text(
                                              "First Seen: ",
                                              style: labelTextStyle,
                                            ),
                                            Text(
                                              Constants.dateTimeFormat.format(
                                                DateTime.fromMillisecondsSinceEpoch(
                                                  modMetadata.firstSeen,
                                                ),
                                              ),
                                              style: bodyTextStyle,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (modMetadata != null &&
                                      modMetadata.lastEnabled != null)
                                    MovingTooltipWidget.text(
                                      message: "Last enabled by TriOS",
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Last enabled: ",
                                              style: labelTextStyle,
                                            ),
                                            Text(
                                              Constants.dateTimeFormat.format(
                                                DateTime.fromMillisecondsSinceEpoch(
                                                  modMetadata.lastEnabled!,
                                                ),
                                              ),
                                              style: bodyTextStyle,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Builder(
                                    builder: (context) {
                                      if (forumThreadId != null) {}

                                      return Container();
                                    },
                                  ),

                                  if (variant.modInfo.description
                                      .isNotNullOrEmpty())
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        Text(
                                          "Description",
                                          style: labelTextStyle,
                                        ),
                                        Text(
                                          variant.modInfo.description ??
                                              "(no description)",
                                          style: bodyTextStyle,
                                        ),
                                      ],
                                    ),
                                  Builder(
                                    builder: (context) {
                                      if (modVariants == null ||
                                          enabledMods == null) {
                                        return const SizedBox();
                                      }
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          Text(
                                            "Dependencies",
                                            style: labelTextStyle,
                                          ),
                                          if (variant
                                              .modInfo
                                              .dependencies
                                              .isNotEmpty)
                                            Opacity(
                                              opacity: bodyOpacity,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: variant
                                                    .modInfo
                                                    .dependencies
                                                    .map((dep) {
                                                      var dependencyState = dep
                                                          .isSatisfiedByAny(
                                                            modVariants,
                                                            enabledMods,
                                                            gameVersion,
                                                          );
                                                      return Text(
                                                        "- ${dep.formattedNameVersion} ${dependencyState.getDependencyStateText()}",
                                                        style: theme
                                                            .textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                              color: getStateColorForDependencyText(
                                                                dependencyState,
                                                              ),
                                                            ),
                                                      );
                                                    })
                                                    .toList(),
                                              ),
                                            ),
                                          if (variant
                                              .modInfo
                                              .dependencies
                                              .isEmpty)
                                            Text(
                                              "None",
                                              style: theme.textTheme.labelLarge,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // TODO graphicslib doesn't show up for LazyLib 3.0 but it does for 2.8b
                                  Text("Dependents", style: labelTextStyle),
                                  Builder(
                                    builder: (context) {
                                      final enabledDependents = dependents
                                          .where((mod) => mod.hasEnabledVariant)
                                          .toList();
                                      return enabledDependents.isNotEmpty
                                          ? DependentsListWidget(
                                              dependents: enabledDependents,
                                              selectedMod: selectedMod,
                                              allMods: allMods,
                                              style: bodyTextStyle,
                                            )
                                          : Text(
                                              "No mods depend on ${variant.modInfo.name}",
                                              style: bodyTextStyle,
                                            );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      final disabledDependents = dependents
                                          .where(
                                            (mod) => !mod.hasEnabledVariant,
                                          )
                                          .toList();
                                      return disabledDependents.isNotEmpty
                                          ? Opacity(
                                              opacity: 0.8,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Disabled Dependents",
                                                    style: theme
                                                        .textTheme
                                                        .labelLarge
                                                        ?.copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  DependentsListWidget(
                                                    dependents:
                                                        disabledDependents,
                                                    selectedMod: selectedMod,
                                                    allMods: allMods,
                                                    style: bodyTextStyle,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Theme(
                    data: paletteTheme,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, right: 8),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            widget.onClose();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<ModVariant> calculateDependents(ModVariant variant) {
    final modVariants = ref.watch(AppState.modVariants).value;
    final enabledMods = ref
        .watch(AppState.enabledModsFile)
        .value
        ?.enabledMods
        .toList();
    if (modVariants == null || enabledMods == null) return [];
    return modVariants
        .where(
          (v) => v.modInfo.dependencies.any((dep) {
            var satisfiedBy = dep.isSatisfiedBy(variant, enabledMods);
            return satisfiedBy is VersionWarning ||
                satisfiedBy is Satisfied ||
                satisfiedBy is Disabled;
          }),
        )
        .toList();
  }
}

class DependentsListWidget extends StatelessWidget {
  const DependentsListWidget({
    super.key,
    required this.dependents,
    required this.selectedMod,
    required this.allMods,
    this.style,
  });

  final List<Mod> dependents;
  final Mod selectedMod;
  final List<Mod> allMods;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: dependents.map((modDep) {
            final variant = modDep.findFirstEnabledOrHighestVersion;
            final dependencyVersion = variant?.modInfo.dependencies
                .firstWhereOrNull((dep) => dep.id == selectedMod.id)
                ?.version;
            final enabled = variant?.isEnabled(allMods) == true;
            return Text(
              "- ${variant?.modInfo.name}${dependencyVersion != null ? " (wants $dependencyVersion)" : ""}",
              style: style,
            );
          }).toList(),
        ),
      ],
    );
  }
}
