import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/utils/util.dart';

part 'game_paths_setup_controller.mapper.dart';

/// State class for the game paths setup controller
@MappableClass()
class GamePathsSetupState with GamePathsSetupStateMappable {
  final String gamePathText;
  final bool gamePathExists;
  final bool useCustomExecutable;
  final String customExecutablePathText;
  final bool customExecutablePathExists;
  final bool useCustomModsPath;
  final String customModsPathText;
  final bool customModsPathExists;
  final bool useCustomSavesPath;
  final String customSavesPathText;
  final bool customSavesPathExists;
  final bool useCustomCorePath;
  final String customCorePathText;
  final bool customCorePathExists;

  const GamePathsSetupState({
    this.gamePathText = '',
    this.gamePathExists = false,
    this.useCustomExecutable = false,
    this.customExecutablePathText = '',
    this.customExecutablePathExists = false,
    this.useCustomModsPath = false,
    this.customModsPathText = '',
    this.customModsPathExists = false,
    this.useCustomSavesPath = false,
    this.customSavesPathText = '',
    this.customSavesPathExists = false,
    this.useCustomCorePath = false,
    this.customCorePathText = '',
    this.customCorePathExists = false,
  });
}

/// Controller for the game paths setup using AutoDisposeNotifier
class GamePathsSetupController
    extends AutoDisposeNotifier<GamePathsSetupState> {
  @override
  GamePathsSetupState build() {
    final gameFolderPathFromSettings =
        ref.watch(appSettings.select((s) => s.gameDir))?.normalize.path ?? "";

    // Custom exe path
    final customExecutablePathTextFromSettings =
        ref.watch(appSettings.select((s) => s.customGameExePath)) ?? "";
    final useCustomExecutable = ref.watch(
      appSettings.select((s) => s.useCustomGameExePath),
    );

    // Custom mods path
    final customModsPathTextFromSettings =
        ref.watch(AppState.modsFolder).valueOrNull?.path ?? "";
    final useCustomModsPath = ref.watch(
      appSettings.select((s) => s.hasCustomModsDir),
    );

    // Custom saves path
    final customSavesPathTextFromSettings =
        ref.watch(appSettings.select((s) => s.customSavesPath)) ?? "";
    final useCustomSavesPath = ref.watch(
      appSettings.select((s) => s.useCustomSavesPath),
    );

    // Custom core path
    final customCorePathTextFromSettings =
        ref.watch(appSettings.select((s) => s.customCoreFolderPath)) ?? "";
    final useCustomCorePath = ref.watch(
      appSettings.select((s) => s.useCustomCoreFolderPath),
    );

    final doesGamePathExist = validateGameFolderPath(
      gameFolderPathFromSettings,
    );

    final customExecutablePathTextToShow = useCustomExecutable
        ? customExecutablePathTextFromSettings
        : getDefaultGameExecutable(
            gameFolderPathFromSettings.toDirectory(),
          ).toFile().path.let((p) => p.isEmpty ? "" : p);

    return GamePathsSetupState(
      gamePathText: gameFolderPathFromSettings,
      gamePathExists: doesGamePathExist,
      customExecutablePathText: customExecutablePathTextToShow,
      customExecutablePathExists: customExecutablePathTextToShow
          .toFile()
          .existsSync(),
      useCustomModsPath: useCustomModsPath,
      customModsPathText: customModsPathTextFromSettings,
      customModsPathExists: customModsPathTextFromSettings
          .toDirectory()
          .existsSync(),
    );
  }

  /// Update game path and validate it
  void updateGamePath(String newGameDir) {
    newGameDir = newGameDir.isNullOrEmpty ? defaultGamePath().path : newGameDir;

    final dirExists = validateGameFolderPath(newGameDir);

    if (dirExists) {
      ref.read(appSettings.notifier).update((settings) {
        var newModDirPath = settings.hasCustomModsDir
            ? settings.modsDir?.toDirectory()
            : generateModsFolderPath(newGameDir.toDirectory());
        newModDirPath = newModDirPath?.normalize.toDirectory();

        return settings.copyWith(
          gameDir: Directory(newGameDir).normalize,
          modsDir: newModDirPath,
        );
      });
    }

    state = state.copyWith(gamePathText: newGameDir, gamePathExists: dirExists);
  }

  /// Update custom executable path and validate it
  void updateCustomExecutablePath(String newPath) {
    final settings = ref.read(appSettings);
    final exists = newPath.toFile().existsSync();

    if (exists) {
      ref
          .read(appSettings.notifier)
          .update(
            (state) =>
                state.copyWith(customGameExePath: File(newPath).normalize.path),
          );
    }

    // Update state with new values
    state = state.copyWith(
      customExecutablePathText: newPath,
      customExecutablePathExists: exists,
    );
  }

  /// Toggle use custom executable setting
  void toggleUseCustomExecutable(bool value) {
    final currentSettings = ref.read(appSettings);
    final customPath = currentSettings.customGameExePath ?? "";
    final gamePath = currentSettings.gameDir?.toDirectory();
    final currentLaunchPath = gamePath?.let(
      (dir) => getDefaultGameExecutable(dir).toFile().path,
    );

    // Update the setting
    ref
        .read(appSettings.notifier)
        .update((state) => state.copyWith(useCustomGameExePath: value));

    // Update the displayed path based on the toggle
    String newDisplayPath;
    if (!value) {
      // Show default path when custom is disabled
      newDisplayPath = currentLaunchPath ?? "";
    } else {
      // Show custom path when custom is enabled
      newDisplayPath = customPath;
    }

    state = state.copyWith(
      customExecutablePathText: newDisplayPath,
      customExecutablePathExists: newDisplayPath.toFile().existsSync(),
    );
  }

  void toggleUseCustomModsPath(bool value) {
    ref
        .read(appSettings.notifier)
        .update((state) => state.copyWith(hasCustomModsDir: value));
  }

  void updateCustomModsPath(String newPath) {
    final newPathExists = newPath.toDirectory().existsSync();

    if (newPathExists) {
      ref.read(appSettings.notifier).update((s) {
        return s.copyWith(modsDir: Directory(newPath).normalize);
      });
    }

    state = state.copyWith(
      customModsPathText: newPath,
      customModsPathExists: newPathExists,
    );
  }

  /// Get the current launch path for display
  String getCurrentLaunchPath() {
    final settings = ref.read(appSettings);
    final gamePath = settings.gameDir?.toDirectory();
    return gamePath?.let(
          (dir) => getDefaultGameExecutable(dir).toFile().path,
        ) ??
        "";
  }
}

final gamePathsSetupControllerProvider =
    AutoDisposeNotifierProvider<GamePathsSetupController, GamePathsSetupState>(
      GamePathsSetupController.new,
    );
