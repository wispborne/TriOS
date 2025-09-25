import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/models/launch_settings.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

part 'settings.mapper.dart';

const sharedPrefsSettingsKey = "settings";

/// MacOs: /Users/<user>/Library/Preferences/org.wisp.TriOS.plist

/// Settings object model
@MappableClass(ignoreNull: true)
class Settings with SettingsMappable {
  @MappableField(hook: DirectoryHook())
  final Directory? gameDir;
  @MappableField(hook: DirectoryHook())
  final Directory? gameCoreDir;

  // Paths
  final String? customGameExePath;
  final bool useCustomGameExePath;

  /// DO NOT USE directly; use `AppState.modsFolder`
  @MappableField(hook: DirectoryHook())
  final Directory? modsDir;
  final bool hasCustomModsDir;
  @MappableField(hook: DirectoryHook())
  final Directory? customSavesPath;
  final bool useCustomSavesPath;
  @MappableField(hook: DirectoryHook())
  final Directory? customCoreFolderPath;
  final bool useCustomCoreFolderPath;

  final bool isRulesHotReloadEnabled;

  // Window State
  final double? windowXPos;
  final double? windowYPos;
  final double? windowWidth;
  final double? windowHeight;
  final bool? isMaximized;
  final bool? isMinimized;
  final TriOSTools defaultTool;

  final String? lastActiveJreVersion;
  final bool showCustomJreConsoleWindow;
  final String? themeKey;
  final bool? showChangelogNextLaunch;

  /// If true, TriOS acts as the launcher. If false, basically just clicks game exe.
  final bool enableDirectLaunch;
  final LaunchSettings launchSettings;
  final String? lastStarsectorVersion;
  final DashboardGridModUpdateVisibility dashboardGridModUpdateVisibility;
  @MappableField(hook: SafeDecodeHook())
  final WispGridState modsGridState;
  final WispGridState weaponsGridState;
  final WispGridState shipsGridState;

  // Mods Page
  final bool doubleClickForModsPanel;
  final bool pinFavorites;

  // Settings Page
  @Deprecated(
    "Bad idea, can get stuck in crash -> downgrade -> auto-update -> crash loop.",
  )
  final bool shouldAutoUpdateOnLaunch;
  final int secondsBetweenModFolderChecks;
  final int toastDurationSeconds;
  final int maxHttpRequestsAtOnce;
  final FolderNamingSetting folderNamingSetting;
  final int? keepLastNVersions;
  final bool? allowCrashReporting;
  final bool updateToPrereleases;
  final bool autoEnableAndDisableDependencies;
  final bool enableLauncherPrecheck;
  final ModUpdateBehavior modUpdateBehavior;
  final DashboardModListSort dashboardModListSort;
  final bool checkIfGameIsRunning;
  final CompressionLib compressionLib;
  final double windowScaleFactor;
  final bool enableAccessibilitySemanticsOnLinux;

  @Deprecated("Use getSentryUserId instead.")
  final String userId; // For Sentry
  final bool? hasHiddenForumDarkModeTip;

  // Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
  // in a different shared_prefs key.
  final String? activeModProfileId;

  final bool showForceUpdateWarning;
  final bool showDonationButton;

  Settings({
    this.gameDir,
    this.gameCoreDir,
    this.modsDir,
    this.hasCustomModsDir = false,
    this.isRulesHotReloadEnabled = false,
    this.windowXPos,
    this.windowYPos,
    this.windowWidth,
    this.windowHeight,
    this.isMaximized,
    this.isMinimized,
    this.defaultTool = TriOSTools.dashboard,
    this.lastActiveJreVersion,
    this.showCustomJreConsoleWindow = true,
    this.themeKey,
    this.showChangelogNextLaunch,
    this.enableDirectLaunch = false,
    this.launchSettings = const LaunchSettings(),
    this.lastStarsectorVersion,
    this.dashboardGridModUpdateVisibility =
        DashboardGridModUpdateVisibility.hideMuted,
    this.modsGridState = const WispGridState(
      groupingSetting: GroupingSetting(
        currentGroupedByKey: 'enabledState',
        isSortDescending: false,
      ),
      sortedColumnKey: 'name',
      columnsState: {},
    ),
    this.weaponsGridState = const WispGridState(
      groupingSetting: null,
      columnsState: {},
    ),
    this.shipsGridState = const WispGridState(
      groupingSetting: null,
      columnsState: {},
    ),
    this.customGameExePath,
    this.useCustomGameExePath = false,
    this.customSavesPath,
    this.useCustomSavesPath = false,
    this.customCoreFolderPath,
    this.useCustomCoreFolderPath = false,
    this.doubleClickForModsPanel = true,
    this.pinFavorites = true,
    this.shouldAutoUpdateOnLaunch = false,
    this.secondsBetweenModFolderChecks = 15,
    this.toastDurationSeconds = 7,
    this.maxHttpRequestsAtOnce = 20,
    this.folderNamingSetting = FolderNamingSetting.allFoldersVersioned,
    this.keepLastNVersions,
    this.allowCrashReporting,
    this.updateToPrereleases = false,
    this.autoEnableAndDisableDependencies = false,
    this.enableLauncherPrecheck = true,
    this.modUpdateBehavior = ModUpdateBehavior.switchToNewVersionIfWasEnabled,
    this.dashboardModListSort = DashboardModListSort.name,
    this.checkIfGameIsRunning = true,
    this.compressionLib = CompressionLib.sevenZip,
    this.windowScaleFactor = 1.0,
    this.enableAccessibilitySemanticsOnLinux = false,
    this.userId = '',
    this.hasHiddenForumDarkModeTip,
    this.activeModProfileId,
    this.showForceUpdateWarning = true,
    this.showDonationButton = true,
  });
}

@MappableEnum(defaultValue: FolderNamingSetting.allFoldersVersioned)
enum FolderNamingSetting {
  @MappableValue(0)
  doNotChangeNameForHighestVersion,
  @MappableValue(1)
  allFoldersVersioned,
  @MappableValue(2)
  doNotChangeNamesEver,
}

@MappableEnum(defaultValue: ModUpdateBehavior.switchToNewVersionIfWasEnabled)
enum ModUpdateBehavior { doNotChange, switchToNewVersionIfWasEnabled }

@MappableEnum(defaultValue: DashboardGridModUpdateVisibility.hideMuted)
enum DashboardGridModUpdateVisibility { allVisible, hideMuted, hideAll }

@MappableEnum(defaultValue: CompressionLib.sevenZip)
enum CompressionLib { sevenZip, libarchive }

@MappableEnum(defaultValue: DashboardModListSort.name)
enum DashboardModListSort { name, author, version, vram, gameVersion, enabled }
