// TODO make synchronous to update in memory
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:trios/trios/settings/settings.dart';

import '../../mod_manager/mod_manager_logic.dart';
import '../../models/enabled_mods.dart';
import '../../utils/logging.dart';
import '../../utils/util.dart';

class EnabledModsNotifier extends AsyncNotifier<EnabledMods> {
  StreamController<File>? _enabledModsWatcher;

  // static StreamController<File>? _enabledModsWatcher;
  final fileLock = Mutex();

  @override
  Future<EnabledMods> build() async {
    await refreshEnabledMods();
    return state.valueOrNull ?? const EnabledMods({});
  }

  Future<void> enableMod(String modId, {bool enabled = true}) async {
    // Prevent concurrent writes to the enabled_mods.json file and make sure
    // that the file is not read while it's being written to.
    await fileLock.protect(() async {
      final modsFolder = ref.read(appSettings.select((value) => value.modsDir));
      if (modsFolder == null) {
        return;
      }

      final enabledModsFile = getEnabledModsFile(modsFolder);
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
            ? "Enabled mod $modId in enabled_mods.json"
            : "Disabled mod $modId in enabled_mods.json",
      );
    });
  }

  Future<void> disableMod(String modId) async {
    await enableMod(modId, enabled: false);
  }

  Future<void> refreshEnabledMods() async {
    final modsFolder = ref.watch(appSettings.select((value) => value.modsDir));

    if (modsFolder == null || !modsFolder.existsSync()) {
      state = const AsyncValue.data(EnabledMods({}));
    } else {
      final enabledModsFile = getEnabledModsFile(modsFolder);
      if (!enabledModsFile.existsSync()) {
        state = const AsyncValue.data(EnabledMods({}));
      }

      // If the watcher is closed somehow, we need to recreate it.
      if (_enabledModsWatcher != null && _enabledModsWatcher!.isClosed) {
        _enabledModsWatcher = null;
      }

      // Watch the enabled_mods.json file for changes
      if (_enabledModsWatcher == null) {
        _enabledModsWatcher = StreamController<File>();
        _enabledModsWatcher?.stream.listen((event) {
          refreshEnabledMods();
        });

        pollFileForModification(enabledModsFile, _enabledModsWatcher!,
            intervalMillis: 1500);
      }

      var enabledMods = await getEnabledMods(modsFolder);
      state = AsyncValue.data(enabledMods);
    }
  }
}
