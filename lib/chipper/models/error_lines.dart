import 'package:flutter/material.dart';

import '../utils.dart';

abstract class LogLine {
  int lineNumber;
  String fullError;
  bool shouldWrap = false;
  bool isPreviousThreadLine;

  LogLine(this.lineNumber, this.fullError, {required this.isPreviousThreadLine});

  Widget createLogWidget(BuildContext context);
}

class GeneralErrorLogLine extends LogLine {
  static final RegExp _logRegex =
      RegExp("(?<millis>\\d*?) +(?<thread>\\[.*?\\]) +(?<level>\\w+?) +(?<namespace>.*?) +- +(?<error>.*)");

  String? time;
  String? thread;
  String? logLevel;
  String? namespace;
  String? error;

  GeneralErrorLogLine(super.lineNumber, super.fullError, {required super.isPreviousThreadLine});

  static GeneralErrorLogLine? tryCreate(int lineNumber, String fullError) {
    final match = _logRegex.firstMatch(fullError);

    if (match != null) {
      final log = GeneralErrorLogLine(lineNumber, fullError, isPreviousThreadLine: false);
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
  Widget createLogWidget(BuildContext context) {
    return GeneralErrorLogLineWidget(logLine: this);
  }
}

class GeneralErrorLogLineWidget extends StatelessWidget {
  final GeneralErrorLogLine logLine;

  const GeneralErrorLogLineWidget({super.key, required this.logLine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
        softWrap: logLine.shouldWrap,
        TextSpan(style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240)), children: [
          TextSpan(text: logLine.time, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(200))),
          TextSpan(
              text: logLine.thread?.prepend(" "), style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(140))),
          TextSpan(
              text: logLine.logLevel?.prepend(" "),
              style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(200))),
          TextSpan(
              text: logLine.namespace?.prepend(" "),
              style: TextStyle(color: theme.colorScheme.tertiary.withAlpha(200))),
          TextSpan(
              text: logLine.error?.prepend(" "), style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240))),
        ]));
  }
}

class StacktraceLogLine extends LogLine {
  static final RegExp _stacktraceRegex = RegExp("(?<at>\\tat) (?<namespace>.*)\\.(?<method>.*?)\\((?<classAndLine>.*)\\)");

  String? at;
  String? namespace;
  String? method;

  /// No parentheses.
  String? classAndLine;

  StacktraceLogLine(super.lineNumber, super.fullError, {required super.isPreviousThreadLine});

  static StacktraceLogLine? tryCreate(int lineNumber, String fullError) {
    final match = _stacktraceRegex.firstMatch(fullError);

    if (match != null) {
      final log = StacktraceLogLine(lineNumber, fullError, isPreviousThreadLine: false);
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
  Widget createLogWidget(BuildContext context) {
    return StacktraceLogLineWidget(logLine: this);
  }
}

class StacktraceLogLineWidget extends StatelessWidget {
  final StacktraceLogLine logLine;

  const StacktraceLogLineWidget({super.key, required this.logLine});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final obfColor = theme.colorScheme.onSurface.withAlpha(200);
    final isObf = logLine.classAndLine == "Unknown Source"; // Hardcoding, baby
    var importantColor = theme.colorScheme.tertiary;

    return Text.rich(
        softWrap: logLine.shouldWrap,
        style: TextStyle(color: isObf ? obfColor : importantColor.withAlpha(240)),
        TextSpan(children: [
          TextSpan(text: "    ", style: TextStyle(color: theme.hintColor)),
          TextSpan(text: logLine.at, style: TextStyle(color: theme.hintColor)),
          TextSpan(
              text: logLine.namespace?.prepend(" "),
              style: TextStyle(color: isObf ? obfColor : importantColor.withAlpha(180))),
          TextSpan(
              text: logLine.method?.prepend("."),
              style: TextStyle(color: isObf ? obfColor : importantColor.withAlpha(240))),
          TextSpan(
              text: logLine.classAndLine?.prepend("(").append(")"),
              style: TextStyle(color: isObf ? obfColor : importantColor.withAlpha(240))),
        ]));
  }
}

class UnknownLogLine extends LogLine {
  UnknownLogLine(super.lineNumber, super.fullError, {required super.isPreviousThreadLine});

  static UnknownLogLine? tryCreate(int lineNumber, String fullError, bool isPreviousThreadLine) {
    return UnknownLogLine(lineNumber, fullError, isPreviousThreadLine: isPreviousThreadLine);
  }

  @override
  Widget createLogWidget(BuildContext context) {
    return UnknownLogLineWidget(logLine: this);
  }
}

class UnknownLogLineWidget extends StatelessWidget {
  final UnknownLogLine logLine;

  const UnknownLogLineWidget({super.key, required this.logLine});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
        softWrap: logLine.shouldWrap,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
        TextSpan(text: logLine.fullError, children: const []));
  }
}
