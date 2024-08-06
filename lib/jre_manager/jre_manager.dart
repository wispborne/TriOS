import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:styled_text/styled_text.dart';
import 'package:trios/jre_manager/jre_23.dart';
import 'package:trios/jre_manager/ram_changer.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/download_progress_indicator.dart';

import '../models/download_progress.dart';
import '../trios/app_state.dart';
import '../widgets/disable_if_cannot_write_game_folder.dart';
import 'jre_entry.dart';
import 'jre_manager_logic.dart';

const gameJreFolderName = "jre";

class JreManager extends ConsumerStatefulWidget {
  const JreManager({super.key});

  @override
  ConsumerState createState() => _JreManagerState();
}

class _JreManagerState extends ConsumerState<JreManager>
    with AutomaticKeepAliveClientMixin {
  List<JreEntry> jres = [];
  StreamSubscription? jreWatcherSubscription;
  bool isModifyingFiles = false;

  @override
  void initState() {
    super.initState();
    _reloadJres();
    _watchJres();
    Jre23.getVersionCheckerInfo();
  }

  _reloadJres() {
    if (isModifyingFiles) return;
    findJREs(ref.read(appSettings.select((value) => value.gameDir))?.path)
        .then((value) {
      jres = value.map((e) => e as JreEntry).toList();

      if (!jres
          .any((jre) => jre is JreEntryInstalled && jre.versionInt == 23)) {
        // Cheating a little by only passing in the progress provider for the JDK download, but it is a much larger download so it should always be the bottleneck.
        jres += [
          JreToDownload(JreVersion("23-Himemi"), Jre23.installJre23,
              jre23jdkDownloadProgress)
        ];
      }

      setState(() {});
    });
  }

  _watchJres() async {
    jreWatcherSubscription?.cancel();
    final jresDir =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (jresDir == null) return;
    jreWatcherSubscription = jresDir.watch().listen((event) {
      _reloadJres();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appSettings.select((value) => value.gameDir),
        (_, newJresDir) async {
      if (newJresDir == null) return;
      _reloadJres();
      _watchJres();
    });
    final gameDir =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();

    if (gameDir == null) {
      return const Center(child: Text("Game directory not set."));
    }

    final vmparams = ref.watch(vmparamsVanillaContent).value;
    final isUsingJre23 =
        ref.watch(appSettings.select((value) => value.useJre23));

    var iconSize = 40.0;
    bool jreVersionSupportCheck(int version) => version <= 8 || version == 23;

    return Stack(
      children: [
        if (isModifyingFiles) const Center(child: RefreshProgressIndicator()),
        GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380, crossAxisSpacing: 8, mainAxisSpacing: 8),
          shrinkWrap: true,
          children: [
            SizedBox(
                width: 350,
                child: DisableIfCannotWriteGameFolder(
                  child: Card(
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge)),
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
                            ..sort((a, b) =>
                                a.versionString.compareTo(b.versionString)))
                            ConditionalWrap(
                              condition: !jre.isActive(isUsingJre23, jres),
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
                                                    await jre
                                                        .installRunner(ref);
                                                    _reloadJres();
                                                  },
                                                  child:
                                                      const Text("Download")),
                                            ],
                                          );
                                        });
                                  } else if (jre is JreEntryInstalled) {
                                    if (!jreVersionSupportCheck(
                                        jre.versionInt)) {
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
                                      if (jre.versionInt == 23) {
                                        ref.read(appSettings.notifier).update(
                                            (it) =>
                                                it.copyWith(useJre23: true));
                                      } else {
                                        ref.read(appSettings.notifier).update(
                                            (it) =>
                                                it.copyWith(useJre23: false));
                                        await _changeJre(jre);
                                      }
                                      setState(() {
                                        isModifyingFiles = false;
                                      });
                                      _reloadJres();
                                    }
                                  }
                                },
                                mouseCursor: WidgetStateMouseCursor.clickable,
                                child: child,
                              ),
                              child: Opacity(
                                opacity: jreVersionSupportCheck(jre.versionInt)
                                    ? 1
                                    : 0.5,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Row(
                                    children: [
                                      jre.isActive(isUsingJre23, jres)
                                          ? Container(
                                              width: iconSize,
                                              height: iconSize,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                              child: Icon(
                                                  jre is JreEntryInstalled
                                                      ? Icons.coffee
                                                      : Icons.download,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary))
                                          : SizedBox(
                                              width: iconSize,
                                              height: iconSize,
                                              child: Icon(
                                                  jre is JreEntryInstalled
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
                                                        PlaceholderAlignment
                                                            .middle,
                                                    child: Text(
                                                        "Java ${jre.versionInt}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleLarge
                                                            ?.copyWith(
                                                                color: jre.isActive(
                                                                        isUsingJre23,
                                                                        jres)
                                                                    ? Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                    : null))),
                                                TextSpan(
                                                    text:
                                                        "  (${jre.versionString})",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal)),
                                              ])),
                                              if (jre is JreEntryInstalled)
                                                Opacity(
                                                    opacity: 0.8,
                                                    child: Text(
                                                        jre.path.name ?? "",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall)),
                                              if (jre is JreToDownload)
                                                DownloadProgressIndicator(
                                                  value: ref.watch(jre
                                                          .progressProvider) ??
                                                      const DownloadProgress(
                                                          0, 0,
                                                          isIndeterminate:
                                                              true),
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
                )),
            SizedBox(
              width: 350,
              child: DisableIfCannotWriteGameFolder(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text("Change RAM",
                              style: Theme.of(context).textTheme.titleLarge),
                          StyledText(
                              text: vmparams == null ||
                                      getRamAmountFromVmparamsInMb(vmparams) ==
                                          null
                                  ? "No vmparams file found."
                                  : "Assigned: <b>${getRamAmountFromVmparamsInMb(vmparams)!} MB</b>",
                              tags: {
                                "b": StyledTextTag(
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold))
                              }),
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.only(
                                top: 8, left: 4.0, right: 4.0, bottom: 8),
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _changeJre(JreEntryInstalled newJre) async {
    var gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null || !gamePath.existsSync()) {
      return;
    }
    final isUsingJre23 =
        ref.watch(appSettings.select((value) => value.useJre23));

    var currentJreSource =
        jres.firstWhereOrNull((element) => element.isActive(isUsingJre23, jres))
            as JreEntryInstalled?;

    if (currentJreSource != null &&
        newJre.version == currentJreSource.version) {
      Fimber.i("JRE ${newJre.versionString} is already active.");
      return;
    }

    Directory? currentJreDest;
    var gameJrePath =
        Directory(gamePath.resolve(gameJreFolderName).absolute.path);

    if (currentJreSource != null && currentJreSource.path.existsSync()) {
      // We'll move the current JRE to a new folder, which has the JRE's version string in the name.
      currentJreDest =
          "${gameJrePath.path}-${currentJreSource.versionString}".toDirectory();

      // If the destination already exists, add a random suffix to the name.
      if (currentJreDest.existsSync()) {
        currentJreDest =
            "${currentJreDest.path}-${DateTime.now().millisecondsSinceEpoch.toString().takeLast(6)}"
                .toDirectory();
      }

      try {
        Fimber.i(
            "Moving JRE ${currentJreSource.versionString} from '${currentJreSource.path}' to '$currentJreDest'.");
        await currentJreSource.path.moveDirectory(currentJreDest);
      } catch (e, st) {
        Fimber.w(
            "Unable to move currently used JRE. Make sure the game is not running.",
            ex: e,
            stacktrace: st);
        return;
      }
    }

    // Rename target JRE to "jre".
    try {
      await newJre.path.moveDirectory(gameJrePath);
      Fimber.i("Moved JRE ${newJre.versionString} to '$gameJrePath'.");
      ref.invalidate(AppState.activeJre);
    } catch (e, st) {
      Fimber.w(
          "Unable to move new JRE ${newJre.versionString} to '$gameJrePath'. Maybe you need to run as Admin?",
          ex: e,
          stacktrace: st);
      if (!gameJrePath.existsSync() &&
          currentJreDest != null &&
          currentJreDest.existsSync()) {
        Fimber.w(
            "Rolling back JRE change. Moving '$currentJreDest' to '$gameJrePath'.");

        try {
          await currentJreDest.moveDirectory(gameJrePath);
        } catch (e, st) {
          Fimber.e("Failed to roll back JRE change.", ex: e, stacktrace: st);
        }
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}
