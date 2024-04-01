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

import 'package:fimber/fimber.dart';
import 'package:trios/utils/extensions.dart';

import 'jre_manager.dart';

class JreEntry {
  final String versionString;
  final Directory path;

  JreEntry(this.versionString, this.path);

  bool get isUsedByGame => path.name == gameJreFolderName;

  int get version {
    try {
      if (versionString.startsWith("1.")) return int.parse(versionString.substring(2, 3));
      return int.parse(versionString.takeWhile((char) => char != '.' && char != '-' && char != '+'));
    } catch (e, st) {
      Fimber.d(e.toString(), ex: e, stacktrace: st);
      return 0;
    }
  }
}
