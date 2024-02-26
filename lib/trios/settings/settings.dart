import 'dart:convert';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/app_state.dart';
import 'package:trios/utils/util.dart';

part '../../generated/trios/settings/settings.freezed.dart';
part '../../generated/trios/settings/settings.g.dart';

const sharedPrefsSettingsKey = "settings";

/// Settings State Provider
final appSettings = StateProvider<Settings>((ref) {
  final settings = readAppSettings();
  if (settings != null) {
    return settings;
  }

  final gameDir = defaultGamePath()?.absolute;
  if (gameDir == null) {
    return Settings();
  } else {
    return Settings(gameDir: gameDir.path, modsDir: ref.read(modFolderPath)?.path);
  }
});

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
    final List<String>? enabledModIds,
    @Default(false) final bool shouldAutoUpdateOnLaunch,
    @Default(false) final bool isRulesHotReloadEnabled,
    final double? windowXPos,
    final double? windowYPos,
    final double? windowWidth,
    final double? windowHeight,
    final bool? isMaximized,
    final bool? isMinimized,
  }) = _Settings;

  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
}

/// When settings change, save them to shared prefs
class SettingSaver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    if (provider == appSettings) {
      var settings = newValue as Settings;

      if (newValue == previousValue) {
        Fimber.v("No settings change: $settings");
        return;
      }

      Fimber.d("Updated settings: $settings");

      sharedPrefs.setString(sharedPrefsSettingsKey, jsonEncode(settings.toJson()));

      if (settings.gameDir == null) {
        return;
      }
    }
  }
}
