import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/vmparams/vmparams_manager.dart';

/// Mixin for intents that need access to settings and system info.
mixin SettingsAwareIntent {
  Ref get ref;

  Settings get settings => ref.read(appSettings);

  Directory? get gameFolder => ref.read(AppState.gameFolder).valueOrNull;

  Directory? get modsFolder => ref.read(AppState.modsFolder).valueOrNull;

  Directory? get savesFolder => ref.read(AppState.savesFolder).valueOrNull;

  bool get isGameRunning =>
      ref.read(AppState.isGameRunning).valueOrNull == true;

  String? get currentRam => ref.read(currentRamAmountInMb);

  VmparamsManagerState? get vmparamsState =>
      ref.read(vmparamsManagerProvider).valueOrNull;
}
