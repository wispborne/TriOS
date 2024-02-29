import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/app_state.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/utils/util.dart';

part '../../generated/trios/settings/settings.freezed.dart';
part '../../generated/trios/settings/settings.g.dart';

const sharedPrefsSettingsKey = "settings";

/// Settings State Provider
final appSettings = NotifierProvider<SettingSaver, Settings>(() => SettingSaver());

Settings? readAppSettings() {
  if (sharedPrefs.containsKey(sharedPrefsSettingsKey)) {
    return Settings.fromJson(jsonDecode(sharedPrefs.getString(sharedPrefsSettingsKey)!));
  } else {
    return null;
  }
}

/// Settings object model
@freezed
class Settings with _$Settings {
  factory Settings({
    final String? gameDir,
    final String? modsDir,
    @Default(false) final bool hasCustomModsDir,
    final List<String>? enabledModIds,
    @Default(false) final bool shouldAutoUpdateOnLaunch,
    @Default(false) final bool isRulesHotReloadEnabled,
    final double? windowXPos,
    final double? windowYPos,
    final double? windowWidth,
    final double? windowHeight,
    final bool? isMaximized,
    final bool? isMinimized,
    final TriOSTools? defaultTool,
  }) = _Settings;

  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
}

/// When settings change, save them to shared prefs
class SettingSaver extends Notifier<Settings> {
  @override
  Settings build() {
    final settings = readAppSettings();
    if (settings != null) {
      return settings;
    } else {
      return Settings();
    }

    // final gameDir = defaultGamePath()?.absolute;
    // if (gameDir == null) {
    //   return Settings();
    // } else {
    //   return Settings(gameDir: gameDir.path, modsDir: ref.read(modFolderPath)?.path);
    // }
  }

  void update(Settings Function(Settings) update) {
    final prevState = state;
    var newState = update(state);

    if (prevState == newState) {
      Fimber.v("No settings change: $newState");
      return;
    }

    if (!newState.hasCustomModsDir) {
      if (newState.gameDir != null) {
        var newModsDir = generateModFolderPath(Directory(newState.gameDir!))?.path;
        newState = newState.copyWith(modsDir: newModsDir);
      }
    }

    Fimber.d("Updated settings: $newState");

    sharedPrefs.setString(sharedPrefsSettingsKey, jsonEncode(newState.toJson()));
    state = newState;
  }
}
