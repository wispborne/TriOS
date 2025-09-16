import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/game_paths_setup_widget/game_paths_setup_controller.dart';
import 'package:trios/widgets/under_construction_overlay.dart';

import 'custom_path_field_widget.dart';

class GamePathsWidget extends ConsumerWidget {
  const GamePathsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(gamePathsSetupControllerProvider.notifier);
    final state = ref.watch(gamePathsSetupControllerProvider);
    final settings = ref.watch(appSettings);

    return Column(
      children: [
        // Game Path Field (always enabled, no checkbox)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: state.gamePathText),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelStyle: Theme.of(context).textTheme.labelLarge,
                    errorText: state.gamePathExists
                        ? null
                        : "Starsector not found",
                    labelText: 'Starsector Folder',
                  ),
                  onChanged: (newGameDir) {
                    controller.updateGamePath(newGameDir);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder),
                onPressed: () async {
                  final newGameDir = await FilePicker.platform
                      .getDirectoryPath();
                  if (newGameDir == null) return;
                  controller.updateGamePath(newGameDir);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Custom Paths
        CustomPathField(
          labelText: "Starsector launcher path",
          checkboxTooltip: "When checked, uses the custom launcher path",
          fieldTooltip: "Allows you to set a custom Starsector launcher path",
          currentPath: state.customExecutablePathText,
          isEnabled: settings.useCustomGameExePath,
          isDirectoryPicker: false,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Starsector launcher",
          validatePath: (path) => state.customExecutablePathExists,
          errorMessage: "Path does not exist",
          onEnabledChanged: (isEnabled) {
            controller.toggleUseCustomExecutable(isEnabled);
          },
          onPathChanged: (path) {
            controller.updateCustomExecutablePath(path);
          },
        ),
        const SizedBox(height: 16),
        UnderConstructionOverlay(
          child: CustomPathField(
            labelText: "Mods path",
            checkboxTooltip: "When checked, uses the custom mod folder",
            fieldTooltip: "Allows you to set a custom mod folder",
            currentPath: state.customModsPathText,
            isEnabled: state.useCustomModsPath,
            isDirectoryPicker: false,
            initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
            pickerDialogTitle: "Select Mods folder",
            validatePath: (path) => state.customModsPathExists,
            errorMessage: "Path does not exist",
            onEnabledChanged: (isEnabled) {
              controller.toggleUseCustomModsPath(isEnabled);
            },
            onPathChanged: (path) {
              controller.updateCustomModsPath(path);
            },
          ),
        ),
      ],
    );
  }
}
