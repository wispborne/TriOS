import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import '../utils/util.dart';
import 'all_seeing_eye.dart';

final vanillaRulesCsvFile = StateProvider<File?>((ref) => null);
final modRulesDotCsvFiles = StateProvider<List<File>?>(
    (ref) => ref.read(appSettings).modsDir?.let((path) => getAllRulesCsvsInModsFolder(path.toDirectory())));

class RulesHotReload extends ConsumerStatefulWidget {
  final bool isEnabled;

  const RulesHotReload({super.key, required this.isEnabled});

  @override
  ConsumerState createState() => _RulesHotReloadState();
}

class _RulesHotReloadState extends ConsumerState<RulesHotReload> {
  int _counter = 0;

  _saveVanillaRulesDotCsv(WidgetRef ref) {
    ref.read(vanillaRulesCsvFile.notifier).update((file) => file?..setLastModified(DateTime.now()));
    setState(() {
      _counter++;
    });
  }

  var fileChanges = StreamController<File>();

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
        _saveVanillaRulesDotCsv(ref);
      });

      for (var modRulesDotCsv in ref.watch(modRulesDotCsvFiles) ?? []) {
        pollFileForModification(modRulesDotCsv, fileChanges);
      }
    }

    final modsBeingWatchedCount = fileChanges.isClosed ? 0 : ref.watch(modRulesDotCsvFiles)?.length ?? 0;

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
