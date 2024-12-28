import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:styled_text/styled_text.dart';
import 'package:trios/jre_manager/ram_changer.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/download_progress_indicator.dart';

import '../models/download_progress.dart';
import '../widgets/disable_if_cannot_write_game_folder.dart';
import 'jre_entry.dart';
import 'jre_manager_logic.dart';

const gameJreFolderName = "jre";

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

    return Stack(
      children: [
        GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380, crossAxisSpacing: 8, mainAxisSpacing: 8),
          shrinkWrap: true,
          children: [
            SizedBox(width: 350, child: ChangeJreWidget()),
            SizedBox(
              width: 350,
              child: ChangeRamWidget(
                currentRamAmountInMb: jreManager?.activeJre?.ramAmountInMb,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ChangeJreWidget extends ConsumerStatefulWidget {
  const ChangeJreWidget({
    super.key,
  });

  @override
  ConsumerState createState() => _ChangeJreWidgetState();
}

class _ChangeJreWidgetState extends ConsumerState<ChangeJreWidget> {
  bool isModifyingFiles = false;

  @override
  Widget build(BuildContext context) {
    final jreManager = ref.watch(jreManagerProvider).valueOrNull;
    final isUsingCustomJre = jreManager?.activeJre is CustomJreToDownload;
    final jres = jreManager?.installedJres.orEmpty().toList() ?? [];
    final activeJres = jreManager?.activeJres.orEmpty().toList() ?? [];
    final activeJre = jreManager?.activeJre;

    var iconSize = 40.0;

    return DisableIfCannotWriteGameFolder(
      child: Stack(
        children: [
          if (isModifyingFiles) const Center(child: RefreshProgressIndicator()),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Stack(
                      children: [
                        Center(
                            child: Text("Change JRE",
                                style: Theme.of(context).textTheme.titleLarge)),
                        // Align(
                        //     alignment: Alignment.centerRight,
                        //     child: IconButton(
                        //         onPressed: _reloadJres,
                        //         icon: const Icon(Icons.refresh),
                        //         padding: EdgeInsets.zero)),
                      ],
                    ),
                  ),
                  for (var jre in jres
                    ..sort(
                        (a, b) => a.versionString.compareTo(b.versionString)))
                    ConditionalWrap(
                      condition:
                          jreManager?.activeJres.none((it) => it == jre) ??
                              true,
                      wrapper: (child) => InkWell(
                        onTap: () async {
                          if (jre is JreToDownload) {
                            // confirmation dialog
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Download JRE"),
                                    content: Text(
                                        "Are you sure you want to download Java ${jre.versionString}?"),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("Cancel")),
                                      TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            ref
                                                .read(jre
                                                    .downloadProvider.notifier)
                                                .installCustomJre();
                                          },
                                          child: const Text("Download")),
                                    ],
                                  );
                                });
                          } else if (jre is JreEntryInstalled) {
                            if (!jre.isSupportedByTriOS) {
                              showDialog(
                                  context: context,
                                  builder: (context) => const AlertDialog(
                                      title: Text(
                                          "Only JRE 8 and below supported"),
                                      content: Text(
                                          "JRE 9+ requires custom game changes.")));
                            } else {
                              setState(() {
                                isModifyingFiles = true;
                              });
                              await ref
                                  .read(jreManagerProvider.notifier)
                                  .changeActiveJre(jre);
                              setState(() {
                                isModifyingFiles = false;
                              });
                            }
                          }
                        },
                        mouseCursor: WidgetStateMouseCursor.clickable,
                        child: child,
                      ),
                      child: Opacity(
                        opacity: jre.isSupportedByTriOS ? 1 : 0.5,
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                      child: Icon(Icons.coffee,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary))
                                  : SizedBox(
                                      width: iconSize,
                                      height: iconSize,
                                      child: Icon(jre is JreEntryInstalled
                                          ? Icons.coffee
                                          : Icons.download)),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, bottom: 8, top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(TextSpan(children: [
                                        WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: Text(
                                                "Java ${jre.versionInt}",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        color: jre == activeJre
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                            : null))),
                                        TextSpan(
                                            text: "  (${jre.versionString})",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.normal)),
                                      ])),
                                      if (jre is JreEntryInstalled)
                                        Opacity(
                                            opacity: 0.8,
                                            child: Text(
                                                jre.jreAbsolutePath.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall)),
                                      if (jre is JreToDownload)
                                        TriOSDownloadProgressIndicator(
                                          value: ref
                                                  .watch(jre.downloadProvider)
                                                  .value
                                                  ?.downloadProgress ??
                                              TriOSDownloadProgress(0, 0,
                                                  isIndeterminate: true),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChangeRamWidget extends StatelessWidget {
  const ChangeRamWidget({
    super.key,
    required this.currentRamAmountInMb,
  });

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
                Text("Change RAM",
                    style: Theme.of(context).textTheme.titleLarge),
                StyledText(
                    text: currentRamAmountInMb == null
                        ? "No vmparams file found."
                        : "Assigned: <b>${currentRamAmountInMb!} MB</b>",
                    tags: {
                      "b": StyledTextTag(
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold))
                    }),
                const Center(
                    child: Padding(
                  padding:
                      EdgeInsets.only(top: 8, left: 4.0, right: 4.0, bottom: 8),
                  child: RamChanger(),
                )),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "More RAM is not always better.\n6 or 8 GB is enough for almost any game.\n\nUse the Console Commands mod to view RAM use in the top-left of the console.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
