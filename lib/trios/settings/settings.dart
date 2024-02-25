import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/app_state.dart';
import 'package:trios/trios/settings/settingsSaver.dart';
import 'package:trios/utils/util.dart';

part '../../generated/trios/settings/settings.freezed.dart';
part '../../generated/trios/settings/settings.g.dart';

final appSettings = StateProvider<Settings>((ref) {
  if (settingsFile.existsSync()) {
    // Settings.fromJson(jsonDecode(settingsFile.readAsStringSync()));
    return Settings.fromJson(jsonDecode(settingsFile.readAsStringSync()));
  }

  final gameDir = defaultGamePath()?.absolute;
  if (gameDir == null) {
    return Settings();
  } else {
    return Settings(gameDir: gameDir.path, modsDir: ref.read(modFolderPath)?.path);
  }
});

@freezed
class Settings with _$Settings {
  factory Settings({final String? gameDir, final String? modsDir, final List<String>? enabledModIds}) = _Settings;

  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
}
