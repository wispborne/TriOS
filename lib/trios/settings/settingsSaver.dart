import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:trios/trios/settings/settings.dart';

var settingsFile = File("trios-settings.json");

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

      settingsFile.writeAsString(jsonEncode(settings.toJson()).toString());

      if (settings.gameDir == null) {
        return;
      }
    }
  }
}

List<String> getModFolderNames(String gameDir) {
  var modsDir = "$gameDir/mods";
  return Directory(modsDir).listSync().whereType<Directory>().map((e) => path.split(e.path).last).toList();
}
