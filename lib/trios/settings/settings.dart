import 'dart:convert';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/app_state.dart';
import 'package:trios/utils/util.dart';

part '../../generated/trios/settings/settings.freezed.dart';
part '../../generated/trios/settings/settings.g.dart';

const _sharedPrefsKey = "settings";

/// Settings State Provider
final appSettings = StateProvider<Settings>((ref) {
  if (sharedPrefs.containsKey(_sharedPrefsKey)) {
    return Settings.fromJson(jsonDecode(sharedPrefs.getString(_sharedPrefsKey)!));
  }

  final gameDir = defaultGamePath()?.absolute;
  if (gameDir == null) {
    return Settings();
  } else {
    return Settings(gameDir: gameDir.path, modsDir: ref.read(modFolderPath)?.path);
  }
});

/// Settings object model
@freezed
class Settings with _$Settings {
  factory Settings(
      {final String? gameDir,
      final String? modsDir,
      final List<String>? enabledModIds,
      @Default(false) final bool shouldAutoUpdateOnLaunch,
      @Default(false) final bool isRulesHotReloadEnabled,
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
        Fimber.d("No settings change: $settings");
        return;
      }

      Fimber.d("Updated settings: $settings");

      sharedPrefs.setString(_sharedPrefsKey, jsonEncode(settings.toJson()));

      if (settings.gameDir == null) {
        return;
      }
    }
  }
}
