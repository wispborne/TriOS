import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';

class ForceGameVersionWarningDialog extends ConsumerWidget {
  final ModVariant? modVariant;
  final List<Mod>? mods;
  final Function()? onForced;
  final bool refreshModlistAfter;

  ForceGameVersionWarningDialog({
    super.key,
    this.modVariant,
    this.mods,
    this.onForced,
    this.refreshModlistAfter = true,
  }) {
    assert(
      modVariant != null || mods?.isNotEmpty == true,
      "At least one of 'mods' or 'modVariant' must be provided",
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showForceUpdateWarning = ref.read(
      appSettings.select((s) => s.showForceUpdateWarning),
    );

    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;
    final currentStarsectorVersion = ref.read(
      appSettings.select((s) => s.lastStarsectorVersion),
    );

    if (currentStarsectorVersion == null) {
      return AlertDialog(
        title: const Text("Error"),
        content: const Text("Could not determine current Starsector version."),
      );
    }

    final modsToForce =
        (mods
                    ?.where(
                      (mod) => isModGameVersionIncorrect(
                        currentStarsectorVersion,
                        isGameRunning,
                        mod.findFirstEnabledOrHighestVersion!,
                      ),
                    )
                    .map((mod) => mod.findFirstEnabledOrHighestVersion!) ??
                [modVariant!])
            .toList();

    if (!showForceUpdateWarning) {
      _onPressedForce(context, modsToForce, ref, currentStarsectorVersion);
      return const SizedBox.shrink(); // Shouldn't be shown since we're popping the dialog.
    }

    final hasMultiple = modsToForce.length > 1;
    final singleModIntro = hasMultiple
        ? ""
        : "'${modsToForce.single.modInfo.nameOrId}' was made for Starsector ${modsToForce.single.modInfo.gameVersion}, but you can try running it in $currentStarsectorVersion.\n";

    // Split the singleModIntro into parts to apply bold formatting to the mod name
    final singleModIntroParts = hasMultiple
        ? <TextSpan>[]
        : [
            TextSpan(
              text: modsToForce.single.modInfo.nameOrId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  " was made for Starsector ${modsToForce.single.modInfo.gameVersion}, but you can try running it in $currentStarsectorVersion.\n",
            ),
          ];

    return AlertDialog(
      title: Text(
        "Force ${hasMultiple ? "${modsToForce.length} mods " : ""}to $currentStarsectorVersion?",
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                ...singleModIntroParts, // Use the split parts here
                TextSpan(
                  text:
                      "${hasMultiple ? singleModIntro : ""}Simple mods like portrait packs should be fine. Game updates usually don't break mods, but it depends on the mod and the game version.\n\n",
                ),
                if (hasMultiple)
                  TextSpan(
                    text:
                        "${modsToForce.joinToString(separator: '\n', transform: (mod) => "- ${mod.modInfo.nameOrId} (${mod.modInfo.version}) is meant for Starsector '${mod.modInfo.gameVersion}'.")}"
                        "\n\n",
                  ),
                TextSpan(
                  text: hasMultiple
                      ? "Are you sure you want to modify ${modsToForce.length} mod_info.json files "
                            "to run on $currentStarsectorVersion?"
                      : "Are you sure you want to modify the '${modsToForce.single.modInfo.nameOrId}' mod_info.json file "
                            "to run on $currentStarsectorVersion?",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 16),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: ConstrainedBox(
          //     constraints: const BoxConstraints(maxWidth: 360),
          //     child: StatefulBuilder(
          //       builder: (context, setState) {
          //         final showForceUpdateWarning = ref.watch(
          //           appSettings.select((s) => s.showForceUpdateWarning),
          //         );
          //
          //         return CheckboxListTile(
          //           value: !showForceUpdateWarning,
          //           controlAffinity: ListTileControlAffinity.leading,
          //           onChanged: (value) {
          //             ref
          //                 .read(appSettings.notifier)
          //                 .update(
          //                   (state) => state.copyWith(
          //                     showForceUpdateWarning: !(value ?? false),
          //                   ),
          //                 );
          //           },
          //           title: const Text("Don't show this warning again"),
          //           contentPadding: EdgeInsets.zero,
          //           dense: true,
          //         );
          //       },
          //     ),
          //   ),
          // ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            _onPressedForce(
              context,
              modsToForce,
              ref,
              currentStarsectorVersion,
            );
          },
          child: const Text("Force"),
        ),
      ],
    );
  }

  void _onPressedForce(
    BuildContext context,
    List<ModVariant> modsToForce,
    WidgetRef ref,
    String currentStarsectorVersion,
  ) {
    Navigator.of(context).pop();
    for (final variant in modsToForce) {
      ref
          .read(modManager.notifier)
          .forceChangeModGameVersion(
            variant,
            currentStarsectorVersion,
            refreshModlistAfter: refreshModlistAfter,
          );
    }
    ref.read(AppState.modVariants.notifier).reloadModVariants();
    onForced?.call();
  }
}
