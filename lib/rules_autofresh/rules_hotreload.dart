import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/extensions.dart';

import '../app_state.dart';
import '../utils/util.dart';
import 'all_seeing_eye.dart';

final vanillaRulesCsv = StateProvider<File?>((ref) => null);
final modRulesCsvs =
    StateProvider<List<File>?>((ref) => ref.read(modFolderPath)?.let((path) => getAllRulesCsvsInModsFolder(path)));

var fileChanges = StreamController();

/// Should probably be a way to stop this.
pollFileForModification(File file, int interval) async {
  var lastModified = file.lastModifiedSync();
  final fileChangesInstance = fileChanges;

  while (!fileChangesInstance.isClosed) {
    await Future.delayed(Duration(seconds: interval));
    final newModified = file.lastModifiedSync();
    if (newModified.isAfter(lastModified)) {
      lastModified = newModified;
      fileChanges.add(file);
    }
  }
}

class RulesHotReload extends ConsumerStatefulWidget {
  const RulesHotReload({super.key});

  @override
  ConsumerState createState() => _RulesHotReloadState();
}

class _RulesHotReloadState extends ConsumerState<RulesHotReload> {
  int _counter = 0;
  int _modsBeingWatched = 0;

  _saveVanillaRulesCsv(WidgetRef ref) {
    ref.read(vanillaRulesCsv.notifier).update((file) => file?..setLastModified(DateTime.now()));
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    fileChanges.close();
    fileChanges = StreamController();

    _modsBeingWatched = ref.watch(modRulesCsvs)?.length ?? 0;

    fileChanges.stream.listen((event) {
      _saveVanillaRulesCsv(ref);
    });

    for (var element in ref.watch(modRulesCsvs) ?? []) {
      pollFileForModification(element, 1);
    }

    return Column(children: [
      // Text(
      //   '$_counter',
      //   style: Theme.of(context).textTheme.headlineMedium,
      // ),
      const FadingEye(),
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$_modsBeingWatched',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: 'x rules.csv'),
          ],
        ),
      ),
    ]);
  }
}
