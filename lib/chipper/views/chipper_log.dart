import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/models/error_lines.dart';
import 'package:trios/chipper/views/readout.dart';
import 'package:trios/utils/extensions.dart';

import '../selection_transformer.dart';

class ChipperLog extends ConsumerStatefulWidget {
  final List<LogLine> errors;
  final bool showInfoLogs;

  const ChipperLog({
    super.key,
    required this.errors,
    required this.showInfoLogs,
  });

  @override
  ConsumerState createState() => _ChipperLogState();
}

class _ChipperLogState extends ConsumerState<ChipperLog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errors = widget.errors.reversed.toList(growable: false);
    final showInfoLogs = widget.showInfoLogs;
    final scrollController = ScrollController();

    final width =
        ((errors
                        .maxByOrNull<num>((e) => e.fullError.length)
                        ?.fullError
                        .length ??
                    20) *
                10)
            .toDouble();
    return SelectionArea(
      child: SelectionTransformer.tabular(
        columns: 2,
        separator: " ",
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              thickness: 10,
              scrollbarOrientation: ScrollbarOrientation.right,
              child: ListView.builder(
                itemCount: errors.length,
                reverse: true,
                controller: scrollController,
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  return !showInfoLogs && errors[index].isPreviousThreadLine
                      ? Container(height: 0)
                      : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: width,
                          child: Column(
                            children: [
                              if (!isConsecutiveWithPreviousLine(
                                index,
                                showInfoLogs,
                              ))
                                Divider(color: theme.disabledColor),
                              Container(
                                padding:
                                    (!isConsecutiveWithPreviousLine(
                                          index,
                                          showInfoLogs,
                                        ))
                                        ? const EdgeInsets.only()
                                        : const EdgeInsets.only(
                                          top: 1,
                                          bottom: 1,
                                        ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (!isConsecutiveWithPreviousLine(
                                                index,
                                                showInfoLogs,
                                              ))
                                                ViewPreviousEntryButton(
                                                  errors: errors,
                                                  theme: theme,
                                                  index: index,
                                                )
                                              else
                                                Container(width: 20),
                                              SizedBox(
                                                width: 85,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      "${errors[index].lineNumber}    ",
                                                      style: TextStyle(
                                                        color: theme.hintColor
                                                            .withAlpha(40),
                                                        fontFeatures: const [
                                                          FontFeature.tabularFigures(),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: errors[index].createLogWidget(
                                          context,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isConsecutiveWithPreviousLine(int index, bool showInfoLogs) {
    final errors = widget.errors;
    final reversedIndex = errors.length - index - 2;
    // Fimber.d("reverseIndex: $reversedIndex");
    if (reversedIndex + 1 >= errors.length || (reversedIndex - 1) < 0) {
      return false;
    }
    var left = errors[reversedIndex].lineNumber;
    var right = errors[reversedIndex + 1].lineNumber - 1;
    // Fimber.d("reverseIndex: $reversedIndex, left: $left, right: $right");
    return left == right;
  }
}
