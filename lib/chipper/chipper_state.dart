import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/views/chipper_home.dart';

import 'models/error_lines.dart';
import 'models/mod_entry.dart';
import 'models/user_mods.dart';

class ChipperState {
  // static LoadedLog loadedLog = LoadedLog();
  static final isLoadingLog = StateProvider<bool>((ref) => ref.watch(logRawContents).isLoading);

  // static final logRawContents = StateProvider<LogFile?>((ref) => null);
  static final logRawContents =
      AsyncNotifierProvider<_ChipperLogParserNotifier, LogChips?>(_ChipperLogParserNotifier.new);
}

class _ChipperLogParserNotifier extends AsyncNotifier<LogChips?> {
  @override
  LogChips? build() {
    return null;
  }

  void parseLog(LogFile? next) {
    if (next == null) return;
    state = const AsyncValue.loading();

    compute(handleNewLogContent, next.contents).then((LogChips? chips) {
      state = AsyncValue.data(chips?..filepath = next.filepath);
      // setState(() {
      //   Fimber.i("Parsing false");
      //   parsing = false;
      // });
    });
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
