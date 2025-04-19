import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:styled_text/styled_text.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/dashboard/game_settings_manager.dart';
import 'package:trios/jre_manager/ram_changer.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';

import '../models/download_progress.dart';
import '../widgets/disable_if_cannot_write_game_folder.dart';
import 'jre_entry.dart';
import 'jre_manager_logic.dart';

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
    final gameDir =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();

    if (gameDir == null) {
      return const Center(child: Text("Game directory not set."));
    }

    final jreManager = ref.watch(jreManagerProvider).value;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            child: SizedBox(
              width: 350,
              child: Column(
                children: [ChangeSettingsWidget(), ChangeJreWidget()],
              ),
            ),
          ),
          SizedBox(
            width: 350,
            child: ChangeRamWidget(
              currentRamAmountInMb: jreManager?.activeJre?.ramAmountInMb,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ChangeJreWidget extends ConsumerStatefulWidget {
  const ChangeJreWidget({super.key});

  @override
  ConsumerState createState() => _ChangeJreWidgetState();
}

class _ChangeJreWidgetState extends ConsumerState<ChangeJreWidget> {
  bool isModifyingFiles = false;

  @override
  Widget build(BuildContext context) {
    final jreManager = ref.watch(jreManagerProvider).valueOrNull;
    // final isUsingCustomJre = jreManager?.activeJre is CustomJreToDownload;
    final jres = jreManager?.installedJres.orEmpty().toList() ?? [];
    // final activeJres = jreManager?.activeJres.orEmpty().toList() ?? [];
    final activeJre = jreManager?.activeJre;
    final gameVersion =
        ref.watch(AppState.starsectorVersion).valueOrNull ?? "0.0.0";

    var iconSize = 40.0;

    return DisableIfCannotWriteGameFolder(
      child: Stack(
        children: [
          if (isModifyingFiles) const Center(child: RefreshProgressIndicator()),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              "JRE",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 32,
                              width: 32,
                              child: IconButton(
                                onPressed:
                                    () => ref.invalidate(jreManagerProvider),
                                icon: const Icon(Icons.refresh),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (var jre
                        in jres..sort(
                          (a, b) => a.versionString.compareTo(b.versionString),
                        ))
                      Builder(
                        builder: (context) {
                          var missingFilesForJre =
                              jre is JreEntryInstalled
                                  ? jre.missingFiles()
                                  : <String>[];
                          final isSupported = jre.isGameVersionSupported(
                            gameVersion,
                          );
                          final isEnabled = jre.isGameVersionSupported(
                            gameVersion,
                          );
                          return MovingTooltipWidget.text(
                            warningLevel:
                                jre is JreToDownload
                                    ? TooltipWarningLevel.warning
                                    : null,
                            message:
                                !isSupported
                                    ? "This JRE is not supported for $gameVersion."
                                    : jre is JreToDownload
                                    ? "Run ${Constants.appName} as an administrator if installation hangs after downloading."
                                    : jre == activeJre
                                    ? "Active"
                                    : null,
                            child: Disable(
                              isEnabled: isEnabled,
                              child: ConditionalWrap(
                                condition: jre != activeJre,
                                wrapper:
                                    (child) =>
                                        missingFilesForJre.isNotEmpty
                                            ? child
                                            : InkWell(
                                              onTap: () async {
                                                if (jre is JreToDownload) {
                                                  // confirmation dialog
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          "Download JRE",
                                                        ),
                                                        content: Text(
                                                          "Are you sure you want to download Java ${jre.versionString}?"
                                                          "\n"
                                                          "If it fails, please try running ${Constants.appName} as an administrator and trying again.",
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                            child: const Text(
                                                              "Cancel",
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                              await ref
                                                                  .read(
                                                                    jre
                                                                        .downloadProvider
                                                                        .notifier,
                                                                  )
                                                                  .installCustomJre();
                                                              ref.invalidate(
                                                                jreManagerProvider,
                                                              );
                                                            },
                                                            child: const Text(
                                                              "Download",
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                } else if (jre
                                                    is JreEntryInstalled) {
                                                  if (!jre
                                                      .isGameVersionSupported(
                                                        gameVersion,
                                                      )) {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => const AlertDialog(
                                                            content: Text(
                                                              "This game version is not supported.",
                                                            ),
                                                          ),
                                                    );
                                                  } else {
                                                    setState(() {
                                                      isModifyingFiles = true;
                                                    });
                                                    await ref
                                                        .read(
                                                          jreManagerProvider
                                                              .notifier,
                                                        )
                                                        .changeActiveJre(jre);
                                                    setState(() {
                                                      isModifyingFiles = false;
                                                    });
                                                  }
                                                }
                                              },
                                              mouseCursor:
                                                  WidgetStateMouseCursor
                                                      .clickable,
                                              child: child,
                                            ),
                                child: Opacity(
                                  opacity: isEnabled ? 1 : 0.5,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Row(
                                      children: [
                                        jre == activeJre
                                            ? Container(
                                              width: iconSize,
                                              height: iconSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                              child: Icon(
                                                Icons.coffee,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                              ),
                                            )
                                            : SizedBox(
                                              width: iconSize,
                                              height: iconSize,
                                              child: Icon(
                                                jre is JreEntryInstalled
                                                    ? Icons.coffee
                                                    : Icons.download,
                                              ),
                                            ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                              bottom: 8,
                                              top: 8,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      WidgetSpan(
                                                        alignment:
                                                            PlaceholderAlignment
                                                                .middle,
                                                        child: Text(
                                                          "Java ${jre.versionInt}",
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.titleMedium?.copyWith(
                                                            color:
                                                                jre == activeJre
                                                                    ? Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .primary
                                                                    : null,
                                                          ),
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            "  (${jre.versionString})",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (jre is JreEntryInstalled)
                                                  Opacity(
                                                    opacity: 0.8,
                                                    child: Text(
                                                      "${jre.jreAbsolutePath.name}/",
                                                      style:
                                                          Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall,
                                                    ),
                                                  ),
                                                if (jre is JreToDownload)
                                                  Builder(
                                                    builder: (context) {
                                                      final downloadState =
                                                          ref
                                                              .watch(
                                                                jre.downloadProvider,
                                                              )
                                                              .valueOrNull;
                                                      return downloadState
                                                                  ?.downloadProgress ==
                                                              null
                                                          ? Text(
                                                            "Click to download",
                                                            style: Theme.of(
                                                                  context,
                                                                )
                                                                .textTheme
                                                                .labelLarge
                                                                ?.copyWith(
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                ),
                                                          )
                                                          : TriOSDownloadProgressIndicator(
                                                            value:
                                                                downloadState
                                                                    ?.downloadProgress ??
                                                                TriOSDownloadProgress(
                                                                  0,
                                                                  1,
                                                                  isIndeterminate:
                                                                      false,
                                                                ),
                                                          );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (jre is CustomJreToDownload)
                                          Builder(
                                            builder: (context) {
                                              return MovingTooltipWidget.text(
                                                message: "Download links",
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.info_outline,
                                                  ),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                            "Download Info",
                                                          ),
                                                          content: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                "JRE will be downloaded from:",
                                                              ),
                                                              Linkify(
                                                                text:
                                                                    jre.versionCheckerUrl,
                                                                onOpen: (link) {
                                                                  OpenFilex.open(
                                                                    link.url,
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          )
                                        else if (jre is JreEntryInstalled &&
                                            missingFilesForJre.isNotEmpty)
                                          Builder(
                                            builder: (context) {
                                              return MovingTooltipWidget.text(
                                                message:
                                                    "Broken installation!"
                                                    "\n${missingFilesForJre.map((file) => "$file is missing").join("\n")}",
                                                child: const Icon(
                                                  Icons.error,
                                                  color:
                                                      ThemeManager
                                                          .vanillaErrorColor,
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (jres.countWhere((it) => it is MikohimeCustomJreEntry) >
                        1)
                      MovingTooltipWidget.text(
                        message:
                            "Because Mikohime JREs use the same 'mikohime' folder and same launcher .bat files, you may see more than one here but "
                            "launching any of them will only run the last one installed.",
                        child: Text(
                          "Multiple \"Mikohime\" JREs are not supported."
                          "\nOnly the last-installed one will run.",
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChangeRamWidget extends StatelessWidget {
  const ChangeRamWidget({super.key, required this.currentRamAmountInMb});

  final String? currentRamAmountInMb;

  @override
  Widget build(BuildContext context) {
    return DisableIfCannotWriteGameFolder(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text("RAM", style: Theme.of(context).textTheme.titleLarge),
                StyledText(
                  text:
                      currentRamAmountInMb == null
                          ? "No vmparams file found."
                          : "Assigned: <b>${currentRamAmountInMb!} MB</b>",
                  tags: {
                    "b": StyledTextTag(
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  },
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
                  child: Text(
                    "Game Settings",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                gameSettingsPvdr.when(
                  data:
                      (gameSettings) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FPS Limit",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          gameSettings.fps == null
                              ? TextTriOS(
                                "Unable to read FPS Limit from settings.json",
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: warningColor,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: fpsSliderValue!.toDouble(),
                                      min: 30,
                                      max: 144,
                                      divisions: 114,
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
                                              .read(
                                                gameSettingsProvider.notifier,
                                              )
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
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: warningColor,
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
                                    labelStyle:
                                        Theme.of(context).textTheme.labelLarge,
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
                  error:
                      (err, stack) => TextTriOS(
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
