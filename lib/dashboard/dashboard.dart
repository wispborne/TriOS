import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/utils/extensions.dart';

import '../chipper/chipper_state.dart';
import '../chipper/views/chipper_log.dart';
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

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Card(
                  child: Padding(
                padding: EdgeInsets.all(8),
                child: LaunchWithSettings(),
              )),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("Chipper Log Viewer",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 20)),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
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
                              Text(
                                  ref
                                          .watch(ChipperState.logRawContents)
                                          .valueOrNull
                                          ?.filepath
                                          ?.toFile()
                                          .nameWithExtension ??
                                      "",
                                  style: Theme.of(context).textTheme.labelSmall)
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
    );
  }
}
