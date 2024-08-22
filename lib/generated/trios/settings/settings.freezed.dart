// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../trios/settings/settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Settings _$SettingsFromJson(Map<String, dynamic> json) {
  return _Settings.fromJson(json);
}

/// @nodoc
mixin _$Settings {
  @JsonDirectoryConverter()
  Directory? get gameDir => throw _privateConstructorUsedError;
  @JsonDirectoryConverter()
  Directory? get gameCoreDir => throw _privateConstructorUsedError;
  @JsonDirectoryConverter()
  Directory? get modsDir => throw _privateConstructorUsedError;
  bool get hasCustomModsDir => throw _privateConstructorUsedError;
  bool get shouldAutoUpdateOnLaunch => throw _privateConstructorUsedError;
  bool get isRulesHotReloadEnabled => throw _privateConstructorUsedError;
  double? get windowXPos => throw _privateConstructorUsedError;
  double? get windowYPos => throw _privateConstructorUsedError;
  double? get windowWidth => throw _privateConstructorUsedError;
  double? get windowHeight => throw _privateConstructorUsedError;
  bool? get isMaximized => throw _privateConstructorUsedError;
  bool? get isMinimized => throw _privateConstructorUsedError;
  TriOSTools? get defaultTool => throw _privateConstructorUsedError;
  String? get jre23VmparamsFilename => throw _privateConstructorUsedError;
  bool? get useJre23 => throw _privateConstructorUsedError;
  bool get showJre23ConsoleWindow => throw _privateConstructorUsedError;

  /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
  bool get enableDirectLaunch => throw _privateConstructorUsedError;
  LaunchSettings get launchSettings => throw _privateConstructorUsedError;
  String? get lastStarsectorVersion => throw _privateConstructorUsedError;
  int get secondsBetweenModFolderChecks => throw _privateConstructorUsedError;
  int get toastDurationSeconds => throw _privateConstructorUsedError;
  bool get isUpdatesFieldShown => throw _privateConstructorUsedError;
  ModsGridState? get modsGridState => throw _privateConstructorUsedError;
  FolderNamingSetting get folderNamingSetting =>
      throw _privateConstructorUsedError;
  bool? get allowCrashReporting => throw _privateConstructorUsedError;
  bool get updateToPrereleases => throw _privateConstructorUsedError;
  String get userId =>
      throw _privateConstructorUsedError; // Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
// in a different shared_prefs key.
  String? get activeModProfileId => throw _privateConstructorUsedError;

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SettingsCopyWith<Settings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsCopyWith<$Res> {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) then) =
      _$SettingsCopyWithImpl<$Res, Settings>;
  @useResult
  $Res call(
      {@JsonDirectoryConverter() Directory? gameDir,
      @JsonDirectoryConverter() Directory? gameCoreDir,
      @JsonDirectoryConverter() Directory? modsDir,
      bool hasCustomModsDir,
      bool shouldAutoUpdateOnLaunch,
      bool isRulesHotReloadEnabled,
      double? windowXPos,
      double? windowYPos,
      double? windowWidth,
      double? windowHeight,
      bool? isMaximized,
      bool? isMinimized,
      TriOSTools? defaultTool,
      String? jre23VmparamsFilename,
      bool? useJre23,
      bool showJre23ConsoleWindow,
      bool enableDirectLaunch,
      LaunchSettings launchSettings,
      String? lastStarsectorVersion,
      int secondsBetweenModFolderChecks,
      int toastDurationSeconds,
      bool isUpdatesFieldShown,
      ModsGridState? modsGridState,
      FolderNamingSetting folderNamingSetting,
      bool? allowCrashReporting,
      bool updateToPrereleases,
      String userId,
      String? activeModProfileId});

  $LaunchSettingsCopyWith<$Res> get launchSettings;
  $ModsGridStateCopyWith<$Res>? get modsGridState;
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res, $Val extends Settings>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameDir = freezed,
    Object? gameCoreDir = freezed,
    Object? modsDir = freezed,
    Object? hasCustomModsDir = null,
    Object? shouldAutoUpdateOnLaunch = null,
    Object? isRulesHotReloadEnabled = null,
    Object? windowXPos = freezed,
    Object? windowYPos = freezed,
    Object? windowWidth = freezed,
    Object? windowHeight = freezed,
    Object? isMaximized = freezed,
    Object? isMinimized = freezed,
    Object? defaultTool = freezed,
    Object? jre23VmparamsFilename = freezed,
    Object? useJre23 = freezed,
    Object? showJre23ConsoleWindow = null,
    Object? enableDirectLaunch = null,
    Object? launchSettings = null,
    Object? lastStarsectorVersion = freezed,
    Object? secondsBetweenModFolderChecks = null,
    Object? toastDurationSeconds = null,
    Object? isUpdatesFieldShown = null,
    Object? modsGridState = freezed,
    Object? folderNamingSetting = null,
    Object? allowCrashReporting = freezed,
    Object? updateToPrereleases = null,
    Object? userId = null,
    Object? activeModProfileId = freezed,
  }) {
    return _then(_value.copyWith(
      gameDir: freezed == gameDir
          ? _value.gameDir
          : gameDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
      gameCoreDir: freezed == gameCoreDir
          ? _value.gameCoreDir
          : gameCoreDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
      modsDir: freezed == modsDir
          ? _value.modsDir
          : modsDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
      hasCustomModsDir: null == hasCustomModsDir
          ? _value.hasCustomModsDir
          : hasCustomModsDir // ignore: cast_nullable_to_non_nullable
              as bool,
      shouldAutoUpdateOnLaunch: null == shouldAutoUpdateOnLaunch
          ? _value.shouldAutoUpdateOnLaunch
          : shouldAutoUpdateOnLaunch // ignore: cast_nullable_to_non_nullable
              as bool,
      isRulesHotReloadEnabled: null == isRulesHotReloadEnabled
          ? _value.isRulesHotReloadEnabled
          : isRulesHotReloadEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      windowXPos: freezed == windowXPos
          ? _value.windowXPos
          : windowXPos // ignore: cast_nullable_to_non_nullable
              as double?,
      windowYPos: freezed == windowYPos
          ? _value.windowYPos
          : windowYPos // ignore: cast_nullable_to_non_nullable
              as double?,
      windowWidth: freezed == windowWidth
          ? _value.windowWidth
          : windowWidth // ignore: cast_nullable_to_non_nullable
              as double?,
      windowHeight: freezed == windowHeight
          ? _value.windowHeight
          : windowHeight // ignore: cast_nullable_to_non_nullable
              as double?,
      isMaximized: freezed == isMaximized
          ? _value.isMaximized
          : isMaximized // ignore: cast_nullable_to_non_nullable
              as bool?,
      isMinimized: freezed == isMinimized
          ? _value.isMinimized
          : isMinimized // ignore: cast_nullable_to_non_nullable
              as bool?,
      defaultTool: freezed == defaultTool
          ? _value.defaultTool
          : defaultTool // ignore: cast_nullable_to_non_nullable
              as TriOSTools?,
      jre23VmparamsFilename: freezed == jre23VmparamsFilename
          ? _value.jre23VmparamsFilename
          : jre23VmparamsFilename // ignore: cast_nullable_to_non_nullable
              as String?,
      useJre23: freezed == useJre23
          ? _value.useJre23
          : useJre23 // ignore: cast_nullable_to_non_nullable
              as bool?,
      showJre23ConsoleWindow: null == showJre23ConsoleWindow
          ? _value.showJre23ConsoleWindow
          : showJre23ConsoleWindow // ignore: cast_nullable_to_non_nullable
              as bool,
      enableDirectLaunch: null == enableDirectLaunch
          ? _value.enableDirectLaunch
          : enableDirectLaunch // ignore: cast_nullable_to_non_nullable
              as bool,
      launchSettings: null == launchSettings
          ? _value.launchSettings
          : launchSettings // ignore: cast_nullable_to_non_nullable
              as LaunchSettings,
      lastStarsectorVersion: freezed == lastStarsectorVersion
          ? _value.lastStarsectorVersion
          : lastStarsectorVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      secondsBetweenModFolderChecks: null == secondsBetweenModFolderChecks
          ? _value.secondsBetweenModFolderChecks
          : secondsBetweenModFolderChecks // ignore: cast_nullable_to_non_nullable
              as int,
      toastDurationSeconds: null == toastDurationSeconds
          ? _value.toastDurationSeconds
          : toastDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isUpdatesFieldShown: null == isUpdatesFieldShown
          ? _value.isUpdatesFieldShown
          : isUpdatesFieldShown // ignore: cast_nullable_to_non_nullable
              as bool,
      modsGridState: freezed == modsGridState
          ? _value.modsGridState
          : modsGridState // ignore: cast_nullable_to_non_nullable
              as ModsGridState?,
      folderNamingSetting: null == folderNamingSetting
          ? _value.folderNamingSetting
          : folderNamingSetting // ignore: cast_nullable_to_non_nullable
              as FolderNamingSetting,
      allowCrashReporting: freezed == allowCrashReporting
          ? _value.allowCrashReporting
          : allowCrashReporting // ignore: cast_nullable_to_non_nullable
              as bool?,
      updateToPrereleases: null == updateToPrereleases
          ? _value.updateToPrereleases
          : updateToPrereleases // ignore: cast_nullable_to_non_nullable
              as bool,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      activeModProfileId: freezed == activeModProfileId
          ? _value.activeModProfileId
          : activeModProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LaunchSettingsCopyWith<$Res> get launchSettings {
    return $LaunchSettingsCopyWith<$Res>(_value.launchSettings, (value) {
      return _then(_value.copyWith(launchSettings: value) as $Val);
    });
  }

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModsGridStateCopyWith<$Res>? get modsGridState {
    if (_value.modsGridState == null) {
      return null;
    }

    return $ModsGridStateCopyWith<$Res>(_value.modsGridState!, (value) {
      return _then(_value.copyWith(modsGridState: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SettingsImplCopyWith<$Res>
    implements $SettingsCopyWith<$Res> {
  factory _$$SettingsImplCopyWith(
          _$SettingsImpl value, $Res Function(_$SettingsImpl) then) =
      __$$SettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonDirectoryConverter() Directory? gameDir,
      @JsonDirectoryConverter() Directory? gameCoreDir,
      @JsonDirectoryConverter() Directory? modsDir,
      bool hasCustomModsDir,
      bool shouldAutoUpdateOnLaunch,
      bool isRulesHotReloadEnabled,
      double? windowXPos,
      double? windowYPos,
      double? windowWidth,
      double? windowHeight,
      bool? isMaximized,
      bool? isMinimized,
      TriOSTools? defaultTool,
      String? jre23VmparamsFilename,
      bool? useJre23,
      bool showJre23ConsoleWindow,
      bool enableDirectLaunch,
      LaunchSettings launchSettings,
      String? lastStarsectorVersion,
      int secondsBetweenModFolderChecks,
      int toastDurationSeconds,
      bool isUpdatesFieldShown,
      ModsGridState? modsGridState,
      FolderNamingSetting folderNamingSetting,
      bool? allowCrashReporting,
      bool updateToPrereleases,
      String userId,
      String? activeModProfileId});

  @override
  $LaunchSettingsCopyWith<$Res> get launchSettings;
  @override
  $ModsGridStateCopyWith<$Res>? get modsGridState;
}

/// @nodoc
class __$$SettingsImplCopyWithImpl<$Res>
    extends _$SettingsCopyWithImpl<$Res, _$SettingsImpl>
    implements _$$SettingsImplCopyWith<$Res> {
  __$$SettingsImplCopyWithImpl(
      _$SettingsImpl _value, $Res Function(_$SettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameDir = freezed,
    Object? gameCoreDir = freezed,
    Object? modsDir = freezed,
    Object? hasCustomModsDir = null,
    Object? shouldAutoUpdateOnLaunch = null,
    Object? isRulesHotReloadEnabled = null,
    Object? windowXPos = freezed,
    Object? windowYPos = freezed,
    Object? windowWidth = freezed,
    Object? windowHeight = freezed,
    Object? isMaximized = freezed,
    Object? isMinimized = freezed,
    Object? defaultTool = freezed,
    Object? jre23VmparamsFilename = freezed,
    Object? useJre23 = freezed,
    Object? showJre23ConsoleWindow = null,
    Object? enableDirectLaunch = null,
    Object? launchSettings = null,
    Object? lastStarsectorVersion = freezed,
    Object? secondsBetweenModFolderChecks = null,
    Object? toastDurationSeconds = null,
    Object? isUpdatesFieldShown = null,
    Object? modsGridState = freezed,
    Object? folderNamingSetting = null,
    Object? allowCrashReporting = freezed,
    Object? updateToPrereleases = null,
    Object? userId = null,
    Object? activeModProfileId = freezed,
  }) {
    return _then(_$SettingsImpl(
      gameDir: freezed == gameDir
          ? _value.gameDir
          : gameDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
      gameCoreDir: freezed == gameCoreDir
          ? _value.gameCoreDir
          : gameCoreDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
      modsDir: freezed == modsDir
          ? _value.modsDir
          : modsDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
      hasCustomModsDir: null == hasCustomModsDir
          ? _value.hasCustomModsDir
          : hasCustomModsDir // ignore: cast_nullable_to_non_nullable
              as bool,
      shouldAutoUpdateOnLaunch: null == shouldAutoUpdateOnLaunch
          ? _value.shouldAutoUpdateOnLaunch
          : shouldAutoUpdateOnLaunch // ignore: cast_nullable_to_non_nullable
              as bool,
      isRulesHotReloadEnabled: null == isRulesHotReloadEnabled
          ? _value.isRulesHotReloadEnabled
          : isRulesHotReloadEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      windowXPos: freezed == windowXPos
          ? _value.windowXPos
          : windowXPos // ignore: cast_nullable_to_non_nullable
              as double?,
      windowYPos: freezed == windowYPos
          ? _value.windowYPos
          : windowYPos // ignore: cast_nullable_to_non_nullable
              as double?,
      windowWidth: freezed == windowWidth
          ? _value.windowWidth
          : windowWidth // ignore: cast_nullable_to_non_nullable
              as double?,
      windowHeight: freezed == windowHeight
          ? _value.windowHeight
          : windowHeight // ignore: cast_nullable_to_non_nullable
              as double?,
      isMaximized: freezed == isMaximized
          ? _value.isMaximized
          : isMaximized // ignore: cast_nullable_to_non_nullable
              as bool?,
      isMinimized: freezed == isMinimized
          ? _value.isMinimized
          : isMinimized // ignore: cast_nullable_to_non_nullable
              as bool?,
      defaultTool: freezed == defaultTool
          ? _value.defaultTool
          : defaultTool // ignore: cast_nullable_to_non_nullable
              as TriOSTools?,
      jre23VmparamsFilename: freezed == jre23VmparamsFilename
          ? _value.jre23VmparamsFilename
          : jre23VmparamsFilename // ignore: cast_nullable_to_non_nullable
              as String?,
      useJre23: freezed == useJre23
          ? _value.useJre23
          : useJre23 // ignore: cast_nullable_to_non_nullable
              as bool?,
      showJre23ConsoleWindow: null == showJre23ConsoleWindow
          ? _value.showJre23ConsoleWindow
          : showJre23ConsoleWindow // ignore: cast_nullable_to_non_nullable
              as bool,
      enableDirectLaunch: null == enableDirectLaunch
          ? _value.enableDirectLaunch
          : enableDirectLaunch // ignore: cast_nullable_to_non_nullable
              as bool,
      launchSettings: null == launchSettings
          ? _value.launchSettings
          : launchSettings // ignore: cast_nullable_to_non_nullable
              as LaunchSettings,
      lastStarsectorVersion: freezed == lastStarsectorVersion
          ? _value.lastStarsectorVersion
          : lastStarsectorVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      secondsBetweenModFolderChecks: null == secondsBetweenModFolderChecks
          ? _value.secondsBetweenModFolderChecks
          : secondsBetweenModFolderChecks // ignore: cast_nullable_to_non_nullable
              as int,
      toastDurationSeconds: null == toastDurationSeconds
          ? _value.toastDurationSeconds
          : toastDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isUpdatesFieldShown: null == isUpdatesFieldShown
          ? _value.isUpdatesFieldShown
          : isUpdatesFieldShown // ignore: cast_nullable_to_non_nullable
              as bool,
      modsGridState: freezed == modsGridState
          ? _value.modsGridState
          : modsGridState // ignore: cast_nullable_to_non_nullable
              as ModsGridState?,
      folderNamingSetting: null == folderNamingSetting
          ? _value.folderNamingSetting
          : folderNamingSetting // ignore: cast_nullable_to_non_nullable
              as FolderNamingSetting,
      allowCrashReporting: freezed == allowCrashReporting
          ? _value.allowCrashReporting
          : allowCrashReporting // ignore: cast_nullable_to_non_nullable
              as bool?,
      updateToPrereleases: null == updateToPrereleases
          ? _value.updateToPrereleases
          : updateToPrereleases // ignore: cast_nullable_to_non_nullable
              as bool,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      activeModProfileId: freezed == activeModProfileId
          ? _value.activeModProfileId
          : activeModProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SettingsImpl implements _Settings {
  _$SettingsImpl(
      {@JsonDirectoryConverter() this.gameDir,
      @JsonDirectoryConverter() this.gameCoreDir,
      @JsonDirectoryConverter() this.modsDir,
      this.hasCustomModsDir = false,
      this.shouldAutoUpdateOnLaunch = false,
      this.isRulesHotReloadEnabled = false,
      this.windowXPos,
      this.windowYPos,
      this.windowWidth,
      this.windowHeight,
      this.isMaximized,
      this.isMinimized,
      this.defaultTool,
      this.jre23VmparamsFilename,
      this.useJre23,
      this.showJre23ConsoleWindow = true,
      this.enableDirectLaunch = false,
      this.launchSettings = const LaunchSettings(),
      this.lastStarsectorVersion,
      this.secondsBetweenModFolderChecks = 15,
      this.toastDurationSeconds = 7,
      this.isUpdatesFieldShown = true,
      this.modsGridState,
      this.folderNamingSetting =
          FolderNamingSetting.doNotChangeNameForHighestVersion,
      this.allowCrashReporting,
      this.updateToPrereleases = false,
      this.userId = "",
      this.activeModProfileId});

  factory _$SettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SettingsImplFromJson(json);

  @override
  @JsonDirectoryConverter()
  final Directory? gameDir;
  @override
  @JsonDirectoryConverter()
  final Directory? gameCoreDir;
  @override
  @JsonDirectoryConverter()
  final Directory? modsDir;
  @override
  @JsonKey()
  final bool hasCustomModsDir;
  @override
  @JsonKey()
  final bool shouldAutoUpdateOnLaunch;
  @override
  @JsonKey()
  final bool isRulesHotReloadEnabled;
  @override
  final double? windowXPos;
  @override
  final double? windowYPos;
  @override
  final double? windowWidth;
  @override
  final double? windowHeight;
  @override
  final bool? isMaximized;
  @override
  final bool? isMinimized;
  @override
  final TriOSTools? defaultTool;
  @override
  final String? jre23VmparamsFilename;
  @override
  final bool? useJre23;
  @override
  @JsonKey()
  final bool showJre23ConsoleWindow;

  /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
  @override
  @JsonKey()
  final bool enableDirectLaunch;
  @override
  @JsonKey()
  final LaunchSettings launchSettings;
  @override
  final String? lastStarsectorVersion;
  @override
  @JsonKey()
  final int secondsBetweenModFolderChecks;
  @override
  @JsonKey()
  final int toastDurationSeconds;
  @override
  @JsonKey()
  final bool isUpdatesFieldShown;
  @override
  final ModsGridState? modsGridState;
  @override
  @JsonKey()
  final FolderNamingSetting folderNamingSetting;
  @override
  final bool? allowCrashReporting;
  @override
  @JsonKey()
  final bool updateToPrereleases;
  @override
  @JsonKey()
  final String userId;
// Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
// in a different shared_prefs key.
  @override
  final String? activeModProfileId;

  @override
  String toString() {
    return 'Settings(gameDir: $gameDir, gameCoreDir: $gameCoreDir, modsDir: $modsDir, hasCustomModsDir: $hasCustomModsDir, shouldAutoUpdateOnLaunch: $shouldAutoUpdateOnLaunch, isRulesHotReloadEnabled: $isRulesHotReloadEnabled, windowXPos: $windowXPos, windowYPos: $windowYPos, windowWidth: $windowWidth, windowHeight: $windowHeight, isMaximized: $isMaximized, isMinimized: $isMinimized, defaultTool: $defaultTool, jre23VmparamsFilename: $jre23VmparamsFilename, useJre23: $useJre23, showJre23ConsoleWindow: $showJre23ConsoleWindow, enableDirectLaunch: $enableDirectLaunch, launchSettings: $launchSettings, lastStarsectorVersion: $lastStarsectorVersion, secondsBetweenModFolderChecks: $secondsBetweenModFolderChecks, toastDurationSeconds: $toastDurationSeconds, isUpdatesFieldShown: $isUpdatesFieldShown, modsGridState: $modsGridState, folderNamingSetting: $folderNamingSetting, allowCrashReporting: $allowCrashReporting, updateToPrereleases: $updateToPrereleases, userId: $userId, activeModProfileId: $activeModProfileId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsImpl &&
            (identical(other.gameDir, gameDir) || other.gameDir == gameDir) &&
            (identical(other.gameCoreDir, gameCoreDir) ||
                other.gameCoreDir == gameCoreDir) &&
            (identical(other.modsDir, modsDir) || other.modsDir == modsDir) &&
            (identical(other.hasCustomModsDir, hasCustomModsDir) ||
                other.hasCustomModsDir == hasCustomModsDir) &&
            (identical(other.shouldAutoUpdateOnLaunch, shouldAutoUpdateOnLaunch) ||
                other.shouldAutoUpdateOnLaunch == shouldAutoUpdateOnLaunch) &&
            (identical(other.isRulesHotReloadEnabled, isRulesHotReloadEnabled) ||
                other.isRulesHotReloadEnabled == isRulesHotReloadEnabled) &&
            (identical(other.windowXPos, windowXPos) ||
                other.windowXPos == windowXPos) &&
            (identical(other.windowYPos, windowYPos) ||
                other.windowYPos == windowYPos) &&
            (identical(other.windowWidth, windowWidth) ||
                other.windowWidth == windowWidth) &&
            (identical(other.windowHeight, windowHeight) ||
                other.windowHeight == windowHeight) &&
            (identical(other.isMaximized, isMaximized) ||
                other.isMaximized == isMaximized) &&
            (identical(other.isMinimized, isMinimized) ||
                other.isMinimized == isMinimized) &&
            (identical(other.defaultTool, defaultTool) ||
                other.defaultTool == defaultTool) &&
            (identical(other.jre23VmparamsFilename, jre23VmparamsFilename) ||
                other.jre23VmparamsFilename == jre23VmparamsFilename) &&
            (identical(other.useJre23, useJre23) ||
                other.useJre23 == useJre23) &&
            (identical(other.showJre23ConsoleWindow, showJre23ConsoleWindow) ||
                other.showJre23ConsoleWindow == showJre23ConsoleWindow) &&
            (identical(other.enableDirectLaunch, enableDirectLaunch) ||
                other.enableDirectLaunch == enableDirectLaunch) &&
            (identical(other.launchSettings, launchSettings) ||
                other.launchSettings == launchSettings) &&
            (identical(other.lastStarsectorVersion, lastStarsectorVersion) ||
                other.lastStarsectorVersion == lastStarsectorVersion) &&
            (identical(other.secondsBetweenModFolderChecks, secondsBetweenModFolderChecks) ||
                other.secondsBetweenModFolderChecks ==
                    secondsBetweenModFolderChecks) &&
            (identical(other.toastDurationSeconds, toastDurationSeconds) ||
                other.toastDurationSeconds == toastDurationSeconds) &&
            (identical(other.isUpdatesFieldShown, isUpdatesFieldShown) ||
                other.isUpdatesFieldShown == isUpdatesFieldShown) &&
            (identical(other.modsGridState, modsGridState) ||
                other.modsGridState == modsGridState) &&
            (identical(other.folderNamingSetting, folderNamingSetting) ||
                other.folderNamingSetting == folderNamingSetting) &&
            (identical(other.allowCrashReporting, allowCrashReporting) ||
                other.allowCrashReporting == allowCrashReporting) &&
            (identical(other.updateToPrereleases, updateToPrereleases) ||
                other.updateToPrereleases == updateToPrereleases) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.activeModProfileId, activeModProfileId) ||
                other.activeModProfileId == activeModProfileId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        gameDir,
        gameCoreDir,
        modsDir,
        hasCustomModsDir,
        shouldAutoUpdateOnLaunch,
        isRulesHotReloadEnabled,
        windowXPos,
        windowYPos,
        windowWidth,
        windowHeight,
        isMaximized,
        isMinimized,
        defaultTool,
        jre23VmparamsFilename,
        useJre23,
        showJre23ConsoleWindow,
        enableDirectLaunch,
        launchSettings,
        lastStarsectorVersion,
        secondsBetweenModFolderChecks,
        toastDurationSeconds,
        isUpdatesFieldShown,
        modsGridState,
        folderNamingSetting,
        allowCrashReporting,
        updateToPrereleases,
        userId,
        activeModProfileId
      ]);

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      __$$SettingsImplCopyWithImpl<_$SettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SettingsImplToJson(
      this,
    );
  }
}

abstract class _Settings implements Settings {
  factory _Settings(
      {@JsonDirectoryConverter() final Directory? gameDir,
      @JsonDirectoryConverter() final Directory? gameCoreDir,
      @JsonDirectoryConverter() final Directory? modsDir,
      final bool hasCustomModsDir,
      final bool shouldAutoUpdateOnLaunch,
      final bool isRulesHotReloadEnabled,
      final double? windowXPos,
      final double? windowYPos,
      final double? windowWidth,
      final double? windowHeight,
      final bool? isMaximized,
      final bool? isMinimized,
      final TriOSTools? defaultTool,
      final String? jre23VmparamsFilename,
      final bool? useJre23,
      final bool showJre23ConsoleWindow,
      final bool enableDirectLaunch,
      final LaunchSettings launchSettings,
      final String? lastStarsectorVersion,
      final int secondsBetweenModFolderChecks,
      final int toastDurationSeconds,
      final bool isUpdatesFieldShown,
      final ModsGridState? modsGridState,
      final FolderNamingSetting folderNamingSetting,
      final bool? allowCrashReporting,
      final bool updateToPrereleases,
      final String userId,
      final String? activeModProfileId}) = _$SettingsImpl;

  factory _Settings.fromJson(Map<String, dynamic> json) =
      _$SettingsImpl.fromJson;

  @override
  @JsonDirectoryConverter()
  Directory? get gameDir;
  @override
  @JsonDirectoryConverter()
  Directory? get gameCoreDir;
  @override
  @JsonDirectoryConverter()
  Directory? get modsDir;
  @override
  bool get hasCustomModsDir;
  @override
  bool get shouldAutoUpdateOnLaunch;
  @override
  bool get isRulesHotReloadEnabled;
  @override
  double? get windowXPos;
  @override
  double? get windowYPos;
  @override
  double? get windowWidth;
  @override
  double? get windowHeight;
  @override
  bool? get isMaximized;
  @override
  bool? get isMinimized;
  @override
  TriOSTools? get defaultTool;
  @override
  String? get jre23VmparamsFilename;
  @override
  bool? get useJre23;
  @override
  bool get showJre23ConsoleWindow;

  /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
  @override
  bool get enableDirectLaunch;
  @override
  LaunchSettings get launchSettings;
  @override
  String? get lastStarsectorVersion;
  @override
  int get secondsBetweenModFolderChecks;
  @override
  int get toastDurationSeconds;
  @override
  bool get isUpdatesFieldShown;
  @override
  ModsGridState? get modsGridState;
  @override
  FolderNamingSetting get folderNamingSetting;
  @override
  bool? get allowCrashReporting;
  @override
  bool get updateToPrereleases;
  @override
  String
      get userId; // Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
// in a different shared_prefs key.
  @override
  String? get activeModProfileId;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
