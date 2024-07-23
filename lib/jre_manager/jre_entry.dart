// data class JreEntry(
// val versionString: String,
// val path: Path
// ) {
// val isUsedByGame = path.name == JreManager.gameJreFolderName
// val version = runCatching {
// if (versionString.startsWith("1.")) versionString.removePrefix("1.").take(1).toInt()
// else versionString.takeWhile { it != '.' }.toInt()
// }
//     .onFailure { Timber.d(it) }
//     .getOrElse { 0 }
// }

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

import '../models/download_progress.dart';

abstract class JreEntry {
  JreVersion get version;

  int get versionInt => version.version;

  String get versionString => version.versionString;
}

class JreEntryInstalled implements JreEntry {
  @override
  final JreVersion version;
  final Directory path;

  JreEntryInstalled(this.version, this.path);

  @override
  int get versionInt => version.version;

  @override
  String get versionString => version.versionString;
}

class JreToDownload implements JreEntry {
  @override
  final JreVersion version;
  final Function(WidgetRef ref) installRunner;
  final StateProvider<DownloadProgress?> progressProvider;

  JreToDownload(this.version, this.installRunner, this.progressProvider);

  @override
  int get versionInt => version.version;

  @override
  String get versionString => version.versionString;
}

class JreVersion {
  final String versionString;

  JreVersion(this.versionString);

  int get version {
    try {
      if (versionString.startsWith("1."))
        return int.parse(versionString.substring(2, 3));
      return int.parse(versionString
          .takeWhile((char) => char != '.' && char != '-' && char != '+'));
    } catch (e, st) {
      Fimber.d(e.toString(), ex: e, stacktrace: st);
      return 0;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is JreVersion) {
      return versionString == other.versionString;
    }
    return false;
  }

  @override
  int get hashCode => versionString.hashCode;
}
