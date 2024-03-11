import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/utils/extensions.dart';

// part 'generated/app_state.g.dart';

class appState {
  static TriOSTheme theme = TriOSTheme();
  static final selfUpdateDownloadProgress = StateProvider<double?>((ref) => null);
  static final isLoadingLog = StateProvider<bool>((ref) => false);

  static final modInfos = FutureProvider<List<ModInfo>>((ref) async {
    final gamePath = ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) {
      return [];
    }

    return await getModsInFolder(gamePath.resolve("mods").toDirectory());
  });

  static final enabledModIds = FutureProvider<List<String>>((ref) async {
    final modsFolder = ref.read(appSettings.select((value) => value.modsDir))?.toDirectory();
    if (modsFolder == null) {
      return [];
    } else {
      return getEnabledMods(modsFolder);
    }
  });

  static final starsectorVersion = FutureProvider<String?>((ref) async {
    final gameCorePath = ref.read(appSettings.select((value) => value.gameCoreDir))?.toDirectory();
    if (gameCorePath == null) {
      return null;
    }
    final versionInLog = await readStarsectorVersionFromLog(gameCorePath);
    if (versionInLog != null) {
      // If found in log, update the last saved version
      ref.read(appSettings.notifier).update((s) => s.copyWith(lastStarsectorVersion: versionInLog));
      return versionInLog;
    } else {
      // Fallback to last saved version
      return ref.read(appSettings.select((value) => value.lastStarsectorVersion));
    }
  });
}

Future<String?> readStarsectorVersionFromLog(Directory gameCorePath) async {
  const versionContains = r"Starting Starsector";
  final versionRegex = RegExp(r"Starting Starsector (.*) launcher");
  final logfile =
      utf8.decode(gameCorePath.resolve("starsector.log").toFile().readAsBytesSync().toList(), allowMalformed: true);
  for (var line in logfile.split("\n")) {
    if (line.contains(versionContains)) {
      try {
        final version = versionRegex.firstMatch(line)!.group(1);
        if (version == null) {
          continue;
        }

        return version;
      } catch (_) {
        continue;
      }
    }
  }

  return null;
}

/// Initialized in main.dart
late SharedPreferences sharedPrefs;

var currentFileHandles = 0;
var maxFileHandles = 2000;

Future<T> withFileHandleLimit<T>(Future<T> Function() function) async {
  while (currentFileHandles + 1 > maxFileHandles) {
    Fimber.v("Waiting for file handles to free up. Current file handles: $currentFileHandles");
    await Future.delayed(const Duration(milliseconds: 100));
  }
  currentFileHandles++;
  try {
    return await function();
  } finally {
    currentFileHandles--;
  }
}
