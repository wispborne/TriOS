import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:styled_text/styled_text.dart';
import 'package:trios/dashboard/game_settings_manager.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vmparams/vmparams_file_selector_dialog.dart';
import 'package:trios/vmparams/vmparams_manager.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/trios/constants_theme.dart';

import '../vmparams/ram_changer.dart';
import '../widgets/disable_if_cannot_write_game_folder.dart';

class GamePerformanceWidget extends ConsumerStatefulWidget {
  const GamePerformanceWidget({super.key});

  @override
  ConsumerState createState() => _GamePerformanceWidgetState();
}

class _GamePerformanceWidgetState extends ConsumerState<GamePerformanceWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gameDir = ref.read(AppState.gameFolder).value?.toDirectory();

    if (gameDir == null) {
      return const Center(child: Text("Game directory not set."));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            child: SizedBox(
              width: 350,
              child: Column(children: [ChangeSettingsWidget()]),
            ),
          ),
          SizedBox(width: 350, child: ChangeRamWidget()),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ChangeRamWidget extends ConsumerWidget {
  const ChangeRamWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmState = ref.watch(vmparamsManagerProvider).value;
    final ramAmount = vmState?.currentRamAmountInMb;
    final hasMultipleWithDifferentRam =
        vmState?.hasMultipleFilesWithDifferentRam ?? false;

    return DisableIfCannotWriteGameFolder(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Text(
                        "RAM",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MovingTooltipWidget.text(
                        message: "Choose which vmparams files to manage",
                        child: SizedBox(
                          height: 32,
                          width: 32,
                          child: IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    const VmparamsFileSelectorDialog(),
                              );
                            },
                            icon: const Icon(Icons.settings, size: 20),
                            padding: EdgeInsets.zero,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasMultipleWithDifferentRam)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 24,
                          color: TriOSThemeConstants.vanillaWarningColor,
                        ),
                      ),
                    MovingTooltipWidget.text(
                      message:
                          "vmparams files:\n${ref.watch(vmparamsManagerProvider).value?.detectedVmparamsFiles.joinToString(separator: "\n", transform: (file) => file.nameWithExtension)}",
                      child: StyledText(
                        text: ramAmount == null
                            ? "No vmparams file found."
                            : hasMultipleWithDifferentRam
                            ? "<b>Warning</b>: Not all vmparams files"
                                  "\nare set to use the same amount of RAM."
                                  "\nPick one RAM option below to set all"
                                  "\nto the same value."
                            : "Assigned: <b>$ramAmount MB</b> in <b>${ref.watch(vmparamsManagerProvider).value?.detectedVmparamsFiles.length}</b> files",
                        tags: {
                          "b": StyledTextTag(
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        },
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      left: 4.0,
                      right: 4.0,
                      bottom: 8,
                    ),
                    child: RamChanger(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "More RAM is not always better.\n6 or 8 GB is enough for almost any game.\n\nUse the Console Commands mod to view RAM use in the top-left of the console.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChangeSettingsWidget extends ConsumerStatefulWidget {
  const ChangeSettingsWidget({super.key});

  @override
  ConsumerState createState() => _ChangeSettingsWidgetState();
}

class _ChangeSettingsWidgetState extends ConsumerState<ChangeSettingsWidget> {
  int? fpsSliderValue;

  @override
  Widget build(BuildContext context) {
    final fpsInSettings = ref.watch(gameSettingsProvider).value?.fps;

    if (fpsSliderValue == null && fpsInSettings != null) {
      setState(() {
        fpsSliderValue = fpsInSettings;
      });
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Builder(
          builder: (context) {
            final gameSettingsPvdr = ref.watch(gameSettingsProvider);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          "Game Settings",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: MovingTooltipWidget.text(
                          message:
                              "Open config.json in your default text editor",
                          child: SizedBox(
                            height: 32,
                            width: 32,
                            child: IconButton(
                              onPressed: () => ref
                                  .read(gameSettingsProvider.notifier)
                                  .settingsFile
                                  .path
                                  .openAsUriInBrowser(),
                              icon: SvgImageIcon(
                                "assets/images/icon-file-settings.svg",
                              ),
                              padding: EdgeInsets.zero,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                gameSettingsPvdr.when(
                  data: (gameSettings) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "FPS Limit",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SizedBox(width: 8),
                          MovingTooltipWidget.text(
                            message:
                                "Recommended: Set your max FPS to your monitor's refresh rate or lower.",
                            child: Icon(
                              Icons.info_outlined,
                              size: 20,
                              color: Theme.of(
                                context,
                              ).iconTheme.color?.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      gameSettings.fps == null
                          ? TextTriOS(
                              "Unable to read FPS Limit from settings.json",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: TriOSThemeConstants.vanillaWarningColor,
                                  ),
                            )
                          : Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                  ),
                                  child: Text(
                                    "$fpsSliderValue",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: fpsSliderValue!.toDouble(),
                                    min: 30,
                                    max: 240,
                                    divisions: 240,
                                    padding: EdgeInsets.zero,
                                    onChangeEnd: (value) {
                                      ref
                                          .read(gameSettingsProvider.notifier)
                                          .setFps(value.toInt());
                                      fpsSliderValue = value.toInt();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        fpsSliderValue = value.toInt();
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: MovingTooltipWidget.text(
                                    message: "Reset to 60 FPS",
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        ref
                                            .read(gameSettingsProvider.notifier)
                                            .setFps(60);
                                        setState(() {
                                          fpsSliderValue = 60;
                                        });
                                      },
                                      icon: Icon(Icons.restart_alt),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      gameSettings.vsync == null
                          ? TextTriOS(
                              "Unable to read Vsync from settings.json",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: TriOSThemeConstants.vanillaWarningColor,
                                  ),
                            )
                          : MovingTooltipWidget.text(
                              message:
                                  "Vsync reduces screen tearing but introduces a tiny input delay.",
                              child: Transform.translate(
                                offset: Offset(0, 0),
                                child: CheckboxWithLabel(
                                  label: "Use Vsync",
                                  value: gameSettings.vsync!,
                                  labelStyle: Theme.of(
                                    context,
                                  ).textTheme.labelLarge,
                                  onChanged: (value) {
                                    ref
                                        .read(gameSettingsProvider.notifier)
                                        .setVsync(value == true);
                                  },
                                ),
                              ),
                            ),
                    ],
                  ),
                  error: (err, stack) => TextTriOS(
                    "Error: $err",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  loading: () => CircularProgressIndicator(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
