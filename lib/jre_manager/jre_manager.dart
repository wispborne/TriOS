import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_23.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/ConditionalWrap.dart';
import 'package:trios/widgets/download_progress_indicator.dart';

import '../models/download_progress.dart';
import 'jre_entry.dart';
import 'jre_manager_logic.dart';

const gameJreFolderName = "jre";

class JreManager extends ConsumerStatefulWidget {
  const JreManager({super.key});

  @override
  ConsumerState createState() => _JreManagerState();
}

class _JreManagerState extends ConsumerState<JreManager> {
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
    findJREs(ref.read(appSettings.select((value) => value.gameDir))).then((value) {
      jres = value;
      setState(() {});
    });
  }

  _watchJres() async {
    jreWatcherSubscription?.cancel();
    final jresDir = ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (jresDir == null) return;
    jreWatcherSubscription = jresDir.watch().listen((event) {
      _reloadJres();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appSettings.select((value) => value.gameDir), (_, newJresDir) async {
      if (newJresDir == null) return;
      _reloadJres();
      _watchJres();
    });

    var iconSize = 40.0;
    return Stack(
      children: [
        if (isModifyingFiles) const Center(child: RefreshProgressIndicator()),
        Column(
          children: [
            for (var jre in jres..sort((a, b) => a.versionString.compareTo(b.versionString)))
              // Text(jre.versionString),
              ConditionalWrap(
                condition: !jre.isUsedByGame,
                wrapper: (child) => InkWell(
                  onTap: () async {
                    if (jre.version > 8) {
                      showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                              title: Text("Only JRE 8 and below supported"),
                              content: Text("JRE 9+ requires custom game changes.")));
                    } else {
                      setState(() {
                        isModifyingFiles = true;
                      });
                      await _changeJre(jre);
                      setState(() {
                        isModifyingFiles = false;
                      });
                      _reloadJres();
                    }
                  },
                  child: child,
                ),
                child: ListTile(
                  title: Text.rich(TextSpan(children: [
                    WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Text(jre.version.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: jre.isUsedByGame ? Theme.of(context).colorScheme.primary : null))),
                    TextSpan(
                        text: "  (${jre.versionString})",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal)),
                  ])),
                  subtitle: Opacity(opacity: 0.8, child: Text(jre.path.name)),
                  leading: jre.isUsedByGame
                      ? Container(
                          width: iconSize,
                          height: iconSize,
                          decoration:
                              BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary),
                          child: Icon(Icons.coffee, color: Theme.of(context).colorScheme.onPrimary))
                      : SizedBox(width: iconSize, height: iconSize, child: const Icon(Icons.coffee)),
                ),
              ),
            ElevatedButton(onPressed: () {
              Jre23.installJre23(ref);
            }, child: Text("Install JRE 23 ")),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Text("Starsector Himemi Config"),
                      DownloadProgressIndicator(
                          value:
                              ref.watch(jdk23ConfigDownloadProgress) ?? DownloadProgress(0, 0, isIndeterminate: true)),
                    ],
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Text("JDK 23"),
                      DownloadProgressIndicator(
                          value: ref.watch(jre23jdkDownloadProgress) ?? DownloadProgress(0, 0, isIndeterminate: true)),
                    ],
                  )),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _changeJre(JreEntry newJre) async {
    var gamePath = ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null || !gamePath.existsSync()) {
      return;
    }

    var currentJreSource = jres.firstWhereOrNull((element) => element.isUsedByGame);

    Directory? currentJreDest;
    var gameJrePath = Directory(gamePath.resolve(gameJreFolderName).absolute.path);

    if (currentJreSource != null && currentJreSource.path.existsSync()) {
      // We'll move the current JRE to a new folder, which has the JRE's version string in the name.
      currentJreDest = "${gameJrePath.path}-${currentJreSource.versionString}".toDirectory();

      // If the destination already exists, add a random suffix to the name.
      if (currentJreDest.existsSync()) {
        currentJreDest =
            "${currentJreDest.path}-${DateTime.now().millisecondsSinceEpoch.toString().takeLast(6)}".toDirectory();
      }

      try {
        Fimber.i("Moving JRE ${currentJreSource.versionString} from '${currentJreSource.path}' to '$currentJreDest'.");
        await currentJreSource.path.moveDirectory(currentJreDest);
      } catch (e, st) {
        Fimber.w("Unable to move currently used JRE. Make sure the game is not running.", ex: e, stacktrace: st);
        return;
      }
    }

    // Rename target JRE to "jre".
    try {
      await newJre.path.moveDirectory(gameJrePath);
    } catch (e, st) {
      Fimber.w("Unable to move new JRE ${newJre.versionString} to '$gameJrePath'. Maybe you need to run as Admin?",
          ex: e, stacktrace: st);
      if (!gameJrePath.existsSync() && currentJreDest != null && currentJreDest.existsSync()) {
        Fimber.w("Rolling back JRE change. Moving '$currentJreDest' to '$gameJrePath'.");

        try {
          await currentJreDest.moveDirectory(gameJrePath);
        } catch (e, st) {
          Fimber.e("Failed to roll back JRE change.", ex: e, stacktrace: st);
        }
      }
    }
  }
}
