// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
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
        return FolderNamingSetting.values[1];
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
      case r'doNotChange':
        return ModUpdateBehavior.doNotChange;
      case r'switchToNewVersionIfWasEnabled':
        return ModUpdateBehavior.switchToNewVersionIfWasEnabled;
      default:
        return ModUpdateBehavior.values[1];
    }
  }

  @override
  dynamic encode(ModUpdateBehavior self) {
    switch (self) {
      case ModUpdateBehavior.doNotChange:
        return r'doNotChange';
      case ModUpdateBehavior.switchToNewVersionIfWasEnabled:
        return r'switchToNewVersionIfWasEnabled';
    }
  }
}

extension ModUpdateBehaviorMapperExtension on ModUpdateBehavior {
  String toValue() {
    ModUpdateBehaviorMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModUpdateBehavior>(this) as String;
  }
}

class DashboardGridModUpdateVisibilityMapper
    extends EnumMapper<DashboardGridModUpdateVisibility> {
  DashboardGridModUpdateVisibilityMapper._();

  static DashboardGridModUpdateVisibilityMapper? _instance;
  static DashboardGridModUpdateVisibilityMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = DashboardGridModUpdateVisibilityMapper._(),
      );
    }
    return _instance!;
  }

  static DashboardGridModUpdateVisibility fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DashboardGridModUpdateVisibility decode(dynamic value) {
    switch (value) {
      case r'allVisible':
        return DashboardGridModUpdateVisibility.allVisible;
      case r'hideMuted':
        return DashboardGridModUpdateVisibility.hideMuted;
      case r'hideAll':
        return DashboardGridModUpdateVisibility.hideAll;
      default:
        return DashboardGridModUpdateVisibility.values[1];
    }
  }

  @override
  dynamic encode(DashboardGridModUpdateVisibility self) {
    switch (self) {
      case DashboardGridModUpdateVisibility.allVisible:
        return r'allVisible';
      case DashboardGridModUpdateVisibility.hideMuted:
        return r'hideMuted';
      case DashboardGridModUpdateVisibility.hideAll:
        return r'hideAll';
    }
  }
}

extension DashboardGridModUpdateVisibilityMapperExtension
    on DashboardGridModUpdateVisibility {
  String toValue() {
    DashboardGridModUpdateVisibilityMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DashboardGridModUpdateVisibility>(
          this,
        )
        as String;
  }
}

class CompressionLibMapper extends EnumMapper<CompressionLib> {
  CompressionLibMapper._();

  static CompressionLibMapper? _instance;
  static CompressionLibMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CompressionLibMapper._());
    }
    return _instance!;
  }

  static CompressionLib fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CompressionLib decode(dynamic value) {
    switch (value) {
      case r'sevenZip':
        return CompressionLib.sevenZip;
      case r'libarchive':
        return CompressionLib.libarchive;
      default:
        return CompressionLib.values[0];
    }
  }

  @override
  dynamic encode(CompressionLib self) {
    switch (self) {
      case CompressionLib.sevenZip:
        return r'sevenZip';
      case CompressionLib.libarchive:
        return r'libarchive';
    }
  }
}

extension CompressionLibMapperExtension on CompressionLib {
  String toValue() {
    CompressionLibMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CompressionLib>(this) as String;
  }
}

class DashboardModListSortMapper extends EnumMapper<DashboardModListSort> {
  DashboardModListSortMapper._();

  static DashboardModListSortMapper? _instance;
  static DashboardModListSortMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DashboardModListSortMapper._());
    }
    return _instance!;
  }

  static DashboardModListSort fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DashboardModListSort decode(dynamic value) {
    switch (value) {
      case r'name':
        return DashboardModListSort.name;
      case r'author':
        return DashboardModListSort.author;
      case r'version':
        return DashboardModListSort.version;
      case r'vram':
        return DashboardModListSort.vram;
      case r'gameVersion':
        return DashboardModListSort.gameVersion;
      case r'enabled':
        return DashboardModListSort.enabled;
      default:
        return DashboardModListSort.values[0];
    }
  }

  @override
  dynamic encode(DashboardModListSort self) {
    switch (self) {
      case DashboardModListSort.name:
        return r'name';
      case DashboardModListSort.author:
        return r'author';
      case DashboardModListSort.version:
        return r'version';
      case DashboardModListSort.vram:
        return r'vram';
      case DashboardModListSort.gameVersion:
        return r'gameVersion';
      case DashboardModListSort.enabled:
        return r'enabled';
    }
  }
}

extension DashboardModListSortMapperExtension on DashboardModListSort {
  String toValue() {
    DashboardModListSortMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DashboardModListSort>(this)
        as String;
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
      DashboardGridModUpdateVisibilityMapper.ensureInitialized();
      WispGridStateMapper.ensureInitialized();
      FolderNamingSettingMapper.ensureInitialized();
      ModUpdateBehaviorMapper.ensureInitialized();
      DashboardModListSortMapper.ensureInitialized();
      CompressionLibMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Settings';

  static Directory? _$gameDir(Settings v) => v.gameDir;
  static const Field<Settings, Directory> _f$gameDir = Field(
    'gameDir',
    _$gameDir,
    opt: true,
    hook: DirectoryHook(),
  );
  static Directory? _$gameCoreDir(Settings v) => v.gameCoreDir;
  static const Field<Settings, Directory> _f$gameCoreDir = Field(
    'gameCoreDir',
    _$gameCoreDir,
    opt: true,
    hook: DirectoryHook(),
  );
  static Directory? _$modsDir(Settings v) => v.modsDir;
  static const Field<Settings, Directory> _f$modsDir = Field(
    'modsDir',
    _$modsDir,
    opt: true,
    hook: DirectoryHook(),
  );
  static bool _$hasCustomModsDir(Settings v) => v.hasCustomModsDir;
  static const Field<Settings, bool> _f$hasCustomModsDir = Field(
    'hasCustomModsDir',
    _$hasCustomModsDir,
    opt: true,
    def: false,
  );
  static bool _$isRulesHotReloadEnabled(Settings v) =>
      v.isRulesHotReloadEnabled;
  static const Field<Settings, bool> _f$isRulesHotReloadEnabled = Field(
    'isRulesHotReloadEnabled',
    _$isRulesHotReloadEnabled,
    opt: true,
    def: false,
  );
  static double? _$windowXPos(Settings v) => v.windowXPos;
  static const Field<Settings, double> _f$windowXPos = Field(
    'windowXPos',
    _$windowXPos,
    opt: true,
  );
  static double? _$windowYPos(Settings v) => v.windowYPos;
  static const Field<Settings, double> _f$windowYPos = Field(
    'windowYPos',
    _$windowYPos,
    opt: true,
  );
  static double? _$windowWidth(Settings v) => v.windowWidth;
  static const Field<Settings, double> _f$windowWidth = Field(
    'windowWidth',
    _$windowWidth,
    opt: true,
  );
  static double? _$windowHeight(Settings v) => v.windowHeight;
  static const Field<Settings, double> _f$windowHeight = Field(
    'windowHeight',
    _$windowHeight,
    opt: true,
  );
  static bool? _$isMaximized(Settings v) => v.isMaximized;
  static const Field<Settings, bool> _f$isMaximized = Field(
    'isMaximized',
    _$isMaximized,
    opt: true,
  );
  static bool? _$isMinimized(Settings v) => v.isMinimized;
  static const Field<Settings, bool> _f$isMinimized = Field(
    'isMinimized',
    _$isMinimized,
    opt: true,
  );
  static TriOSTools _$defaultTool(Settings v) => v.defaultTool;
  static const Field<Settings, TriOSTools> _f$defaultTool = Field(
    'defaultTool',
    _$defaultTool,
    opt: true,
    def: TriOSTools.dashboard,
  );
  static String? _$lastActiveJreVersion(Settings v) => v.lastActiveJreVersion;
  static const Field<Settings, String> _f$lastActiveJreVersion = Field(
    'lastActiveJreVersion',
    _$lastActiveJreVersion,
    opt: true,
  );
  static bool _$showCustomJreConsoleWindow(Settings v) =>
      v.showCustomJreConsoleWindow;
  static const Field<Settings, bool> _f$showCustomJreConsoleWindow = Field(
    'showCustomJreConsoleWindow',
    _$showCustomJreConsoleWindow,
    opt: true,
    def: true,
  );
  static String? _$themeKey(Settings v) => v.themeKey;
  static const Field<Settings, String> _f$themeKey = Field(
    'themeKey',
    _$themeKey,
    opt: true,
  );
  static bool? _$showChangelogNextLaunch(Settings v) =>
      v.showChangelogNextLaunch;
  static const Field<Settings, bool> _f$showChangelogNextLaunch = Field(
    'showChangelogNextLaunch',
    _$showChangelogNextLaunch,
    opt: true,
  );
  static bool _$enableDirectLaunch(Settings v) => v.enableDirectLaunch;
  static const Field<Settings, bool> _f$enableDirectLaunch = Field(
    'enableDirectLaunch',
    _$enableDirectLaunch,
    opt: true,
    def: false,
  );
  static LaunchSettings _$launchSettings(Settings v) => v.launchSettings;
  static const Field<Settings, LaunchSettings> _f$launchSettings = Field(
    'launchSettings',
    _$launchSettings,
    opt: true,
    def: const LaunchSettings(),
  );
  static String? _$lastStarsectorVersion(Settings v) => v.lastStarsectorVersion;
  static const Field<Settings, String> _f$lastStarsectorVersion = Field(
    'lastStarsectorVersion',
    _$lastStarsectorVersion,
    opt: true,
  );
  static DashboardGridModUpdateVisibility _$dashboardGridModUpdateVisibility(
    Settings v,
  ) => v.dashboardGridModUpdateVisibility;
  static const Field<Settings, DashboardGridModUpdateVisibility>
  _f$dashboardGridModUpdateVisibility = Field(
    'dashboardGridModUpdateVisibility',
    _$dashboardGridModUpdateVisibility,
    opt: true,
    def: DashboardGridModUpdateVisibility.hideMuted,
  );
  static WispGridState _$modsGridState(Settings v) => v.modsGridState;
  static const Field<Settings, WispGridState> _f$modsGridState = Field(
    'modsGridState',
    _$modsGridState,
    opt: true,
    def: const WispGridState(
      groupingSetting: GroupingSetting(
        currentGroupedByKey: 'enabledState',
        isSortDescending: false,
      ),
      sortedColumnKey: 'name',
      columnsState: {},
    ),
    hook: SafeDecodeHook(),
  );
  static WispGridState _$weaponsGridState(Settings v) => v.weaponsGridState;
  static const Field<Settings, WispGridState> _f$weaponsGridState = Field(
    'weaponsGridState',
    _$weaponsGridState,
    opt: true,
    def: const WispGridState(groupingSetting: null, columnsState: {}),
  );
  static WispGridState _$shipsGridState(Settings v) => v.shipsGridState;
  static const Field<Settings, WispGridState> _f$shipsGridState = Field(
    'shipsGridState',
    _$shipsGridState,
    opt: true,
    def: const WispGridState(groupingSetting: null, columnsState: {}),
  );
  static String? _$customGameExePath(Settings v) => v.customGameExePath;
  static const Field<Settings, String> _f$customGameExePath = Field(
    'customGameExePath',
    _$customGameExePath,
    opt: true,
  );
  static bool _$useCustomGameExePath(Settings v) => v.useCustomGameExePath;
  static const Field<Settings, bool> _f$useCustomGameExePath = Field(
    'useCustomGameExePath',
    _$useCustomGameExePath,
    opt: true,
    def: false,
  );
  static Directory? _$customSavesPath(Settings v) => v.customSavesPath;
  static const Field<Settings, Directory> _f$customSavesPath = Field(
    'customSavesPath',
    _$customSavesPath,
    opt: true,
    hook: DirectoryHook(),
  );
  static bool _$useCustomSavesPath(Settings v) => v.useCustomSavesPath;
  static const Field<Settings, bool> _f$useCustomSavesPath = Field(
    'useCustomSavesPath',
    _$useCustomSavesPath,
    opt: true,
    def: false,
  );
  static Directory? _$customCoreFolderPath(Settings v) =>
      v.customCoreFolderPath;
  static const Field<Settings, Directory> _f$customCoreFolderPath = Field(
    'customCoreFolderPath',
    _$customCoreFolderPath,
    opt: true,
    hook: DirectoryHook(),
  );
  static bool _$useCustomCoreFolderPath(Settings v) =>
      v.useCustomCoreFolderPath;
  static const Field<Settings, bool> _f$useCustomCoreFolderPath = Field(
    'useCustomCoreFolderPath',
    _$useCustomCoreFolderPath,
    opt: true,
    def: false,
  );
  static bool _$doubleClickForModsPanel(Settings v) =>
      v.doubleClickForModsPanel;
  static const Field<Settings, bool> _f$doubleClickForModsPanel = Field(
    'doubleClickForModsPanel',
    _$doubleClickForModsPanel,
    opt: true,
    def: true,
  );
  static bool _$pinFavorites(Settings v) => v.pinFavorites;
  static const Field<Settings, bool> _f$pinFavorites = Field(
    'pinFavorites',
    _$pinFavorites,
    opt: true,
    def: true,
  );
  static bool _$shouldAutoUpdateOnLaunch(Settings v) =>
      v.shouldAutoUpdateOnLaunch;
  static const Field<Settings, bool> _f$shouldAutoUpdateOnLaunch = Field(
    'shouldAutoUpdateOnLaunch',
    _$shouldAutoUpdateOnLaunch,
    opt: true,
    def: false,
  );
  static int _$secondsBetweenModFolderChecks(Settings v) =>
      v.secondsBetweenModFolderChecks;
  static const Field<Settings, int> _f$secondsBetweenModFolderChecks = Field(
    'secondsBetweenModFolderChecks',
    _$secondsBetweenModFolderChecks,
    opt: true,
    def: 15,
  );
  static int _$toastDurationSeconds(Settings v) => v.toastDurationSeconds;
  static const Field<Settings, int> _f$toastDurationSeconds = Field(
    'toastDurationSeconds',
    _$toastDurationSeconds,
    opt: true,
    def: 7,
  );
  static int _$maxHttpRequestsAtOnce(Settings v) => v.maxHttpRequestsAtOnce;
  static const Field<Settings, int> _f$maxHttpRequestsAtOnce = Field(
    'maxHttpRequestsAtOnce',
    _$maxHttpRequestsAtOnce,
    opt: true,
    def: 20,
  );
  static FolderNamingSetting _$folderNamingSetting(Settings v) =>
      v.folderNamingSetting;
  static const Field<Settings, FolderNamingSetting> _f$folderNamingSetting =
      Field(
        'folderNamingSetting',
        _$folderNamingSetting,
        opt: true,
        def: FolderNamingSetting.allFoldersVersioned,
      );
  static int? _$keepLastNVersions(Settings v) => v.keepLastNVersions;
  static const Field<Settings, int> _f$keepLastNVersions = Field(
    'keepLastNVersions',
    _$keepLastNVersions,
    opt: true,
  );
  static bool? _$allowCrashReporting(Settings v) => v.allowCrashReporting;
  static const Field<Settings, bool> _f$allowCrashReporting = Field(
    'allowCrashReporting',
    _$allowCrashReporting,
    opt: true,
  );
  static bool _$updateToPrereleases(Settings v) => v.updateToPrereleases;
  static const Field<Settings, bool> _f$updateToPrereleases = Field(
    'updateToPrereleases',
    _$updateToPrereleases,
    opt: true,
    def: false,
  );
  static bool _$autoEnableAndDisableDependencies(Settings v) =>
      v.autoEnableAndDisableDependencies;
  static const Field<Settings, bool> _f$autoEnableAndDisableDependencies =
      Field(
        'autoEnableAndDisableDependencies',
        _$autoEnableAndDisableDependencies,
        opt: true,
        def: false,
      );
  static bool _$enableLauncherPrecheck(Settings v) => v.enableLauncherPrecheck;
  static const Field<Settings, bool> _f$enableLauncherPrecheck = Field(
    'enableLauncherPrecheck',
    _$enableLauncherPrecheck,
    opt: true,
    def: true,
  );
  static ModUpdateBehavior _$modUpdateBehavior(Settings v) =>
      v.modUpdateBehavior;
  static const Field<Settings, ModUpdateBehavior> _f$modUpdateBehavior = Field(
    'modUpdateBehavior',
    _$modUpdateBehavior,
    opt: true,
    def: ModUpdateBehavior.switchToNewVersionIfWasEnabled,
  );
  static DashboardModListSort _$dashboardModListSort(Settings v) =>
      v.dashboardModListSort;
  static const Field<Settings, DashboardModListSort> _f$dashboardModListSort =
      Field(
        'dashboardModListSort',
        _$dashboardModListSort,
        opt: true,
        def: DashboardModListSort.name,
      );
  static bool _$checkIfGameIsRunning(Settings v) => v.checkIfGameIsRunning;
  static const Field<Settings, bool> _f$checkIfGameIsRunning = Field(
    'checkIfGameIsRunning',
    _$checkIfGameIsRunning,
    opt: true,
    def: true,
  );
  static CompressionLib _$compressionLib(Settings v) => v.compressionLib;
  static const Field<Settings, CompressionLib> _f$compressionLib = Field(
    'compressionLib',
    _$compressionLib,
    opt: true,
    def: CompressionLib.sevenZip,
  );
  static double _$windowScaleFactor(Settings v) => v.windowScaleFactor;
  static const Field<Settings, double> _f$windowScaleFactor = Field(
    'windowScaleFactor',
    _$windowScaleFactor,
    opt: true,
    def: 1.0,
  );
  static bool _$enableAccessibilitySemanticsOnLinux(Settings v) =>
      v.enableAccessibilitySemanticsOnLinux;
  static const Field<Settings, bool> _f$enableAccessibilitySemanticsOnLinux =
      Field(
        'enableAccessibilitySemanticsOnLinux',
        _$enableAccessibilitySemanticsOnLinux,
        opt: true,
        def: false,
      );
  static String _$userId(Settings v) => v.userId;
  static const Field<Settings, String> _f$userId = Field(
    'userId',
    _$userId,
    opt: true,
    def: '',
  );
  static bool? _$hasHiddenForumDarkModeTip(Settings v) =>
      v.hasHiddenForumDarkModeTip;
  static const Field<Settings, bool> _f$hasHiddenForumDarkModeTip = Field(
    'hasHiddenForumDarkModeTip',
    _$hasHiddenForumDarkModeTip,
    opt: true,
  );
  static String? _$activeModProfileId(Settings v) => v.activeModProfileId;
  static const Field<Settings, String> _f$activeModProfileId = Field(
    'activeModProfileId',
    _$activeModProfileId,
    opt: true,
  );
  static bool _$showForceUpdateWarning(Settings v) => v.showForceUpdateWarning;
  static const Field<Settings, bool> _f$showForceUpdateWarning = Field(
    'showForceUpdateWarning',
    _$showForceUpdateWarning,
    opt: true,
    def: true,
  );
  static bool _$showDonationButton(Settings v) => v.showDonationButton;
  static const Field<Settings, bool> _f$showDonationButton = Field(
    'showDonationButton',
    _$showDonationButton,
    opt: true,
    def: true,
  );

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
    #lastActiveJreVersion: _f$lastActiveJreVersion,
    #showCustomJreConsoleWindow: _f$showCustomJreConsoleWindow,
    #themeKey: _f$themeKey,
    #showChangelogNextLaunch: _f$showChangelogNextLaunch,
    #enableDirectLaunch: _f$enableDirectLaunch,
    #launchSettings: _f$launchSettings,
    #lastStarsectorVersion: _f$lastStarsectorVersion,
    #dashboardGridModUpdateVisibility: _f$dashboardGridModUpdateVisibility,
    #modsGridState: _f$modsGridState,
    #weaponsGridState: _f$weaponsGridState,
    #shipsGridState: _f$shipsGridState,
    #customGameExePath: _f$customGameExePath,
    #useCustomGameExePath: _f$useCustomGameExePath,
    #customSavesPath: _f$customSavesPath,
    #useCustomSavesPath: _f$useCustomSavesPath,
    #customCoreFolderPath: _f$customCoreFolderPath,
    #useCustomCoreFolderPath: _f$useCustomCoreFolderPath,
    #doubleClickForModsPanel: _f$doubleClickForModsPanel,
    #pinFavorites: _f$pinFavorites,
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
    #dashboardModListSort: _f$dashboardModListSort,
    #checkIfGameIsRunning: _f$checkIfGameIsRunning,
    #compressionLib: _f$compressionLib,
    #windowScaleFactor: _f$windowScaleFactor,
    #enableAccessibilitySemanticsOnLinux:
        _f$enableAccessibilitySemanticsOnLinux,
    #userId: _f$userId,
    #hasHiddenForumDarkModeTip: _f$hasHiddenForumDarkModeTip,
    #activeModProfileId: _f$activeModProfileId,
    #showForceUpdateWarning: _f$showForceUpdateWarning,
    #showDonationButton: _f$showDonationButton,
  };
  @override
  final bool ignoreNull = true;

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
      lastActiveJreVersion: data.dec(_f$lastActiveJreVersion),
      showCustomJreConsoleWindow: data.dec(_f$showCustomJreConsoleWindow),
      themeKey: data.dec(_f$themeKey),
      showChangelogNextLaunch: data.dec(_f$showChangelogNextLaunch),
      enableDirectLaunch: data.dec(_f$enableDirectLaunch),
      launchSettings: data.dec(_f$launchSettings),
      lastStarsectorVersion: data.dec(_f$lastStarsectorVersion),
      dashboardGridModUpdateVisibility: data.dec(
        _f$dashboardGridModUpdateVisibility,
      ),
      modsGridState: data.dec(_f$modsGridState),
      weaponsGridState: data.dec(_f$weaponsGridState),
      shipsGridState: data.dec(_f$shipsGridState),
      customGameExePath: data.dec(_f$customGameExePath),
      useCustomGameExePath: data.dec(_f$useCustomGameExePath),
      customSavesPath: data.dec(_f$customSavesPath),
      useCustomSavesPath: data.dec(_f$useCustomSavesPath),
      customCoreFolderPath: data.dec(_f$customCoreFolderPath),
      useCustomCoreFolderPath: data.dec(_f$useCustomCoreFolderPath),
      doubleClickForModsPanel: data.dec(_f$doubleClickForModsPanel),
      pinFavorites: data.dec(_f$pinFavorites),
      shouldAutoUpdateOnLaunch: data.dec(_f$shouldAutoUpdateOnLaunch),
      secondsBetweenModFolderChecks: data.dec(_f$secondsBetweenModFolderChecks),
      toastDurationSeconds: data.dec(_f$toastDurationSeconds),
      maxHttpRequestsAtOnce: data.dec(_f$maxHttpRequestsAtOnce),
      folderNamingSetting: data.dec(_f$folderNamingSetting),
      keepLastNVersions: data.dec(_f$keepLastNVersions),
      allowCrashReporting: data.dec(_f$allowCrashReporting),
      updateToPrereleases: data.dec(_f$updateToPrereleases),
      autoEnableAndDisableDependencies: data.dec(
        _f$autoEnableAndDisableDependencies,
      ),
      enableLauncherPrecheck: data.dec(_f$enableLauncherPrecheck),
      modUpdateBehavior: data.dec(_f$modUpdateBehavior),
      dashboardModListSort: data.dec(_f$dashboardModListSort),
      checkIfGameIsRunning: data.dec(_f$checkIfGameIsRunning),
      compressionLib: data.dec(_f$compressionLib),
      windowScaleFactor: data.dec(_f$windowScaleFactor),
      enableAccessibilitySemanticsOnLinux: data.dec(
        _f$enableAccessibilitySemanticsOnLinux,
      ),
      userId: data.dec(_f$userId),
      hasHiddenForumDarkModeTip: data.dec(_f$hasHiddenForumDarkModeTip),
      activeModProfileId: data.dec(_f$activeModProfileId),
      showForceUpdateWarning: data.dec(_f$showForceUpdateWarning),
      showDonationButton: data.dec(_f$showDonationButton),
    );
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
    return SettingsMapper.ensureInitialized().encodeJson<Settings>(
      this as Settings,
    );
  }

  Map<String, dynamic> toMap() {
    return SettingsMapper.ensureInitialized().encodeMap<Settings>(
      this as Settings,
    );
  }

  SettingsCopyWith<Settings, Settings, Settings> get copyWith =>
      _SettingsCopyWithImpl<Settings, Settings>(
        this as Settings,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SettingsMapper.ensureInitialized().stringifyValue(this as Settings);
  }

  @override
  bool operator ==(Object other) {
    return SettingsMapper.ensureInitialized().equalsValue(
      this as Settings,
      other,
    );
  }

  @override
  int get hashCode {
    return SettingsMapper.ensureInitialized().hashValue(this as Settings);
  }
}

extension SettingsValueCopy<$R, $Out> on ObjectCopyWith<$R, Settings, $Out> {
  SettingsCopyWith<$R, Settings, $Out> get $asSettings =>
      $base.as((v, t, t2) => _SettingsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SettingsCopyWith<$R, $In extends Settings, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  LaunchSettingsCopyWith<$R, LaunchSettings, LaunchSettings> get launchSettings;
  WispGridStateCopyWith<$R, WispGridState, WispGridState> get modsGridState;
  WispGridStateCopyWith<$R, WispGridState, WispGridState> get weaponsGridState;
  WispGridStateCopyWith<$R, WispGridState, WispGridState> get shipsGridState;
  $R call({
    Directory? gameDir,
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
    String? lastActiveJreVersion,
    bool? showCustomJreConsoleWindow,
    String? themeKey,
    bool? showChangelogNextLaunch,
    bool? enableDirectLaunch,
    LaunchSettings? launchSettings,
    String? lastStarsectorVersion,
    DashboardGridModUpdateVisibility? dashboardGridModUpdateVisibility,
    WispGridState? modsGridState,
    WispGridState? weaponsGridState,
    WispGridState? shipsGridState,
    String? customGameExePath,
    bool? useCustomGameExePath,
    Directory? customSavesPath,
    bool? useCustomSavesPath,
    Directory? customCoreFolderPath,
    bool? useCustomCoreFolderPath,
    bool? doubleClickForModsPanel,
    bool? pinFavorites,
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
    DashboardModListSort? dashboardModListSort,
    bool? checkIfGameIsRunning,
    CompressionLib? compressionLib,
    double? windowScaleFactor,
    bool? enableAccessibilitySemanticsOnLinux,
    String? userId,
    bool? hasHiddenForumDarkModeTip,
    String? activeModProfileId,
    bool? showForceUpdateWarning,
    bool? showDonationButton,
  });
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
  WispGridStateCopyWith<$R, WispGridState, WispGridState>
  get weaponsGridState =>
      $value.weaponsGridState.copyWith.$chain((v) => call(weaponsGridState: v));
  @override
  WispGridStateCopyWith<$R, WispGridState, WispGridState> get shipsGridState =>
      $value.shipsGridState.copyWith.$chain((v) => call(shipsGridState: v));
  @override
  $R call({
    Object? gameDir = $none,
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
    TriOSTools? defaultTool,
    Object? lastActiveJreVersion = $none,
    bool? showCustomJreConsoleWindow,
    Object? themeKey = $none,
    Object? showChangelogNextLaunch = $none,
    bool? enableDirectLaunch,
    LaunchSettings? launchSettings,
    Object? lastStarsectorVersion = $none,
    DashboardGridModUpdateVisibility? dashboardGridModUpdateVisibility,
    WispGridState? modsGridState,
    WispGridState? weaponsGridState,
    WispGridState? shipsGridState,
    Object? customGameExePath = $none,
    bool? useCustomGameExePath,
    Object? customSavesPath = $none,
    bool? useCustomSavesPath,
    Object? customCoreFolderPath = $none,
    bool? useCustomCoreFolderPath,
    bool? doubleClickForModsPanel,
    bool? pinFavorites,
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
    DashboardModListSort? dashboardModListSort,
    bool? checkIfGameIsRunning,
    CompressionLib? compressionLib,
    double? windowScaleFactor,
    bool? enableAccessibilitySemanticsOnLinux,
    String? userId,
    Object? hasHiddenForumDarkModeTip = $none,
    Object? activeModProfileId = $none,
    bool? showForceUpdateWarning,
    bool? showDonationButton,
  }) => $apply(
    FieldCopyWithData({
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
      if (defaultTool != null) #defaultTool: defaultTool,
      if (lastActiveJreVersion != $none)
        #lastActiveJreVersion: lastActiveJreVersion,
      if (showCustomJreConsoleWindow != null)
        #showCustomJreConsoleWindow: showCustomJreConsoleWindow,
      if (themeKey != $none) #themeKey: themeKey,
      if (showChangelogNextLaunch != $none)
        #showChangelogNextLaunch: showChangelogNextLaunch,
      if (enableDirectLaunch != null) #enableDirectLaunch: enableDirectLaunch,
      if (launchSettings != null) #launchSettings: launchSettings,
      if (lastStarsectorVersion != $none)
        #lastStarsectorVersion: lastStarsectorVersion,
      if (dashboardGridModUpdateVisibility != null)
        #dashboardGridModUpdateVisibility: dashboardGridModUpdateVisibility,
      if (modsGridState != null) #modsGridState: modsGridState,
      if (weaponsGridState != null) #weaponsGridState: weaponsGridState,
      if (shipsGridState != null) #shipsGridState: shipsGridState,
      if (customGameExePath != $none) #customGameExePath: customGameExePath,
      if (useCustomGameExePath != null)
        #useCustomGameExePath: useCustomGameExePath,
      if (customSavesPath != $none) #customSavesPath: customSavesPath,
      if (useCustomSavesPath != null) #useCustomSavesPath: useCustomSavesPath,
      if (customCoreFolderPath != $none)
        #customCoreFolderPath: customCoreFolderPath,
      if (useCustomCoreFolderPath != null)
        #useCustomCoreFolderPath: useCustomCoreFolderPath,
      if (doubleClickForModsPanel != null)
        #doubleClickForModsPanel: doubleClickForModsPanel,
      if (pinFavorites != null) #pinFavorites: pinFavorites,
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
      if (dashboardModListSort != null)
        #dashboardModListSort: dashboardModListSort,
      if (checkIfGameIsRunning != null)
        #checkIfGameIsRunning: checkIfGameIsRunning,
      if (compressionLib != null) #compressionLib: compressionLib,
      if (windowScaleFactor != null) #windowScaleFactor: windowScaleFactor,
      if (enableAccessibilitySemanticsOnLinux != null)
        #enableAccessibilitySemanticsOnLinux:
            enableAccessibilitySemanticsOnLinux,
      if (userId != null) #userId: userId,
      if (hasHiddenForumDarkModeTip != $none)
        #hasHiddenForumDarkModeTip: hasHiddenForumDarkModeTip,
      if (activeModProfileId != $none) #activeModProfileId: activeModProfileId,
      if (showForceUpdateWarning != null)
        #showForceUpdateWarning: showForceUpdateWarning,
      if (showDonationButton != null) #showDonationButton: showDonationButton,
    }),
  );
  @override
  Settings $make(CopyWithData data) => Settings(
    gameDir: data.get(#gameDir, or: $value.gameDir),
    gameCoreDir: data.get(#gameCoreDir, or: $value.gameCoreDir),
    modsDir: data.get(#modsDir, or: $value.modsDir),
    hasCustomModsDir: data.get(#hasCustomModsDir, or: $value.hasCustomModsDir),
    isRulesHotReloadEnabled: data.get(
      #isRulesHotReloadEnabled,
      or: $value.isRulesHotReloadEnabled,
    ),
    windowXPos: data.get(#windowXPos, or: $value.windowXPos),
    windowYPos: data.get(#windowYPos, or: $value.windowYPos),
    windowWidth: data.get(#windowWidth, or: $value.windowWidth),
    windowHeight: data.get(#windowHeight, or: $value.windowHeight),
    isMaximized: data.get(#isMaximized, or: $value.isMaximized),
    isMinimized: data.get(#isMinimized, or: $value.isMinimized),
    defaultTool: data.get(#defaultTool, or: $value.defaultTool),
    lastActiveJreVersion: data.get(
      #lastActiveJreVersion,
      or: $value.lastActiveJreVersion,
    ),
    showCustomJreConsoleWindow: data.get(
      #showCustomJreConsoleWindow,
      or: $value.showCustomJreConsoleWindow,
    ),
    themeKey: data.get(#themeKey, or: $value.themeKey),
    showChangelogNextLaunch: data.get(
      #showChangelogNextLaunch,
      or: $value.showChangelogNextLaunch,
    ),
    enableDirectLaunch: data.get(
      #enableDirectLaunch,
      or: $value.enableDirectLaunch,
    ),
    launchSettings: data.get(#launchSettings, or: $value.launchSettings),
    lastStarsectorVersion: data.get(
      #lastStarsectorVersion,
      or: $value.lastStarsectorVersion,
    ),
    dashboardGridModUpdateVisibility: data.get(
      #dashboardGridModUpdateVisibility,
      or: $value.dashboardGridModUpdateVisibility,
    ),
    modsGridState: data.get(#modsGridState, or: $value.modsGridState),
    weaponsGridState: data.get(#weaponsGridState, or: $value.weaponsGridState),
    shipsGridState: data.get(#shipsGridState, or: $value.shipsGridState),
    customGameExePath: data.get(
      #customGameExePath,
      or: $value.customGameExePath,
    ),
    useCustomGameExePath: data.get(
      #useCustomGameExePath,
      or: $value.useCustomGameExePath,
    ),
    customSavesPath: data.get(#customSavesPath, or: $value.customSavesPath),
    useCustomSavesPath: data.get(
      #useCustomSavesPath,
      or: $value.useCustomSavesPath,
    ),
    customCoreFolderPath: data.get(
      #customCoreFolderPath,
      or: $value.customCoreFolderPath,
    ),
    useCustomCoreFolderPath: data.get(
      #useCustomCoreFolderPath,
      or: $value.useCustomCoreFolderPath,
    ),
    doubleClickForModsPanel: data.get(
      #doubleClickForModsPanel,
      or: $value.doubleClickForModsPanel,
    ),
    pinFavorites: data.get(#pinFavorites, or: $value.pinFavorites),
    shouldAutoUpdateOnLaunch: data.get(
      #shouldAutoUpdateOnLaunch,
      or: $value.shouldAutoUpdateOnLaunch,
    ),
    secondsBetweenModFolderChecks: data.get(
      #secondsBetweenModFolderChecks,
      or: $value.secondsBetweenModFolderChecks,
    ),
    toastDurationSeconds: data.get(
      #toastDurationSeconds,
      or: $value.toastDurationSeconds,
    ),
    maxHttpRequestsAtOnce: data.get(
      #maxHttpRequestsAtOnce,
      or: $value.maxHttpRequestsAtOnce,
    ),
    folderNamingSetting: data.get(
      #folderNamingSetting,
      or: $value.folderNamingSetting,
    ),
    keepLastNVersions: data.get(
      #keepLastNVersions,
      or: $value.keepLastNVersions,
    ),
    allowCrashReporting: data.get(
      #allowCrashReporting,
      or: $value.allowCrashReporting,
    ),
    updateToPrereleases: data.get(
      #updateToPrereleases,
      or: $value.updateToPrereleases,
    ),
    autoEnableAndDisableDependencies: data.get(
      #autoEnableAndDisableDependencies,
      or: $value.autoEnableAndDisableDependencies,
    ),
    enableLauncherPrecheck: data.get(
      #enableLauncherPrecheck,
      or: $value.enableLauncherPrecheck,
    ),
    modUpdateBehavior: data.get(
      #modUpdateBehavior,
      or: $value.modUpdateBehavior,
    ),
    dashboardModListSort: data.get(
      #dashboardModListSort,
      or: $value.dashboardModListSort,
    ),
    checkIfGameIsRunning: data.get(
      #checkIfGameIsRunning,
      or: $value.checkIfGameIsRunning,
    ),
    compressionLib: data.get(#compressionLib, or: $value.compressionLib),
    windowScaleFactor: data.get(
      #windowScaleFactor,
      or: $value.windowScaleFactor,
    ),
    enableAccessibilitySemanticsOnLinux: data.get(
      #enableAccessibilitySemanticsOnLinux,
      or: $value.enableAccessibilitySemanticsOnLinux,
    ),
    userId: data.get(#userId, or: $value.userId),
    hasHiddenForumDarkModeTip: data.get(
      #hasHiddenForumDarkModeTip,
      or: $value.hasHiddenForumDarkModeTip,
    ),
    activeModProfileId: data.get(
      #activeModProfileId,
      or: $value.activeModProfileId,
    ),
    showForceUpdateWarning: data.get(
      #showForceUpdateWarning,
      or: $value.showForceUpdateWarning,
    ),
    showDonationButton: data.get(
      #showDonationButton,
      or: $value.showDonationButton,
    ),
  );

  @override
  SettingsCopyWith<$R2, Settings, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SettingsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

