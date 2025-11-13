import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/utils/util.dart';

part 'game_paths_controller.mapper.dart';

final gamePathsControllerProvider =
    AutoDisposeNotifierProvider<GamePathsSetupController, GamePathsSetupState>(
      GamePathsSetupController.new,
    );

/// State class for the game paths setup controller
@MappableClass()
class GamePathsSetupState with GamePathsSetupStateMappable {
  final String gamePathText;
  final bool gamePathExists;
  final CustomPathFieldState customExecutablePathState;
  final CustomPathFieldState customModsPathState;
  final CustomPathFieldState customSavesPathState;
  final CustomPathFieldState customCorePathState;

  const GamePathsSetupState({
    this.gamePathText = '',
    this.gamePathExists = false,
    this.customExecutablePathState = const CustomPathFieldState(),
    this.customModsPathState = const CustomPathFieldState(),
    this.customSavesPathState = const CustomPathFieldState(),
    this.customCorePathState = const CustomPathFieldState(),
  });
}

@MappableClass()
class CustomPathFieldState with CustomPathFieldStateMappable {
  final bool useCustomPath;
  final String pathText;
  final bool pathExists;

  const CustomPathFieldState({
    this.useCustomPath = false,
    this.pathText = '',
    this.pathExists = false,
  });
}

/// Controller for the game paths setup using AutoDisposeNotifier
class GamePathsSetupController
    extends AutoDisposeNotifier<GamePathsSetupState> {
  @override
  GamePathsSetupState build() {
    final gameFolderPathFromSettings =
        ref.watch(appSettings.select((s) => s.gameDir))?.normalize.path ??
        defaultGamePath().path;

    // Custom exe path
    final customExecutablePathTextFromSettings = ref.watch(
      appSettings.select((s) => s.customGameExePath),
    );
    final useCustomExecutable = ref.watch(
      appSettings.select((s) => s.useCustomGameExePath),
    );

    // Custom mods path
    final customModsPathTextFromSettings = ref
        .watch(AppState.modsFolder)
        .valueOrNull
        ?.path;
    final useCustomModsPath = ref.watch(
      appSettings.select((s) => s.hasCustomModsDir),
    );

    // Custom saves path
    final customSavesPathTextFromSettings = ref
        .watch(appSettings.select((s) => s.customSavesPath))
        ?.path;
    final useCustomSavesPath = ref.watch(
      appSettings.select((s) => s.useCustomSavesPath),
    );

    // Custom core path
    final customCorePathTextFromSettings = ref
        .watch(appSettings.select((s) => s.customCoreFolderPath))
        ?.path;
    final useCustomCorePath = ref.watch(
      appSettings.select((s) => s.useCustomCoreFolderPath),
    );

    final doesGamePathExist = validateGameFolderPath(
      gameFolderPathFromSettings,
    );

    final nonCustomGameExecutable = getDefaultGameExecutable(
      gameFolderPathFromSettings.toDirectory(),
    ).toFile().path.let((p) => p.isEmpty ? "" : p);
    final customExecutablePathTextToShow = useCustomExecutable
        ? customExecutablePathTextFromSettings ?? nonCustomGameExecutable
        : nonCustomGameExecutable;

    final nonCustomModsPath =
        generateModsFolderPath(
          gameFolderPathFromSettings.toDirectory(),
        )?.path ??
        "";
    final customModsPathTextToShow = useCustomModsPath
        ? customModsPathTextFromSettings ?? nonCustomModsPath
        : nonCustomModsPath;

    final nonCustomSavesPath =
        generateSavesFolderPath(
          gameFolderPathFromSettings.toDirectory(),
        )?.path ??
        "";
    final customSavesPathTextToShow = useCustomSavesPath
        ? customSavesPathTextFromSettings ?? nonCustomSavesPath
        : nonCustomSavesPath;

    final nonCustomGameCorePath =
        generateGameCorePath(gameFolderPathFromSettings.toDirectory())?.path ??
        "";
    final customCorePathTextToShow = useCustomCorePath
        ? customCorePathTextFromSettings ?? nonCustomGameCorePath
        : nonCustomGameCorePath;

    return GamePathsSetupState(
      gamePathText: gameFolderPathFromSettings,
      gamePathExists: doesGamePathExist,
      customExecutablePathState: CustomPathFieldState(
        useCustomPath: useCustomExecutable,
        pathText: customExecutablePathTextToShow,
        pathExists: customExecutablePathTextToShow.toFile().existsSync(),
      ),
      customModsPathState: CustomPathFieldState(
        useCustomPath: useCustomModsPath,
        pathText: customModsPathTextToShow,
        pathExists: customModsPathTextToShow.toDirectory().existsSync(),
      ),
      customSavesPathState: CustomPathFieldState(
        useCustomPath: useCustomSavesPath,
        pathText: customSavesPathTextToShow,
        pathExists: customSavesPathTextToShow.toDirectory().existsSync(),
      ),
      customCorePathState: CustomPathFieldState(
        useCustomPath: useCustomCorePath,
        pathText: customCorePathTextToShow,
        pathExists: customCorePathTextToShow.toDirectory().existsSync(),
      ),
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
    final exists = newPath.toFile().existsSync();

    // Update state with new values
    state = state.copyWith(
      customExecutablePathState: state.customExecutablePathState.copyWith(
        pathExists: exists,
      ),
    );
  }

  void submitCustomExecutablePath(String newPath) {
    final exists = newPath.toFile().existsSync();

    if (exists) {
      ref
          .read(appSettings.notifier)
          .update(
            (state) =>
                state.copyWith(customGameExePath: File(newPath).normalize.path),
          );
    }
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
      customExecutablePathState: state.customExecutablePathState.copyWith(
        useCustomPath: value,
        pathText: newDisplayPath,
        pathExists: newDisplayPath.toFile().existsSync(),
      ),
    );
  }

  void toggleUseCustomModsPath(bool value) {
    ref
        .read(appSettings.notifier)
        .update((state) => state.copyWith(hasCustomModsDir: value));
  }

  void updateCustomModsPath(String newPath) async {
    final newPathExists = await newPath.toDirectory().exists();

    state = state.copyWith(
      customModsPathState: state.customModsPathState.copyWith(
        pathExists: newPathExists,
      ),
    );
  }

  void submitCustomModsPath(String newPath) async {
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(modsDir: Directory(newPath)));
  }

  void toggleUseCustomSavesPath(bool value) {
    ref
        .read(appSettings.notifier)
        .update((state) => state.copyWith(useCustomSavesPath: value));
  }

  void updateCustomSavesPath(String newPath) async {
    final newPathExists = await newPath.toDirectory().exists();

    state = state.copyWith(
      customSavesPathState: state.customSavesPathState.copyWith(
        pathExists: newPathExists,
      ),
    );
  }

  void submitCustomSavesPath(String newPath) async {
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(customSavesPath: Directory(newPath)));
  }

  void toggleUseCustomCorePath(bool value) {
    ref
        .read(appSettings.notifier)
        .update((state) => state.copyWith(useCustomCoreFolderPath: value));
  }

  void updateCustomCorePath(String newPath) async {
    final newPathExists = await newPath.toDirectory().exists();

    state = state.copyWith(
      customCorePathState: state.customCorePathState.copyWith(
        pathExists: newPathExists,
      ),
    );
  }

  void submitCustomCorePath(String newPath) async {
    ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(customCoreFolderPath: Directory(newPath)));
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
