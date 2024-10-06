import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';

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
    if (ref.read(ChipperState.logRawContents).valueOrNull == null) {
      loadDefaultLog(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final logfile =
        ref.watch(ChipperState.logRawContents).valueOrNull?.filepath?.toFile();
    return Theme(
      data: Theme.of(context).lowContrastCardTheme(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Card(
                    child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      const LaunchWithSettings(),
                      if (Platform.isWindows)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TriOSExpansionTile(
                            title: const Text("JRE & RAM Settings"),
                            leading: const Icon(Icons.speed, size: 32),
                            subtitle: Text(
                                "Java ${ref.watch(AppState.activeJre).valueOrNull?.version.versionString ?? "(unknown JRE)"} • ${ref.watch(currentRamAmountInMb).valueOrNull ?? "(unknown RAM)"} MB"),
                            collapsedBackgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow
                                .withOpacity(0.5),
                            children: const [
                              GamePerformanceWidget(),
                            ],
                          ),
                        )
                    ],
                  ),
                )),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("Starsector Log",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontSize: 20)),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, top: 4),
                                  child: TextButton.icon(
                                      onPressed: () {
                                        loadDefaultLog(ref);
                                      },
                                      icon: const Icon(Icons.refresh),
                                      style: ButtonStyle(
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurface)),
                                      label: const Text("Reload")),
                                ),
                                const Spacer(),
                                Tooltip(
                                  message: logfile?.path ?? "",
                                  child: Text(logfile?.nameWithExtension ?? "",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: Builder(builder: (context) {
                              // ChipperState.loadedLog.addListener(() {
                              //   setState(() {});
                              // });
                              final errors = ref
                                  .watch(ChipperState.logRawContents)
                                  .valueOrNull
                                  ?.errorBlock;
                              if (errors != null) {
                                return DefaultTextStyle.merge(
                                    child: ChipperLog(
                                        errors: errors, showInfoLogs: true),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 14));
                              } else {
                                return const SizedBox(
                                    width: 350,
                                    child: Column(
                                      children: [
                                        Text("No log loaded"),
                                      ],
                                    ));
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 350, child: Card(child: ModListMini()))
        ],
      ),
    );
  }
}
