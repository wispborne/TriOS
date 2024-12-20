// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'settings.dart';

class FolderNamingSettingMapper extends EnumMapper<FolderNamingSetting> {
  FolderNamingSettingMapper._();

  static FolderNamingSettingMapper? _instance;
  static FolderNamingSettingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FolderNamingSettingMapper._());
    }
    return _instance!;
  }

  static FolderNamingSetting fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FolderNamingSetting decode(dynamic value) {
    switch (value) {
      case 0:
        return FolderNamingSetting.doNotChangeNameForHighestVersion;
      case 1:
        return FolderNamingSetting.allFoldersVersioned;
      case 2:
        return FolderNamingSetting.doNotChangeNamesEver;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FolderNamingSetting self) {
    switch (self) {
      case FolderNamingSetting.doNotChangeNameForHighestVersion:
        return 0;
      case FolderNamingSetting.allFoldersVersioned:
        return 1;
      case FolderNamingSetting.doNotChangeNamesEver:
        return 2;
    }
  }
}

extension FolderNamingSettingMapperExtension on FolderNamingSetting {
  dynamic toValue() {
    FolderNamingSettingMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FolderNamingSetting>(this);
  }
}

class ModUpdateBehaviorMapper extends EnumMapper<ModUpdateBehavior> {
  ModUpdateBehaviorMapper._();

  static ModUpdateBehaviorMapper? _instance;
  static ModUpdateBehaviorMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModUpdateBehaviorMapper._());
    }
    return _instance!;
  }

  static ModUpdateBehavior fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModUpdateBehavior decode(dynamic value) {
    switch (value) {
      case 'doNotChange':
        return ModUpdateBehavior.doNotChange;
      case 'switchToNewVersionIfWasEnabled':
        return ModUpdateBehavior.switchToNewVersionIfWasEnabled;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModUpdateBehavior self) {
    switch (self) {
      case ModUpdateBehavior.doNotChange:
        return 'doNotChange';
      case ModUpdateBehavior.switchToNewVersionIfWasEnabled:
        return 'switchToNewVersionIfWasEnabled';
    }
  }
}

extension ModUpdateBehaviorMapperExtension on ModUpdateBehavior {
  String toValue() {
    ModUpdateBehaviorMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModUpdateBehavior>(this) as String;
  }
}

class SettingsMapper extends ClassMapperBase<Settings> {
  SettingsMapper._();

  static SettingsMapper? _instance;
  static SettingsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SettingsMapper._());
      TriOSToolsMapper.ensureInitialized();
      LaunchSettingsMapper.ensureInitialized();
      WispGridStateMapper.ensureInitialized();
      ModsGridStateMapper.ensureInitialized();
      FolderNamingSettingMapper.ensureInitialized();
      ModUpdateBehaviorMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Settings';

  static Directory? _$gameDir(Settings v) => v.gameDir;
  static const Field<Settings, Directory> _f$gameDir =
      Field('gameDir', _$gameDir, opt: true, hook: DirectoryHook());
  static Directory? _$gameCoreDir(Settings v) => v.gameCoreDir;
  static const Field<Settings, Directory> _f$gameCoreDir =
      Field('gameCoreDir', _$gameCoreDir, opt: true, hook: DirectoryHook());
  static Directory? _$modsDir(Settings v) => v.modsDir;
  static const Field<Settings, Directory> _f$modsDir =
      Field('modsDir', _$modsDir, opt: true, hook: DirectoryHook());
  static bool _$hasCustomModsDir(Settings v) => v.hasCustomModsDir;
  static const Field<Settings, bool> _f$hasCustomModsDir =
      Field('hasCustomModsDir', _$hasCustomModsDir, opt: true, def: false);
  static bool _$isRulesHotReloadEnabled(Settings v) =>
      v.isRulesHotReloadEnabled;
  static const Field<Settings, bool> _f$isRulesHotReloadEnabled = Field(
      'isRulesHotReloadEnabled', _$isRulesHotReloadEnabled,
      opt: true, def: false);
  static double? _$windowXPos(Settings v) => v.windowXPos;
  static const Field<Settings, double> _f$windowXPos =
      Field('windowXPos', _$windowXPos, opt: true);
  static double? _$windowYPos(Settings v) => v.windowYPos;
  static const Field<Settings, double> _f$windowYPos =
      Field('windowYPos', _$windowYPos, opt: true);
  static double? _$windowWidth(Settings v) => v.windowWidth;
  static const Field<Settings, double> _f$windowWidth =
      Field('windowWidth', _$windowWidth, opt: true);
  static double? _$windowHeight(Settings v) => v.windowHeight;
  static const Field<Settings, double> _f$windowHeight =
      Field('windowHeight', _$windowHeight, opt: true);
  static bool? _$isMaximized(Settings v) => v.isMaximized;
  static const Field<Settings, bool> _f$isMaximized =
      Field('isMaximized', _$isMaximized, opt: true);
  static bool? _$isMinimized(Settings v) => v.isMinimized;
  static const Field<Settings, bool> _f$isMinimized =
      Field('isMinimized', _$isMinimized, opt: true);
  static TriOSTools? _$defaultTool(Settings v) => v.defaultTool;
  static const Field<Settings, TriOSTools> _f$defaultTool =
      Field('defaultTool', _$defaultTool, opt: true);
  static String? _$jre23VmparamsFilename(Settings v) => v.jre23VmparamsFilename;
  static const Field<Settings, String> _f$jre23VmparamsFilename =
      Field('jre23VmparamsFilename', _$jre23VmparamsFilename, opt: true);
  static bool? _$useJre23(Settings v) => v.useJre23;
  static const Field<Settings, bool> _f$useJre23 =
      Field('useJre23', _$useJre23, opt: true);
  static bool _$showJre23ConsoleWindow(Settings v) => v.showJre23ConsoleWindow;
  static const Field<Settings, bool> _f$showJre23ConsoleWindow = Field(
      'showJre23ConsoleWindow', _$showJre23ConsoleWindow,
      opt: true, def: true);
  static String? _$themeKey(Settings v) => v.themeKey;
  static const Field<Settings, String> _f$themeKey =
      Field('themeKey', _$themeKey, opt: true);
  static bool _$enableDirectLaunch(Settings v) => v.enableDirectLaunch;
  static const Field<Settings, bool> _f$enableDirectLaunch =
      Field('enableDirectLaunch', _$enableDirectLaunch, opt: true, def: false);
  static LaunchSettings _$launchSettings(Settings v) => v.launchSettings;
  static const Field<Settings, LaunchSettings> _f$launchSettings = Field(
      'launchSettings', _$launchSettings,
      opt: true, def: const LaunchSettings());
  static String? _$lastStarsectorVersion(Settings v) => v.lastStarsectorVersion;
  static const Field<Settings, String> _f$lastStarsectorVersion =
      Field('lastStarsectorVersion', _$lastStarsectorVersion, opt: true);
  static bool _$isUpdatesFieldShown(Settings v) => v.isUpdatesFieldShown;
  static const Field<Settings, bool> _f$isUpdatesFieldShown =
      Field('isUpdatesFieldShown', _$isUpdatesFieldShown, opt: true, def: true);
  static WispGridState _$modsGridState(Settings v) => v.modsGridState;
  static const Field<Settings, WispGridState> _f$modsGridState = Field(
      'modsGridState', _$modsGridState,
      opt: true,
      def: const WispGridState(
          groupingSetting:
              GroupingSetting(grouping: ModGridGroupEnum.enabledState)),
      hook: SafeDecodeHook());
  static ModsGridState? _$oldModsGridState(Settings v) => v.oldModsGridState;
  static const Field<Settings, ModsGridState> _f$oldModsGridState =
      Field('oldModsGridState', _$oldModsGridState, opt: true);
  static bool _$shouldAutoUpdateOnLaunch(Settings v) =>
      v.shouldAutoUpdateOnLaunch;
  static const Field<Settings, bool> _f$shouldAutoUpdateOnLaunch = Field(
      'shouldAutoUpdateOnLaunch', _$shouldAutoUpdateOnLaunch,
      opt: true, def: false);
  static int _$secondsBetweenModFolderChecks(Settings v) =>
      v.secondsBetweenModFolderChecks;
  static const Field<Settings, int> _f$secondsBetweenModFolderChecks = Field(
      'secondsBetweenModFolderChecks', _$secondsBetweenModFolderChecks,
      opt: true, def: 15);
  static int _$toastDurationSeconds(Settings v) => v.toastDurationSeconds;
  static const Field<Settings, int> _f$toastDurationSeconds =
      Field('toastDurationSeconds', _$toastDurationSeconds, opt: true, def: 7);
  static int _$maxHttpRequestsAtOnce(Settings v) => v.maxHttpRequestsAtOnce;
  static const Field<Settings, int> _f$maxHttpRequestsAtOnce = Field(
      'maxHttpRequestsAtOnce', _$maxHttpRequestsAtOnce,
      opt: true, def: 20);
  static FolderNamingSetting _$folderNamingSetting(Settings v) =>
      v.folderNamingSetting;
  static const Field<Settings, FolderNamingSetting> _f$folderNamingSetting =
      Field('folderNamingSetting', _$folderNamingSetting,
          opt: true, def: FolderNamingSetting.allFoldersVersioned);
  static int? _$keepLastNVersions(Settings v) => v.keepLastNVersions;
  static const Field<Settings, int> _f$keepLastNVersions =
      Field('keepLastNVersions', _$keepLastNVersions, opt: true);
  static bool? _$allowCrashReporting(Settings v) => v.allowCrashReporting;
  static const Field<Settings, bool> _f$allowCrashReporting =
      Field('allowCrashReporting', _$allowCrashReporting, opt: true);
  static bool _$updateToPrereleases(Settings v) => v.updateToPrereleases;
  static const Field<Settings, bool> _f$updateToPrereleases = Field(
      'updateToPrereleases', _$updateToPrereleases,
      opt: true, def: false);
  static bool _$autoEnableAndDisableDependencies(Settings v) =>
      v.autoEnableAndDisableDependencies;
  static const Field<Settings, bool> _f$autoEnableAndDisableDependencies =
      Field('autoEnableAndDisableDependencies',
          _$autoEnableAndDisableDependencies,
          opt: true, def: false);
  static bool _$enableLauncherPrecheck(Settings v) => v.enableLauncherPrecheck;
  static const Field<Settings, bool> _f$enableLauncherPrecheck = Field(
      'enableLauncherPrecheck', _$enableLauncherPrecheck,
      opt: true, def: true);
  static ModUpdateBehavior _$modUpdateBehavior(Settings v) =>
      v.modUpdateBehavior;
  static const Field<Settings, ModUpdateBehavior> _f$modUpdateBehavior = Field(
      'modUpdateBehavior', _$modUpdateBehavior,
      opt: true, def: ModUpdateBehavior.switchToNewVersionIfWasEnabled);
  static String _$userId(Settings v) => v.userId;
  static const Field<Settings, String> _f$userId =
      Field('userId', _$userId, opt: true, def: '');
  static bool? _$hasHiddenForumDarkModeTip(Settings v) =>
      v.hasHiddenForumDarkModeTip;
  static const Field<Settings, bool> _f$hasHiddenForumDarkModeTip = Field(
      'hasHiddenForumDarkModeTip', _$hasHiddenForumDarkModeTip,
      opt: true);
  static String? _$activeModProfileId(Settings v) => v.activeModProfileId;
  static const Field<Settings, String> _f$activeModProfileId =
      Field('activeModProfileId', _$activeModProfileId, opt: true);

  @override
  final MappableFields<Settings> fields = const {
    #gameDir: _f$gameDir,
    #gameCoreDir: _f$gameCoreDir,
    #modsDir: _f$modsDir,
    #hasCustomModsDir: _f$hasCustomModsDir,
    #isRulesHotReloadEnabled: _f$isRulesHotReloadEnabled,
    #windowXPos: _f$windowXPos,
    #windowYPos: _f$windowYPos,
    #windowWidth: _f$windowWidth,
    #windowHeight: _f$windowHeight,
    #isMaximized: _f$isMaximized,
    #isMinimized: _f$isMinimized,
    #defaultTool: _f$defaultTool,
    #jre23VmparamsFilename: _f$jre23VmparamsFilename,
    #useJre23: _f$useJre23,
    #showJre23ConsoleWindow: _f$showJre23ConsoleWindow,
    #themeKey: _f$themeKey,
    #enableDirectLaunch: _f$enableDirectLaunch,
    #launchSettings: _f$launchSettings,
    #lastStarsectorVersion: _f$lastStarsectorVersion,
    #isUpdatesFieldShown: _f$isUpdatesFieldShown,
    #modsGridState: _f$modsGridState,
    #oldModsGridState: _f$oldModsGridState,
    #shouldAutoUpdateOnLaunch: _f$shouldAutoUpdateOnLaunch,
    #secondsBetweenModFolderChecks: _f$secondsBetweenModFolderChecks,
    #toastDurationSeconds: _f$toastDurationSeconds,
    #maxHttpRequestsAtOnce: _f$maxHttpRequestsAtOnce,
    #folderNamingSetting: _f$folderNamingSetting,
    #keepLastNVersions: _f$keepLastNVersions,
    #allowCrashReporting: _f$allowCrashReporting,
    #updateToPrereleases: _f$updateToPrereleases,
    #autoEnableAndDisableDependencies: _f$autoEnableAndDisableDependencies,
    #enableLauncherPrecheck: _f$enableLauncherPrecheck,
    #modUpdateBehavior: _f$modUpdateBehavior,
    #userId: _f$userId,
    #hasHiddenForumDarkModeTip: _f$hasHiddenForumDarkModeTip,
    #activeModProfileId: _f$activeModProfileId,
  };

  static Settings _instantiate(DecodingData data) {
    return Settings(
        gameDir: data.dec(_f$gameDir),
        gameCoreDir: data.dec(_f$gameCoreDir),
        modsDir: data.dec(_f$modsDir),
        hasCustomModsDir: data.dec(_f$hasCustomModsDir),
        isRulesHotReloadEnabled: data.dec(_f$isRulesHotReloadEnabled),
        windowXPos: data.dec(_f$windowXPos),
        windowYPos: data.dec(_f$windowYPos),
        windowWidth: data.dec(_f$windowWidth),
        windowHeight: data.dec(_f$windowHeight),
        isMaximized: data.dec(_f$isMaximized),
        isMinimized: data.dec(_f$isMinimized),
        defaultTool: data.dec(_f$defaultTool),
        jre23VmparamsFilename: data.dec(_f$jre23VmparamsFilename),
        useJre23: data.dec(_f$useJre23),
        showJre23ConsoleWindow: data.dec(_f$showJre23ConsoleWindow),
        themeKey: data.dec(_f$themeKey),
        enableDirectLaunch: data.dec(_f$enableDirectLaunch),
        launchSettings: data.dec(_f$launchSettings),
        lastStarsectorVersion: data.dec(_f$lastStarsectorVersion),
        isUpdatesFieldShown: data.dec(_f$isUpdatesFieldShown),
        modsGridState: data.dec(_f$modsGridState),
        oldModsGridState: data.dec(_f$oldModsGridState),
        shouldAutoUpdateOnLaunch: data.dec(_f$shouldAutoUpdateOnLaunch),
        secondsBetweenModFolderChecks:
            data.dec(_f$secondsBetweenModFolderChecks),
        toastDurationSeconds: data.dec(_f$toastDurationSeconds),
        maxHttpRequestsAtOnce: data.dec(_f$maxHttpRequestsAtOnce),
        folderNamingSetting: data.dec(_f$folderNamingSetting),
        keepLastNVersions: data.dec(_f$keepLastNVersions),
        allowCrashReporting: data.dec(_f$allowCrashReporting),
        updateToPrereleases: data.dec(_f$updateToPrereleases),
        autoEnableAndDisableDependencies:
            data.dec(_f$autoEnableAndDisableDependencies),
        enableLauncherPrecheck: data.dec(_f$enableLauncherPrecheck),
        modUpdateBehavior: data.dec(_f$modUpdateBehavior),
        userId: data.dec(_f$userId),
        hasHiddenForumDarkModeTip: data.dec(_f$hasHiddenForumDarkModeTip),
        activeModProfileId: data.dec(_f$activeModProfileId));
  }

  @override
  final Function instantiate = _instantiate;

  static Settings fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Settings>(map);
  }

  static Settings fromJson(String json) {
    return ensureInitialized().decodeJson<Settings>(json);
  }
}

mixin SettingsMappable {
  String toJson() {
    return SettingsMapper.ensureInitialized()
        .encodeJson<Settings>(this as Settings);
  }

  Map<String, dynamic> toMap() {
    return SettingsMapper.ensureInitialized()
        .encodeMap<Settings>(this as Settings);
  }

  SettingsCopyWith<Settings, Settings, Settings> get copyWith =>
      _SettingsCopyWithImpl(this as Settings, $identity, $identity);
  @override
  String toString() {
    return SettingsMapper.ensureInitialized().stringifyValue(this as Settings);
  }

  @override
  bool operator ==(Object other) {
    return SettingsMapper.ensureInitialized()
        .equalsValue(this as Settings, other);
  }

  @override
  int get hashCode {
    return SettingsMapper.ensureInitialized().hashValue(this as Settings);
  }
}

extension SettingsValueCopy<$R, $Out> on ObjectCopyWith<$R, Settings, $Out> {
  SettingsCopyWith<$R, Settings, $Out> get $asSettings =>
      $base.as((v, t, t2) => _SettingsCopyWithImpl(v, t, t2));
}

abstract class SettingsCopyWith<$R, $In extends Settings, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  LaunchSettingsCopyWith<$R, LaunchSettings, LaunchSettings> get launchSettings;
  WispGridStateCopyWith<$R, WispGridState, WispGridState> get modsGridState;
  ModsGridStateCopyWith<$R, ModsGridState, ModsGridState>? get oldModsGridState;
  $R call(
      {Directory? gameDir,
      Directory? gameCoreDir,
      Directory? modsDir,
      bool? hasCustomModsDir,
      bool? isRulesHotReloadEnabled,
      double? windowXPos,
      double? windowYPos,
      double? windowWidth,
      double? windowHeight,
      bool? isMaximized,
      bool? isMinimized,
      TriOSTools? defaultTool,
      String? jre23VmparamsFilename,
      bool? useJre23,
      bool? showJre23ConsoleWindow,
      String? themeKey,
      bool? enableDirectLaunch,
      LaunchSettings? launchSettings,
      String? lastStarsectorVersion,
      bool? isUpdatesFieldShown,
      WispGridState? modsGridState,
      ModsGridState? oldModsGridState,
      bool? shouldAutoUpdateOnLaunch,
      int? secondsBetweenModFolderChecks,
      int? toastDurationSeconds,
      int? maxHttpRequestsAtOnce,
      FolderNamingSetting? folderNamingSetting,
      int? keepLastNVersions,
      bool? allowCrashReporting,
      bool? updateToPrereleases,
      bool? autoEnableAndDisableDependencies,
      bool? enableLauncherPrecheck,
      ModUpdateBehavior? modUpdateBehavior,
      String? userId,
      bool? hasHiddenForumDarkModeTip,
      String? activeModProfileId});
  SettingsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SettingsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Settings, $Out>
    implements SettingsCopyWith<$R, Settings, $Out> {
  _SettingsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Settings> $mapper =
      SettingsMapper.ensureInitialized();
  @override
  LaunchSettingsCopyWith<$R, LaunchSettings, LaunchSettings>
      get launchSettings =>
          $value.launchSettings.copyWith.$chain((v) => call(launchSettings: v));
  @override
  WispGridStateCopyWith<$R, WispGridState, WispGridState> get modsGridState =>
      $value.modsGridState.copyWith.$chain((v) => call(modsGridState: v));
  @override
  ModsGridStateCopyWith<$R, ModsGridState, ModsGridState>?
      get oldModsGridState => $value.oldModsGridState?.copyWith
          .$chain((v) => call(oldModsGridState: v));
  @override
  $R call(
          {Object? gameDir = $none,
          Object? gameCoreDir = $none,
          Object? modsDir = $none,
          bool? hasCustomModsDir,
          bool? isRulesHotReloadEnabled,
          Object? windowXPos = $none,
          Object? windowYPos = $none,
          Object? windowWidth = $none,
          Object? windowHeight = $none,
          Object? isMaximized = $none,
          Object? isMinimized = $none,
          Object? defaultTool = $none,
          Object? jre23VmparamsFilename = $none,
          Object? useJre23 = $none,
          bool? showJre23ConsoleWindow,
          Object? themeKey = $none,
          bool? enableDirectLaunch,
          LaunchSettings? launchSettings,
          Object? lastStarsectorVersion = $none,
          bool? isUpdatesFieldShown,
          WispGridState? modsGridState,
          Object? oldModsGridState = $none,
          bool? shouldAutoUpdateOnLaunch,
          int? secondsBetweenModFolderChecks,
          int? toastDurationSeconds,
          int? maxHttpRequestsAtOnce,
          FolderNamingSetting? folderNamingSetting,
          Object? keepLastNVersions = $none,
          Object? allowCrashReporting = $none,
          bool? updateToPrereleases,
          bool? autoEnableAndDisableDependencies,
          bool? enableLauncherPrecheck,
          ModUpdateBehavior? modUpdateBehavior,
          String? userId,
          Object? hasHiddenForumDarkModeTip = $none,
          Object? activeModProfileId = $none}) =>
      $apply(FieldCopyWithData({
        if (gameDir != $none) #gameDir: gameDir,
        if (gameCoreDir != $none) #gameCoreDir: gameCoreDir,
        if (modsDir != $none) #modsDir: modsDir,
        if (hasCustomModsDir != null) #hasCustomModsDir: hasCustomModsDir,
        if (isRulesHotReloadEnabled != null)
          #isRulesHotReloadEnabled: isRulesHotReloadEnabled,
        if (windowXPos != $none) #windowXPos: windowXPos,
        if (windowYPos != $none) #windowYPos: windowYPos,
        if (windowWidth != $none) #windowWidth: windowWidth,
        if (windowHeight != $none) #windowHeight: windowHeight,
        if (isMaximized != $none) #isMaximized: isMaximized,
        if (isMinimized != $none) #isMinimized: isMinimized,
        if (defaultTool != $none) #defaultTool: defaultTool,
        if (jre23VmparamsFilename != $none)
          #jre23VmparamsFilename: jre23VmparamsFilename,
        if (useJre23 != $none) #useJre23: useJre23,
        if (showJre23ConsoleWindow != null)
          #showJre23ConsoleWindow: showJre23ConsoleWindow,
        if (themeKey != $none) #themeKey: themeKey,
        if (enableDirectLaunch != null) #enableDirectLaunch: enableDirectLaunch,
        if (launchSettings != null) #launchSettings: launchSettings,
        if (lastStarsectorVersion != $none)
          #lastStarsectorVersion: lastStarsectorVersion,
        if (isUpdatesFieldShown != null)
          #isUpdatesFieldShown: isUpdatesFieldShown,
        if (modsGridState != null) #modsGridState: modsGridState,
        if (oldModsGridState != $none) #oldModsGridState: oldModsGridState,
        if (shouldAutoUpdateOnLaunch != null)
          #shouldAutoUpdateOnLaunch: shouldAutoUpdateOnLaunch,
        if (secondsBetweenModFolderChecks != null)
          #secondsBetweenModFolderChecks: secondsBetweenModFolderChecks,
        if (toastDurationSeconds != null)
          #toastDurationSeconds: toastDurationSeconds,
        if (maxHttpRequestsAtOnce != null)
          #maxHttpRequestsAtOnce: maxHttpRequestsAtOnce,
        if (folderNamingSetting != null)
          #folderNamingSetting: folderNamingSetting,
        if (keepLastNVersions != $none) #keepLastNVersions: keepLastNVersions,
        if (allowCrashReporting != $none)
          #allowCrashReporting: allowCrashReporting,
        if (updateToPrereleases != null)
          #updateToPrereleases: updateToPrereleases,
        if (autoEnableAndDisableDependencies != null)
          #autoEnableAndDisableDependencies: autoEnableAndDisableDependencies,
        if (enableLauncherPrecheck != null)
          #enableLauncherPrecheck: enableLauncherPrecheck,
        if (modUpdateBehavior != null) #modUpdateBehavior: modUpdateBehavior,
        if (userId != null) #userId: userId,
        if (hasHiddenForumDarkModeTip != $none)
          #hasHiddenForumDarkModeTip: hasHiddenForumDarkModeTip,
        if (activeModProfileId != $none) #activeModProfileId: activeModProfileId
      }));
  @override
  Settings $make(CopyWithData data) => Settings(
      gameDir: data.get(#gameDir, or: $value.gameDir),
      gameCoreDir: data.get(#gameCoreDir, or: $value.gameCoreDir),
      modsDir: data.get(#modsDir, or: $value.modsDir),
      hasCustomModsDir:
          data.get(#hasCustomModsDir, or: $value.hasCustomModsDir),
      isRulesHotReloadEnabled: data.get(#isRulesHotReloadEnabled,
          or: $value.isRulesHotReloadEnabled),
      windowXPos: data.get(#windowXPos, or: $value.windowXPos),
      windowYPos: data.get(#windowYPos, or: $value.windowYPos),
      windowWidth: data.get(#windowWidth, or: $value.windowWidth),
      windowHeight: data.get(#windowHeight, or: $value.windowHeight),
      isMaximized: data.get(#isMaximized, or: $value.isMaximized),
      isMinimized: data.get(#isMinimized, or: $value.isMinimized),
      defaultTool: data.get(#defaultTool, or: $value.defaultTool),
      jre23VmparamsFilename:
          data.get(#jre23VmparamsFilename, or: $value.jre23VmparamsFilename),
      useJre23: data.get(#useJre23, or: $value.useJre23),
      showJre23ConsoleWindow:
          data.get(#showJre23ConsoleWindow, or: $value.showJre23ConsoleWindow),
      themeKey: data.get(#themeKey, or: $value.themeKey),
      enableDirectLaunch:
          data.get(#enableDirectLaunch, or: $value.enableDirectLaunch),
      launchSettings: data.get(#launchSettings, or: $value.launchSettings),
      lastStarsectorVersion:
          data.get(#lastStarsectorVersion, or: $value.lastStarsectorVersion),
      isUpdatesFieldShown:
          data.get(#isUpdatesFieldShown, or: $value.isUpdatesFieldShown),
      modsGridState: data.get(#modsGridState, or: $value.modsGridState),
      oldModsGridState:
          data.get(#oldModsGridState, or: $value.oldModsGridState),
      shouldAutoUpdateOnLaunch: data.get(#shouldAutoUpdateOnLaunch,
          or: $value.shouldAutoUpdateOnLaunch),
      secondsBetweenModFolderChecks: data.get(#secondsBetweenModFolderChecks,
          or: $value.secondsBetweenModFolderChecks),
      toastDurationSeconds:
          data.get(#toastDurationSeconds, or: $value.toastDurationSeconds),
      maxHttpRequestsAtOnce:
          data.get(#maxHttpRequestsAtOnce, or: $value.maxHttpRequestsAtOnce),
      folderNamingSetting:
          data.get(#folderNamingSetting, or: $value.folderNamingSetting),
      keepLastNVersions:
          data.get(#keepLastNVersions, or: $value.keepLastNVersions),
      allowCrashReporting:
          data.get(#allowCrashReporting, or: $value.allowCrashReporting),
      updateToPrereleases:
          data.get(#updateToPrereleases, or: $value.updateToPrereleases),
      autoEnableAndDisableDependencies: data.get(
          #autoEnableAndDisableDependencies,
          or: $value.autoEnableAndDisableDependencies),
      enableLauncherPrecheck:
          data.get(#enableLauncherPrecheck, or: $value.enableLauncherPrecheck),
      modUpdateBehavior:
          data.get(#modUpdateBehavior, or: $value.modUpdateBehavior),
      userId: data.get(#userId, or: $value.userId),
      hasHiddenForumDarkModeTip: data.get(#hasHiddenForumDarkModeTip,
          or: $value.hasHiddenForumDarkModeTip),
      activeModProfileId:
          data.get(#activeModProfileId, or: $value.activeModProfileId));

  @override
  SettingsCopyWith<$R2, Settings, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _SettingsCopyWithImpl($value, $cast, t);
}
