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
@MappableClass()
class Settings with SettingsMappable {
  @MappableField(hook: DirectoryHook())
  final Directory? gameDir;
  @MappableField(hook: DirectoryHook())
  final Directory? gameCoreDir;
  @MappableField(hook: DirectoryHook())
  final Directory? modsDir;
  final bool hasCustomModsDir;
  final bool isRulesHotReloadEnabled;

  // Window State
  final double? windowXPos;
  final double? windowYPos;
  final double? windowWidth;
  final double? windowHeight;
  final bool? isMaximized;
  final bool? isMinimized;
  final TriOSTools? defaultTool;

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
  final String? customGameExePath;
  final bool useCustomGameExePath;

  // Mods Page
  final bool doubleClickForModsPanel;

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
  final bool checkIfGameIsRunning;
  final CompressionLib compressionLib;
  final double windowScaleFactor;

  @Deprecated("Use getSentryUserId instead.")
  final String userId; // For Sentry
  final bool? hasHiddenForumDarkModeTip;

  // Mod profiles are stored in [ModProfilesSettings] and [ModProfileManagerNotifier],
  // in a different shared_prefs key.
  final String? activeModProfileId;

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
    this.defaultTool,
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
    this.customGameExePath,
    this.useCustomGameExePath = false,
    this.doubleClickForModsPanel = true,
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
    this.checkIfGameIsRunning = true,
    this.compressionLib = CompressionLib.sevenZip,
    this.windowScaleFactor = 1.0,
    this.userId = '',
    this.hasHiddenForumDarkModeTip,
    this.activeModProfileId,
  });
}

@MappableEnum()
enum FolderNamingSetting {
  @MappableValue(0)
  doNotChangeNameForHighestVersion,
  @MappableValue(1)
  allFoldersVersioned,
  @MappableValue(2)
  doNotChangeNamesEver,
}

@MappableEnum()
enum ModUpdateBehavior { doNotChange, switchToNewVersionIfWasEnabled }

@MappableEnum()
enum DashboardGridModUpdateVisibility { allVisible, hideMuted, hideAll }

@MappableEnum()
enum CompressionLib { sevenZip, libarchive }
