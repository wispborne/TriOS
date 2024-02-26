import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/extensions.dart';

import '../app_state.dart';
import '../utils/util.dart';
import 'all_seeing_eye.dart';

final vanillaRulesCsvFile = StateProvider<File?>((ref) => null);
final modRulesCsvFiles =
    StateProvider<List<File>?>((ref) => ref.read(modFolderPath)?.let((path) => getAllRulesCsvsInModsFolder(path)));

class RulesHotReload extends ConsumerStatefulWidget {
  final bool isEnabled;

  const RulesHotReload({super.key, required this.isEnabled});

  @override
  ConsumerState createState() => _RulesHotReloadState();
}

class _RulesHotReloadState extends ConsumerState<RulesHotReload> {
  int _counter = 0;

  _saveVanillaRulesCsv(WidgetRef ref) {
    ref.read(vanillaRulesCsvFile.notifier).update((file) => file?..setLastModified(DateTime.now()));
    setState(() {
      _counter++;
    });
  }

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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    fileChanges.close();

    if (widget.isEnabled) {
      fileChanges = StreamController();

      fileChanges.stream.listen((event) {
        _saveVanillaRulesCsv(ref);
      });

      for (var element in ref.watch(modRulesCsvFiles) ?? []) {
        pollFileForModification(element, 1);
      }
    }

    final modsBeingWatched = fileChanges.isClosed ? 0 : ref.watch(modRulesCsvFiles)?.length ?? 0;

    return Opacity(
      opacity: widget.isEnabled ? 1 : 0.5,
      child: Column(children: [
        // Text(
        //   '$_counter',
        //   style: Theme.of(context).textTheme.headlineMedium,
        // ),
        FadingEye(shouldAnimate: widget.isEnabled),
        Text('rules.csv reload', style: Theme.of(context).textTheme.labelMedium),
        // RichText(
        //   textAlign: TextAlign.center,
        //   text: TextSpan(
        //     children: [
        //       TextSpan(
        //         text: '$modsBeingWatched',
        //         style: const TextStyle(
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //       const TextSpan(text: 'x rules.csv'),
        //     ],
        //   ),
        // ),
      ]),
    );
  }
}
