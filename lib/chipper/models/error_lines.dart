import 'package:flutter/material.dart';

import '../mod_class_names.dart';
import '../utils.dart';

/// Splits [text] into alternating normal/highlighted [TextSpan]s wherever
/// [query] matches (case-insensitive). Returns a single-element list when
/// [query] is null/empty or there is no match, so callers can always spread
/// the result directly into a parent TextSpan's children list.
List<TextSpan> _highlightSpans(
  String? text,
  TextStyle style,
  String? query,
  Color highlightBg,
) {
  if (text == null || text.isEmpty || query == null || query.isEmpty) {
    return [TextSpan(text: text, style: style)];
  }
  final lower = text.toLowerCase();
  final lowerQ = query.toLowerCase();
  final spans = <TextSpan>[];
  int start = 0;
  while (true) {
    final idx = lower.indexOf(lowerQ, start);
    if (idx == -1) {
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: style));
      }
      break;
    }
    if (idx > start) {
      spans.add(TextSpan(text: text.substring(start, idx), style: style));
    }
    spans.add(
      TextSpan(
        text: text.substring(idx, idx + query.length),
        style: style.copyWith(backgroundColor: highlightBg),
      ),
    );
    start = idx + query.length;
  }
  return spans;
}

/// Like [_highlightSpans], but first picks out any mod class name in [text] and
/// gives it [modStyle] instead of [style]. Used for free-form text such as an
/// error message or a "Caused by:" line, where the mod's name is buried in a
/// sentence rather than in a field of its own.
List<TextSpan> _spansWithModNames(
  String? text,
  TextStyle style,
  TextStyle modStyle,
  String? query,
  Color highlightBg,
) {
  if (text == null || text.isEmpty) {
    return [TextSpan(text: text, style: style)];
  }

  final spans = <TextSpan>[];
  int start = 0;
  for (final match in classNameInTextPattern.allMatches(text)) {
    if (!isModClassName(match[0])) continue;
    if (match.start > start) {
      spans.addAll(
        _highlightSpans(
          text.substring(start, match.start),
          style,
          query,
          highlightBg,
        ),
      );
    }
    spans.addAll(_highlightSpans(match[0], modStyle, query, highlightBg));
    start = match.end;
  }

  if (spans.isEmpty) {
    return _highlightSpans(text, style, query, highlightBg);
  }
  if (start < text.length) {
    spans.addAll(
      _highlightSpans(text.substring(start), style, query, highlightBg),
    );
  }
  return spans;
}

abstract class LogLine {
  int lineNumber;
  String fullError;
  bool shouldWrap = false;
  bool isPreviousThreadLine;

  LogLine(
    this.lineNumber,
    this.fullError, {
    required this.isPreviousThreadLine,
  });

  Widget createLogWidget(BuildContext context, {String? highlightQuery});
}

class GeneralErrorLogLine extends LogLine {
  static final RegExp _logRegex = RegExp(
    "(?<millis>\\d*?) +(?<thread>\\[.*?\\]) +(?<level>\\w+?) +(?<namespace>.*?) +- +(?<error>.*)",
  );

  String? time;
  String? thread;
  String? logLevel;
  String? namespace;
  String? error;

  GeneralErrorLogLine(
    super.lineNumber,
    super.fullError, {
    required super.isPreviousThreadLine,
  });

  static GeneralErrorLogLine? tryCreate(int lineNumber, String fullError) {
    final match = _logRegex.firstMatch(fullError);

    if (match != null) {
      final log = GeneralErrorLogLine(
        lineNumber,
        fullError,
        isPreviousThreadLine: false,
      );
      log.time = match.namedGroup("millis");
      log.thread = match.namedGroup("thread");
      log.logLevel = match.namedGroup("level");
      log.namespace = match.namedGroup("namespace");
      log.error = match.namedGroup("error");
      return log;
    } else {
      return null;
    }
  }

  @override
  Widget createLogWidget(BuildContext context, {String? highlightQuery}) {
    return GeneralErrorLogLineWidget(
      logLine: this,
      highlightQuery: highlightQuery,
    );
  }
}

class GeneralErrorLogLineWidget extends StatelessWidget {
  final GeneralErrorLogLine logLine;
  final String? highlightQuery;

  const GeneralErrorLogLineWidget({
    super.key,
    required this.logLine,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hl = theme.colorScheme.primary.withAlpha(80);

    final timeStyle = TextStyle(
      color: theme.colorScheme.onSurface.withAlpha(200),
    );
    final threadStyle = TextStyle(
      color: theme.colorScheme.onSurface.withAlpha(140),
    );
    final levelStyle = TextStyle(
      color: theme.colorScheme.onSurface.withAlpha(200),
    );
    final modColor = theme.colorScheme.tertiary;
    final namespaceStyle = TextStyle(
      color: isModClassName(logLine.namespace)
          ? modColor.withAlpha(200)
          : theme.colorScheme.onSurface.withAlpha(160),
    );
    final errorStyle = TextStyle(
      color: theme.colorScheme.onSurface.withAlpha(240),
    );
    final errorModStyle = TextStyle(color: modColor);

    return Text.rich(
      softWrap: logLine.shouldWrap,
      TextSpan(
        style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240)),
        children: [
          ..._highlightSpans(logLine.time, timeStyle, highlightQuery, hl),
          ..._highlightSpans(
            logLine.thread?.prepend(" "),
            threadStyle,
            highlightQuery,
            hl,
          ),
          ..._highlightSpans(
            logLine.logLevel?.prepend(" "),
            levelStyle,
            highlightQuery,
            hl,
          ),
          ..._highlightSpans(
            logLine.namespace?.prepend(" "),
            namespaceStyle,
            highlightQuery,
            hl,
          ),
          ..._spansWithModNames(
            logLine.error?.prepend(" "),
            errorStyle,
            errorModStyle,
            highlightQuery,
            hl,
          ),
        ],
      ),
    );
  }
}

class StacktraceLogLine extends LogLine {
  static final RegExp _stacktraceRegex = RegExp(
    "(?<at>\\tat) (?<namespace>.*)\\.(?<method>.*?)\\((?<classAndLine>.*)\\)",
  );

  String? at;
  String? namespace;
  String? method;

  /// No parentheses.
  String? classAndLine;

  StacktraceLogLine(
    super.lineNumber,
    super.fullError, {
    required super.isPreviousThreadLine,
  });

  static StacktraceLogLine? tryCreate(int lineNumber, String fullError) {
    final match = _stacktraceRegex.firstMatch(fullError);

    if (match != null) {
      final log = StacktraceLogLine(
        lineNumber,
        fullError,
        isPreviousThreadLine: false,
      );
      log.at = match.namedGroup("at");
      log.namespace = match.namedGroup("namespace");
      log.method = match.namedGroup("method");
      log.classAndLine = match.namedGroup("classAndLine");
      return log;
    } else {
      return null;
    }
  }

  @override
  Widget createLogWidget(BuildContext context, {String? highlightQuery}) {
    return StacktraceLogLineWidget(
      logLine: this,
      highlightQuery: highlightQuery,
    );
  }
}

class StacktraceLogLineWidget extends StatelessWidget {
  final StacktraceLogLine logLine;
  final String? highlightQuery;

  const StacktraceLogLineWidget({
    super.key,
    required this.logLine,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameColor = theme.colorScheme.onSurface.withAlpha(200);
    final isMod = isModClassName(logLine.namespace);
    final modColor = theme.colorScheme.tertiary;
    final hl = theme.colorScheme.primary.withAlpha(80);

    final atStyle = TextStyle(color: theme.hintColor);
    final namespaceStyle = TextStyle(
      color: isMod ? modColor.withAlpha(180) : gameColor,
    );
    final methodStyle = TextStyle(
      color: isMod ? modColor.withAlpha(240) : gameColor,
    );
    final classStyle = TextStyle(
      color: isMod ? modColor.withAlpha(240) : gameColor,
    );

    return Text.rich(
      softWrap: logLine.shouldWrap,
      style: TextStyle(color: isMod ? modColor.withAlpha(240) : gameColor),
      TextSpan(
        children: [
          const TextSpan(text: "    "),
          ..._highlightSpans(logLine.at, atStyle, highlightQuery, hl),
          ..._highlightSpans(
            logLine.namespace?.prepend(" "),
            namespaceStyle,
            highlightQuery,
            hl,
          ),
          ..._highlightSpans(
            logLine.method?.prepend("."),
            methodStyle,
            highlightQuery,
            hl,
          ),
          ..._highlightSpans(
            logLine.classAndLine?.prepend("(").append(")"),
            classStyle,
            highlightQuery,
            hl,
          ),
        ],
      ),
    );
  }
}

class UnknownLogLine extends LogLine {
  UnknownLogLine(
    super.lineNumber,
    super.fullError, {
    required super.isPreviousThreadLine,
  });

  static UnknownLogLine? tryCreate(
    int lineNumber,
    String fullError,
    bool isPreviousThreadLine,
  ) {
    return UnknownLogLine(
      lineNumber,
      fullError,
      isPreviousThreadLine: isPreviousThreadLine,
    );
  }

  @override
  Widget createLogWidget(BuildContext context, {String? highlightQuery}) {
    return UnknownLogLineWidget(logLine: this, highlightQuery: highlightQuery);
  }
}

class UnknownLogLineWidget extends StatelessWidget {
  final UnknownLogLine logLine;
  final String? highlightQuery;

  const UnknownLogLineWidget({
    super.key,
    required this.logLine,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = TextStyle(
      color: theme.colorScheme.onSurface.withAlpha(180),
    );
    final modStyle = TextStyle(color: theme.colorScheme.tertiary);
    final hl = theme.colorScheme.primary.withAlpha(80);

    return Text.rich(
      softWrap: logLine.shouldWrap,
      TextSpan(
        children: _spansWithModNames(
          logLine.fullError,
          baseStyle,
          modStyle,
          highlightQuery,
          hl,
        ),
      ),
    );
  }
}
