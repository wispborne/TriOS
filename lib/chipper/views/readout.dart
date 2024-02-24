import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

import '../app_state.dart';
import '../copy.dart';
import '../models/error_lines.dart';
import '../models/mod_entry.dart';
import '../selection_transformer.dart';
import '../utils.dart';

class Readout extends StatelessWidget {
  Readout(LogChips chips, {Key? key}) : super(key: key) {
    _chips = chips;

    _gameVersion = _chips.gameVersion ?? "Not found in log.";
    _os = _chips.os ?? "Not found in log.";
    _javaVersion = _chips.javaVersion ?? "Not found in log.";
    _mods = _chips.modList.modList;
    _isPerfectList = _chips.modList.isPerfectList;
    _errors = _chips.errorBlock.reversed.toList(growable: false);
  }

  late LogChips _chips;
  String? _gameVersion;
  String? _os;
  String? _javaVersion;
  UnmodifiableListView<ModEntry>? _mods;
  bool _isPerfectList = false;
  List<LogLine>? _errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconOpacity = 140;
    const showInfoLogs = true;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_gameVersion != null || _javaVersion != null)
        Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectionArea(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text("System", style: theme.textTheme.titleLarge),
                  IconButton(
                    tooltip: "Copy",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: createSystemCopyString(_chips)));
                    },
                    icon: Icon(Icons.copy, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
                    iconSize: 20,
                  ),
                  Expanded(
                      child: Text.rich(
                          TextSpan(
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.textTheme.labelSmall?.color?.withAlpha(120)),
                              children: [
                                _chips.filename == null
                                    ? const TextSpan(text: "log")
                                    : TextSpan(
                                        text: basename(_chips.filename!),
                                        style: TextStyle(
                                            color: theme.textTheme.labelSmall?.color?.withAlpha(200),
                                            fontWeight: FontWeight.w500)),
                                TextSpan(
                                    text: " chipped in ${NumberFormat.decimalPattern().format(_chips.timeTaken)}ms"),
                              ]),
                          textAlign: TextAlign.right))
                ]),
                Text.rich(TextSpan(style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240)), children: [
                  TextSpan(text: "Starsector: ", style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(190))),
                  TextSpan(text: _gameVersion, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240))),
                  TextSpan(text: "\nJRE: ", style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(190))),
                  TextSpan(text: _javaVersion, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240))),
                  TextSpan(text: "\nOS: ", style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(190))),
                  TextSpan(text: _os, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240))),
                ]))
              ],
            ))),
      if (_mods != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  if (!_isPerfectList && _mods?.isNotEmpty == true)
                    Tooltip(
                        message: "This list may be incomplete.\n\"Running with the following mods\" block not found in log.",
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.warning_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                            shadows: [
                              Shadow(blurRadius: 12.0, color: theme.colorScheme.secondary),
                            ],
                          ),
                        )),
                  SelectionArea(child: Text("Mods (${_mods?.length})", style: theme.textTheme.titleLarge)),
                  IconButton(
                    tooltip: "Copy",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: createModsCopyString(_chips, minify: false)));
                    },
                    icon: Icon(
                      Icons.copy,
                      color: theme.iconTheme.color?.withAlpha(iconOpacity),
                    ),
                    iconSize: 20,
                  ),
                  IconButton(
                    tooltip: "Copy (less info)",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: createModsCopyString(_chips, minify: true)));
                    },
                    icon: Icon(Icons.copy, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
                    iconSize: 14,
                  ),
                  // IconButton(
                  //   tooltip: "Download",
                  //   onPressed: () {
                  //     FileSaver.instance.saveAs("mods", Uint8List.fromList(utf8.encode(createModsCopyString(_chips))),
                  //         "txt", MimeType.TEXT);
                  //     // Clipboard.setData(ClipboardData(text: createModsCopyString(_chips, minify: true)));
                  //   },
                  //   icon: Icon(Icons.file_download, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
                  //   iconSize: 14,
                  // ),
                  IconButton(
                    tooltip: "Popup",
                    onPressed: () {
                      showMyDialog(context, body: [ModsList(mods: _mods)]);
                    },
                    icon: Icon(Icons.open_in_full, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
                    iconSize: 20,
                  ),
                ]),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: InkWell(
                      onTap: () => showMyDialog(context, body: [ModsList(mods: _mods)]),
                      mouseCursor: SystemMouseCursors.click,
                      child: ListView.builder(
                          itemCount: _mods!.length,
                          scrollDirection: Axis.vertical,
                          itemBuilder: (context, index) => _mods![index].createWidget(context))),
                )
              ],
            )),
      if (_errors != null)
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text("Errors", style: theme.textTheme.titleLarge),
            IconButton(
              tooltip: "Copy",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: createErrorsCopyString(_chips)));
              },
              icon: Icon(Icons.copy, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
              iconSize: 20,
            )
          ]),
          Expanded(
              child: SelectionArea(
                  child: SelectionTransformer.tabular(
                      columns: 2,
                      separator: " ",
                      child: ListView.builder(
                          itemCount: _errors!.length,
                          reverse: true,
                          itemBuilder: (BuildContext context, int index) {
                            return !showInfoLogs && _errors![index].isPreviousThreadLine
                                ? Container(
                                    height: 0,
                                  )
                                : Column(children: [
                                    if (!isConsecutiveWithPreviousLine(index, showInfoLogs))
                                      Divider(
                                        color: theme.disabledColor,
                                      ),
                                    Container(
                                        padding: (!isConsecutiveWithPreviousLine(index, showInfoLogs))
                                            ? const EdgeInsets.only()
                                            : const EdgeInsets.only(top: 1, bottom: 1),
                                        child: IntrinsicHeight(
                                            child: Row(children: [
                                          Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                            Row(children: [
                                              if (!isConsecutiveWithPreviousLine(index, showInfoLogs))
                                                ViewPreviousEntryButton(
                                                    errors: _errors ?? [], theme: theme, index: index)
                                              else
                                                Container(
                                                  width: 20,
                                                ),
                                              SizedBox(
                                                  width: 85,
                                                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                    Text(
                                                      "${_errors![index].lineNumber}    ",
                                                      style: TextStyle(
                                                          color: theme.hintColor.withAlpha(40),
                                                          fontFeatures: const [FontFeature.tabularFigures()]),
                                                    )
                                                  ]))
                                            ])
                                          ]),
                                          Expanded(child: _errors![index].createLogWidget(context))
                                        ])))
                                  ]);
                          }))))
        ])),
    ]);
  }

  bool isConsecutiveWithPreviousLine(int index, bool showInfoLogs) {
    if (index + 1 >= _errors!.length) return false;
    var left = (_errors![index].lineNumber - 1);
    var right = _errors![index + 1].lineNumber;
    return left == right;
  }
}

class ViewPreviousEntryButton extends StatelessWidget {
  const ViewPreviousEntryButton({
    super.key,
    required List<LogLine> errors,
    required this.theme,
    required this.index,
  }) : _errors = errors;

  final List<LogLine> _errors;
  final ThemeData theme;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Take a list of all lines before this one, then find the last one in the list that is specifically a "previous line" entry..
    var thisError = _errors[index] is GeneralErrorLogLine ? (_errors[index] as GeneralErrorLogLine) : null;
    var prevThreadMessage = _errors
        .sublist(index + 1, _errors.length)
        .firstWhereOrNull((element) => element is GeneralErrorLogLine ? element.thread == thisError?.thread : true);
    if (prevThreadMessage == null) return const SizedBox(height: 15, width: 20);

    return Tooltip(
        richMessage: WidgetSpan(
            child: Container(
                padding: const EdgeInsets.all(10),
                color: theme.colorScheme.surface,
                child: SelectionArea(
                  child: SelectionTransformer.separated(
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Previous line on ${thisError?.thread?.replaceFirst('[', '').replaceFirst(']', '') ?? "thread"}",
                                    style: theme.textTheme.titleMedium),
                                Row(children: [
                                  lineNumber(prevThreadMessage.lineNumber, theme),
                                  prevThreadMessage.createLogWidget(context)
                                ]),
                                Opacity(
                                    opacity: 0.4,
                                    child: Row(children: [
                                      lineNumber(_errors[index].lineNumber, theme),
                                      _errors[index].createLogWidget(context)
                                    ]))
                              ]))),
                  // const Spacer(),
                  // IconButton(
                  //   onPressed: () => snacker.clearSnackBars(),
                  //   icon: const Icon(Icons.close),
                  // ),
                ))),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        preferBelow: false,
        child: Icon(
          Icons.info_outline_rounded,
          color: theme.disabledColor,
          size: 20,
        )
        // tooltip: "View previous entry on this thread.",
        );
  }
}

Text lineNumber(int lineNumber, ThemeData theme) {
  return Text(
    " $lineNumber  ",
    style: TextStyle(color: theme.hintColor.withAlpha(40), fontFeatures: const [FontFeature.tabularFigures()]),
  );
}

class ModsList extends StatelessWidget {
  ModsList({super.key, this.mods});

  UnmodifiableListView<ModEntry>? mods;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mods (${mods?.length})", style: Theme.of(context).textTheme.titleLarge),
          ...mods!.map((e) => e.createWidget(context)).toList()
        ],
      );
}
