import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/utils/util.dart';

/// State class for the game paths setup controller
class GamePathsSetupState {
  final String gamePathText;
  final String customExecutablePathText;
  final bool gamePathExists;
  final bool customExePathExists;

  const GamePathsSetupState({
    this.gamePathText = '',
    this.customExecutablePathText = '',
    this.gamePathExists = false,
    this.customExePathExists = false,
  });

  GamePathsSetupState copyWith({
    String? gamePathText,
    String? customExecutablePathText,
    bool? gamePathExists,
    bool? customExePathExists,
  }) {
    return GamePathsSetupState(
      gamePathText: gamePathText ?? this.gamePathText,
      customExecutablePathText:
          customExecutablePathText ?? this.customExecutablePathText,
      gamePathExists: gamePathExists ?? this.gamePathExists,
      customExePathExists: customExePathExists ?? this.customExePathExists,
    );
  }
}

/// Controller for the game paths setup using AutoDisposeNotifier
class GamePathsSetupController
    extends AutoDisposeNotifier<GamePathsSetupState> {
  @override
  GamePathsSetupState build() {
    final gamePathTextFromSettings =
        ref.watch(appSettings.select((s) => s.gameDir))?.normalize.path ?? "";
    final customExecutablePathTextFromSettings =
        ref.watch(appSettings.select((s) => s.customGameExePath)) ?? "";
    final useCustomExecutable = ref.watch(
      appSettings.select((s) => s.useCustomGameExePath),
    );

    // Validate paths - pass gamePathText as parameter instead of using state
    final gamePathExists = validateGameFolderPath(gamePathTextFromSettings);

    var customExePathExists = false;
    var customExecutablePathTextToShow = customExecutablePathTextFromSettings;

    // If not using override, show the vanilla path that'll be used instead.
    if (useCustomExecutable) {
      customExePathExists = _validateCustomExecutablePath(
        customExecutablePathTextFromSettings,
        useCustomExecutable,
        gamePathTextFromSettings, // Pass as parameter
      );
    }
    // If not using override, show the vanilla path that'll be used instead.
    else {
      customExePathExists = true;
      final currentLaunchPath = getDefaultGameExecutable(
        gamePathTextFromSettings.toDirectory(),
      ).toFile();
      customExecutablePathTextToShow =
          (currentLaunchPath.path.isNotEmpty == true)
          ? currentLaunchPath.path
          : "";
    }

    return GamePathsSetupState(
      gamePathText: gamePathTextFromSettings,
      customExecutablePathText: customExecutablePathTextToShow,
      gamePathExists: gamePathExists,
      customExePathExists: customExePathExists,
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
    final exists = validateIsProbablyAProgram(newPath);

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
      customExePathExists: _validateCustomExecutablePath(
        newPath,
        settings.useCustomGameExePath,
        state.gamePathText, // Now state is available
      ),
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
      customExePathExists: _validateCustomExecutablePath(
        newDisplayPath,
        value,
        state.gamePathText,
      ),
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

  /// Validate custom executable path based on current settings
  /// Added gamePathText parameter to avoid accessing uninitialized state
  bool _validateCustomExecutablePath(
    String path,
    bool useCustomExecutable,
    String gamePathText, // Add parameter instead of using state
  ) {
    if (!useCustomExecutable) {
      // When not using custom, validate game folder path instead
      return validateGameFolderPath(gamePathText);
    } else {
      // When using custom, validate the executable path
      return path.isNotEmpty && validateIsProbablyAProgram(path);
    }
  }
}

final gamePathsSetupControllerProvider =
    AutoDisposeNotifierProvider<GamePathsSetupController, GamePathsSetupState>(
      GamePathsSetupController.new,
    );
