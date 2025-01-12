// TODO make synchronous to update in memory
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import '../../models/enabled_mods.dart';
import '../../models/mod.dart';
import '../../utils/logging.dart';
import '../../utils/util.dart';

class EnabledModsNotifier extends AsyncNotifier<EnabledMods> {
  StreamController<File?>? _enabledModsWatcher;

  // static StreamController<File>? _enabledModsWatcher;
  final fileLock = Mutex();

  @override
  Future<EnabledMods> build() async {
    return fileLock.protect(() async {
      await refreshEnabledMods();
      return state.valueOrNull ?? const EnabledMods({});
    });
  }

  File _getEnabledModsFile(Directory modsFolder) {
    return File(p.join(modsFolder.path, "enabled_mods.json"));
  }

  Future<bool> isWritable() {
    final modsFolder = ref.read(appSettings.select((value) => value.modsDir));
    if (modsFolder == null) {
      return Future.value(false);
    }
    return _getEnabledModsFile(modsFolder).isWritable();
  }

  Future<void> enableMod(String modId, {bool enabled = true}) async {
    // Prevent concurrent writes to the enabled_mods.json file and make sure
    // that the file is not read while it's being written to.
    await fileLock.protect(() async {
      final modsFolder = ref.read(appSettings.select((value) => value.modsDir));
      if (modsFolder == null) {
        return;
      }

      final enabledModsFile = _getEnabledModsFile(modsFolder);
      var enabledMods = state.valueOrNull ?? const EnabledMods({});

      if (enabled) {
        enabledMods = enabledMods.copyWith(
            enabledMods: enabledMods.enabledMods.toSet()..add(modId));
        // enabledMods = enabledMods.copyWith()..enabledMods.add(modId);
      } else {
        enabledMods = enabledMods.copyWith(
            enabledMods:
                enabledMods.enabledMods.where((id) => id != modId).toSet());
        // enabledMods = enabledMods.copyWith()..enabledMods.remove(modId);
      }

      // Creates a new enabled_mods.json file if it doesn't exist.
      // Might be ok not to await this.
      Fimber.d("Writing enabled mods to enabled_mods.json: $enabledMods");
      enabledModsFile.writeAsStringSync(jsonEncode(enabledMods.toJson()));
      state = AsyncValue.data(enabledMods);
      Fimber.i(
        enabled
            ? "Enabled mod $modId in enabled_mods.json. ${enabledMods.enabledMods.length} now enabled."
            : "Disabled mod $modId in enabled_mods.json. ${enabledMods.enabledMods.length} now enabled.",
      );
    });
  }

  Future<void> disableMod(String modId) async {
    await enableMod(modId, enabled: false);
  }

  /// Refreshes the list of enabled mods by reading the enabled_mods.json file.
  /// If the file doesn't exist, it'll create a new one.
  /// `allMods` is an optional parameter that filters out mods that don't exist.
  Future<void> refreshEnabledMods() async {
    fileLock.protect(() async {
      final modsFolder =
          ref.watch(appSettings.select((value) => value.modsDir));

      if (modsFolder == null || !modsFolder.existsSync()) {
        state = const AsyncValue.data(EnabledMods({}));
      } else {
        File enabledModsFile = _getEnabledModsFile(modsFolder);
        if (enabledModsFile.existsSync() == false) {
          try {
            enabledModsFile.createSync(recursive: true);
            enabledModsFile.writeAsStringSync(
                const EnabledMods({}).toJson().toJsonString());
          } catch (e, stack) {
            Fimber.e(
                "Failed to create enabled mods file at ${enabledModsFile.path}",
                ex: e,
                stacktrace: stack);
          }
        }

        enabledModsFile = _getEnabledModsFile(modsFolder);
        if (!enabledModsFile.existsSync()) {
          state = const AsyncValue.data(EnabledMods({}));
        }

        // If the watcher is closed somehow, we need to recreate it.
        if (_enabledModsWatcher != null && _enabledModsWatcher!.isClosed) {
          _enabledModsWatcher = null;
        }

        // Watch the enabled_mods.json file for changes
        if (_enabledModsWatcher == null) {
          _enabledModsWatcher = StreamController<File?>();
          _enabledModsWatcher?.stream.listen((event) {
            refreshEnabledMods();
          });

          pollFileForModification(enabledModsFile, _enabledModsWatcher!,
              intervalMillis: 1500);
        }

        var enabledMods = await _getEnabledMods(modsFolder);
        state = AsyncValue.data(enabledMods);
      }
    });
  }

  /// `allMods` will filter out mods that have been removed from the mods folder since the last time the enabled mods file was written.
  Future<EnabledMods> _getEnabledMods(Directory modsFolder,
      {List<Mod>? allMods}) async {
    return EnabledMods.fromJson(
        (await _getEnabledModsFile(modsFolder).readAsString()).fixJsonToMap());
  }
}
