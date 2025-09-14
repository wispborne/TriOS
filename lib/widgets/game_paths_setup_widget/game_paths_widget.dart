import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/game_paths_setup_widget/game_paths_setup_controller.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class GamePathsWidget extends ConsumerStatefulWidget {
  const GamePathsWidget({super.key});

  @override
  ConsumerState<GamePathsWidget> createState() => _GamePathsWidgetState();
}

class _GamePathsWidgetState extends ConsumerState<GamePathsWidget> {
  final customExecutableTextController = TextEditingController();
  final gamePathTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(gamePathsSetupControllerProvider.notifier);
    final state = ref.watch(gamePathsSetupControllerProvider);

    customExecutableTextController.text = state.customExecutablePathText;
    gamePathTextController.text = state.gamePathText;
    final useCustomExecutable = ref.watch(
      appSettings.select((value) => value.useCustomGameExePath),
    );

    return Column(
      children: [
        _buildGamePathSection(context, controller, state),
        const SizedBox(height: 24),
        _buildCustomExecutableSection(
          context,
          controller,
          state,
          useCustomExecutable,
          ref,
        ),
      ],
    );
  }

  Widget _buildGamePathSection(
    BuildContext context,
    GamePathsSetupController controller,
    GamePathsSetupState state,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: gamePathTextController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelStyle: Theme.of(context).textTheme.labelLarge,
                errorText: state.gamePathExists ? null : "Starsector not found",
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
              var newGameDir = await FilePicker.platform.getDirectoryPath();
              if (newGameDir == null) return;
              controller.updateGamePath(
                newGameDir.toDirectory().normalize.path,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomExecutableSection(
    BuildContext context,
    GamePathsSetupController controller,
    GamePathsSetupState state,
    bool useCustomExecutable,
    WidgetRef ref,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MovingTooltipWidget.text(
              message: "When checked, uses the custom launcher path",
              child: Checkbox(
                value: useCustomExecutable,
                onChanged: (value) {
                  controller.toggleUseCustomExecutable(value ?? false);
                },
              ),
            ),
          ),
          Expanded(
            child: MovingTooltipWidget.text(
              message: "Allows you to set a custom Starsector launcher path",
              child: Disable(
                isEnabled: useCustomExecutable,
                child: TextField(
                  controller: customExecutableTextController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: state.customExePathExists
                        ? null
                        : "Path does not exist",
                    labelText: "Starsector launcher path",
                    hintStyle: Theme.of(context).textTheme.labelLarge,
                    labelStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  onChanged: (newPath) {
                    controller.updateCustomExecutablePath(newPath);
                  },
                ),
              ),
            ),
          ),
          Disable(
            isEnabled: useCustomExecutable,
            child: IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () async {
                final settings = ref.read(appSettings);
                var newPath = (await FilePicker.platform.pickFiles(
                  dialogTitle: "Select Starsector launcher",
                  allowMultiple: false,
                  initialDirectory:
                      settings.gameDir?.path ?? defaultGamePath().path,
                ))?.paths.firstOrNull;
                if (newPath == null) return;
                controller.updateCustomExecutablePath(newPath);
              },
            ),
          ),
        ],
      ),
    );
  }
}
