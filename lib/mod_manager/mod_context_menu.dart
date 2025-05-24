import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/force_game_version_warning_dialog.dart';

ContextMenu buildModContextMenu(
  Mod mod,
  WidgetRef ref,
  BuildContext context, {
  bool showSwapToVersion = true,
}) {
  final currentStarsectorVersion = ref.read(
    appSettings.select((s) => s.lastStarsectorVersion),
  );
  final modVariant = mod.findFirstEnabledOrHighestVersion!;
  final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

  return ContextMenu(
    entries: <ContextMenuEntry>[
      if (!isGameRunning && showSwapToVersion)
        buildMenuItemChangeVersion(mod, ref),
      buildMenuItemOpenFolder(mod),
      buildMenuItemOpenModInfoFile(mod),
      buildMenuItemOpenForumPage(modVariant, context),
      if (ref.watch(AppState.vramEstimatorProvider).valueOrNull?.isScanning !=
          true)
        buildMenuItemCheckVram(mod, ref),
      buildMenuItemToggleMuteUpdates(mod, ref),
      if (!isGameRunning) menuItemDeleteFolder(mod, context, ref),
      if (isModGameVersionIncorrect(
        currentStarsectorVersion,
        isGameRunning,
        modVariant,
      ))
        buildMenuItemForceChangeModGameVersion(
          currentStarsectorVersion!,
          ref,
          modVariant,
        ),
      buildMenuItemDebugging(context, mod, ref, isGameRunning),
    ],
    padding: const EdgeInsets.all(8.0),
  );
}

ContextMenu buildModBulkActionContextMenu(
  List<Mod> selectedMods,
  WidgetRef ref,
  BuildContext context,
) {
  final currentStarsectorVersion = ref.read(
    appSettings.select((s) => s.lastStarsectorVersion),
  );
  final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

  return ContextMenu(
    entries: <ContextMenuEntry>[
      MenuHeader(text: "${selectedMods.length} mods selected"),
      if (!isGameRunning && selectedMods.any((mod) => !mod.hasEnabledVariant))
        MenuItem(
          label: 'Enable',
          icon: Icons.toggle_on,
          onSelected: () async {
            for (final mod in selectedMods.sublist(
              0,
              selectedMods.length - 1,
            )) {
              await ref
                  .read(modManager.notifier)
                  .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                    mod,
                    mod.findHighestVersion,
                    validateDependencies: false,
                  );
            }
            // Validate dependencies only at the end.
            await ref
                .read(modManager.notifier)
                .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                  selectedMods.last,
                  selectedMods.last.findHighestVersion,
                  validateDependencies: true,
                );
            ref.invalidate(AppState.modVariants);
          },
        ),
      if (!isGameRunning && selectedMods.any((mod) => mod.hasEnabledVariant))
        MenuItem(
          label: 'Disable',
          icon: Icons.toggle_off,
          onSelected: () async {
            // Validate dependencies only at the end.
            for (final mod in selectedMods.sublist(
              0,
              selectedMods.length - 1,
            )) {
              // Don't need to use changeActiveModVariantWithForceModGameVersionDialogIfNeeded because we're disabling the mod.
              await ref
                  .read(modManager.notifier)
                  .changeActiveModVariant(
                    mod,
                    null,
                    validateDependencies: false,
                  );
            }
            // Validate dependencies only at the end.
            await ref
                .read(modManager.notifier)
                .changeActiveModVariant(
                  selectedMods.last,
                  null,
                  validateDependencies: true,
                );
            ref.invalidate(AppState.modVariants);
          },
        ),
      // check vram of selected
      MenuItem(
        label: 'Check VRAM of selected',
        icon: Icons.memory,
        onSelected: () {
          ref
              .read(AppState.vramEstimatorProvider.notifier)
              .startEstimating(
                variantsToCheck: selectedMods
                    .map((mod) => mod.findFirstEnabledOrHighestVersion!)
                    .toList(),
              );
        },
      ),
      MenuItem(
        label: 'Check for updates',
        icon: Icons.refresh,
        onSelected: () {
          ref
              .read(AppState.versionCheckResults.notifier)
              .refresh(
                skipCache: true,
                specificVariantsToCheck: selectedMods
                    .map((mod) => mod.findFirstEnabledOrHighestVersion!)
                    .toList(),
              );
        },
      ),
      MenuItem(
        label: 'Copy to clipboard',
        icon: Icons.copy,
        onSelected: () {
          copyModListToClipboardFromMods(selectedMods, context);
        },
      ),

      if (selectedMods.any(
        (mod) => isModGameVersionIncorrect(
          currentStarsectorVersion,
          isGameRunning,
          mod.findFirstEnabledOrHighestVersion!,
        ),
      ))
        MenuItem(
          label: 'Force to $currentStarsectorVersion',
          icon: Icons.electric_bolt,
          onSelected: () {
            showDialog(
              context: ref.context,
              builder: (context) {
                return ForceGameVersionWarningDialog(mods: selectedMods);
              },
            );
          },
        ),
    ],
    padding: const EdgeInsets.all(8.0),
  );
}
