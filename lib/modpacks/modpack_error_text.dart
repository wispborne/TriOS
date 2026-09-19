import 'dart:async';
import 'dart:io';

import 'package:trios/modpacks/modpack_format.dart';

/// Why installing can't happen right now, such as the game being open. It is
/// not a problem with any mod's source, so it is never saved as a failure.
class ModpackInstallBlocked implements Exception {
  final String message;

  const ModpackInstallBlocked(this.message);

  @override
  String toString() => message;
}

/// Converts common errors to user-facing text without Dart type prefixes.
String modpackErrorText(Object error) => switch (error) {
  ModpackFormatException(:final message) => message,
  StateError(:final message) => message,
  ArgumentError(:final message) => '$message',
  FormatException(:final message) => message,
  HttpException(:final message, :final uri) =>
    uri == null ? message : '$message ($uri)',
  TimeoutException() => 'The request took too long.',
  _ => error.toString(),
};
