import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/error_lines.dart';
import 'models/mod_entry.dart';
import 'models/user_mods.dart';

class ChipperState {
  static LoadedLog loadedLog = LoadedLog();
}

final logRawContents = StateProvider<LogFile?>((ref) => null);

class LoadedLog extends ChangeNotifier {
  LogChips? _chips;

  LogChips? get chips => _chips;

  set chips(LogChips? newChips) {
    _chips = newChips;
    notifyListeners();
  }
}

class LogFile {
  final String? filepath;
  final String contents;

  LogFile(this.filepath, this.contents);
}

class LogChips {
  String? filepath;
  final String? gameVersion;
  final String? os;
  final String? javaVersion;
  UserMods modList = UserMods(UnmodifiableListView<ModEntry>([]), isPerfectList: false);
  UnmodifiableListView<LogLine> errorBlock = UnmodifiableListView([]);
  final int timeTaken;

  LogChips(this.filepath, this.gameVersion, this.os, this.javaVersion, this.modList, this.errorBlock, this.timeTaken);
}
