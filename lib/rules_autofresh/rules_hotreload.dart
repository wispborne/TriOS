import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/widgets/blur.dart';

import '../trios/app_state.dart';
import '../utils/logging.dart';
import '../utils/util.dart';
import 'all_seeing_eye.dart';

final vanillaRulesCsvFile = StateProvider<File?>((ref) => null);
// final modRulesDotCsvFiles = StateProvider<List<File>?>(
//     (ref) => ref.read(appSettings).modsDir?.let((path) => getAllRulesCsvsInModsFolder(path.toDirectory())));

class RulesHotReload extends ConsumerStatefulWidget {
  final bool isEnabled;

  const RulesHotReload({super.key, required this.isEnabled});

  @override
  ConsumerState createState() => _RulesHotReloadState();
}

class _RulesHotReloadState extends ConsumerState<RulesHotReload> {
  int _counter = 0;

  _saveVanillaRulesDotCsv(WidgetRef ref) {
    Fimber.i(
        "Detected rules.csv change, touching vanilla rules.csv last modified date");
    final gameCoreDir = ref.read(appSettings.select((s) => s.gameCoreDir));
    if (gameCoreDir == null) {
      return;
    }

    final vanillaRulesCsvFile = getRulesCsvInModFolder(gameCoreDir);
    vanillaRulesCsvFile?.setLastModified(DateTime.now());
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
    final modVariants = ref.watch(AppState.modVariants).valueOrNull;
    final modRulesDotCsvFiles = modVariants
            ?.map((variant) => getRulesCsvInModFolder(variant.modFolder))
            .whereNotNull()
            .toList() ??
        [];

    if (widget.isEnabled) {
      fileChanges = StreamController();

      fileChanges.stream.listen((event) {
        _saveVanillaRulesDotCsv(ref);
      });

      // Fimber.i('Watching ${modRulesDotCsvFiles.join()}');
      for (var modRulesDotCsv in modRulesDotCsvFiles) {
        pollFileForModification(modRulesDotCsv, fileChanges);
      }
    }

    final modsBeingWatchedCount =
        fileChanges.isClosed ? 0 : modRulesDotCsvFiles.length ?? 0;

    var theme = Theme.of(context);
    return Opacity(
      opacity: widget.isEnabled ? 1 : 0.5,
      child: Column(children: [
        // Text(
        //   '$_counter',
        //   style: Theme.of(context).textTheme.headlineMedium,
        // ),
        Stack(
          children: [
            if (widget.isEnabled)
              Blur(
                  blurX: 8,
                  blurY: 8,
                  child: FadingEye(
                      shouldAnimate: false, color: theme.colorScheme.primary)),
            FadingEye(
                shouldAnimate: false,
                color: widget.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface),
          ],
        ),
        Text('rules.csv',
            style: theme.textTheme.labelMedium?.copyWith(
                color: widget.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface)),
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
