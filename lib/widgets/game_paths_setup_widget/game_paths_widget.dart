import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/game_paths_setup_widget/game_paths_setup_controller.dart';

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
                    labelText: 'Game Folder',
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
          labelText: "Starsector launcher",
          checkboxTooltip: "When checked, uses the custom launcher path",
          fieldTooltip: "Allows you to set a custom Starsector launcher path",
          currentPath: state.customExecutablePathState.pathText,
          isEnabled: settings.useCustomGameExePath,
          isDirectoryPicker: false,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Starsector launcher",
          errorMessage: state.customExecutablePathState.pathExists
              ? null
              : "Path does not exist",
          onEnabledChanged: (isEnabled) {
            controller.toggleUseCustomExecutable(isEnabled);
          },
          onPathChanged: controller.updateCustomExecutablePath,
          onSubmitted: controller.submitCustomExecutablePath,
        ),
        const SizedBox(height: 16),
        CustomPathField(
          labelText: "Mods",
          checkboxTooltip: "When checked, uses the custom mod folder",
          fieldTooltip: "Allows you to set a custom mod folder",
          currentPath: state.customModsPathState.pathText,
          isEnabled: state.customModsPathState.useCustomPath,
          isDirectoryPicker: true,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Mods folder",
          errorMessage: state.customModsPathState.pathExists
              ? null
              : "Path does not exist",
          onEnabledChanged: (isEnabled) {
            controller.toggleUseCustomModsPath(isEnabled);
          },
          onPathChanged: controller.updateCustomModsPath,
          onSubmitted: controller.submitCustomModsPath,
        ),
        const SizedBox(height: 16),
        CustomPathField(
          labelText: "Saves",
          checkboxTooltip: "When checked, uses the custom saves folder",
          fieldTooltip: "Allows you to set a custom saves folder",
          currentPath: state.customSavesPathState.pathText,
          isEnabled: state.customSavesPathState.useCustomPath,
          isDirectoryPicker: true,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Saves folder",
          errorMessage: state.customSavesPathState.pathExists
              ? null
              : "Path does not exist",
          onEnabledChanged: (isEnabled) {
            controller.toggleUseCustomSavesPath(isEnabled);
          },
          onPathChanged: controller.updateCustomSavesPath,
          onSubmitted: controller.submitCustomSavesPath,
        ),
        const SizedBox(height: 16),
        CustomPathField(
          labelText: "Core data",
          checkboxTooltip:
              "When checked, uses the custom core folder."
              "\nThis is the folder that contains data, graphics, sounds, and jar files.",
          fieldTooltip: "Allows you to set a custom core folder",
          currentPath: state.customCorePathState.pathText,
          isEnabled: state.customCorePathState.useCustomPath,
          isDirectoryPicker: true,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Core folder",
          errorMessage: state.customCorePathState.pathExists
              ? null
              : "Path does not exist",
          onEnabledChanged: (isEnabled) {
            controller.toggleUseCustomCorePath(isEnabled);
          },
          onPathChanged: controller.updateCustomCorePath,
          onSubmitted: controller.submitCustomCorePath,
        ),
      ],
    );
  }
}
