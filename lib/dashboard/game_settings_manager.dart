import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

part 'game_settings_manager.mapper.dart';

@MappableClass()
class GameSettings with GameSettingsMappable {
  final bool? vsync;
  final int? fps;

  const GameSettings({required this.vsync, required this.fps});
}

final gameSettingsProvider =
    StateNotifierProvider<GameSettingsNotifier, AsyncValue<GameSettings>>(
      (ref) => GameSettingsNotifier(ref),
    );

class GameSettingsNotifier extends StateNotifier<AsyncValue<GameSettings>> {
  GameSettingsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final Ref ref;
  late final File settingsFile;

  static final RegExp _vsyncRegex = RegExp(
    r'("vsync"\s*:\s*)(true|false)',
    multiLine: true,
  );
  static final RegExp _fpsRegex = RegExp(
    r'("fps"\s*:\s*)(\d+)',
    multiLine: true,
  );

  Future<void> setVsync(bool value) async {
    await _updateSetting(_vsyncRegex, value.toString());
    _refreshState(vsync: value);
  }

  Future<void> setFps(int value) async {
    await _updateSetting(_fpsRegex, value.toString());
    _refreshState(fps: value);
  }

  // Internal -------------------------------------------------------------------

  Future<void> _initialize() async {
    try {
      final gameCoreDir = ref.watch(AppState.gameCoreFolder).value;
      if (gameCoreDir == null) {
        return;
      }

      settingsFile = gameCoreDir
          .resolve(p.join('data', 'config', 'settings.json'))
          .toFile();

      state = AsyncValue.data(await _readSettings());
    } catch (e, st) {
      Fimber.e('Failed to load settings.json', ex: e, stacktrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<GameSettings> _readSettings() async {
    final content = await settingsFile.readAsString();

    final vsyncMatch = _vsyncRegex.firstMatch(content);
    final fpsMatch = _fpsRegex.firstMatch(content);

    bool? vsync;
    int? fps;

    if (vsyncMatch == null) {
      Fimber.i("Unable to read 'vsync' from settings.json");
    } else {
      try {
        final vsyncStr = vsyncMatch.group(2)?.toLowerCase();
        vsync = bool.parse(vsyncStr!);
      } catch (e, sl) {
        Fimber.w(
          "Failure when trying to parse vsync value '${vsyncMatch.group(2)}'}",
          stacktrace: sl,
        );
      }
    }
    if (fpsMatch == null) {
      Fimber.i("Unable to read 'fpsMatch' from settings.json");
    } else {
      try {
        fps = int.parse(fpsMatch.group(2)!);
      } catch (e, sl) {
        Fimber.w(
          "Failure when trying to parse fps value '${fpsMatch.group(2)}'}",
          stacktrace: sl,
        );
      }
    }

    return GameSettings(vsync: vsync, fps: fps);
  }

  Future<void> _updateSetting(RegExp pattern, String newValue) async {
    final original = await settingsFile.readAsString();

    // Replace only the captured value, preserving comments, commas, and spacing.
    final updated = original.replaceFirstMapped(pattern, (match) {
      final prefix = match.group(1)!; // "key": part with spacing.
      return '$prefix$newValue';
    });

    if (identical(original, updated)) {
      Fimber.w('No changes made – pattern not found.');
      return;
    }

    // Backup before writing.
    await _backupFile();
    await settingsFile.writeAsString(updated);
  }

  Future<void> _backupFile() async {
    final backupPath = '${settingsFile.path}.bak';
    try {
      await settingsFile.copy(backupPath);
    } on Exception catch (e, st) {
      Fimber.w('Could not create backup: $backupPath', ex: e, stacktrace: st);
    }
  }

  Future<void> _refreshState({bool? vsync, int? fps}) async {
    state.whenData((current) async {
      state = AsyncValue.data(await _readSettings());
    });
  }
}
