import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/views/chipper_home.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_paths.dart';

import 'models/error_lines.dart';
import 'models/mod_entry.dart';
import 'models/user_mods.dart';

class ChipperState {
  // static LoadedLog loadedLog = LoadedLog();
  static final isLoadingLog = StateProvider<bool>(
    (ref) => ref.watch(logRawContents).isLoading,
  );

  // static final logRawContents = StateProvider<LogFile?>((ref) => null);
  static final logRawContents =
      AsyncNotifierProvider<_ChipperLogParserNotifier, LogChips?>(
        _ChipperLogParserNotifier.new,
      );
}

class _ChipperLogParserNotifier extends AsyncNotifier<LogChips?> {
  @override
  LogChips? build() {
    // Reload when game is closed
    ref.listen(AppState.isGameRunning, (wasRunning, isRunning) {
      if (wasRunning?.valueOrNull == true && isRunning.valueOrNull == false) {
        loadDefaultLog();
      }
    });

    return null;
  }

  void parseLogAndSetState(LogFile? next) {
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

  void loadDefaultLog() async {
    final gamePath = ref.read(appSettings.select((value) => value.gameDir));
    final gameFilesPath = getLogPath(gamePath!);

    if (gameFilesPath.existsSync()) {
      gameFilesPath.readAsBytes().then((bytes) async {
        final stopwatch = Stopwatch()..start();
        final content = utf8.decode(bytes.toList(), allowMalformed: true);
        final parsedLog = parseLogAndSetState(
          LogFile(gameFilesPath.path, content),
        );
        stopwatch.stop();
        Fimber.i("Parsed log in ${stopwatch.elapsedMilliseconds}ms");
        return parsedLog;
      });
    }
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
  UserMods modList = UserMods(
    UnmodifiableListView<ModEntry>([]),
    isPerfectList: false,
  );
  UnmodifiableListView<LogLine> errorBlock = UnmodifiableListView([]);
  final int timeTaken;
  final DateTime? lastUpdated;

  LogChips(
    this.filepath,
    this.gameVersion,
    this.os,
    this.javaVersion,
    this.modList,
    this.errorBlock,
    this.timeTaken,
    this.lastUpdated,
  );
}
