import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/force_game_version_warning_dialog.dart';

ContextMenu buildModContextMenu(
  Mod mod,
  WidgetRef ref,
  BuildContext context, {
  bool showSwapToVersion = true,
  bool showEstimateVram = true,
  Function(Mod? mod)? openSidebar,
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
      _buildCategorySubmenu(mod.id, ref, context),
      _buildColorSubmenu(mod.id, ref),
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
      if (!isGameRunning) menuItemDeleteFolder(mod, context, ref),
      MenuHeader(text: Constants.appName, disableUppercase: true),
      if (openSidebar != null)
        buildMenuItemOpenInSidebar(mod, ref, openSidebar),
      if (showEstimateVram &&
          ref.watch(AppState.vramEstimatorProvider).value?.isScanning != true)
        buildMenuItemCheckVram(mod, ref),
      buildMenuItemToggleMuteUpdates(mod, ref),
      if (false) // not done
        buildMenuItemViewModWeapons(context, mod, ref),
      // MenuHeader(text: "Debugging", disableUppercase: true),
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
      MenuHeader(text: "${selectedMods.length} mods"),
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
            ref.read(AppState.modVariants.notifier).reloadModVariants();
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
            ref.read(AppState.modVariants.notifier).reloadModVariants();
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

      menuItemDeleteMultipleMods(selectedMods, context, ref),

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

const _colorPresets = <(String, Color)>[
  ('Red', Color(0xFFE53935)),
  ('Coral', Color(0xFFFF7043)),
  ('Amber', Color(0xFFFFCA28)),
  ('Chartreuse', Color(0xFFC0CA33)),
  ('Emerald', Color(0xFF00897B)),
  ('Sky', Color(0xFF42A5F5)),
  ('Violet', Color(0xFF7E57C2)),
  ('Rose', Color(0xFFEC407A)),
];

MenuItem _buildColorSubmenu(String modId, WidgetRef ref) {
  final currentColor = ref
      .read(AppState.modsMetadata)
      .value
      ?.getMergedModMetadata(modId)
      ?.color;

  return MenuItem.submenu(
    label: 'Color',
    icon: Icons.palette,
    items: [
      MenuItem(
        label: '',
        icon: Icons.clear,
        padding: .only(left: 4),
        onSelected: () {
          ref
              .read(AppState.modsMetadata.notifier)
              .updateModUserMetadata(modId, (old) => old.copyWith(color: null));
        },
      ),
      ..._colorPresets.map(
        (preset) => _ColorMenuItem(
          label: preset.$1,
          color: preset.$2,
          isSelected: currentColor?.toARGB32() == preset.$2.toARGB32(),
          onSelected: () {
            ref
                .read(AppState.modsMetadata.notifier)
                .updateModUserMetadata(
                  modId,
                  (old) => old.copyWith(color: preset.$2),
                );
          },
        ),
      ),
    ],
  );
}

MenuItem _buildCategorySubmenu(
  String modId,
  WidgetRef ref,
  BuildContext context,
) {
  final notifier = ref.read(categoryManagerProvider.notifier);
  final allCategories = notifier.getAllCategories();
  final assignments = notifier.getAssignmentsForMod(modId);
  final assignedIds = assignments.map((a) => a.categoryId).toSet();

  return MenuItem.submenu(
    label: 'Categories',
    icon: Icons.category,
    items: [
      ...allCategories.map((category) {
        final isAssigned = assignedIds.contains(category.id);
        return CheckableMenuItem(
          label: category.name,
          isChecked: isAssigned,
          onSelected: () {
            if (isAssigned) {
              notifier.removeCategoryFromMod(modId, category.id);
            } else {
              notifier.addCategoryToMod(modId, category.id);
            }
          },
        );
      }),
    ],
  );
}

final class _ColorMenuItem extends ContextMenuItem<void> {
  final String label;
  final Color color;
  final bool isSelected;

  const _ColorMenuItem({
    required this.label,
    required this.color,
    required this.isSelected,
    super.onSelected,
  });

  @override
  Widget builder(
    BuildContext context,
    ContextMenuState menuState, [
    FocusNode? focusNode,
  ]) {
    final isFocused = menuState.focusedEntry == this;
    final theme = Theme.of(context);
    final background = theme.colorScheme.surfaceContainerLow;
    final normalTextColor = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(alpha: 0.7),
      background,
    );
    final focusedTextColor = theme.colorScheme.onSurface;

    return ConstrainedBox(
      constraints: const BoxConstraints.expand(height: 32.0),
      child: Material(
        color: isFocused ? theme.focusColor.withAlpha(20) : background,
        borderRadius: BorderRadius.circular(4.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => handleItemSelection(context),
          canRequestFocus: false,
          child: Row(
            children: [
              const SizedBox(width: 8.0),
              SizedBox.square(
                dimension: 32.0,
                child: Center(
                  child: Container(
                    width: isSelected ? 32 : 12,
                    height: isSelected ? 16 : 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(isSelected ? 4 : 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  String get debugLabel => "[${hashCode.toString().substring(0, 5)}] $label";
}
