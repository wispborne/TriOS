import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:trios/utils/dialogs.dart';

import '../chipper_state.dart';
import '../copy.dart';
import '../models/error_lines.dart';
import '../models/mod_entry.dart';
import '../selection_transformer.dart';
import 'chipper_log.dart';

class Readout extends StatefulWidget {
  final LogChips chips;

  const Readout(this.chips, {super.key});

  @override
  State<Readout> createState() => _ReadoutState();
}

class _ReadoutState extends State<Readout> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void didUpdateWidget(Readout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chips != widget.chips) {
      _searchController.clear();
      _searchQuery = "";
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chips = widget.chips;
    final gameVersion = chips.gameVersion ?? "Not found in log.";
    final os = chips.os ?? "Not found in log.";
    final javaVersion = chips.javaVersion ?? "Not found in log.";
    final mods = chips.modList.modList;
    final isPerfectList = chips.modList.isPerfectList;

    final theme = Theme.of(context);
    const iconOpacity = 140;
    const showInfoLogs = true;

    final allErrors = chips.errorBlock;
    final filteredErrors = _searchQuery.isEmpty
        ? allErrors
        : allErrors
            .where(
              (e) => e.fullError.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.gameVersion != null ||
            chips.javaVersion != null ||
            mods.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                // ── System info ──────────────────────────────────────────────
                if (chips.gameVersion != null || chips.javaVersion != null)
                  Expanded(
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "System",
                                style: theme.textTheme.titleLarge,
                              ),
                              IconButton(
                                tooltip: "Copy",
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: createSystemCopyString(chips),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.copy,
                                  color: theme.iconTheme.color
                                      ?.withAlpha(iconOpacity),
                                ),
                                iconSize: 20,
                              ),
                            ],
                          ),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  240,
                                ),
                              ),
                              children: [
                                TextSpan(
                                  text: "Starsector: ",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(190),
                                  ),
                                ),
                                TextSpan(
                                  text: gameVersion,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(240),
                                  ),
                                ),
                                TextSpan(
                                  text: "\nJRE: ",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(190),
                                  ),
                                ),
                                TextSpan(
                                  text: javaVersion,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(240),
                                  ),
                                ),
                                TextSpan(
                                  text: "\nOS: ",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(190),
                                  ),
                                ),
                                TextSpan(
                                  text: os,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(240),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // ── Mods list ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isPerfectList && mods.isNotEmpty)
                            Tooltip(
                              message:
                                  "This list may be incomplete.\n\"Running with the following mods\" block not found in log.",
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 12.0,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SelectionArea(
                            child: Text(
                              "Mods (${mods.length})",
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: "Copy",
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: createModsCopyString(
                                    chips,
                                    minify: false,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.copy,
                              color: theme.iconTheme.color
                                  ?.withAlpha(iconOpacity),
                            ),
                            iconSize: 20,
                          ),
                          IconButton(
                            tooltip: "Copy (less info)",
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: createModsCopyString(
                                    chips,
                                    minify: true,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.copy,
                              color: theme.iconTheme.color
                                  ?.withAlpha(iconOpacity),
                            ),
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
                              showMyDialog(
                                context,
                                body: [ModsList(mods: mods)],
                              );
                            },
                            icon: Icon(
                              Icons.open_in_full,
                              color: theme.iconTheme.color
                                  ?.withAlpha(iconOpacity),
                            ),
                            iconSize: 20,
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.textTheme.labelSmall?.color
                                      ?.withAlpha(120),
                                ),
                                children: [
                                  chips.filepath == null
                                      ? const TextSpan(text: "log")
                                      : TextSpan(
                                    text: basename(chips.filepath!),
                                    style: TextStyle(
                                      color: theme
                                          .textTheme
                                          .labelSmall
                                          ?.color
                                          ?.withAlpha(200),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                    " chipped in ${NumberFormat.decimalPattern().format(chips.timeTaken)}ms",
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: InkWell(
                          onTap: () => showMyDialog(
                            context,
                            body: [ModsList(mods: mods)],
                          ),
                          mouseCursor: SystemMouseCursors.click,
                          child: ListView.builder(
                            itemCount: mods.length,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) =>
                                mods[index].createWidget(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (allErrors.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? "Errors (${allErrors.length})"
                          : "Errors (${filteredErrors.length}/${allErrors.length})",
                      style: theme.textTheme.titleLarge,
                    ),
                    IconButton(
                      tooltip: "Copy",
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: createErrorsCopyString(chips)),
                        );
                      },
                      icon: Icon(
                        Icons.copy,
                        color: theme.iconTheme.color?.withAlpha(iconOpacity),
                      ),
                      iconSize: 20,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Filter...",
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: ChipperLog(
                    errors: filteredErrors,
                    showInfoLogs: showInfoLogs,
                    showInfoIcons: false,
                    highlightQuery:
                        _searchQuery.isEmpty ? null : _searchQuery,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
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
    var thisError = _errors[index] is GeneralErrorLogLine
        ? (_errors[index] as GeneralErrorLogLine)
        : null;
    var prevThreadMessage = _errors
        .sublist(index + 1, _errors.length)
        .firstWhereOrNull(
          (element) => element is GeneralErrorLogLine
              ? element.thread == thisError?.thread
              : true,
        );
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
                      style: theme.textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        lineNumber(prevThreadMessage.lineNumber, theme),
                        prevThreadMessage.createLogWidget(context),
                      ],
                    ),
                    Opacity(
                      opacity: 0.4,
                      child: Row(
                        children: [
                          lineNumber(_errors[index].lineNumber, theme),
                          _errors[index].createLogWidget(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // const Spacer(),
            // IconButton(
            //   onPressed: () => snacker.clearSnackBars(),
            //   icon: const Icon(Icons.close),
            // ),
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      preferBelow: false,
      child: Icon(
        Icons.info_outline_rounded,
        color: theme.disabledColor,
        size: 20,
      ),
      // tooltip: "View previous entry on this thread.",
    );
  }
}

Text lineNumber(int lineNumber, ThemeData theme) {
  return Text(
    " $lineNumber  ",
    style: TextStyle(
      color: theme.hintColor.withAlpha(40),
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

class ModsList extends StatelessWidget {
  const ModsList({super.key, this.mods});

  final UnmodifiableListView<ModEntry>? mods;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Mods (${mods?.length})",
        style: Theme.of(context).textTheme.titleLarge,
      ),
      ...mods!.map((e) => e.createWidget(context)),
    ],
  );
}
