import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/game_paths_widget/game_paths_controller.dart';

import 'custom_path_field_widget.dart';

class GamePathsWidget extends ConsumerStatefulWidget {
  const GamePathsWidget({super.key});

  @override
  ConsumerState<GamePathsWidget> createState() => _GamePathsWidgetState();
}

class _GamePathsWidgetState extends ConsumerState<GamePathsWidget> {
  // Not to be confused with [GamePathsController].
  final gamePathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(gamePathsControllerProvider);
    gamePathController.text = state.gamePathText;
  }

  @override
  Widget build(BuildContext context) {
    final customGamePathsController = ref.watch(
      gamePathsControllerProvider.notifier,
    );
    final state = ref.watch(gamePathsControllerProvider);
    final settings = ref.watch(appSettings);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game Path Field (always enabled, no checkbox)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: gamePathController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelStyle: theme.textTheme.labelLarge,
                    errorText: state.gamePathExists
                        ? null
                        : "Starsector not found",
                    labelText: 'Game Folder',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder),
                onPressed: () async {
                  final newGameDir = await FilePicker.platform
                      .getDirectoryPath();
                  if (newGameDir == null) return;
                  customGamePathsController.updateGamePath(newGameDir);
                },
              ),
              if (gamePathController.text != state.gamePathText)
                TextButton.icon(
                  label: const Text("Apply"),
                  icon: const Icon(Icons.check),
                  onPressed: () => customGamePathsController.updateGamePath(
                    gamePathController.text,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Custom Paths
        CustomPathField(
          labelText: "Starsector launcher",
          checkboxTooltip: "If checked, overrides the default path.",
          fieldTooltip:
              "What to launch when you click 'Launch' within ${Constants.appName}.",
          pathWhenUnchecked: state.customExecutablePathState.defaultPath,
          customPathWhenChecked: state.customExecutablePathState.customPath,
          isChecked: state.customExecutablePathState.useCustomPath,
          isDirectoryPicker: false,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Starsector launcher",
          errorMessage: state.customExecutablePathState.pathExists
              ? null
              : "Path does not exist",
          onCheckedChanged: (isEnabled) {
            customGamePathsController.toggleUseCustomExecutable(isEnabled);
          },
          onPathChanged: customGamePathsController.updateCustomExecutablePath,
          onSubmitted: customGamePathsController.submitCustomExecutablePath,
        ),
        const SizedBox(height: 16),
        CustomPathField(
          labelText: "Mods",
          checkboxTooltip: "If checked, overrides the default path.",
          fieldTooltip: "Where your mods are located.",
          pathWhenUnchecked: state.customModsPathState.defaultPath,
          customPathWhenChecked: state.customModsPathState.customPath,
          isChecked: state.customModsPathState.useCustomPath,
          isDirectoryPicker: true,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Mods folder",
          errorMessage: state.customModsPathState.pathExists
              ? null
              : "Path does not exist",
          onCheckedChanged: (isEnabled) {
            customGamePathsController.toggleUseCustomModsPath(isEnabled);
          },
          onPathChanged: customGamePathsController.updateCustomModsPath,
          onSubmitted: customGamePathsController.submitCustomModsPath,
        ),
        const SizedBox(height: 16),
        CustomPathField(
          labelText: "Saves",
          checkboxTooltip: "If checked, overrides the default path.",
          fieldTooltip: "Where the game's saves are located.",
          pathWhenUnchecked: state.customSavesPathState.defaultPath,
          customPathWhenChecked: state.customSavesPathState.customPath,
          isChecked: state.customSavesPathState.useCustomPath,
          isDirectoryPicker: true,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Saves folder",
          errorMessage: state.customSavesPathState.pathExists
              ? null
              : "Path does not exist",
          onCheckedChanged: (isEnabled) {
            customGamePathsController.toggleUseCustomSavesPath(isEnabled);
          },
          onPathChanged: customGamePathsController.updateCustomSavesPath,
          onSubmitted: customGamePathsController.submitCustomSavesPath,
        ),
        const SizedBox(height: 16),
        CustomPathField(
          labelText: "Core data",
          checkboxTooltip: "If checked, overrides the default path.",
          fieldTooltip:
              "Where the game's data is located."
              "\nThis is the folder that contains data, graphics, sounds, and jar files.",
          pathWhenUnchecked: state.customCorePathState.defaultPath,
          customPathWhenChecked: state.customCorePathState.customPath,
          isChecked: state.customCorePathState.useCustomPath,
          isDirectoryPicker: true,
          initialDirectory: settings.gameDir?.path ?? defaultGamePath().path,
          pickerDialogTitle: "Select Core folder",
          errorMessage: state.customCorePathState.pathExists
              ? null
              : "Path does not exist",
          onCheckedChanged: (isEnabled) {
            customGamePathsController.toggleUseCustomCorePath(isEnabled);
          },
          onPathChanged: customGamePathsController.updateCustomCorePath,
          onSubmitted: customGamePathsController.submitCustomCorePath,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48, top: 16),
          child: Text(
            "These paths tell ${Constants.appName} where to look for data. They do not affect Starsector or how it loads data.",
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    gamePathController.dispose();
    super.dispose();
  }
}
