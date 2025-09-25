import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../chipper/chipper_state.dart';
import '../chipper/views/chipper_log.dart';
import '../jre_manager/game_performance_widget.dart';
import '../jre_manager/jre_manager_logic.dart';
import '../widgets/trios_expansion_tile.dart';
import 'launch_with_settings.dart';
import 'mod_list_basic.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // For startup performance, wait to load until after mods have loaded.
    if (ref.watch(AppState.mods).isNotEmpty) {
      if (ref.read(ChipperState.logRawContents).valueOrNull == null) {
        ref.read(ChipperState.logRawContents.notifier).loadDefaultLog();
      }
    }

    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;
    final logfile = ref
        .watch(ChipperState.logRawContents)
        .valueOrNull
        ?.filepath
        ?.toFile();

    return Theme(
      data: Theme.of(context).lowContrastCardTheme(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Tooltip(
                  message: isGameRunning ? "Game is running" : "",
                  child: Disable(
                    isEnabled: !isGameRunning,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            LaunchWithSettings(isGameRunning: isGameRunning),
                            if (Platform.isWindows)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: TriOSExpansionTile(
                                  title: const Text(
                                    "JRE, RAM, and Game Settings",
                                  ),
                                  leading: const Icon(Icons.speed, size: 32),
                                  subtitle: Text(
                                    "Java ${ref.watch(AppState.activeJre).valueOrNull?.version.versionString ?? "(unknown JRE)"} • ${ref.watch(currentRamAmountInMb).valueOrNull ?? "(unknown RAM)"} MB",
                                  ),
                                  collapsedBackgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow
                                      .withOpacity(0.5),
                                  children: const [GamePerformanceWidget()],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Builder(
                        builder: (context) {
                          final errors = ref
                              .watch(ChipperState.logRawContents)
                              .valueOrNull;
                          final theme = Theme.of(context);
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    MovingTooltipWidget.text(
                                      message:
                                          "Errors are normal. You can ignore them unless Starsector is misbehaving."
                                          "\n"
                                          "\nIf there is a crash, look at the bottom of the log for a bunch of lines starting with 'at'. Hopefully, one of them will mention the problematic mod's id, name, or prefix."
                                          "\nFor example, 'at data.scripts.campaign.II_IGFleetInflater.inflate(II_IGFleetInflater.java:59)' shows 'II_', which is Interstellar Imperium."
                                          "\n"
                                          "\nMake sure your mods are up to date and report bugs to the mod makers!",
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Starsector Log",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(fontSize: 20),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                              top: 4,
                                            ),
                                            child: Icon(
                                              Icons.info_outline,
                                              size: 18,
                                              color: theme.iconTheme.color
                                                  ?.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    MovingTooltipWidget.text(
                                      message: logfile?.path ?? "",
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "${logfile?.nameWithExtension ?? ""} • last updated ${errors?.lastUpdated?.relativeTimestamp() ?? "unknown"}",
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        top: 4,
                                      ),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          final path = ref
                                              .read(ChipperState.logRawContents)
                                              .value
                                              ?.filepath;
                                          if (path != null) {
                                            final file = File(path);
                                            launchUrlString(
                                              file.absolute.normalize.path,
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.launch_rounded,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        style: ButtonStyle(
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                                theme.colorScheme.onSurface,
                                              ),
                                        ),
                                        label: const Text("Open"),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        top: 4,
                                      ),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          ref
                                              .read(
                                                ChipperState
                                                    .logRawContents
                                                    .notifier,
                                              )
                                              .loadDefaultLog();
                                        },
                                        icon: Icon(
                                          Icons.refresh,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        style: ButtonStyle(
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                                theme.colorScheme.onSurface,
                                              ),
                                        ),
                                        label: const Text("Reload"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: (errors != null)
                                    ? DefaultTextStyle.merge(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: ChipperLog(
                                            errors: errors.errorBlock,
                                            showInfoLogs: true,
                                            showInfoIcons: false,
                                          ),
                                        ),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(fontSize: 14),
                                      )
                                    : const SizedBox(
                                        width: 350,
                                        child: Column(
                                          children: [Text("No log loaded")],
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  "Errors are normal. If the game crashes, check here for fatal errors.",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.textTheme.labelMedium?.color
                                        ?.withValues(alpha: 0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 350, child: Card(child: ModListMini())),
        ],
      ),
    );
  }
}
