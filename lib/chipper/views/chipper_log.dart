import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/models/error_lines.dart';
import 'package:trios/chipper/views/readout.dart';
import 'package:trios/utils/extensions.dart';

import '../selection_transformer.dart';

class ChipperLog extends ConsumerStatefulWidget {
  final List<LogLine> errors;
  final bool showInfoLogs;

  const ChipperLog(
      {super.key, required this.errors, required this.showInfoLogs});

  @override
  ConsumerState createState() => _ChipperLogState();
}

class _ChipperLogState extends ConsumerState<ChipperLog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errors = widget.errors.reversed.toList(growable: false);
    final showInfoLogs = widget.showInfoLogs;

    return SelectionArea(
        child: SelectionTransformer.tabular(
            columns: 2,
            separator: " ",
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (errors
                            .maxByOrNull<num>((e) => e.fullError.length)
                            ?.fullError
                            .length ??
                        20) *
                    5,
                child: ListView.builder(
                    itemCount: errors.length,
                    reverse: true,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return !showInfoLogs && errors[index].isPreviousThreadLine
                          ? Container(
                              height: 0,
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: IntrinsicWidth(
                                child: Column(children: [
                                  if (!isConsecutiveWithPreviousLine(
                                      index, showInfoLogs))
                                    Divider(
                                      color: theme.disabledColor,
                                    ),
                                  Container(
                                      padding: (!isConsecutiveWithPreviousLine(
                                              index, showInfoLogs))
                                          ? const EdgeInsets.only()
                                          : const EdgeInsets.only(
                                              top: 1, bottom: 1),
                                      child: IntrinsicHeight(
                                          child: Row(children: [
                                        Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                if (!isConsecutiveWithPreviousLine(
                                                    index, showInfoLogs))
                                                  ViewPreviousEntryButton(
                                                      errors: errors,
                                                      theme: theme,
                                                      index: index)
                                                else
                                                  Container(
                                                    width: 20,
                                                  ),
                                                SizedBox(
                                                    width: 85,
                                                    child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            "${errors[index].lineNumber}    ",
                                                            style: TextStyle(
                                                                color: theme
                                                                    .hintColor
                                                                    .withAlpha(
                                                                        40),
                                                                fontFeatures: const [
                                                                  FontFeature
                                                                      .tabularFigures()
                                                                ]),
                                                          )
                                                        ]))
                                              ])
                                            ]),
                                        Expanded(
                                            child: errors[index]
                                                .createLogWidget(context))
                                      ])))
                                ]),
                              ),
                            );
                    }),
              ),
            )));
  }

  bool isConsecutiveWithPreviousLine(int index, bool showInfoLogs) {
    final errors = widget.errors;
    if (index + 1 >= errors.length) return false;
    var left = (errors[index].lineNumber - 1);
    var right = errors[index + 1].lineNumber;
    return left == right;
  }
}
