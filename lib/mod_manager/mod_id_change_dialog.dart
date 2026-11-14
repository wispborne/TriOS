import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/dashboard/mod_summary_widget.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/force_game_version_warning_dialog.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

/// Shown when an update installed a mod with a different ID from the mod it
/// was started from. The old mod is shown above the new one.
///
/// If the old mod is enabled, it asks whether to switch to the new mod, and
/// closes with `true` on Switch. If the old mod is disabled, it only has an OK
/// button. Every other way of closing it returns `false` or `null`.
///
/// It doesn't change anything. The mute checkbox reads and writes
/// [muteOldMod], which the caller owns, so its value survives the dialog
/// closing with Escape or a click outside.
class ModIdChangeDialog extends StatelessWidget {
  /// The old mod's enabled version, or its highest version if it's disabled.
  final ModVariant oldVariant;
  final bool isOldModEnabled;
  final ModVariant newVariant;

  /// The enabled mods that depend on the old mod's ID.
  final List<Mod> dependents;

  /// The current game version, used to color each mod's game version.
  final String? gameVersion;
  final ValueNotifier<bool> muteOldMod;

  const ModIdChangeDialog({
    super.key,
    required this.oldVariant,
    required this.isOldModEnabled,
    required this.newVariant,
    required this.dependents,
    required this.gameVersion,
    required this.muteOldMod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text("Mod ID change"),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 16,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: "The update for "),
                  TextSpan(
                    text: oldVariant.modInfo.nameOrId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " installed a mod with a different ID."),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: .stretch,
              spacing: 4,
              children: [
                _ModCard(variant: oldVariant, gameVersion: gameVersion),
                Center(
                  child: Text(
                    "updated to a different mod",
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                _ModCard(variant: newVariant, gameVersion: gameVersion),
              ],
            ),
            const SizedBox(height: 8),
            if (isOldModEnabled && dependents.isNotEmpty)
              Padding(
                padding: const .only(bottom: 24),
                child: _buildDependents(context),
              ),
            if (isOldModEnabled)
              Text(
                "Do you want to switch to the new mod?",
                style: theme.textTheme.titleSmall,
              ),
            ValueListenableBuilder<bool>(
              valueListenable: muteOldMod,
              builder: (context, isMuteChecked, _) => CheckboxWithLabel(
                value: isMuteChecked,
                onChanged: (value) => muteOldMod.value = value ?? false,
                // labelWidget, not label: label centers its text.
                labelWidget: Row(
                  mainAxisSize: .min,
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text(
                        "Mute updates for the old mod",
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message: "The old mod will always show as having an update but always redownload the new mod.",
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
                textPadding: const .only(left: 8),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(isOldModEnabled ? "Don't switch" : "OK"),
        ),
        if (isOldModEnabled)
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Switch"),
          ),
      ],
    );
  }

  /// A warning saying how many mods depend on the old mod, with the mods
  /// listed inside it. Drawn like the dashboard's and catalog's warnings: a
  /// folding tile with a yellow warning icon.
  Widget _buildDependents(BuildContext context) {
    final count = dependents.length;
    final theme = Theme.of(context);
    final variants =
        dependents
            .map((mod) => mod.findFirstEnabledOrHighestVersion)
            .nonNulls
            .toList()
          ..sort(
            (a, b) => a.modInfo.nameOrId.toLowerCase().compareTo(
              b.modInfo.nameOrId.toLowerCase(),
            ),
          );

    // Colorless: the default fill would make it look like another card.
    return TriOSExpansionTile.colorless(
      leading: const Icon(
        Icons.warning_amber_rounded,
        color: TriOSThemeConstants.vanillaWarningColor,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(
        count == 1
            ? "1 mod depends on the old mod"
            : "$count mods depend on the old mod",
      ),
      subtitle: Text(
        "They may or may not work with the new mod.",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      childrenPadding: const .only(left: 24),
      children: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text("Copy names and IDs"),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: variants
                    .map((v) => "${v.modInfo.nameOrId} (${v.modInfo.id})")
                    .join("\n"),
              ),
            );
            showSnackBar(
              context: context,
              content: const Text("Copied to clipboard"),
            );
          },
        ),
        _DependentsList(variants: variants, gameVersion: gameVersion),
      ],
    );
  }
}

/// The mods that depend on the old mod, in a list that scrolls once it's
/// [_maxHeight] tall. Each mod shows its summary on hover.
class _DependentsList extends StatefulWidget {
  static const _maxHeight = 160.0;

  /// The dependent mods' versions, already sorted.
  final List<ModVariant> variants;

  /// The current game version, for the hover summaries.
  final String? gameVersion;

  const _DependentsList({required this.variants, required this.gameVersion});

  @override
  State<_DependentsList> createState() => _DependentsListState();
}

class _DependentsListState extends State<_DependentsList> {
  // Scrollbar needs the list's controller to keep its thumb showing.
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.variants;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _DependentsList._maxHeight),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          padding: const .symmetric(vertical: 8),
          itemCount: variants.length,
          itemBuilder: (context, index) {
            final variant = variants[index];
            return _withModSummaryTooltip(
              variant,
              widget.gameVersion,
              Padding(
                padding: const .symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  spacing: 8,
                  children: [
                    ModIcon.fromVariant(
                      variant,
                      size: 24,
                      takeUpSpaceIfNoIcon: true,
                    ),
                    Expanded(
                      child: Text(
                        variant.modInfo.nameOrId,
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One mod in [ModIdChangeDialog]: its icon, name, ID, version and game
/// version.
class _ModCard extends StatelessWidget {
  final ModVariant variant;
  final String? gameVersion;

  const _ModCard({required this.variant, required this.gameVersion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modInfo = variant.modInfo;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final separator = TextSpan(
      text: "  •  ",
      style: TextStyle(color: mutedColor),
    );
    final gameVersionColor = modInfo
        .isCompatibleWithGame(gameVersion)
        .getGameCompatibilityColor();

    final card = Card.outlined(
      margin: .zero,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const .all(16),
        child: Row(
          spacing: 16,
          children: [
            ModIcon.fromVariant(variant, size: 32, takeUpSpaceIfNoIcon: true),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    modInfo.nameOrId,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: modInfo.id,
                          style: TextStyle(
                            fontFamily: GoogleFonts.sourceCodePro().fontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (modInfo.version != null) ...[
                          separator,
                          TextSpan(text: "v${modInfo.version}"),
                        ],
                        if (modInfo.gameVersion != null) ...[
                          separator,
                          TextSpan(
                            text: modInfo.gameVersion,
                            style: TextStyle(color: gameVersionColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return _withModSummaryTooltip(variant, gameVersion, card);
  }
}

/// Wraps [child] in the mod summary tooltip that the dashboard and Activity
/// Panel show on hover. [gameVersion] is the current game version.
Widget _withModSummaryTooltip(
  ModVariant variant,
  String? gameVersion,
  Widget child,
) {
  return MovingTooltipWidget.framed(
    position: TooltipPosition.topLeft,
    padding: .zero,
    tooltipWidgetBuilder: (context) {
      // Only needed once the tooltip shows.
      final compatWithGame = variant.modInfo.isCompatibleWithGame(gameVersion);
      return SizedBox(
        width: 400,
        child: ModSummaryWidget(
          modVariant: variant,
          compatWithGame: compatWithGame,
          compatTextColor: compatWithGame.getGameCompatibilityColor(),
          showIconTip: false,
        ),
      );
    },
    child: child,
  );
}

/// Shows [ModIdChangeDialog] for an update that installed [newVariant]
/// instead of a new version of [oldMod]. Then mutes the old mod and switches
/// to the new one, if the user chose to.
///
/// [ref] must last longer than the dialog, so pass the installer's `Ref`. A
/// dialog's `WidgetRef` stops working once the dialog closes.
///
/// [dependents] are the enabled mods that depend on the old mod's ID.
///
/// Nothing awaits this, so it logs its own errors.
Future<void> askAboutModIdChange(
  Ref ref,
  BuildContext context, {
  required Mod oldMod,
  required ModVariant newVariant,
  required List<Mod> dependents,
}) async {
  final muteOldMod = ValueNotifier(true);
  try {
    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (context) => ModIdChangeDialog(
        oldVariant: oldMod.findFirstEnabledOrHighestVersion!,
        isOldModEnabled: oldMod.isEnabledInGame,
        newVariant: newVariant,
        dependents: dependents,
        gameVersion: ref.read(
          appSettings.select((s) => s.lastStarsectorVersion),
        ),
        muteOldMod: muteOldMod,
      ),
    );

    if (muteOldMod.value) {
      ref
          .read(AppState.modsMetadata.notifier)
          .updateModUserMetadata(
            oldMod.id,
            (old) => old.copyWith(areUpdatesMuted: true),
          );
    }

    if (shouldSwitch == true) {
      await _switchToNewMod(ref, oldMod, newVariant);
    }
  } catch (e, st) {
    Fimber.e(
      "Failed to handle the mod ID change from ${oldMod.id} to ${newVariant.modInfo.id}",
      ex: e,
      stacktrace: st,
    );
  } finally {
    muteOldMod.dispose();
  }
}

/// Enables [newVariant] and then disables [oldMod].
///
/// If the new mod was made for a different game version, this first shows the
/// force-version warning. Both steps only run if the user presses Force there,
/// so pressing Cancel leaves the old mod enabled.
Future<void> _switchToNewMod(Ref ref, Mod oldMod, ModVariant newVariant) async {
  final modManagerNotifier = ref.read(modManager.notifier);

  // The old mod is only disabled after the new one is enabled, so the user
  // never ends up with neither of them enabled.
  Future<void> enableNewThenDisableOld() async {
    try {
      final newMod = newVariant.mod(ref.read(AppState.mods));
      if (newMod == null) {
        Fimber.w(
          "Can't switch to ${newVariant.smolId}: it's no longer in the mod list.",
        );
        return;
      }
      await modManagerNotifier.changeActiveModVariant(newMod, newVariant);
      await modManagerNotifier.changeActiveModVariant(oldMod, null);
    } catch (e, st) {
      // The force-version dialog calls this after it has closed, and nothing
      // awaits it there, so log errors here.
      Fimber.e(
        "Failed to switch from ${oldMod.id} to ${newVariant.smolId}",
        ex: e,
        stacktrace: st,
      );
    }
  }

  final isWrongGameVersion = isModGameVersionIncorrect(
    ref.read(appSettings.select((s) => s.lastStarsectorVersion)),
    ref.read(AppState.isGameRunning).value == true,
    newVariant,
  );

  if (!isWrongGameVersion) {
    await enableNewThenDisableOld();
    return;
  }

  final context = ref.read(AppState.appContext);
  if (context == null || !context.mounted) {
    Fimber.w(
      "Can't show the game version warning for ${newVariant.smolId}: no app context.",
    );
    return;
  }
  await showDialog(
    context: context,
    builder: (context) => ForceGameVersionWarningDialog(
      modVariant: newVariant,
      onForced: enableNewThenDisableOld,
    ),
  );
}
