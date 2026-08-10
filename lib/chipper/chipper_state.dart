import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:trios/chipper/views/chipper_home.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/app_worker.dart';
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
      if (wasRunning?.value == true && isRunning.value == false) {
        loadDefaultLog();
      }
    });

    return null;
  }

  void parseLogAndSetState(LogFile? next) {
    if (next == null || state.isLoading) return;
    final contents = next.contents;
    final filepath = next.filepath;
    if (contents == null && filepath == null) return;
    state = const AsyncValue.loading();

    // When we only have a path, the worker reads the file itself. Sending the
    // log as a string pinned a copy of the whole log (36 MB for an 18 MB
    // file) in the worker isolate for the life of the app.
    final parseJob = contents != null
        ? ref.read(appWorkerProvider).run(handleNewLogContent, contents)
        : ref.read(appWorkerProvider).run(parseLogFromDisk, filepath!);

    parseJob
        .then((LogChips? chips) {
          state = AsyncValue.data(chips?..filepath = next.filepath);
        })
        .catchError((Object e, StackTrace st) {
          Fimber.w("Couldn't read or parse log.", ex: e, stacktrace: st);
          state = AsyncValue.error(e, st);
        });
  }

  void loadDefaultLog() async {
    final gamePath = ref.read(AppState.gameFolder).value;
    final gameFilesPath = getLogPath(gamePath!);

    if (gameFilesPath.existsSync()) {
      parseLogAndSetState(LogFile(gameFilesPath.path, null));
    }
  }
}

/// A log to parse. When [contents] is null the worker isolate reads
/// [filepath] from disk itself, which keeps the log's text out of the UI
/// isolate entirely. [contents] is for logs with no local file: clipboard
/// pastes and logs fetched from a dropped `.url` shortcut.
class LogFile {
  final String? filepath;
  final String? contents;

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
