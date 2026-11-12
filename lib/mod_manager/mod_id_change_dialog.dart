import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/force_game_version_warning_dialog.dart';

/// Shown when an update installed a mod with a different ID from the mod it
/// was started from.
///
/// If the old mod is enabled, it asks whether to switch to the new mod, and
/// closes with `true` on Switch. If the old mod is disabled, it only has an OK
/// button. Every other way of closing it returns `false` or `null`.
///
/// It doesn't read providers or change anything. The mute checkbox reads and
/// writes [muteOldMod], which the caller owns, so its value survives the
/// dialog closing with Escape or a click outside.
class ModIdChangeDialog extends StatelessWidget {
  final String oldModName;
  final String oldModId;
  final String newModName;
  final String newModId;
  final bool isOldModEnabled;

  /// Names of the enabled mods that depend on the old mod's ID.
  final List<String> dependentNames;
  final ValueNotifier<bool> muteOldMod;

  const ModIdChangeDialog({
    super.key,
    required this.oldModName,
    required this.oldModId,
    required this.newModName,
    required this.newModId,
    required this.isOldModEnabled,
    required this.dependentNames,
    required this.muteOldMod,
  });

  @override
  Widget build(BuildContext context) {
    final monoStyle = TextStyle(
      fontFamily: GoogleFonts.sourceCodePro().fontFamily,
    );
    TextSpan modId(String id) => TextSpan(text: id, style: monoStyle);

    return AlertDialog(
      title: const Text("Mod ID change"),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 16,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "The update for $oldModName ("),
                  modId(oldModId),
                  TextSpan(
                    text:
                        ") installed a mod with a different id: $newModName (",
                  ),
                  modId(newModId),
                  const TextSpan(text: ")."),
                ],
              ),
            ),
            if (isOldModEnabled)
              const Text("Do you want to switch to this new mod?"),
            if (isOldModEnabled && dependentNames.isNotEmpty)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "${_joinNames(dependentNames)} ${dependentNames.length == 1 ? "depends" : "depend"} on the old mod (",
                    ),
                    modId(oldModId),
                    const TextSpan(
                      text: ") and may or may not work with the new mod.",
                    ),
                  ],
                ),
              ),
            ValueListenableBuilder<bool>(
              valueListenable: muteOldMod,
              builder: (context, isMuteChecked, _) => CheckboxWithLabel(
                value: isMuteChecked,
                onChanged: (value) => muteOldMod.value = value ?? false,
                labelWidget: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: "Also mute updates for the old mod (",
                      ),
                      modId(oldModId),
                      const TextSpan(
                        text:
                            "), since it will always redownload this new mod (",
                      ),
                      modId(newModId),
                      const TextSpan(text: ")."),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: isOldModEnabled
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Don't switch"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Switch"),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("OK"),
              ),
            ],
    );
  }
}

/// Joins names as "X", "X and Y", or "X, Y and Z".
String _joinNames(List<String> names) {
  if (names.length <= 1) return names.join();
  return "${names.sublist(0, names.length - 1).join(", ")} and ${names.last}";
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
    final isOldModEnabled = oldMod.isEnabledInGame;
    final oldModInfo = oldMod.findFirstEnabledOrHighestVersion?.modInfo;

    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (context) => ModIdChangeDialog(
        oldModName: oldModInfo?.nameOrId ?? oldMod.id,
        oldModId: oldMod.id,
        newModName: newVariant.modInfo.nameOrId,
        newModId: newVariant.modInfo.id,
        isOldModEnabled: isOldModEnabled,
        dependentNames: dependents
            .map(
              (mod) =>
                  mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ??
                  mod.id,
            )
            .toList(),
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
