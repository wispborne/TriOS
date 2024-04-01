import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../chipper_state.dart';
import '../logparser.dart';
import '../utils.dart';
import 'chipper_dropper.dart';
import 'readout.dart';

class DesktopDrop extends ConsumerStatefulWidget {
  const DesktopDrop({super.key, this.chips});

  final LogChips? chips;

  @override
  ConsumerState<DesktopDrop> createState() => DesktopDropState();
}

class DesktopDropState extends ConsumerState<DesktopDrop> {
  static bool parsing = false;
  final String _macPath = "/Applications/Starsector.app/logs/starsector.log";
  final String _winPath = "C:/Program Files (x86)/Fractal Softworks/Starsector/starsector-core/starsector.log";
  final String _linuxPath = "<game folder>/starsector.log";

  parseLogListener(LogFile? next) {
    if (next == null) return;
    setState(() {
      Fimber.i("Parsing true");
      parsing = true;
    });
    compute(handleNewLogContent, next.contents).then((LogChips? chips) {
      ChipperState.loadedLog.chips = chips?..filepath = next.filepath;
      setState(() {
        Fimber.i("Parsing false");
        parsing = false;
      });
    });
  }

  @override
  void initState() {
    parseLogListener(ref.read(logRawContents));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(logRawContents, (pref, next) => parseLogListener(next));

    return ChipperDropper(
        child: (parsing == true || widget.chips == null)
            ? Container(
                constraints: const BoxConstraints(),
                child: Center(
                    widthFactor: 1.5,
                    child: parsing
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const CircularProgressIndicator(),
                            Container(height: 10),
                            Text(
                              [
                                "thinking...",
                                "processing...",
                                "parsing...",
                                "pondering the log",
                                "chipping...",
                                "breaking logs down...",
                                "analyzing...",
                                "analysing...",
                                "spinning...",
                                "please wait...",
                                "please hold...",
                              ].random(),
                              style: theme.textTheme.headlineMedium,
                            )
                          ])
                        : Column(children: [
                            Expanded(
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(
                                "Drop starsector.log here",
                                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 34),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    "or control-v to paste",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 18, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                  )),
                              Text("\n—",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                              SelectionArea(
                                  child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text: "\nWindows: ",
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                        fontSize: 20, color: theme.textTheme.headlineSmall?.color?.withOpacity(0.6)),
                                  ),
                                  TextSpan(
                                    text: _winPath,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 18,
                                        color: theme.textTheme.headlineSmall?.color?.withOpacity(0.7)),
                                  ),
                                  TextSpan(
                                    text: "\n\nMacOS: ",
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                        fontSize: 20, color: theme.textTheme.headlineSmall?.color?.withOpacity(0.6)),
                                  ),
                                  TextSpan(
                                    text: _macPath,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 18,
                                        color: theme.textTheme.headlineSmall?.color?.withOpacity(0.7)),
                                  ),
                                  TextSpan(
                                    text: "\n\nLinux: ",
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                        fontSize: 20, color: theme.textTheme.headlineSmall?.color?.withOpacity(0.6)),
                                  ),
                                  TextSpan(
                                    text: _linuxPath,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 18,
                                        color: theme.textTheme.headlineSmall?.color?.withOpacity(0.7)),
                                  ),
                                ]),
                                textAlign: TextAlign.left,
                              )),
                            ])),
                            Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child: Text(
                                  "Nothing is ever uploaded. All processing is done on your computer.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                ))
                          ])))
            : LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: constraints.maxWidth, child: Readout(widget.chips!)));
                }));
  }
}

Future<String?> handleDroppedFile(String droppedFilePaths) async {
  final files = [droppedFilePaths].map((e) => XFile(e));
  for (final file in files) {
    Fimber.i('  Path:${file.path}'
        '\n  Name:${file.name}'
        '\n  Modified:${await file.lastModified()}'
        '\n  Length: ${await file.length()}'
        '\n  Type: ${file.runtimeType}'
        '\n  MIME:${file.mimeType}');
  }

  final droppedFile = files.firstOrNull;
  if (droppedFile == null) return null;

  // No need to filter by name for now, in case file has (Copy) or (1) in it.
  // .firstWhereOrNull((element) => element.name == "starsector.log");
  String? logStream;

  // Check if file is a url or an actual file
  if (droppedFile.name.endsWith(".url")) {
    final url = RegExp(".*(http.*)").firstMatch(await droppedFile.readAsString())?.group(1);
    if (url != null) {
      final uri = Uri.parse(url);
      try {
        Fimber.i("Fetching and streaming online url $uri");
        logStream = (await http.get(uri, headers: {
          'Content-Type': 'text/plain',
        }))
            .body; //get()).bodyBytes;//.onError((error, stackTrace) => );
      } catch (e) {
        Fimber.w("Failed to read $url", ex: e);
      }
    }
  } else {
    try {
      logStream = utf8.decode((await droppedFile.readAsBytes()),
          allowMalformed: true); //.openRead().map((chunk) => utf8.decode(chunk, allowMalformed: true));
    } catch (e) {
      Fimber.w("Couldn't parse text file.", ex: e);
    }
  }

  return logStream;
}

Future<LogChips?> handleNewLogContent(String logContent) {
  // final wrongLogRegex = RegExp(".*\.log\./d", caseSensitive: false);
  return LogParser().parse(logContent);
}
