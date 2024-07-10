import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mod.dart';
import '../trios/app_state.dart';
import '../trios/constants.dart';
import '../widgets/mod_type_icon.dart';

class ModSummaryPanel extends ConsumerStatefulWidget {
  final Mod? mod;
  final void Function() onClose;

  const ModSummaryPanel(this.mod, this.onClose, {super.key});

  @override
  ConsumerState createState() => _ModSummaryPanelState();
}

class _ModSummaryPanelState extends ConsumerState<ModSummaryPanel> {
  PaletteGenerator? paletteGenerator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMod = widget.mod;
    final modVariants = ref.watch(AppState.modVariants).valueOrNull;
    final enabledMods = ref.watch(AppState.enabledModsFile).valueOrNull;
    final gameVersion = ref.watch(AppState.starsectorVersion).valueOrNull;

    return Container(
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
        final iconFilePath = variant.iconFilePath;

        if (iconFilePath != null) {
          // PaletteGenerator.fromImageProvider(
          //         Image.file(iconFilePath.toFile(), width: 48, height: 48)
          //             .image)
          //     .then((generator) => {
          //           setState(() {
          //             paletteGenerator = generator;
          //           })
          //         });
        } else {
          paletteGenerator = null;
        }

        return Stack(
          children: [
            // if (paletteGenerator != null)
            //   Container(
            //     height: 70,
            //     decoration: BoxDecoration(
            //       color: paletteGenerator!.dominantColor?.color ??
            //           theme.colorScheme.surface,
            //     ),
            //   ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (iconFilePath != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Stack(
                                children: [
                                  Image.file(
                                    iconFilePath.toFile(),
                                    width: 48,
                                    height: 48,
                                  )
                                ],
                              ),
                            )
                          else
                            const SizedBox(width: 0, height: 48),
                          Expanded(
                            child: Text(variant.modInfo.name ?? "(no name)",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontFamily: "Orbitron",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("${variant.modInfo.id} ${variant.modInfo.version}",
                          style: theme.textTheme.labelLarge?.copyWith(
                              fontFamily:
                                  GoogleFonts.sourceCodePro().fontFamily)),
                      const SizedBox(height: 4),
                      Text("Starsector ${variant.modInfo.gameVersion}",
                          style: theme.textTheme.labelLarge?.copyWith(
                              fontFamily:
                                  GoogleFonts.sourceCodePro().fontFamily)),
                      if (variant.modInfo.isUtility ||
                          variant.modInfo.isTotalConversion)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Tooltip(
                              message: ModTypeIcon.getTooltipText(variant),
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
                            )),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text("Version(s)",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedMod.modVariants.joinToString(
                                  separator: ",  ",
                                  transform: (variant) =>
                                      variant.modInfo.version?.toString() ??
                                      "")),
                            ],
                          ),
                        ],
                      ),
                      if (variant.modInfo.author.isNotNullOrEmpty())
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text("Author",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(variant.modInfo.author ?? "(no author)"),
                          ],
                        ),
                      if (variant.modInfo.description.isNotNullOrEmpty())
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text("Description",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(variant.modInfo.description ??
                                "(no description)"),
                          ],
                        ),
                      if (variant.modInfo.dependencies.isNotEmpty)
                        Builder(builder: (context) {
                          final versionCheckResults = ref
                              .watch(AppState.versionCheckResults)
                              .valueOrNull?[variant.smolId];
                          if (modVariants == null ||
                              enabledMods == null ||
                              selectedMod == null) {
                            return const SizedBox();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Text("Dependencies",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    variant.modInfo.dependencies.map((dep) {
                                  var dependencyState = dep.isSatisfiedByAny(
                                      modVariants, enabledMods, gameVersion);
                                  return Text(
                                      "- ${dep.formattedNameVersion} ${dependencyState.getDependencyStateText()}",
                                      style: TextStyle(
                                          color: getStateColorForDependencyText(
                                              dependencyState)));
                                }).toList(),
                              ),
                            ],
                          );
                        }),
                      if (versionCheck?.remoteVersion?.modThreadId
                              .isNotNullOrEmpty() ??
                          false)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text(
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
                    widget.onClose();
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
