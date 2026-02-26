import 'package:flutter/material.dart';

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
    final namespaceStyle = TextStyle(
      color: theme.colorScheme.tertiary.withAlpha(200),
    );
    final errorStyle = TextStyle(
      color: theme.colorScheme.onSurface.withAlpha(240),
    );

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
          ..._highlightSpans(
            logLine.error?.prepend(" "),
            errorStyle,
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
    final obfColor = theme.colorScheme.onSurface.withAlpha(200);
    final isObf = logLine.classAndLine == "Unknown Source";
    final importantColor = theme.colorScheme.tertiary;
    final hl = theme.colorScheme.primary.withAlpha(80);

    final atStyle = TextStyle(color: theme.hintColor);
    final namespaceStyle = TextStyle(
      color: isObf ? obfColor : importantColor.withAlpha(180),
    );
    final methodStyle = TextStyle(
      color: isObf ? obfColor : importantColor.withAlpha(240),
    );
    final classStyle = TextStyle(
      color: isObf ? obfColor : importantColor.withAlpha(240),
    );

    return Text.rich(
      softWrap: logLine.shouldWrap,
      style: TextStyle(color: isObf ? obfColor : importantColor.withAlpha(240)),
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
    final hl = theme.colorScheme.primary.withAlpha(80);

    return Text.rich(
      softWrap: logLine.shouldWrap,
      TextSpan(
        children: _highlightSpans(
          logLine.fullError,
          baseStyle,
          highlightQuery,
          hl,
        ),
      ),
    );
  }
}
